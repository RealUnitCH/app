import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_issue_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/support_service.dart';
import 'package:realunit_wallet/screens/support/cubits/support_tickets_cubit.dart';
import 'package:realunit_wallet/screens/support/cubits/support_tickets_state.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/support_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SupportTicketsPage extends StatelessWidget {
  const SupportTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupportTicketsCubit(getIt<SupportService>())..loadTickets(),
      child: const _SupportTicketsView(),
    );
  }
}

class _SupportTicketsView extends StatelessWidget {
  const _SupportTicketsView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.supportMyTickets),
      ),
      body: BlocBuilder<SupportTicketsCubit, SupportTicketsState>(
        builder: (context, state) {
          return switch (state) {
            SupportTicketsInitial() || SupportTicketsLoading() => const Center(
                child: CupertinoActivityIndicator(),
              ),
            SupportTicketsError(:final message) => Center(
                child: Text(message),
              ),
            SupportTicketsLoaded(:final tickets) => tickets.isEmpty
                ? Center(child: Text(s.supportNoTickets))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _TicketCard(
                      ticket: tickets[index],
                    ),
                  ),
          };
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportIssueDto ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(
        SupportRoutes.chat,
        pathParameters: {'uid': ticket.uid},
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: RealUnitColors.neutral200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ticket.isOpen ? RealUnitColors.green : RealUnitColors.neutral400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(ticket.created),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: RealUnitColors.neutral500,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: RealUnitColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
