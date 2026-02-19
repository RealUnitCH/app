import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsContactPage extends StatelessWidget {
  const SettingsContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.contact),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildContactTile(
                icon: Icons.phone_outlined,
                title: s.phone,
                subtitle: '+41 41 761 00 90',
                onTap: () => launchUrl(Uri.parse('tel:+41417610090')),
              ),
              const SizedBox(height: 12),
              _buildContactTile(
                icon: Icons.email_outlined,
                title: s.email,
                subtitle: 'info@realunit.ch',
                onTap: () => launchUrl(Uri.parse('mailto:info@realunit.ch')),
              ),
              const SizedBox(height: 12),
              _buildContactTile(
                icon: Icons.language_outlined,
                title: s.website,
                subtitle: 'realunit.ch',
                onTap: () => context.push(
                  '/webView',
                  extra: WebViewRouteParams(
                    title: s.website,
                    url: Uri.parse('https://realunit.ch'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                s.imprint,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 24 / 18,
                  color: RealUnitColors.neutral900,
                ),
              ),
              const SizedBox(height: 12),
              _buildContactTile(
                icon: Icons.business_outlined,
                title: 'RealUnit Schweiz AG',
                subtitle: 'Schochenmühlestrasse 6\n6340 Baar, Schweiz',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: RealUnitColors.neutral200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: RealUnitColors.realUnitBlue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 22 / 16,
                        fontWeight: FontWeight.w500,
                        color: RealUnitColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        color: RealUnitColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: RealUnitColors.neutral400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
