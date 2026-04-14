import 'package:realunit_wallet/packages/repository/asset_repository.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/setup/di.dart';

Future<void> setupDefaultAssets() async {
  for (final asset in defaultAssets) {
    await getIt<AssetRepository>().saveAsset(asset);
  }
}
