import 'dart:async';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/repository/wallet_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_isolate.dart';

class WalletService {
  final WalletRepository _repository;
  final SettingsRepository _settingsRepository;
  final BitboxService _bitboxService;
  final AppStore _appStore;
  final SecureStorage _secureStorage;
  // Post-Initiative-IV (BL-018), every sign + derivation runs through
  // this isolate; the main isolate never holds the BIP39 plaintext as
  // a long-lived field. The handle is spawned lazily on first need so
  // an app that never opens a software wallet (e.g. BitBox-only) pays
  // zero overhead.
  WalletIsolate? _walletIsolate;

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
  ///
  /// Post-BL-022 this is a regular Future again — the cancellation that
  /// used to live on `Future.ignore()` has been replaced by an explicit
  /// `WalletIsolate.cancel()` call in [lockCurrentWallet], so the slot
  /// in the isolate is dropped rather than the future being silently
  /// detached.
  Future<SoftwareWallet>? _unlockInFlight;

  WalletService(
    this._bitboxService,
    this._repository,
    this._settingsRepository,
    this._appStore,
    this._secureStorage,
  );

  /// Test-seam: injects a pre-built isolate so unit tests don't pay the
  /// spawn cost. Production callers go through the lazy [_isolate] path.
  // ignore: use_setters_to_change_properties
  void debugInjectWalletIsolate(WalletIsolate isolate) {
    _walletIsolate = isolate;
  }

  /// Lazy spawn of the wallet isolate. Tests can pre-inject via
  /// [debugInjectWalletIsolate]; production callers get a fresh
  /// per-process isolate on first software-wallet operation.
  Future<WalletIsolate> _isolate() async =>
      _walletIsolate ??= await WalletIsolate.spawn();

  /// Generates a fresh BIP39 mnemonic and returns a [SeedDraft] holding
  /// it for the brief onboarding window (verify-seed quiz). The seed
  /// lives on the main isolate ONLY while this draft is alive — Law 6
  /// permits this because the cubit holding the draft is wired to a
  /// `WidgetsBinding` lifecycle observer that calls [SeedDraft.dispose]
  /// on `hidden`, and `commitGeneratedWallet` adopts the plaintext into
  /// the isolate (and disposes the draft) as soon as the user
  /// confirms.
  ///
  /// SECURITY: BIP39 lifetime — see BL-018. Callers must dispose the
  /// draft within one foreground transition. The verify-seed cubit
  /// owns that contract via [SeedDraft] + [WidgetsBindingObserver].
  Future<SeedDraft> generateUncommittedSeedDraft(String name) async {
    final mnemonic = bip39.generateMnemonic();
    return SeedDraft(mnemonic, name: name);
  }

  /// Persists the [draft]'s mnemonic to disk (encrypted + cached
  /// address), adopts the plaintext into the wallet isolate, disposes
  /// the draft, and returns a [SoftwareWallet] handle.
  ///
  /// The draft must not have been disposed already. If the persist /
  /// adopt path throws, the draft is NOT disposed — the caller may
  /// surface a retry. If the persist succeeds but adopt throws, the
  /// row is rolled back so we don't leave a wallet on disk we can't
  /// sign with.
  Future<SoftwareWallet> commitGeneratedWallet(SeedDraft draft) async {
    if (draft.isDisposed) {
      throw StateError('commitGeneratedWallet called on a disposed SeedDraft — '
          'the mnemonic has already been cleared.');
    }
    final name = draft.name ?? 'Wallet';
    final seed = draft.mnemonic;
    final wallet = await _persistSoftwareWallet(name, seed);
    // The plaintext is no longer needed on the main isolate; the
    // adopted copy lives in the isolate's heap.
    draft.dispose();
    return wallet;
  }

  Future<BitboxWallet> createBitboxWallet(String name) async {
    final address = await _bitboxService.bitboxManager.getETHAddress(1, "m/44'/60'/0'/0/0");
    final walletId = await _repository.createViewWallet(name, WalletType.bitbox, address);
    await setCurrentWallet(walletId);
    return BitboxWallet(walletId, name, address, _bitboxService);
  }

  /// Persists a user-supplied seed phrase immediately — the user typed
  /// an existing mnemonic, so there is no verify-seed quiz to gate the
  /// write behind. The string is held only inside this scope; the
  /// adopt-into-isolate path takes over before the function returns.
  ///
  /// SECURITY: BIP39 lifetime — see BL-018. The `seed` parameter is
  /// the only main-isolate string holding the user's mnemonic; do not
  /// store it on a long-lived field.
  Future<SoftwareWallet> restoreWallet(String name, String seed) async {
    final wallet = await _persistSoftwareWallet(name, seed);
    await _settingsRepository.saveCurrentWalletId(wallet.id);
    return wallet;
  }

