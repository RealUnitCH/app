import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_tile.dart';
import 'package:realunit_wallet/setup/routing/routes/support_routes.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.contactSupport),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 16.0,
          ),
          child: Column(
            spacing: 12.0,
            children: [
              SettingsTile(
                icon: Icons.add_comment_outlined,
                title: s.supportCreateTicket,
                subtitle: s.supportCreateTicketDescription,
                onTap: () => context.pushNamed(SupportRoutes.createTicket),
              ),
              SettingsTile(
                icon: Icons.list_alt_outlined,
                title: s.supportMyTickets,
                subtitle: s.supportMyTicketsDescription,
                onTap: () => context.pushNamed(SupportRoutes.tickets),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
