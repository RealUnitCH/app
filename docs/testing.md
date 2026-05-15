# Testing Guide

RealUnit's tests are organised into five tiers (see [#314](https://github.com/DFXswiss/realunit-app/issues/314)). Each tier trades off fidelity for cost; pick the lowest tier that still proves the behaviour you care about.

| Tier | What it exercises | Hardware | CI |
|---|---|---|---|
| 0 | Pure Dart logic — cubits, services, signers, parsers | None | ✅ `flutter test --coverage` |
| 1 | Cubit / widget + SDK-boundary fake — sign ceremonies via `FakeBitboxCredentials`; HTTP via `MockClient` | None | ✅ `flutter test --coverage` |
| 2 | Real BitBox firmware-simulator over TCP (`bitbox_flutter` TCP transport) | Docker, no device | 🟡 Deferred — Phase 2 of #314 |
| 3 | Real BitBox02 hardware via Maestro YAML flows | iPhone + BitBox02 Nova | 🟡 Deferred — Phase 3 of #314 |
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
    cubit.markBitboxConfirmed();
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

## Tier 1 — cubit / widget + SDK-boundary fake

Tier 1 reuses the same `flutter_test` runner but swaps in [`FakeBitboxCredentials`](../lib/packages/hardware_wallet/fake_bitbox_credentials.dart) at the BitBox boundary. The fake `is BitboxCredentials`, so every production type guard (e.g. the `BitboxNotConnectedException` check in `RealUnitRegistrationService`) treats it identically to a real device.

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

## Tier 3 — Maestro on real hardware (deferred)

YAML flows under `.maestro/` driven by [`maestro`](https://maestro.mobile.dev). Required pre-release for security-sensitive flows. Status: deferred — Phase 3 of #314.

## Tier 4 — VCR / replay (stretch)

Capture iOS BLE traffic once on hardware, replay it deterministically thereafter. Status: stretch — Phase 4 of #314. Most of its value is covered by Tier 2 + Tier 3 in tandem.

## CI

Every PR runs Tier 0 and Tier 1 via the `RealUnit Build` workflow:

```bash
flutter pub get
dart run tool/generate_localization.dart
flutter pub run build_runner build
flutter analyze
flutter test --coverage
```

Coverage is uploaded as an artifact (see [#323](https://github.com/DFXswiss/realunit-app/pull/323)). The repo holds a [100 % coverage rule](https://github.com/DFXswiss/realunit-app/pull/322) for new code — drop the threshold only with reviewer sign-off and a written reason.

## Adding tests when you touch BitBox-related code

PRs touching `KycCubit`, `KycRegistrationSubmitCubit`, `Eip712Signer`, `DFXAuthService`, `BitboxCredentials`, or `bitbox_flutter` must add Tier 0 (and ideally Tier 1) coverage. The pattern that gets BitBox bugs caught early:

1. Identify the new behaviour as either a logic branch (Tier 0) or a multi-layer interaction (Tier 1).
2. If Tier 1: pick the `FakeBitboxBehavior` that exercises it. If none fits, extend the enum.
3. Assert the typed result (`SigningCancelledException`, specific `KycState`, specific `RegistrationStatus`) — never on a stringified message.
