import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';

class DfxWidgetService extends DFXAuthService {
  DfxWidgetService(super.appStore, super.walletService);

  bool get isAvailable => appStore.sessionCache.authToken != null;
}
