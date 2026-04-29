import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
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
                      SettingsContactSuccess(:final emailSet) =>
                        emailSet
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
                  OutlinedTile(
                    leading: const Icon(
                      Icons.phone_outlined,
                      color: RealUnitColors.realUnitBlue,
                      size: 24,
                    ),
                    title: S.of(context).phone,
                    subtitle: '+41 41 761 00 90',
                    onTap: () => launchUrl(Uri.parse('tel:+41417610090')),
                    trailingIcon: Icons.open_in_new_outlined,
                  ),
                  OutlinedTile(
                    leading: const Icon(
                      Icons.email_outlined,
                      color: RealUnitColors.realUnitBlue,
                      size: 24,
                    ),
                    title: S.of(context).email,
                    subtitle: 'info@realunit.ch',
                    onTap: () => launchUrl(Uri.parse('mailto:info@realunit.ch')),
                    trailingIcon: Icons.open_in_new_outlined,
                  ),
                  OutlinedTile(
                    leading: const Icon(
                      Icons.language_outlined,
                      color: RealUnitColors.realUnitBlue,
                      size: 24,
                    ),
                    title: S.of(context).website,
                    subtitle: 'realunit.ch',
                    onTap: () => context.pushNamed(
                      AppRoutes.webView,
                      extra: WebViewRouteParams(
                        title: S.of(context).website,
                        url: Uri.parse('https://realunit.ch'),
                      ),
                    ),
                    trailingIcon: Icons.open_in_new_outlined,
                  ),
                ],
              ),
              Column(
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
                  const OutlinedTile(
                    leading: Icon(
                      Icons.business_outlined,
                      color: RealUnitColors.realUnitBlue,
                      size: 24,
                    ),
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
