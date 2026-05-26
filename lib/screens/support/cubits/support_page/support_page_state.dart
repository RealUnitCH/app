part of 'support_page_cubit.dart';

sealed class SupportPageState extends Equatable {
  const SupportPageState();

  @override
  List<Object?> get props => [];
}

/// Tiles are tappable, no in-flight navigation work.
final class SupportPageIdle extends SupportPageState {
  const SupportPageIdle();
}

/// The user has tapped "Create ticket"; the cubit is fetching the user
/// record. Tiles must be disabled in this state and a small activity
/// indicator should be shown so the tap registers visually.
final class SupportPageNavigating extends SupportPageState {
  const SupportPageNavigating();
}

/// Mail present — the view should push `SupportRoutes.createTicket` and
/// then call `acknowledge()` to return to `Idle`.
final class SupportPageNavigateToCreate extends SupportPageState {
  const SupportPageNavigateToCreate();
}

/// Mail missing — the view should push `SupportRoutes.emailCapture`,
/// await its pop result, and (on a `true` result) chain
/// `SupportRoutes.createTicket`. Always call `acknowledge()` after the
/// email-capture page has returned, whether or not the chain fires.
final class SupportPageNavigateToEmailThenCreate extends SupportPageState {
  const SupportPageNavigateToEmailThenCreate();
}

/// `getUser()` threw; the view shows a snackbar with `message` and then
/// calls `acknowledge()`.
final class SupportPageNavigationFailure extends SupportPageState {
  final String message;

  const SupportPageNavigationFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
