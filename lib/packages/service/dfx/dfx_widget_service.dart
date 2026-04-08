import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

class DfxWidgetService extends DFXAuthService {
  DfxWidgetService(super.appStore, this._settingsRepository);

  final SettingsRepository _settingsRepository;

  String get title => 'DFX.swiss';

  @override
  AWalletAccount get wallet => appStore.wallet.currentAccount;

  @override
  String get walletAddress => wallet.primaryAddress.address.hexEip55;

  String get assetIn => 'EUR';

  String get assetOut => 'DEURO';

  String get langCode => _settingsRepository.language;

  bool get isAvailable => appStore.dfxAuthToken != null;

  static List<String> supportedAssets = [
    'Ethereum/DEURO',
    'Polygon/DEURO',
    'Base/DEURO',
    'Optimism/DEURO',
    'Arbitrum/DEURO',

    'Ethereum/ETH',
    'Base/ETH',
    'Optimism/ETH',
    'Arbitrum/ETH',
    'Polygon/POL',
  ];

  String get blockchain => 'Ethereum';

}
