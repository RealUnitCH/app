import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_company_info_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/settings_contact/cubit/settings_contact_cubit.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/support_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsContactPage extends StatelessWidget {
  const SettingsContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsContactCubit(
        getIt<DfxKycService>(),
        getIt<DfxCompanyInfoService>(),
      ),
      child: const SettingsContactView(),
    );
  }
}

class SettingsContactView extends StatelessWidget {
  const SettingsContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).contact),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const .symmetric(
            horizontal: 20.0,
            vertical: 16.0,
          ),
          child: Column(
            spacing: 20.0,
            crossAxisAlignment: .start,
            children: [
              Column(
                spacing: 12.0,
                children: [
                  BlocBuilder<SettingsContactCubit, SettingsContactState>(
                    builder: (context, state) => switch (state) {
                      SettingsContactSuccess(:final supportAvailable) =>
                        supportAvailable
                            ? OutlinedTile(
                                leading: const Icon(
                                  Icons.support_agent_outlined,
                                  color: RealUnitColors.realUnitBlue,
                                  size: 24,
                                ),
                                title: S.of(context).contactSupport,
                                subtitle: S.of(context).contactSupportDescription,
                                onTap: () => context.pushNamed(SupportRoutes.support),
                                trailingIcon: Icons.chevron_right_rounded,
                              )
                            : const SizedBox.shrink(),
                      SettingsContactLoading() => const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CupertinoActivityIndicator(),
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                  BlocBuilder<SettingsContactCubit, SettingsContactState>(
                    builder: (context, state) {
                      final info = state is SettingsContactSuccess ? state.companyInfo : null;
                      if (info == null) return const SizedBox.shrink();
                      return Column(
                        spacing: 12.0,
                        children: [
                          if (info.phone != null)
                            OutlinedTile(
                              leading: const Icon(
                                Icons.phone_outlined,
                                color: RealUnitColors.realUnitBlue,
                                size: 24,
                              ),
                              title: S.of(context).phone,
                              subtitle: info.phone!,
                              onTap: () => launchUrl(
                                Uri.parse('tel:${info.phone!.replaceAll(RegExp(r'[^+\d]'), '')}'),
                              ),
                              trailingIcon: Icons.open_in_new_outlined,
                            ),
                          if (info.email != null)
                            OutlinedTile(
                              leading: const Icon(
                                Icons.email_outlined,
                                color: RealUnitColors.realUnitBlue,
                                size: 24,
                              ),
                              title: S.of(context).email,
                              subtitle: info.email!,
                              onTap: () => launchUrl(Uri.parse('mailto:${info.email}')),
                              trailingIcon: Icons.open_in_new_outlined,
                            ),
                          if (info.website != null)
                            OutlinedTile(
                              leading: const Icon(
                                Icons.language_outlined,
                                color: RealUnitColors.realUnitBlue,
                                size: 24,
                              ),
                              title: S.of(context).website,
                              subtitle: info.website!,
                              onTap: () => context.pushNamed(
                                AppRoutes.webView,
                                extra: WebViewRouteParams(
                                  title: S.of(context).website,
                                  url: Uri.parse(
                                    info.website!.startsWith('http')
                                        ? info.website!
                                        : 'https://${info.website}',
                                  ),
                                ),
                              ),
                              trailingIcon: Icons.open_in_new_outlined,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              BlocBuilder<SettingsContactCubit, SettingsContactState>(
                builder: (context, state) {
                  final info = state is SettingsContactSuccess ? state.companyInfo : null;
                  if (info == null) return const SizedBox.shrink();
                  final address = info.address;
                  final subtitleLines = <String>[];
                  if (address?.street != null) subtitleLines.add(address!.street!);
                  if (address?.zip != null || address?.city != null || address?.country != null) {
                    final secondLine = [
                      address?.zip,
                      address?.city,
                      address?.country,
                    ].whereType<String>().join(' ');
                    if (secondLine.trim().isNotEmpty) subtitleLines.add(secondLine);
                  }
                  return Column(
                    crossAxisAlignment: .start,
                    spacing: 12.0,
                    children: [
                      Text(
                        S.of(context).imprint,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 18,
                          height: 24 / 18,
                        ),
                      ),
                      OutlinedTile(
                        leading: const Icon(
                          Icons.business_outlined,
                          color: RealUnitColors.realUnitBlue,
                          size: 24,
                        ),
                        title: info.name,
                        subtitle: subtitleLines.isEmpty ? '' : subtitleLines.join('\n'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
