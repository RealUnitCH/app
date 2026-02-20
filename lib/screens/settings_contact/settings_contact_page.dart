import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_tile.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsContactPage extends StatelessWidget {
  const SettingsContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).contact),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 16.0,
          ),
          child: Column(
            spacing: 20.0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                spacing: 12.0,
                children: [
                  SettingsTile(
                    icon: Icons.phone_outlined,
                    title: S.of(context).phone,
                    subtitle: '+41 41 761 00 90',
                    onTap: () => launchUrl(Uri.parse('tel:+41417610090')),
                  ),
                  SettingsTile(
                    icon: Icons.email_outlined,
                    title: S.of(context).email,
                    subtitle: 'info@realunit.ch',
                    onTap: () => launchUrl(Uri.parse('mailto:info@realunit.ch')),
                  ),
                  SettingsTile(
                    icon: Icons.language_outlined,
                    title: S.of(context).website,
                    subtitle: 'realunit.ch',
                    onTap: () => context.push(
                      '/webView',
                      extra: WebViewRouteParams(
                        title: S.of(context).website,
                        url: Uri.parse('https://realunit.ch'),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: .start,
                spacing: 12.0,
                children: [
                  Text(
                    S.of(context).imprint,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      height: 24 / 18,
                      color: RealUnitColors.neutral900,
                    ),
                  ),
                  const SettingsTile(
                    icon: Icons.business_outlined,
                    title: 'RealUnit Schweiz AG',
                    subtitle: 'Schochenmühlestrasse 6\n6340 Baar, Schweiz',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
