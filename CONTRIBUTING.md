# RealUnit App — Contributing Guidelines

## Build & Test Commands

```bash
flutter pub get
dart run tool/generate_localization.dart   # generate i18n from ARB files
flutter pub run build_runner build          # generate code (drift, etc.)
flutter test                                # run all tests
flutter analyze                             # lint check
```

After changing ARB files, always regenerate: `dart run tool/generate_localization.dart`

## API Access — CRITICAL

- The app is **only allowed to talk to the DFX API**: `api.dfx.swiss` (mainnet) and `dev.api.dfx.swiss` (testnet/Sepolia). No other hosts.
- **No third-party APIs**: no direct Ethereum JSON-RPC calls (Infura, Alchemy, public nodes, etc.), no block explorer APIs (Etherscan, …), no price feeds, no analytics endpoints, no third-party SDKs that call out over the network.
- If a feature needs on-chain data (e.g. native ETH balance, transaction status, token balance), add a new endpoint to [`DFXswiss/api`](https://github.com/DFXswiss/api) and let the app call that endpoint. The API is the single gateway.
- All network calls must go through `AppStore.httpClient` with `buildUri(_host, …)` — `_host` resolves to the DFX API host via `ApiConfig`. Do not instantiate `http.Client`/`Dio`/`Web3Client` against other hosts.

## Project Architecture

```
lib/
  di.dart                          # GetIt service locator setup
  router.dart                      # GoRouter route definitions
  models/                          # Domain models (extend Equatable)
  packages/
    repository/                    # Data access layer
    service/dfx/
      models/{resource}/dto/       # DTOs with fromJson()
      {resource}_service.dart      # Business logic services
  screens/{screen}/
    bloc/ or cubits/               # State management per screen
    widgets/                       # Screen-specific widgets
  styles/                          # Colors, TextStyles, Themes
  widgets/                         # Shared reusable widgets
```

## Styling — CRITICAL

- **Colors**: Always use `RealUnitColors.*` or `RealUnitColors.basic.white` / `.black`. Avoid using colors from `material.dart` (`Colors.white`, `Colors.black`, `Colors.transparent`, etc.) if possible. NEVER use raw `Color(0x...)` values.
- **Transparent colors**: `RealUnitColors.basic.white.withValues(alpha: 0)` — NEVER `Color(0x00FFFFFF)`.
- **TextStyles**: Always use `Theme.of(context).textTheme.*` (headlineLarge/Medium/Small, bodyLarge/Medium/Small). NEVER hardcode `TextStyle(fontSize: 26, fontWeight: ...)`.
  - Mapping: `headlineLarge` = h1 (30/600), `headlineMedium` = h2 (26/bold), `headlineSmall` = h4 (20/bold), `bodyLarge` = base (16), `bodyMedium` = sm (14), `bodySmall` = xs (12)
  - Any changes to TextStyles should happen via `.copyWith(...)` (e.g., color, fontWeight).
- **Loading indicators**: `CupertinoActivityIndicator` — NEVER `CircularProgressIndicator`.
- **Linter**: Use `analysis_options.yaml` as the linter rule reference.

## Localization (i18n)

- Source files: `assets/languages/strings_de.arb` and `strings_en.arb`
- Generated file: `lib/generated/i18n.dart` (in .gitignore)
- Keys MUST be alphabetically sorted in both ARB files.
- Always update BOTH de and en ARB files.
- Punctuation belongs in the template (`'${s.label}: $value'`), NOT in the ARB value.
- Before adding a new key: search existing keys first — reuse where possible.
- Avoid using `S.current` (no context) in cubits/blocs. Prefer emitting typed states and resolving localization in the UI via `S.of(context)`. When localization is needed in functions, pass `BuildContext` rather than `S`.

## State Management

- **Bloc**: For complex event-driven flows. Events are `sealed class` extending `Equatable`. States use `final class` — use `copyWith` or distinct state classes (Initial, Loading, Success, Failure) depending on the use case.
- **Cubit**: For simpler state. States extend `Equatable` — use `copyWith` or distinct state classes depending on the use case.
- State files are separate from bloc/cubit files.

## DTOs & Models

- DTOs live in `lib/packages/service/dfx/models/{resource}/dto/`
- Naming: `{Resource}Dto` with `factory fromJson(Map<String, dynamic> json)`
- Type casting: `json['field'] as Type` — no dynamic access.
- NEVER parse JSON inline in services — always create a DTO class.
- Domain models are separate from DTOs and extend `Equatable`.

## Navigation

- Uses GoRouter. Routes defined in `lib/setup/routing/router_config.dart`.
- Route names are defined in typed classes: `AppRoutes`, `SettingsRoutes`, `PinRoutes`, `OnboardingRoutes`, `LegalRoutes`.
- Always use `pushNamed`/`goNamed` with route constants — NEVER hardcode route strings.
- Pages should read their own dependencies from Bloc/DI — avoid passing data via route `extra` when the page can obtain it from context.

## Dependency Injection

- GetIt service locator in `lib/di.dart`.
- Access via `getIt<ServiceType>()` — use inline, don't store in local variables unless used multiple times.

## Testing

- Uses `flutter_test`, `bloc_test`, and `mocktail` (NOT mockito).
- Test structure mirrors `lib/` structure.
- Test helper at `test/helper/` (provides `pumpApp`).
- For BitBox-related code, the layered test strategy (Tier 0–4) is documented in [`docs/testing.md`](docs/testing.md), with concrete patterns for cubit tests, widget tests, service + HTTP tests, and `FakeBitboxCredentials`-backed integration tests.
- [`docs/testing.md`](docs/testing.md) also lists the surface that needs an infra PR first (Drift repositories, `getIt`-coupled pages, `path_provider`-coupled cubits, the Sumsub SDK, plugin-coupled widgets). Don't try to mock around those without changing the injection point.

### 1. Service-lifecycle tests are mandatory

Any service class with at least one of: a `Timer` (one-shot or periodic), an observer / subscription loop, or a direct platform/MethodChannel dependency MUST have a dedicated test file that instantiates the *real* class (no mock of the service itself) and drives its lifecycle end-to-end. For BitBox-touching code, use `installSimulatedBitboxPlatform` from `bitbox_flutter/testing.dart`. Tests with time-based behaviour MUST use `package:fake_async` rather than wall-clock `Future.delayed`.

Why: mocking the service-under-test hides the very lifecycle bugs (timer leaks, unsubscribed listeners, double-init) these tests exist to catch. Wall-clock delays make tests slow and flaky.

Reference example: `test/packages/hardware_wallet/bitbox_service_test.dart`.

### 2. Exception surface tests are mandatory

Every typed exception in `lib/` (any class that `implements Exception` or `extends Exception`) MUST have a `toString()` override that returns a human-readable message — not the Dart default `Instance of '<ClassName>'`. The shared `test/packages/service/dfx/exceptions/exception_surface_test.dart` enumerates every typed exception and asserts the rendered string is human-readable. When you add a new typed exception, you MUST add it to that list at the same time.

Why: exceptions surface in logs, Sentry, and user-facing error states. A default `Instance of '...'` is useless for debugging and unfriendly for users. Centralising the assertion in one test file keeps the contract visible.

Reference example: `test/packages/service/dfx/exceptions/exception_surface_test.dart`.

### 3. Platform-specific code paths need an integration test (or explicit waiver)

Code paths that depend on Android- or iOS-specific behaviour (USB transports, BLE lifecycle, secure storage, biometric prompts, deep links) MUST either:

1. Have a corresponding `integration_test/` counterpart that exercises the platform behaviour against the real plugin / a vendor simulator, OR
2. Carry an inline `// @no-integration-test: <reason>` annotation at the top of the file or function block, explicitly stating why a unit-level test is sufficient.

Code review must call out platform-specific code that has neither.

Why: unit tests with mocked platform channels cannot catch real-device regressions (permission prompts, OS-level lifecycle, transport quirks). The annotation makes the absence of an integration test a deliberate, reviewable decision rather than an oversight.

Reference example: forward-looking — no `integration_test/` directory exists yet; the first integration test to land will become the reference.

## Widget Guidelines

- Prefer `StatelessWidget` unless lifecycle management is truly needed.
- Extract widgets into own files if they can be graphically as well as semantically separated.
- Don't create wrapper widgets that only delegate to a child.
- Prefer `Align` instead of `Positioned`.

## Dependencies

- `pubspec.yaml` dependencies must be alphabetically sorted.
- Imports within files: alphabetically sorted. Order: `dart:` → `package:flutter` → `package:other` → `package:realunit_wallet/`.

## Common Mistakes to Avoid

- Don't leave unused imports after refactoring.
- Don't use default parameter values that contradict business rules (e.g., `amount = '300'` when minimum is 1000).
- Don't add explanatory comments for workarounds — fix the root cause instead.
- Don't add i18n keys without using them — remove unused keys when deleting features.
- Avoid using `SizedBox` for spacing in Column/Row — use the `spacing` property instead:

  ```dart
  // Bad
  Column(children: [Widget1(), SizedBox(height: 16), Widget2()])

  // Good
  Column(spacing: 16, children: [Widget1(), Widget2()])
  ```

- Don't use positional parameters for optional values in state classes — use named parameters:

  ```dart
  // Bad
  const MyState(this.optionalData, {this.otherField});

  // Good
  const MyState({this.optionalData, this.otherField});
  ```

- Follow existing patterns. For multi-step flows (e.g., KYC), each step should have its own Page + Cubit. Don't combine multiple steps into one, pass data through state, or use inline widgets with callbacks when a separate page is the established pattern.
- Follow the separation of concerns principle.
