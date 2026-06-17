import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/repository/asset_repository.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/repository/supported_fiat_repository.dart';
import 'package:realunit_wallet/packages/repository/supported_language_repository.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/repository/wallet_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/service/debug_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_bank_account_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_blockchain_api_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_config_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_faucet_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_fiat_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_language_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_support_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_widget_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_account_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';
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

  // Warm the API-provided validation patterns so name/address form fields can
  // validate synchronously. Fire-and-forget: a failure here just means the
  // first KYC form defers to the server's authoritative validation.
  unawaited(
    getIt<DfxConfigService>().load().catchError(
      (Object error) => developer.log(
        'failed to preload validation config: $error',
        name: 'di',
        error: error,
      ),
    ),
  );
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
  getIt.registerLazySingleton(
    () => WalletService(
      getIt<BitboxService>(),
      getIt<WalletRepository>(),
      getIt<SettingsRepository>(),
      getIt<AppStore>(),
    ),
  );
  getIt.registerFactory(
    () => TransactionHistoryService(
      getIt<AppStore>(),
      getIt<WalletService>(),
      getIt<TransactionRepository>(),
    ),
  );

  getIt.registerLazySingleton(() => DfxConfigService(getIt<AppStore>()));
  getIt.registerCachedFactory(() => DfxCountryService(getIt<AppStore>()));
  getIt.registerLazySingleton(() => DfxFiatService(getIt<AppStore>()));
  getIt.registerLazySingleton(() => DfxLanguageService(getIt<AppStore>()));
  getIt.registerLazySingleton(
    () => SupportedFiatRepository(getIt<DfxFiatService>()),
  );
  getIt.registerLazySingleton(
    () => SupportedLanguageRepository(getIt<DfxLanguageService>()),
  );
  getIt.registerFactory(
    () => DfxBankAccountService(getIt<AppStore>(), getIt<WalletService>()),
  );
  getIt.registerFactory(
    () => DfxBrokerbotService(getIt<AppStore>(), getIt<WalletService>()),
  );
  getIt.registerFactory(
    () => DfxKycService(getIt<AppStore>(), getIt<WalletService>()),
  );
  getIt.registerFactory(() => DFXPriceService(getIt<AppStore>()));
  getIt.registerFactory(
    () => DfxSupportService(getIt<AppStore>(), getIt<WalletService>()),
  );
  getIt.registerFactory(
    () => DfxFaucetService(getIt<AppStore>(), getIt<WalletService>()),
  );
  getIt.registerFactory(
    () => DfxBlockchainApiService(getIt<AppStore>(), getIt<WalletService>()),
  );
  getIt.registerFactory(
    () => DfxWidgetService(getIt<AppStore>(), getIt<WalletService>()),
  );

  getIt.registerFactory(() => RealUnitAccountService(getIt<AppStore>()));
  getIt.registerFactory(
    () => RealUnitBuyPaymentInfoService(getIt<AppStore>(), getIt<WalletService>()),
  );
  getIt.registerFactory(
    () => RealUnitPdfService(getIt<AppStore>(), getIt<WalletService>()),
  );
  getIt.registerFactory(
    () => RealUnitRegistrationService(getIt<AppStore>(), getIt<WalletService>()),
  );
  getIt.registerFactory(
    () => RealUnitSellPaymentInfoService(getIt<AppStore>(), getIt<WalletService>()),
  );
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
      onNetworkModeChanged: () {
        // Reference-data lists are scoped per backend (mainnet vs. testnet),
        // so drop their session caches when the user switches networks.
        getIt<DfxFiatService>().invalidateCache();
        getIt<DfxLanguageService>().invalidateCache();
        getIt<DfxConfigService>().invalidateCache();
      },
    ),
  );
  getIt.registerSingleton(
    HomeBloc(
      getIt<WalletService>(),
      getIt<BalanceService>(),
      getIt<TransactionHistoryService>(),
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

  // Migrate lockout state from SharedPreferences to SecureStorage
  final failedAttempts = prefs.getInt('pinFailedAttempts');
  if (failedAttempts != null) {
    await secureStorage.setPinFailedAttempts(failedAttempts);
    await prefs.remove('pinFailedAttempts');
  }

  final lockedUntil = prefs.getString('pinLockedUntil');
  if (lockedUntil != null) {
    final parsed = DateTime.tryParse(lockedUntil);
    if (parsed != null) await secureStorage.setPinLockedUntil(parsed);
    await prefs.remove('pinLockedUntil');
  }

  // Clean up legacy isPinEnabled flag (now derived from PIN hash existence)
  await prefs.remove('isPinEnabled');
}
