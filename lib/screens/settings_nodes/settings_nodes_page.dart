import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/utils/asset_logo.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

class SettingsNodesPage extends StatelessWidget {
  const SettingsNodesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: CupertinoNavigationBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: RealUnitColors.realUnitBlack,
              size: 24,
            ),
          ),
          middle: Text(
            S.of(context).settingsNodes,
            style: kPageTitleTextStyle,
          ),
          border: null,
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: BlocBuilder<SettingsBloc, SettingsState>(
              bloc: getIt<SettingsBloc>(),
              builder: (context, state) => SettingsSections(
                settings: Blockchain.values
                    .map(
                      (blockchain) => SettingOption(
                        title: blockchain.name,
                        leading: Image.asset(
                          getChainImagePath(blockchain.chainId),
                          width: 24,
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: RealUnitColors.realUnitBlack,
                        ),
                        onTap: () => context.push('/settings/nodes/${blockchain.chainId}'),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );
}
