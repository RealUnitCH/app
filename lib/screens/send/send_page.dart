import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/send/bloc/send_bloc.dart';
import 'package:realunit_wallet/screens/send/send_view.dart';

class SendRouteParams {
  final String receiver;
  final String amount;
  final Asset asset;

  const SendRouteParams({this.asset = dEUROAsset, this.receiver = '', this.amount = '0'});
}

class SendPage extends StatelessWidget {
  final SendRouteParams params;

  const SendPage({super.key, this.params = const SendRouteParams()});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => SendBloc(getIt<AppStore>(), getIt<BalanceService>(),
            asset: params.asset,
            receiver: params.receiver,
            amount: params.amount.isNotEmpty ? params.amount : '0'),
        child: SendView(receiver: params.receiver),
      );
}
