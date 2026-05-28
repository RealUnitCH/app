import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_support_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/screens/support/cubits/support_create_ticket/support_create_ticket_cubit.dart';
import 'package:realunit_wallet/screens/support/cubits/support_create_ticket/support_create_ticket_state.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/tag_selection.dart';

class SupportCreateTicketPage extends StatelessWidget {
  const SupportCreateTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupportCreateTicketCubit(
        getIt<DfxSupportService>(),
      ),
      child: const SupportCreateTicketView(),
    );
  }
}

class SupportCreateTicketView extends StatelessWidget {
  const SupportCreateTicketView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).supportCreateTicket),
      ),
      body: BlocConsumer<SupportCreateTicketCubit, SupportCreateTicketState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).supportTicketCreated),
                backgroundColor: RealUnitColors.green,
              ),
            );
            context.pop();
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: RealUnitColors.status.red600,
              ),
            );
          }
        },
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: SafeArea(
                      child: Padding(
                        padding: const .symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: .start,
                          spacing: 20.0,
                          children: [
                            Column(
                              crossAxisAlignment: .start,
                              spacing: 12.0,
                              children: [
                                Text(
                                  S.of(context).supportSelectType,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: .w600,
                                  ),
                                ),
                                TagSelection<SupportIssueType>(
                                  items: [
                                    (
                                      SupportIssueType.genericIssue,
                                      S.of(context).supportGenericIssue,
                                      Icons.help_outline,
                                    ),
                                    (
                                      SupportIssueType.bugReport,
                                      S.of(context).supportBugReport,
                                      Icons.bug_report_outlined,
                                    ),
                                    (
                                      SupportIssueType.kycIssue,
                                      S.of(context).supportKycIssue,
                                      Icons.verified_user_outlined,
                                    ),
                                  ],
                                  selected: state.selectedType,
                                  onSelected: context.read<SupportCreateTicketCubit>().selectType,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: .start,
                              spacing: 12.0,
                              children: [
                                Text(
                                  S.of(context).supportTypeMessage,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: .w600,
                                  ),
                                ),
                                TextField(
                                  onChanged: context.read<SupportCreateTicketCubit>().updateMessage,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hintText: S.of(context).supportEnterMessage,
                                    border: OutlineInputBorder(
                                      borderRadius: .circular(12),
                                      borderSide: const BorderSide(
                                        color: RealUnitColors.neutral200,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: .circular(12),
                                      borderSide: const BorderSide(
                                        color: RealUnitColors.neutral200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: .circular(12),
                                      borderSide: const BorderSide(
                                        color: RealUnitColors.realUnitBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            AppFilledButton(
                              state: state.isSubmitting ? .loading : .idle,
                              onPressed: state.canSubmit
                                  ? () => context.read<SupportCreateTicketCubit>().submit()
                                  : null,
                              label: S.of(context).supportSend,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
