import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsContactPage extends StatelessWidget {
  const SettingsContactPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).contact),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SettingsSections(
                title: S.of(context).contact,
                settings: [
                  SettingOption(
                    title: S.of(context).phone,
                    subtitle: '+41 41 761 00 90',
                    leading: const Icon(Icons.phone_outlined, size: 24),
                    onTap: () => launchUrl(Uri.parse('tel:+41417610090')),
                  ),
                  SettingOption(
                    title: S.of(context).email,
                    subtitle: 'info@realunit.ch',
                    leading: const Icon(Icons.email_outlined, size: 24),
                    onTap: () => launchUrl(Uri.parse('mailto:info@realunit.ch')),
                  ),
                  SettingOption(
                    title: S.of(context).website,
                    subtitle: 'realunit.ch',
                    leading: const Icon(Icons.language_outlined, size: 24),
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
              SettingsSections(
                title: S.of(context).imprint,
                settings: [
                  const SettingOption(
                    title: 'RealUnit Schweiz AG',
                    subtitle: 'Schochenmühlestrasse 6\n6340 Baar, Schweiz',
                    leading: Icon(Icons.business_outlined, size: 24),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
