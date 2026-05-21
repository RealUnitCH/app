import 'dart:async';

import 'package:bip39/bip39.dart' as bip39;
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/repository/wallet_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class WalletService {
  final WalletRepository _repository;
  final SettingsRepository _settingsRepository;
  final BitboxService _bitboxService;
  final AppStore _appStore;

  /// Auto-lock 60 s after each unlock, regardless of subsequent activity. The
  /// timer is armed in [ensureCurrentWalletUnlocked] and is NOT reset by user
  /// interaction — it caps the maximum lifetime of the in-memory mnemonic
  /// after an explicit unlock, not an idle window. Sized to comfortably
  /// outlast a normal sign-then-broadcast round-trip.
  static const Duration _postUnlockLockTimeout = Duration(seconds: 60);

  /// Cancellation guard for the post-unlock timer so a lock-during-test or a
  /// concurrent explicit lock doesn't double-fire.
  Timer? _postUnlockLockTimer;

  /// Active holders of the unlocked-wallet contract. Incremented on every
  /// [ensureCurrentWalletUnlocked] call, decremented on every matching
  /// [lockCurrentWallet] — the wallet only flips back to a view-wallet once
  /// the last holder has released. Closes the race where flow A locks
  /// between flow B's ensure and its sign, leaving B with a
  /// [SoftwareViewWallet] mid-flight and an [UnsupportedError] from the
  /// locked-credentials sentinel. The post-unlock timer bypasses the counter
  /// via [_forceLock] so the 60s safety net still caps the mnemonic lifetime
  /// even if a caller forgets to release.
  int _activeUnlockHolders = 0;

  /// Shared future for the currently-in-flight unlock, so two overlapping
  /// [ensureCurrentWalletUnlocked] calls reuse the same DB read + AES-GCM
  /// decrypt instead of triggering it twice. Cleared in `finally` so the
  /// next post-lock ensure starts a fresh unlock.
  Future<SoftwareWallet>? _unlockInFlight;

  WalletService(
    this._bitboxService,
    this._repository,
    this._settingsRepository,
    this._appStore,
  );

  Future<SoftwareWallet> createSeedWallet(String name) async {
    final mnemonic = bip39.generateMnemonic();
    return _persistSoftwareWallet(name, mnemonic);
  }

  Future<BitboxWallet> createBitboxWallet(String name) async {
    final address = await _bitboxService.bitboxManager.getETHAddress(1, "m/44'/60'/0'/0/0");
    final walletId = await _repository.createViewWallet(name, WalletType.bitbox, address);
    await setCurrentWallet(walletId);
    return BitboxWallet(walletId, name, address, _bitboxService);
  }

  Future<SoftwareWallet> restoreWallet(String name, String seed) async {
    final wallet = await _persistSoftwareWallet(name, seed);
    await _settingsRepository.saveCurrentWalletId(wallet.id);
    return wallet;
  }

  /// Builds the BIP32 wallet once to derive the public address, then persists
  /// `(encryptedSeed, address)` so app-start can render the dashboard from the
  /// cached address without re-running the derivation.
  Future<SoftwareWallet> _persistSoftwareWallet(String name, String seed) async {
    final fullWallet = SoftwareWallet(0, name, seed);
    final address = fullWallet.currentAccount.primaryAddress.address.hexEip55;
    final id = await _repository.createWallet(name, WalletType.software, seed, address);
    return SoftwareWallet(id, name, seed);
  }

  Future<DebugWallet> createDebugWallet(String address) async {
    final walletId = await _repository.createViewWallet('Debug', WalletType.debug, address);
    await _settingsRepository.saveCurrentWalletId(walletId);
    return DebugWallet(walletId, 'Debug', address);
  }

  /// Loads a wallet using only what's persisted in clear text — for software
  /// wallets this means a [SoftwareViewWallet] (address only, no mnemonic in
  /// memory). Use [unlockWalletById] when the private key is actually needed.
  Future<AWallet> getWalletById(int id) async {
    final info = (await _repository.getWalletInfo(id))!;
    final walletType = WalletType.values[info.type];
    switch (walletType) {
      case WalletType.software:
        // Legacy rows created before address-caching landed have an empty
        // address column — decrypt the mnemonic this one time, persist the
        // derived address back to the row, then keep using the fast path on
        // subsequent loads.
        if (info.address.isEmpty) {
          final unlocked = (await _repository.getUnlockedWalletById(id))!;
          final wallet = SoftwareWallet(unlocked.id, unlocked.name, unlocked.seed);
          await _repository.updateAddress(
            id,
            wallet.currentAccount.primaryAddress.address.hexEip55,
          );
          return wallet;
        }
        return SoftwareViewWallet(info.id, info.name, info.address);
      case WalletType.bitbox:
        return BitboxWallet(info.id, info.name, info.address, _bitboxService);
      case WalletType.debug:
        return DebugWallet(info.id, info.name, info.address);
    }
  }

  /// Decrypts the mnemonic and returns a [SoftwareWallet] ready to sign.
  /// Throws if the wallet type is not software.
  Future<SoftwareWallet> unlockWalletById(int id) async {
    final info = (await _repository.getUnlockedWalletById(id))!;
    if (WalletType.values[info.type] != WalletType.software) {
      throw StateError('unlockWalletById called for non-software wallet');
    }
    return SoftwareWallet(info.id, info.name, info.seed);
  }

  Future<void> setCurrentWallet(int walletId) async =>
      await _settingsRepository.saveCurrentWalletId(walletId);

  Future<AWallet> getCurrentWallet() async {
    final id = _settingsRepository.currentWalletId!;
    return getWalletById(id);
  }

  Future<SoftwareWallet> unlockCurrentWallet() async {
    final id = _settingsRepository.currentWalletId!;
    return unlockWalletById(id);
  }

  /// Promotes the currently loaded wallet from [SoftwareViewWallet] (address
  /// only) to a fully unlocked [SoftwareWallet] (mnemonic in memory) so the
  /// next sign operation can run. No-op for wallets that aren't locked.
  ///
  /// Owning the lifecycle here — instead of behind a callback wired onto
  /// [AppStore] — keeps the latter as a pure state container.
  ///
  /// Every call increments [_activeUnlockHolders]; callers must pair with
  /// exactly one [lockCurrentWallet] in a finally so concurrent sign flows
  /// don't tear the unlocked state out from under each other.
  Future<void> ensureCurrentWalletUnlocked() async {
    _activeUnlockHolders++;
    // Tracks whether THIS call's unlock landed in [AppStore.wallet]. When
    // the lock-during-flight invalidates the slot, the write is skipped and
    // arming the post-unlock timer would just point at a [SoftwareViewWallet]
    // — `_lockWalletInPlace` would safely no-op via `is! SoftwareWallet`, so
    // it's dead work, not a correctness bug. Skip the arm in that case.
    var landedInStore = false;
    if (_appStore.wallet is SoftwareViewWallet) {
      // Coalesce overlapping unlocks onto a single in-flight future so we
      // don't hammer the DB and re-run AES-GCM for every concurrent caller.
      final inFlight = _unlockInFlight ??= unlockCurrentWallet();
      try {
        final unlocked = await inFlight;
        // If [lockCurrentWallet] fired while this unlock was in flight, it
        // invalidates the slot (`_unlockInFlight = null`). Skip the write
        // so the mnemonic doesn't resurface in [AppStore.wallet] after the
        // user has already covered the app — closes the `_onHidden` race.
        if (identical(_unlockInFlight, inFlight)) {
          _appStore.wallet = unlocked;
          landedInStore = true;
        }
      } finally {
        // Only the caller that started the unlock clears the slot; later
        // joiners observe the field already nulled and skip the clear.
        if (identical(_unlockInFlight, inFlight)) _unlockInFlight = null;
      }
    } else {
      // Wallet was already unlocked (a previous holder's write is still in
      // place). Re-arming the safety net is the right call — extends the
      // 60 s window for the joining holder.
      landedInStore = true;
    }
    // Safety net: if a caller forgets to call lockCurrentWallet() after the
    // sign, drop the mnemonic anyway once the post-unlock window elapses. The
    // reviewer flagged "user signs once then leaves the app foregrounded" —
    // that path now caps at [_postUnlockLockTimeout]. Skip the arm when the
    // intervening lock invalidated our write: the timer would just fire
    // against a view-wallet (no-op) and we'd be doing dead work.
    if (landedInStore) _schedulePostUnlockLock();
  }

  /// Replaces the in-memory [SoftwareWallet] with its lock-screen-safe
  /// [SoftwareViewWallet] counterpart, dropping the mnemonic. Called after a
  /// sign operation completes so the private key isn't kept resident for the
  /// rest of the foreground session. No-op for wallet types that don't hold
  /// a mnemonic, and no-op when no wallet has been loaded yet.
  ///
  /// Respects [_activeUnlockHolders] — a second concurrent caller still
  /// holding the unlocked contract keeps the wallet unlocked. The 60s safety
  /// net runs through [_forceLock] instead so it can bypass the counter.
  Future<void> lockCurrentWallet() async {
    // Onboarding / pre-load guard. The app-lifecycle `hidden` hook can fire
    // before [HomeBloc] populates [AppStore.wallet] — making the precondition
    // explicit here keeps the lifecycle caller a one-liner and means a future
    // lockCurrentWallet extension (DB write, etc.) won't get its errors
    // silently caught at the call site.
    if (!_appStore.isWalletLoaded) return;

    if (_activeUnlockHolders > 0) _activeUnlockHolders--;
    if (_activeUnlockHolders > 0) return;
    // Invalidate any in-flight unlock so its resolution doesn't write the
    // unlocked [SoftwareWallet] back into [AppStore.wallet] after this lock —
    // the race the 60s safety net used to catch as defence-in-depth, now
    // closed at the source.
    _unlockInFlight?.ignore();
    _unlockInFlight = null;
    _postUnlockLockTimer?.cancel();
    _postUnlockLockTimer = null;
    _lockWalletInPlace();
  }

  void _schedulePostUnlockLock() {
    _postUnlockLockTimer?.cancel();
    _postUnlockLockTimer = Timer(_postUnlockLockTimeout, _forceLock);
  }

  /// Hard cap on the in-memory mnemonic lifetime. Bypasses
  /// [_activeUnlockHolders] so a stuck holder can't keep the key resident
  /// past the safety window.
  void _forceLock() {
    _activeUnlockHolders = 0;
    _postUnlockLockTimer = null;
    _lockWalletInPlace();
  }

  void _lockWalletInPlace() {
    final current = _appStore.wallet;
    if (current is! SoftwareWallet) return;
    final address = current.currentAccount.primaryAddress.address.hexEip55;
    _appStore.wallet = SoftwareViewWallet(current.id, current.name, address);
  }

  Future<void> deleteCurrentWallet() async {
    final id = _settingsRepository.currentWalletId!;
    await _repository.deleteWallet(id);
    await _settingsRepository.removeCurrentWalletId();
  }

  bool hasWallet() => _settingsRepository.currentWalletId != null;

  bool validateSeed(String seed) => bip39.validateMnemonic(seed);
}
