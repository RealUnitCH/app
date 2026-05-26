import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/support/cubits/support_page/support_page_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/support_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupportPageCubit(getIt<DfxKycService>()),
      child: const SupportView(),
    );
  }
}

class SupportView extends StatelessWidget {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).contactSupport),
      ),
      body: BlocConsumer<SupportPageCubit, SupportPageState>(
        // Listener only reacts to terminal side-effect states.
        // `SupportPageNavigating` is transient (loading-indicator marker)
        // and `SupportPageIdle` is the resting state — neither carries a
        // navigation/snackbar action, so they must NOT trigger the
        // listener.
        listenWhen: (previous, current) =>
            current is SupportPageNavigateToCreate ||
            current is SupportPageNavigateToEmailThenCreate ||
            current is SupportPageNavigationFailure,
        listener: (context, state) async {
          if (state is SupportPageNavigateToCreate) {
            // The cubit's terminal navigation states fire once per
            // user-initiated tap; the view performs the actual push and
            // then resets the cubit so subsequent rebuilds don't re-fire.
            context.read<SupportPageCubit>().acknowledge();
            context.pushNamed(SupportRoutes.createTicket);
            return;
          }
          if (state is SupportPageNavigateToEmailThenCreate) {
            // Push the email-capture page; it pops with `true` only when
            // the user successfully registered an email. Acknowledge the
            // cubit *after* the navigation has completed so the page
            // doesn't re-trigger this branch on rebuild while the email
            // page is still on top of the stack.
            final captured = await context.pushNamed<bool>(SupportRoutes.emailCapture);
            if (!context.mounted) return;
            context.read<SupportPageCubit>().acknowledge();
            if (captured == true && context.mounted) {
              context.pushNamed(SupportRoutes.createTicket);
            }
            return;
          }
          if (state is SupportPageNavigationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: RealUnitColors.status.red600,
              ),
            );
            context.read<SupportPageCubit>().acknowledge();
          }
        },
        builder: (context, state) {
          // Tiles are ALWAYS rendered. Only their tappability changes
          // while the cubit is resolving the user's mail status; tapping
          // again during that window would be a no-op anyway because the
          // cubit's `requestCreateTicket()` would early-out on the same
          // pending future. Disabling the onTap is the simplest way to
          // communicate that to the user while keeping the page contract
          // (both tiles always visible) intact.
          final isBusy = state is SupportPageNavigating;
          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    spacing: 12.0,
                    children: [
                      OutlinedTile(
                        leading: const Icon(
                          Icons.format_list_bulleted_add,
                          color: RealUnitColors.realUnitBlue,
                          size: 24,
                        ),
                        title: S.of(context).supportCreateTicket,
                        subtitle: S.of(context).supportCreateTicketDescription,
                        onTap: isBusy
                            ? null
                            : () => context.read<SupportPageCubit>().requestCreateTicket(),
                        trailingIcon: Icons.chevron_right_rounded,
                      ),
                      OutlinedTile(
                        leading: const Icon(
                          Icons.format_list_bulleted_outlined,
                          color: RealUnitColors.realUnitBlue,
                          size: 24,
                        ),
                        title: S.of(context).supportMyTickets,
                        subtitle: S.of(context).supportMyTicketsDescription,
                        // Viewing one's own (empty) ticket list does not
                        // need an email — only the *create* endpoint
                        // rejects `mail == null` on the backend. We keep
                        // this tap direct, both as a smaller surface area
                        // for bugs and as documented in the change brief.
                        onTap: isBusy ? null : () => context.pushNamed(SupportRoutes.tickets),
                        trailingIcon: Icons.chevron_right_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              if (isBusy)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
