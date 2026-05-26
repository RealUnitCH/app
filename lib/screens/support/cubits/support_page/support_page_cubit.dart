import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';

part 'support_page_state.dart';

/// Drives the navigation away from `SupportPage` when the user taps the
/// "Create new ticket" tile.
///
/// The page itself renders both tiles unconditionally. The Mail-gate is
/// applied here, after the user has expressed intent, so a pre-signin user
/// still sees the tile, is given a chance to add an email, and ends up on
/// the ticket form — instead of getting the cryptic
/// `BadRequestException('Mail is missing')` snackbar from the create-ticket
/// submit endpoint.
///
/// `My Tickets` is intentionally NOT routed through this cubit: viewing an
/// empty list of one's own tickets is harmless and does not require an
/// email — only the `POST /v1/support/issue` path on the backend rejects
/// `userData.mail == null`.
class SupportPageCubit extends Cubit<SupportPageState> {
  final DfxKycService _kycService;

  SupportPageCubit(DfxKycService kycService)
    : _kycService = kycService,
      super(const SupportPageIdle());

  /// Resolves whether the current user already has a mail on record, then
  /// emits the matching side-effect state for the view's `BlocListener` to
  /// pick up.
  ///
  /// State split:
  /// - `SupportPageNavigating` — transient, fetch-in-flight marker. The
  ///   view uses it to disable the tiles and show a loading indicator; it
  ///   is NOT a side-effect state, so the view's `BlocListener` ignores
  ///   it.
  /// - `SupportPageNavigateToCreate` — terminal side-effect state. Mail
  ///   present, the view pushes the create-ticket route.
  /// - `SupportPageNavigateToEmailThenCreate` — terminal side-effect
  ///   state. Mail missing, the view pushes the email-capture page first
  ///   and chains the create-ticket push on a successful capture.
  /// - `SupportPageNavigationFailure` — terminal side-effect state.
  ///   `getUser()` threw, the view shows a snackbar.
  ///
  /// Each terminal side-effect state is acknowledged by the view (via
  /// [acknowledge]) so the cubit returns to `Idle` and the listener
  /// doesn't re-fire its one-shot navigation on the next rebuild.
  Future<void> requestCreateTicket() async {
    // Guard against re-entry: a second tap while the first fetch is
    // still in flight must not start a parallel `getUser()` call. The
    // view also disables the tile's `onTap` in this state, but the
    // cubit owns its own invariant — programmatic callers (tests,
    // future deep-links) get the same protection.
    if (state is SupportPageNavigating) return;

    emit(const SupportPageNavigating());

    try {
      final user = await _kycService.getUser();
      if (user.mail != null) {
        emit(const SupportPageNavigateToCreate());
      } else {
        emit(const SupportPageNavigateToEmailThenCreate());
      }
    } on ApiException catch (e) {
      developer.log(
        'Could not load user for support navigation: ${e.message}',
        name: '$SupportPageCubit',
      );
      emit(SupportPageNavigationFailure(message: e.message));
    } catch (e) {
      developer.log(
        'Could not load user for support navigation: $e',
        name: '$SupportPageCubit',
      );
      emit(SupportPageNavigationFailure(message: e.toString()));
    }
  }

  /// Resets the cubit back to `Idle` after the view has handled a
  /// side-effect state (navigation or error snackbar). Without this the
  /// `BlocListener` would re-fire its terminal action whenever the page
  /// rebuilds.
  void acknowledge() {
    emit(const SupportPageIdle());
  }
}
