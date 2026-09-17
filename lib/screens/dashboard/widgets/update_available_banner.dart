import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/io/installer_package_adapter.dart';
import 'package:realunit_wallet/packages/io/installer_package_port.dart';
import 'package:realunit_wallet/packages/utils/store_update_target.dart';
import 'package:realunit_wallet/screens/update_required/bloc/client_policy_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateAvailableBanner extends StatefulWidget {
  const UpdateAvailableBanner({
    super.key,
    this.installerPackage = const InstallerPackageAdapter(),
  });

  final InstallerPackagePort installerPackage;

  @override
  State<UpdateAvailableBanner> createState() => _UpdateAvailableBannerState();
}

class _UpdateAvailableBannerState extends State<UpdateAvailableBanner> {
  String? _installer;

  @override
  void initState() {
    super.initState();
    widget.installerPackage.readInstallerPackage().then((value) {
      if (!mounted) return;
      setState(() => _installer = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dashboard goldens host DashboardView without this cubit.
    if (BlocProvider.maybeOf<ClientPolicyCubit>(context) == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<ClientPolicyCubit, ClientPolicyState>(
      builder: (context, state) {
        final cubit = context.read<ClientPolicyCubit>();
        if (!cubit.showSoftBanner) return const SizedBox.shrink();
        if (state is! ClientPolicyLoaded) return const SizedBox.shrink();

        final policy = state.policy;
        final primaryUrl = pickStoreUpdate(
          isIOS: Platform.isIOS,
          installerPackage: _installer,
          policy: policy,
        ).primaryUrl;

        return OutlinedTile(
          leading: const ExcludeSemantics(
            child: Icon(
              Icons.system_update_alt,
              color: RealUnitColors.realUnitBlue,
              size: 24,
            ),
          ),
          title: S.of(context).updateAvailableBannerTitle,
          subtitle: S.of(context).updateAvailableBannerBody,
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => cubit.dismissSoft(policy.latestVersion ?? ''),
          ),
          onTap: primaryUrl == null
              ? null
              : () => launchUrl(
                    Uri.parse(primaryUrl),
                    mode: LaunchMode.externalApplication,
                  ),
        );
      },
    );
  }
}
