// Gate for the holding-amount skip bug: Balance.== used to ignore amount, so
// Cubit.emit / BlocBuilder / BlocListener skipped after the first emit.
// SendAmountPage constructs a real SellBalanceCubit(getIt<BalanceRepository>(),
// getIt<AppStore>()) over a StreamController — do not substitute a mock cubit.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/send/send_amount_page.dart';

import '../../helper/helper.dart';

class _MockBalanceRepository extends Mock implements BalanceRepository {}

class _MockAppStore extends Mock implements AppStore {}

class _MockApiConfig extends Mock implements ApiConfig {}

void main() {
  Balance balanceOf(BigInt value) => Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: '0xwallet',
        balance: value,
        asset: realUnitAsset,
      );

  late _MockBalanceRepository balanceRepo;
  late StreamController<Balance> controller;

  setUpAll(() {
    registerFallbackValue(
      Balance(
        chainId: 1,
        contractAddress: '0x',
        walletAddress: '0x',
        balance: BigInt.zero,
        asset: realUnitAsset,
      ),
    );
  });

  void registerGraph() {
    final getIt = GetIt.instance;
    controller = StreamController<Balance>.broadcast();
    balanceRepo = _MockBalanceRepository();
    when(() => balanceRepo.watchBalance(any())).thenAnswer(
      (_) => controller.stream,
    );
    getIt.registerFactory<BalanceRepository>(() => balanceRepo);
    final appStore = _MockAppStore();
    final apiConfig = _MockApiConfig();
    when(() => apiConfig.asset).thenReturn(realUnitAsset);
    when(() => appStore.apiConfig).thenReturn(apiConfig);
    when(() => appStore.primaryAddress).thenReturn('0xwallet');
    getIt.registerSingleton<AppStore>(appStore);
  }

  tearDown(() async {
    await controller.close();
    await GetIt.instance.reset();
  });

  Future<void> pumpAvailable(WidgetTester tester, BigInt amount) async {
    controller.add(balanceOf(amount));
    await tester.pump();
    await tester.pump();
  }

  group('$SendAmountPage holding updates', () {
    testWidgets(
      'transferOut replaces the available amount (85194 then 85094)',
      (tester) async {
        registerGraph();
        await tester.pumpApp(const SendAmountPage(recipient: '0xRecipient'));
        await tester.pump();

        await pumpAvailable(tester, BigInt.from(85194));
        expect(find.text(S.current.sendAmountAvailable('85194')), findsOne);
        expect(find.text(S.current.sendAmountAvailable('85094')), findsNothing);

        await pumpAvailable(tester, BigInt.from(85094));
        expect(find.text(S.current.sendAmountAvailable('85094')), findsOne);
        expect(find.text(S.current.sendAmountAvailable('85194')), findsNothing);
      },
    );

    testWidgets(
      'transferIn replaces the available amount (77994 then 78094)',
      (tester) async {
        registerGraph();
        await tester.pumpApp(const SendAmountPage(recipient: '0xRecipient'));
        await tester.pump();

        await pumpAvailable(tester, BigInt.from(77994));
        expect(find.text(S.current.sendAmountAvailable('77994')), findsOne);
        expect(find.text(S.current.sendAmountAvailable('78094')), findsNothing);

        await pumpAvailable(tester, BigInt.from(78094));
        expect(find.text(S.current.sendAmountAvailable('78094')), findsOne);
        expect(find.text(S.current.sendAmountAvailable('77994')), findsNothing);
      },
    );
  });
}
