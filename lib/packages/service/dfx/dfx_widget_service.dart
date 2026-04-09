import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

class DfxWidgetService extends DFXAuthService {
  DfxWidgetService(super.appStore);

  @override
  AWalletAccount get wallet => appStore.wallet.currentAccount;

  @override
  String get walletAddress => wallet.primaryAddress.address.hexEip55;

  bool get isAvailable => appStore.dfxAuthToken != null;
}
