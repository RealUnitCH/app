# Testing Guide

RealUnit's tests are organised into five tiers (see [#314](https://github.com/DFXswiss/realunit-app/issues/314)). Each tier trades off fidelity for cost; pick the lowest tier that still proves the behaviour you care about.

| Tier | What it exercises | Hardware | CI |
|---|---|---|---|
| 0 | Pure Dart logic — cubits, services, signers, parsers | None | ✅ `flutter test --coverage` |
| 1 | Cubit / widget + SDK-boundary fake — sign ceremonies via `FakeBitboxCredentials`; HTTP via `MockClient` | None | ✅ `flutter test --coverage` |
| 2 | Real BitBox firmware-simulator over TCP (`bitbox_flutter` TCP transport) | Docker, no device | 🟡 Deferred — Phase 2 of #314 |
| 3 | Maestro YAML flows on an iOS Simulator (handbook capture) · real BitBox02 hardware variant deferred | iPhone simulator (handbook) · iPhone + BitBox02 Nova (hardware) | 🟢 Handbook flows automated · 🟡 hardware variant deferred — Phase 3 of #314 |
| 4 | BLE traffic capture / replay | Capture on hardware, replay anywhere | 🟡 Stretch — Phase 4 of #314 |

## When to pick which tier

```
                    Does the behaviour depend on …
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
  pure Dart logic          a hardware-wallet         the iOS BLE
  (cubit / parser /        sign outcome              transport itself
   service wire shape)     (cancel / disconnect /    (CoreBluetooth
        │                   timeout / malformed)      framing)
        ▼                       │                       │
     Tier 0                     ▼                       ▼
                            Tier 1 first.           Tier 3.
                            Tier 2 catches          Tier 2 cannot —
                            cross-arch /            it speaks U2F-HID
                            firmware-version        over TCP, not BLE.
                            regressions on top.
```

If you can write a Tier 0 test, do that. Drop down only when a Tier 0 test would have to mock the very thing under test.

## Tier 0 — pure Dart

