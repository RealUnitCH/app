import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/setup/routing/routes/support_routes.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).contactSupport),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const .symmetric(
            horizontal: 20.0,
            vertical: 12.0,
          ),
          child: Column(
            spacing: 12.0,
            children: [
              OutlinedTile(
                leadingIcon: Icons.format_list_bulleted_add,
                title: S.of(context).supportCreateTicket,
                subtitle: S.of(context).supportCreateTicketDescription,
                onTap: () => context.pushNamed(SupportRoutes.createTicket),
                trailingIcon: Icons.chevron_right_rounded,
              ),
              OutlinedTile(
                leadingIcon: Icons.format_list_bulleted_outlined,
                title: S.of(context).supportMyTickets,
                subtitle: S.of(context).supportMyTicketsDescription,
                onTap: () => context.pushNamed(SupportRoutes.tickets),
                trailingIcon: Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
