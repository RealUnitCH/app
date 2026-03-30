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
import 'package:realunit_wallet/widgets/primary_button.dart';

class SupportCreateTicketPage extends StatelessWidget {
  const SupportCreateTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupportCreateTicketCubit(getIt<DfxSupportService>()),
      child: const _SupportCreateTicketView(),
    );
  }
}

class _SupportCreateTicketView extends StatelessWidget {
  const _SupportCreateTicketView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return BlocListener<SupportCreateTicketCubit, SupportCreateTicketState>(
      listenWhen: (prev, curr) => prev.isSuccess != curr.isSuccess,
      listener: (context, state) {
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.supportTicketCreated)),
          );
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.supportCreateTicket),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, s.supportSelectType),
              const SizedBox(height: 12),
              const _IssueTypeSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle(context, s.supportTypeMessage),
              const SizedBox(height: 12),
              const _MessageInput(),
              const SizedBox(height: 24),
              const _SubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: RealUnitColors.neutral500,
      ),
    );
  }
}

class _IssueTypeSelector extends StatelessWidget {
  const _IssueTypeSelector();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<SupportCreateTicketCubit>();

    final types = [
      (SupportIssueType.transactionIssue, s.supportTransactionIssue, Icons.swap_horiz),
      (SupportIssueType.kycIssue, s.supportKycIssue, Icons.verified_user_outlined),
      (SupportIssueType.limitRequest, s.supportLimitRequest, Icons.trending_up),
      (SupportIssueType.bugReport, s.supportBugReport, Icons.bug_report_outlined),
      (SupportIssueType.genericIssue, s.supportGenericIssue, Icons.help_outline),
    ];

    return BlocBuilder<SupportCreateTicketCubit, SupportCreateTicketState>(
      buildWhen: (prev, curr) => prev.selectedType != curr.selectedType,
      builder: (context, state) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            final isSelected = state.selectedType == type.$1;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.$3,
                    size: 18,
                    color: isSelected ? RealUnitColors.basic.white : RealUnitColors.neutral600,
                  ),
                  const SizedBox(width: 6),
                  Text(type.$2),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => cubit.selectType(type.$1),
              selectedColor: RealUnitColors.realUnitBlue,
              backgroundColor: RealUnitColors.basic.white,
              labelStyle: TextStyle(
                color: isSelected ? RealUnitColors.basic.white : RealUnitColors.neutral600,
              ),
              side: BorderSide(
                color: isSelected ? RealUnitColors.realUnitBlue : RealUnitColors.neutral200,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<SupportCreateTicketCubit>();

    return TextField(
      onChanged: cubit.updateMessage,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: s.supportEnterMessage,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RealUnitColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RealUnitColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RealUnitColors.realUnitBlue),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return BlocBuilder<SupportCreateTicketCubit, SupportCreateTicketState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: s.supportSend,
            onPressed: state.canSubmit
                ? () => context.read<SupportCreateTicketCubit>().submit()
                : null,
            isLoading: state.isSubmitting,
          ),
        );
      },
    );
  }
}