Test layout mirrors `lib/`. Stack: [`flutter_test`](https://pub.dev/packages/flutter_test), [`bloc_test`](https://pub.dev/packages/bloc_test), [`mocktail`](https://pub.dev/packages/mocktail) (NOT mockito).

### Cubit / Bloc

Use `blocTest` from `bloc_test`. Mock the services it depends on with `mocktail.Mock`.

```dart
class _MockDfxKycService extends Mock implements DfxKycService {}

blocTest<KycCubit, KycState>(
  'emits KycCompleted when level >= required and gates have passed',
  setUp: () {
    when(() => kycService.getKycStatus())
        .thenAnswer((_) async => _kycStatus(level: KycLevel.level30));
    when(() => kycService.getUser()).thenAnswer((_) async => _user());
  },
  build: buildCubit,
  act: (cubit) async {
    cubit.markLegalDisclaimerAccepted();
    cubit.markRegistrationSignProduced();
    await cubit.checkKyc();
  },
  expect: () => [const KycLoading(), const KycCompleted()],
);
```

See `test/screens/kyc/cubits/kyc/kyc_cubit_test.dart` for the full set of state-transition cases.

### Widget

Use the project's [`pumpApp`](../test/helper/pump_app.dart) helper. Mock the cubits the widget reads from (`MockCubit<State>`) — do not exercise the cubit's logic here, that's a separate test.

```dart
class _MockKycEmailStepCubit extends MockCubit<KycEmailStepState>
    implements KycEmailStepCubit {}

testWidgets('shows SnackBar if submitting fails', (tester) async {
  whenListen(
    kycEmailStepCubit,
    Stream.fromIterable([const KycEmailStepFailure('boom')]),
    initialState: const KycEmailStepInitial(),
  );

  await tester.pumpApp(buildSubject(const KycEmailView()));
  await tester.pump();

  expect(find.byType(SnackBar), findsOneWidget);
});
```

See `test/screens/kyc/steps/kyc_email_page_test.dart`.

### Service + HTTP

For services that hit the DFX API, swap in `MockClient` from [`http/testing`](https://pub.dev/packages/http) and a `_MockAppStore` that returns it via the `httpClient` getter.

`DFXAuthService`-derived services walk `getAuthToken()` → `loadSignature()` → `getAuthResponse()` on a cold cache. Pre-seed the JWT in `setUp` so existing tests stay focused on wire behaviour:

```dart
setUp(() {
  appStore = _MockAppStore();
  sessionCache = SessionCache(_MockCacheRepository());
  sessionCache.setAuthToken('test-jwt');                       // short-circuit refresh
  when(() => appStore.sessionCache).thenReturn(sessionCache);
  when(() => appStore.apiConfig)
      .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
});
```

See `test/packages/service/dfx/dfx_bank_account_service_test.dart`.

### Mocktail gotchas

- `Future<X>`-returning methods must use `thenAnswer((_) async => …)`, not `thenReturn`.
- For matchers like `any()` over non-nullable custom types, register a fallback in `setUpAll`:

  ```dart
  setUpAll(() => registerFallbackValue(_registrationFixture));
  ```

- Test mocks should be private to the file (`class _MockX extends Mock implements X {}`). Don't leak them across files.

### Constructor-fires-work cubits

Some cubits kick off async work in their constructor (`SellBitboxCubit` calls `scheduleMicrotask(_checkEthBalance)`; `KycCubit` enters `checkKyc` via the page-level `BlocProvider(create: …)`). `blocTest`'s state-sequence assertion attaches a listener *after* the constructor runs, so it can miss the synchronous initial emit.

Wait for the terminal state instead:

```dart
final cubit = build();
final state = await cubit.stream.firstWhere((s) => s is SellBitboxEthReady);
```

This is also the pattern when you want to assert on the *final* state after a chain of internal emits (Loading → RequestingFaucet → WaitingForEth) without listing every transient step.

### Widget tests that overflow the default viewport

The default `tester` viewport is 800×600. Rows with multiple expanded children + long labels (`SellBitboxDepositStep`'s amount row, `LegalDisclaimerStep`'s text columns) report `RenderFlex overflowed by N pixels on the right/bottom`. Bump the viewport in the offending test:

```dart
tester.view.physicalSize = const Size(1200, 2400);
tester.view.devicePixelRatio = 1.0;
addTearDown(tester.view.resetPhysicalSize);
```

Don't change the production widget to compensate — the production layout is fine on real devices.

### GoRouter harness for sheets that call `context.pop`

`pumpApp` (via `MaterialApp.home`) does not provide a GoRouter, so any sheet that calls `context.pop(result)` throws "Null check operator used on a null value" on render. Use the `MaterialApp.router` constructor with a minimal route:

```dart
final router = GoRouter(
  routes: [GoRoute(path: '/', builder: (_, _) => const MyBottomSheet())],
);
addTearDown(router.dispose);
await tester.pumpWidget(MaterialApp.router(
  routerConfig: router,
  localizationsDelegates: [S.delegate, GlobalMaterialLocalizations.delegate],
  supportedLocales: S.delegate.supportedLocales,
));
```

`pumpApp` is fine for widgets that don't pop — only switch to the router harness when you need `context.pop` resolvable.

### Shared test private key

`FakeBitboxCredentials` derives its signatures from a single deterministic test private key. Reuse the same key directly when you need a real `EthPrivateKey` credential (for example to drive `Eip7702Signer.signAuthorization`, which rejects `BitboxCredentials`):

```dart
const _testPrivateKeyHex =
    'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612';
final privKey = EthPrivateKey.fromHex(_testPrivateKeyHex);
// Derived address: 0x9F5713DEacB8e9CAB6c2d3FaE1AFc2715F8D2D71
```

Sharing the key lets cross-layer tests assert on a single recovered signer address — and means any envelope encoded by `FakeBitboxCredentials(success)` round-trips through `Eip712Signer.signRegistration` to the same byte sequence.

### Service lifecycle (fake_async)

Services with a `Timer`, an observer/subscription loop, or a platform/`MethodChannel` dependency must have a lifecycle test that instantiates the real class — never a mock of the service-under-test. Mocking the service hides timer leaks, unsubscribed listeners, and double-init bugs.

Time-bound assertions must drive time via `package:fake_async`. Wall-clock `Future.delayed` is not acceptable: it makes tests slow and flaky.

```dart
import 'package:bitbox_flutter/testing.dart';
import 'package:bitbox_flutter/usb/bitbox_usb_platform_interface.dart';
import 'package:fake_async/fake_async.dart';

late BitboxUsbPlatform previousPlatform;
late SimulatedBitboxPlatform platform;

setUp(() {
  previousPlatform = BitboxUsbPlatform.instance;
  platform = installSimulatedBitboxPlatform();
});
tearDown(() {
  BitboxUsbPlatform.instance = previousPlatform;
});

test('observer releases USB transport when device vanishes', () {
  fakeAsync((async) {
    final service = BitboxService(
      connectionStatusInterval: const Duration(milliseconds: 50),
    ); // real instance, not a mock
    // … pair the service inside the fakeAsync zone …

    platform.when(
      SimulatedBitboxMethod.getDevices,
      (_) async => const <BitboxDevice>[],
    );
    service.startConnectionStatusObserver();
    async.elapse(const Duration(milliseconds: 150));

    expect(
      platform.count(SimulatedBitboxMethod.close),
      greaterThanOrEqualTo(1),
    );
  });
});
```

See `test/packages/hardware_wallet/bitbox_service_test.dart`. The rule is also documented in `CONTRIBUTING.md` ("Service-lifecycle tests are mandatory").

### Exception surface

Every typed exception in `lib/` (any class that `implements Exception` or `extends Exception`) must:

1. Override `toString()` so the rendered string is non-empty and does not contain `Instance of '...'`.
2. Be enumerated in `test/packages/service/dfx/exceptions/exception_surface_test.dart` in the same PR that introduces it.

Exceptions surface in logs, Sentry, and user-facing error states — the Dart default `Instance of '...'` is useless for debugging and unfriendly for users. The surface test catches drift the moment a new exception is added without an enumeration entry.

### Platform-coupled code without an integration test

Platform-specific paths (USB transports, BLE lifecycle, secure storage, biometric prompts, deep links) must either ship a Tier 1/2 counterpart that exercises the real plugin (or vendor simulator), or carry an inline `// @no-integration-test: <reason>` annotation. The annotation works at file level (as a dartdoc comment) or immediately above the function/method declaration. Grep current annotations with:

```bash
rg "^//\s*@no-integration-test:" lib/
```

Unit tests with mocked platform channels cannot catch real-device regressions (permission prompts, OS-level lifecycle, transport quirks); the annotation makes the absence of an integration test a deliberate, reviewable decision rather than a silent gap.

## Tier 1 — cubit / widget + SDK-boundary fake

Tier 1 reuses the same `flutter_test` runner but swaps in [`FakeBitboxCredentials`](../test/helper/fake_bitbox_credentials.dart) at the BitBox boundary. The fake `is BitboxCredentials`, so every production type guard (e.g. the `BitboxNotConnectedException` check in `RealUnitRegistrationService`) treats it identically to a real device.

`FakeBitboxBehavior` covers the five real-world ceremony outcomes:

| Mode | Behaviour | Mirrors |
|---|---|---|
| `success` | Deterministic EIP-712 / personal-message signature from an embedded test private key | User confirms on device |
| `cancel` | Returns `'0x'` | iOS bridge cancel signal |
| `disconnect` | Throws `SigningCancelledException`; `isConnected == false` | BLE link drop |
| `timeout` | Never resolves; caller imposes its own outer timeout | Device hangs |
| `malformed` | Returns non-hex data | Frame-desync regression (`bitbox_flutter` PR #11) |

```dart
test('cancel mid-sign: fake → Eip712Signer guard → SigningCancelledException', () async {
  final fake = FakeBitboxCredentials(
    behavior: FakeBitboxBehavior.cancel,
    signDelay: Duration.zero,
  );

  await expectLater(
    Eip712Signer.signRegistration(credentials: fake, /* … */),
    throwsA(isA<SigningCancelledException>()),
  );
});
```

See `test/integration/kyc_sign_flow_test.dart` for cross-layer scenarios (happy path, cancel, disconnect, reconnect-and-retry).

For the disconnect-flip-to-success retry pattern, mutate `fake.behavior` between calls:

```dart
fake.behavior = FakeBitboxBehavior.success;
final retrySig = await fake.signTypedDataV4(1, payload);
```

### When to put a Tier 1 test under `test/integration/` vs `test/`

- `test/integration/` — crosses ≥ 2 production layers AND uses the `FakeBitboxCredentials` boundary. Runs headless, no device. A behaviour change in any of the layers should break it.
- `test/` — exercises a single layer with mocked dependencies.

## Tier 2 — firmware simulator (deferred)

The BitBox02 firmware simulator runs as a Docker container, speaks U2F-HID over TCP, and is pre-seeded with a fixed test mnemonic. Same Rust + C code path as the real device for every crypto operation, including the full 13-page EIP-712 sign.

Status: deferred — Phase 2 of #314 has not landed yet. When it does:

```bash
docker compose up bitbox-simulator
flutter run --dart-define=BITBOX_HOST=localhost:15423
flutter test integration_test/ --dart-define=BITBOX_HOST=localhost:15423
```

Does **not** exercise iOS BLE — the simulator is USB-style framing only. Tier 3 stays the only validation for the BLE transport.

## Tier 3 — Maestro flows

YAML flows under `.maestro/` driven by [`maestro`](https://maestro.mobile.dev).

Status: the handbook subset (`.maestro/handbook/*.yaml`) is automated on PRs labelled `tier3:full` and on every push to `develop` — see `.github/workflows/tier3-handbook.yaml`. The workflow resolves and boots an `iPhone 17` device on the highest available iOS 26 runtime; `scripts/run-handbook-flows.sh` then shuts the device down, `simctl erase`s it (Keychain wipes are the only reliable way to start on the welcome flow — see the script for the rationale), pins the simulator locale to `de_CH` so German handbook assertions pass on the `en_US`-default runner, reinstalls the debug `Runner.app`, replays every flow back-to-back, and the workflow uploads `docs/handbook/screenshots/` as a build artifact so reviewers can spot visual drift before merge.

The Maestro version is pinned in `.maestro-version` (today `2.0.10`).
Maestro 2.3.x–2.5.x has documented intermittent failures on Apple
Silicon + iOS 26.x — both driver-hang and silent tap-loss — tracked
upstream as [mobile-dev-inc/maestro#3137](https://github.com/mobile-dev-inc/maestro/issues/3137).
The pinned version is the workaround the upstream issue closed with.
`scripts/run-handbook-flows.sh` retries the residual driver-hang
class up to three times per flow as a safety net, and Tier 3 is
opt-in via the `tier3:full` label rather than a required status
check on `develop` until the reliability is proven on the pinned
version over time. See realunit-app#487 Hard Risk 2b for the
hardening track.

The real-hardware variant (BitBox02 Nova) stays deferred — Phase 3 of #314 — and is the entry point for any PR that adds a `bitbox:full` label later.

## Tier 4 — VCR / replay (stretch)

Capture iOS BLE traffic once on hardware, replay it deterministically thereafter. Status: stretch — Phase 4 of #314. Most of its value is covered by Tier 2 + Tier 3 in tandem.

## CI

Every PR runs Tier 0 and Tier 1 via the `RealUnit Build` workflow (`.github/workflows/pull-request.yaml`):

```bash
flutter pub get
dart run tool/generate_localization.dart
flutter pub run build_runner build
flutter analyze
flutter test --coverage
```

The workflow runs three jobs:

- **`Analyze & Test`** — the block above, plus a `lcov --extract` step that narrows `coverage/lcov.info` to the activated surface (`lib/packages/**`, `lib/screens/**/cubit(s)/**`, `lib/screens/**/bloc/**`) and uploads both the filtered tracefile (`coverage-lcov`) and a one-line summary (`coverage-summary`) as artifacts.
- **`Coverage Floor Gate`** — downloads `coverage-summary` and fails the build when scoped line/function coverage drops below the integers committed to `.coverage-floor-lines` and `.coverage-floor-functions`. This job is the required status check on `develop`; the ratchet protocol is documented in `README.md`.
- **`BitBox quirks audit`** — runs `bitbox-audit` against the diff and inlines its report into the workflow run summary; uploaded as `bitbox-audit-report`.

Tier 3 runs separately under `tier3-handbook.yaml` (push to `develop`, manual, or PRs with the `tier3:full` label). Coverage is uploaded as an artifact (see [#323](https://github.com/DFXswiss/realunit-app/pull/323)). The repo holds a [100 % coverage rule](https://github.com/DFXswiss/realunit-app/pull/322) for new code — drop the threshold only with reviewer sign-off and a written reason.

## Surface that needs infra work before it can be unit-tested

Some files are deliberately uncovered today because exercising them would change project architecture, not just add a test. Don't waste time stubbing around these without a focused infra PR first:

| Area | Why it's not unit-tested | What it would take |
|---|---|---|
| `lib/packages/repository/*` (Drift wrappers) | `AppDatabase(String encryptionPassword)` builds a native SQLCipher executor; the in-memory injection point exists (`AppDatabase.forTesting`, `database.dart`), but the wrapper specs are not written yet | Write repository unit tests that pass `NativeDatabase.memory()` into `AppDatabase.forTesting` |
| `lib/screens/*/`-Page widgets that call `getIt<X>()` directly (Dashboard, Receive, Settings sub-pages) | Service locator usage inside `build` makes the cubits the page wires up impossible to swap | Move the `BlocProvider(create: (_) => Cubit(getIt<X>()))` lookup up one layer so tests can `BlocProvider.value` a mock |
| `transaction_history_*receipt_cubit`, `settings_tax_report_cubit` | Call `getApplicationDocumentsDirectory()` from `path_provider` directly | Inject the path lookup (or use [`path_provider_platform_interface`](https://pub.dev/packages/path_provider_platform_interface) with a fake) |
| `lib/screens/kyc/steps/ident/cubits/kyc_ident/kyc_ident_cubit.dart` | Drives the Sumsub `flutter_idensic_mobile_sdk_plugin` directly | Move the SDK call behind a port the cubit takes via constructor injection |
| `lib/widgets/chain_asset_icon.dart`, `lib/widgets/image_picker_sheet.dart` | `Image.asset` / `ImagePicker` need a real asset bundle / platform channel | Mock the asset loader / use the platform-interface fake |

When you find yourself wanting to test one of these, do the infra PR first and document the new injection point in this file.

## Adding tests when you touch BitBox-related code

PRs touching `KycCubit`, `KycRegistrationSubmitCubit`, `Eip712Signer`, `DFXAuthService`, `BitboxCredentials`, or `bitbox_flutter` must add Tier 0 (and ideally Tier 1) coverage. The pattern that gets BitBox bugs caught early:

1. Identify the new behaviour as either a logic branch (Tier 0) or a multi-layer interaction (Tier 1).
2. If Tier 1: pick the `FakeBitboxBehavior` that exercises it. If none fits, extend the enum.
3. Assert the typed result (`SigningCancelledException`, specific `KycState`, specific `RegistrationStatus`) — never on a stringified message.
