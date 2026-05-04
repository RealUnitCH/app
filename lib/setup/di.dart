import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/repository/asset_repository.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/repository/wallet_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/service/debug_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_bank_account_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_support_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_widget_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_account_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/service/settings_service.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/setup/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final getIt = GetIt.instance;

Future<String> setupEssentials() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton(sharedPreferences);

  getIt.registerFactory(() => SettingsRepository(getIt<SharedPreferences>()));

  final secureStorage = const SecureStorage();
  getIt.registerSingleton(secureStorage);

  await _migrateSecurityFlags(sharedPreferences, secureStorage);

  final encryptionKey = await secureStorage.getEncryptionKey();

  if (encryptionKey == null) {
    if (await _existsDatabaseFile()) {
      throw Exception('Database found, but key is missing!');
    }
    final freshEncryptionKey = SecureStorage.getNewEncryptionKey();
    await secureStorage.setEncryptionKey(freshEncryptionKey);
    await getIt<SettingsRepository>().removeCurrentWalletId();

    return freshEncryptionKey;
  }

  return encryptionKey;
}

Future<void> finishSetup(String encryptionKey) async {
  getIt.registerSingleton(AppDatabase(encryptionKey));
  setupRepositories();

  getIt.registerSingleton(
    AppStore(
      () => ApiConfig(networkMode: getIt<SettingsRepository>().networkMode),
      SessionCache(getIt<CacheRepository>()),
    ),
  );

  setupServices();
  await setupBlocs();

  await setupDefaultAssets();
}

void setupRepositories() {
  getIt.registerFactory(
    () => WalletRepository(
      getIt<AppDatabase>(),
      getIt<SecureStorage>(),
    ),
  );
  getIt.registerFactory(() => BalanceRepository(getIt<AppDatabase>()));
  getIt.registerFactory(() => AssetRepository(getIt<AppDatabase>()));
  getIt.registerFactory(() => CacheRepository(getIt<AppDatabase>()));
  getIt.registerFactory(
    () => TransactionRepository(
      getIt<AppDatabase>(),
      getIt<AssetRepository>(),
    ),
  );
}

void setupServices() {
  getIt.registerSingleton(
    BalanceService(
      getIt<BalanceRepository>(),
      getIt<AppStore>(),
    ),
  );
  getIt.registerFactory(
    () => BiometricService(
      getIt<SecureStorage>(),
    ),
  );
  getIt.registerSingleton(BitboxService());
  getIt.registerFactory(
    () => WalletService(
      getIt<BitboxService>(),
      getIt<WalletRepository>(),
      getIt<SettingsRepository>(),
    ),
  );
  getIt.registerFactory(
    () => TransactionHistoryService(
      getIt<AppStore>(),
      getIt<TransactionRepository>(),
    ),
  );

  getIt.registerCachedFactory(() => DfxCountryService(getIt<AppStore>()));
  getIt.registerFactory(() => DfxBankAccountService(getIt<AppStore>()));
  getIt.registerFactory(() => DfxBrokerbotService(getIt<AppStore>()));
  getIt.registerFactory(() => DfxKycService(getIt<AppStore>()));
  getIt.registerFactory(() => DFXPriceService(getIt<AppStore>()));
  getIt.registerFactory(() => DfxSupportService(getIt<AppStore>()));
  getIt.registerFactory(
    () => DfxWidgetService(
      getIt<AppStore>(),
    ),
  );

  getIt.registerFactory(() => RealUnitAccountService(getIt<AppStore>()));
  getIt.registerFactory(() => RealUnitBuyPaymentInfoService(getIt<AppStore>()));
  getIt.registerFactory(() => RealUnitPdfService(getIt<AppStore>()));
  getIt.registerFactory(() => RealUnitRegistrationService(getIt<AppStore>()));
  getIt.registerFactory(() => RealUnitSellPaymentInfoService(getIt<AppStore>()));
  getIt.registerFactory(() => RealUnitWalletService(getIt<AppStore>()));
  getIt.registerFactory(() => SettingsService(getIt<SettingsRepository>()));
  getIt.registerFactory(
    () => DebugAuthService(getIt<AppStore>(), getIt<SharedPreferences>()),
  );
}

Future<void> setupBlocs() async {
  getIt.registerSingleton(
    SettingsBloc(
      getIt<SettingsRepository>(),
      () => getIt<DfxWidgetService>().refreshAuthToken(),
    ),
  );
  getIt.registerSingleton(
    HomeBloc(
      getIt<WalletService>(),
      getIt<BalanceService>(),
      getIt<TransactionHistoryService>(),
      getIt<DfxWidgetService>(),
      getIt<SettingsService>(),
      getIt<AppStore>(),
      getIt<BitboxService>(),
    ),
  );

  final pinAuthCubit = PinAuthCubit(getIt<SecureStorage>());
  await pinAuthCubit.initialize();
  getIt.registerSingleton(pinAuthCubit);
}

Future<bool> _existsDatabaseFile() async => File(await AppDatabase.getDatabasePath()).exists();

Future<void> _migrateSecurityFlags(
  SharedPreferences prefs,
  SecureStorage secureStorage,
) async {
  // Migrate isBiometricEnabled from SharedPreferences to SecureStorage
  final biometricEnabled = prefs.getBool('isBiometricEnabled');
  if (biometricEnabled != null) {
    await secureStorage.setIsBiometricEnabled(enabled: biometricEnabled);
    await prefs.remove('isBiometricEnabled');
  }

  // Clean up legacy SharedPreferences keys that are now in SecureStorage
  await Future.wait([
    prefs.remove('isPinEnabled'),
    prefs.remove('pinFailedAttempts'),
    prefs.remove('pinLockedUntil'),
  ]);
}