  /// Builds the BIP32 derivation once (inside the isolate) to obtain
  /// the public address, persists `(encryptedSeed, address)` so app
  /// start can render the dashboard from the cached address without
  /// re-running derivation, and seats the unlocked slot in the
  /// isolate so the returned [SoftwareWallet] handle is immediately
  /// signable.
  Future<SoftwareWallet> _persistSoftwareWallet(String name, String seed) async {
    final id = await _repository.createWallet(name, WalletType.software, seed, '');
    final isolate = await _isolate();
    final address = await isolate.adoptPlaintext(id, seed);
    // Persist the derived address back to the row so subsequent
    // `getWalletById` calls take the view-wallet fast path.
    await _repository.updateAddress(id, address);
    return SoftwareWallet(id, name, address, isolate);
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
        // address column — promote them once via an unlock + address
        // back-fill so subsequent loads stay on the fast view-wallet path.
        // The unlock only needs the address: drop the seed from the isolate
        // immediately and return a view wallet (matching the fast path), so
        // the backfill never leaves the mnemonic resident with no auto-lock.
        if (info.address.isEmpty) {
          final wallet = await unlockWalletById(id);
          await _repository.updateAddress(id, wallet.address);
          final isolate = _walletIsolate;
          if (isolate != null) await isolate.lock(id);
          return SoftwareViewWallet(id, wallet.name, wallet.address);
        }
        return SoftwareViewWallet(info.id, info.name, info.address);
      case WalletType.bitbox:
        return BitboxWallet(info.id, info.name, info.address, _bitboxService);
      case WalletType.debug:
        return DebugWallet(info.id, info.name, info.address);
    }
  }

  /// Decrypts the mnemonic inside the wallet isolate and returns a
  /// [SoftwareWallet] handle pointing at the freshly-seated slot. The
  /// plaintext does not cross the channel; the main side receives only
  /// the primary address. Throws if the wallet type is not software.
  Future<SoftwareWallet> unlockWalletById(int id) async {
    final info = (await _repository.getWalletInfo(id))!;
    if (WalletType.values[info.type] != WalletType.software) {
      throw StateError('unlockWalletById called for non-software wallet');
    }
    final key = await _secureStorage.getOrCreateMnemonicKey();
    final isolate = await _isolate();
    final address = await isolate.unlock(id, info.seed, Uint8List.fromList(key));
    return SoftwareWallet(id, info.name, address, isolate);
  }

  /// Round-trips the current wallet's mnemonic back to the main
  /// isolate inside a transient [SeedDraft]. Used by settings-seed
  /// (display words) and verify-seed (quiz) flows. The caller MUST
  /// dispose the returned draft once the words are no longer needed;
  /// the cubit wiring this in is responsible for the lifecycle
  /// observer that drops the draft on `hidden`.
  ///
  /// SECURITY: BIP39 lifetime — see BL-018. This is the only path that
  /// brings the mnemonic back to the main isolate after onboarding;
  /// keep the holder lifetime as small as the UI permits.
  Future<SeedDraft> revealCurrentSeed() async {
    final id = _settingsRepository.currentWalletId!;
    final isolate = await _isolate();
    // The slot must already be unlocked; settings_seed_cubit calls
    // ensureCurrentWalletUnlocked before reaching here.
    final mnemonic = await isolate.reveal(id);
    final info = await _repository.getWalletInfo(id);
    return SeedDraft(mnemonic, name: info?.name);
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
  /// only) to a fully unlocked [SoftwareWallet] (mnemonic seated in the
  /// dedicated isolate's slot) so the next sign operation can run. No-op
  /// for wallets that aren't locked.
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

  /// Replaces the in-memory [SoftwareWallet] handle with its
  /// lock-screen-safe [SoftwareViewWallet] counterpart and drops the
  /// isolate-side slot. Called after a sign operation completes so the
  /// private key isn't kept resident for the rest of the foreground
  /// session. No-op for wallet types that don't hold a mnemonic, and
  /// no-op when no wallet has been loaded yet.
  ///
  /// Respects [_activeUnlockHolders] — a second concurrent caller still
  /// holding the unlocked contract keeps the wallet unlocked. The 60s safety
  /// net runs through [_forceLock] instead so it can bypass the counter.
  ///
  /// Post-BL-022, the cancellation of an in-flight unlock no longer
  /// relies on `Future.ignore()` — the isolate is asked to drop the
  /// slot directly so its decrypted seed is released even if the
  /// awaiting future is never observed.
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
    // unlocked [SoftwareWallet] back into [AppStore.wallet] after this lock.
    final inFlight = _unlockInFlight;
    _unlockInFlight = null;
    _postUnlockLockTimer?.cancel();
    _postUnlockLockTimer = null;
    // An in-flight unlock still seats the decrypted seed in the isolate slot
    // AFTER this lock returns, and `_lockWalletInPlace` no-ops here because
    // `AppStore.wallet` is still a view wallet — so it never reaches
    // `isolate.lock`. Drop that slot once the unlock settles (without blocking
    // this lock) so the seed never outlives the user's intent — closing the
    // leak the dead `WalletIsolate.cancel()` mitigation was meant to handle.
    if (inFlight != null) {
      final isolate = _walletIsolate;
      final id = _appStore.isWalletLoaded ? _appStore.wallet.id : null;
      if (isolate != null && id != null) {
        unawaited(inFlight.then((_) => isolate.lock(id)).catchError((_) {}));
      }
    }
    await _lockWalletInPlace();
  }

  void _schedulePostUnlockLock() {
    _postUnlockLockTimer?.cancel();
    _postUnlockLockTimer = Timer(_postUnlockLockTimeout, () {
      // The safety net is fire-and-forget; the lock itself is async
      // (it talks to the isolate) but the timer callback can't await.
      unawaited(_forceLock());
    });
  }

  /// Hard cap on the in-memory mnemonic lifetime. Bypasses
  /// [_activeUnlockHolders] so a stuck holder can't keep the key resident
  /// past the safety window.
  Future<void> _forceLock() async {
    _activeUnlockHolders = 0;
    _postUnlockLockTimer = null;
    await _lockWalletInPlace();
  }

  Future<void> _lockWalletInPlace() async {
    final current = _appStore.wallet;
    if (current is! SoftwareWallet) return;
    // Replace the slot first so any in-flight derivation tied to the
    // old handle errors out cleanly; THEN flip the AppStore so the UI
    // observes the locked state.
    final isolate = _walletIsolate;
    if (isolate != null) await isolate.lock(current.id);
    _appStore.wallet = SoftwareViewWallet(current.id, current.name, current.address);
  }

  /// Deletes the current wallet end-to-end:
  ///   1. Drops the `walletAccountInfos` rows + `walletInfos` row via
  ///      `WalletRepository.deleteWallet` (BL-004 chain).
  ///   2. If this was the last wallet on the device AND the user opted in
  ///      via [SettingsRepository.deleteMnemonicKeyOnLastWalletDelete],
  ///      removes the Keychain-stored mnemonic encryption key as well.
  ///      The default is opted-out — see the ADR for the trade-off.
  ///   3. Clears the `currentWalletId` setting so the next launch routes
  ///      back through onboarding instead of a no-wallet crash.
  ///
  /// Returns the row counts from the underlying delete so callers (and
  /// integration tests) can audit the cleanup. The third tuple field
  /// signals whether the mnemonic key was actually removed — only true
  /// when both the opt-in flag was set AND the deleted wallet was the
  /// last one.
  Future<({int accountRows, int walletRows, bool mnemonicKeyDeleted})>
      deleteCurrentWallet() async {
    final id = _settingsRepository.currentWalletId!;
    // Drop the isolate slot first so the decrypted seed (if any) is
    // released before the row goes. Defensive: a stale slot from a
    // previous unlock-without-lock cycle would otherwise survive the
    // wallet deletion.
    final isolate = _walletIsolate;
    if (isolate != null) await isolate.lock(id);
    final counts = await _repository.deleteWallet(id);
    final isLast = await _repository.isLastWallet();
    final shouldDeleteKey =
        isLast && _settingsRepository.deleteMnemonicKeyOnLastWalletDelete;
    if (shouldDeleteKey) {
      await _secureStorage.deleteMnemonicEncryptionKey();
    }
    await _settingsRepository.removeCurrentWalletId();
    return (
      accountRows: counts.accountRows,
      walletRows: counts.walletRows,
      mnemonicKeyDeleted: shouldDeleteKey,
    );
  }

  bool hasWallet() => _settingsRepository.currentWalletId != null;

  bool validateSeed(String seed) => bip39.validateMnemonic(seed);
}
