# Real Unit App

A Flutter wallet for Real Unit investors. Multi-chain, BitBox02-ready, KYC-aware.

> **Status:** Early development. APIs, flows and UI are still moving.

## Contributing

**New PRs may only merge into `develop` if test coverage is 100% on the activated surface.** Concretely:

- `flutter test --coverage` must report 100% lines / functions / branches on every file in the activated surface (see Coverage scope below). CI will fail the build below threshold.
- Defensive code that genuinely cannot be reached in `flutter_test` (platform channels without a test override, native plugin entry points, BLE callbacks) is exempted by an inline `// coverage:ignore-line` annotation with a one-line reason.
- The branch is protected on GitHub: a PR cannot be merged while CI is red.

**Coverage scope:** `lib/packages/**` (services, repositories, signers, utils) and the `cubits/` + `bloc/` directories under each `lib/screens/<feature>/`. Widget files (`lib/screens/<feature>/<feature>_page.dart` and `lib/widgets/**`) are exercised via `testWidgets` specs and excluded from the line-coverage gate — widget tests count as `widget` coverage in the feature matrix, not as line %.

The four-tier testing model (Tier 0 Cubit unit · Tier 1 FakeBitbox integration · Tier 2 firmware simulator · Tier 3 Maestro hardware) is tracked in [#314](https://github.com/DFXswiss/realunit-app/issues/314). New BitBox-touching PRs are expected to add tests at the appropriate tier(s).

## Coverage infrastructure roadmap

The 100% rule above is the target state. Until the items below land, it is aspirational and not yet CI-enforced:

- [x] `flutter test --coverage` step in `.github/workflows/pull-request.yaml`
- [x] lcov filter narrowed to the activated surface (`lib/packages/**` + `lib/screens/**/cubit(s)/**` + `lib/screens/**/bloc/**`) and a per-run summary posted to the workflow step summary
- [ ] lcov threshold check (e.g. via `very_good_cli` or a custom `lcov` parser) failing the build below 100% on the scope above
- [ ] GitHub branch protection on `develop` requiring the coverage check
- [ ] Build-time feature-flag mechanism (analogous to `EXPO_PUBLIC_ENABLE_*` in `dfx-wallet`) so non-MVP features can be gated out of the activated surface — required before the 100% rule is realistic across all feature areas
- [ ] Inline `// coverage:ignore-*` annotations on truly unreachable paths, each with a one-line reason

Three PRs already in flight close the largest gaps for KYC + BitBox logic: [#319](https://github.com/DFXswiss/realunit-app/pull/319) (Tier 0 cubit tests), [#320](https://github.com/DFXswiss/realunit-app/pull/320) (Tier 1 FakeBitbox integration), [#321](https://github.com/DFXswiss/realunit-app/pull/321) (dashboard buy actions + auth service tests).

## Features

User-facing functions, their activation status, and the tests that cover them. It is the source of truth for "what does this wallet actually do" — keep it in sync when adding or removing a flow.

**Status legend:** `always` = ships on every build · `android-only` = only available on Android (BitBox flows) · `planned` = surface exists but flow not yet implemented.

**Triage legend** (MVP testing decision): `mvp` = in MVP scope, must reach full test coverage before launch · `defer` = ships but does not block MVP coverage (coverage required eventually, no hard deadline) · `planned` = not in scope for MVP.

**Tests legend:** `widget` = `testWidgets` spec under `test/screens/**` · `unit` = pure-Dart `test/packages/**` spec · `cubit` = `bloc_test`-style spec for a Bloc/Cubit · `integration` = `integration_test/**` spec driving the full app with `FakeBitboxCredentials` · `e2e` = Maestro YAML flow on real hardware · `—` = no test exists.

> Per-feature line-coverage % is omitted today because `--coverage` is not yet wired into CI. Once roadmap items 1 + 2 land, this column will be populated automatically.

### Onboarding & authentication

| Feature | Status | Triage | Tests |
| --- | --- | --- | --- |
| Welcome screen | always | mvp | widget (`welcome_page_test.dart`, `welcome/widgets/welcome_card_test.dart`) |
| Create wallet — software (generate seed) | always | mvp | widget (`create_wallet/create_wallet_page_test.dart`); no cubit/service test |
| Create wallet — BitBox02 (hardware connect) | android-only | mvp | — (integration test landing in [#320](https://github.com/DFXswiss/realunit-app/pull/320)) |
| Restore wallet — software seed phrase | always | mvp | widget (`restore_wallet/restore_wallet_page_test.dart`) |
| Verify seed phrase (3-word challenge) | always | mvp | widget (`verify_seed/verify_seed_page_test.dart`) |
| Setup PIN | always | mvp | widget (`pin/setup_pin_page_test.dart`) |
| Verify PIN (unlock) | always | mvp | widget (`pin/verify_pin_page_test.dart`) |
| Biometric unlock (Face ID / Touch ID / fingerprint) | always | mvp | — |
| Legal disclaimer (post-onboarding gate) | always | mvp | — (cubit transition covered in [#319](https://github.com/DFXswiss/realunit-app/pull/319)) |
| Onboarding completion | always | mvp | widget (`onboarding/onboarding_completed_page_test.dart`) |

### Wallet actions

| Feature | Status | Triage | Tests |
| --- | --- | --- | --- |
| Dashboard — asset list + total balance | always | mvp | widget (`home/home_page_test.dart`); no hook/service test |
| Receive — address + QR code | always | mvp | — |
| Transaction history | always | mvp | widget (`transaction_history/transaction_history_page_test.dart`) |
| Sell to BitBox02 (on-chain transfer) | android-only | defer | — |

### DFX backend integration

| Feature | Status | Triage | Tests |
| --- | --- | --- | --- |
| Buy — DFX fiat on-ramp (SEPA) | always | mvp | widget (`buy/buy_page_test.dart`) + unit (`real_unit_buy_payment_info_service_test.dart`); extended in [#321](https://github.com/DFXswiss/realunit-app/pull/321) |
| Sell — DFX fiat off-ramp (IBAN) | always | mvp | widget (`sell/sell_page_test.dart`); extended in [#321](https://github.com/DFXswiss/realunit-app/pull/321) |
| KYC: Email + 2FA gate | always | mvp | widget (`kyc_email_page_test.dart`, `kyc_2fa_page_test.dart`); cubit landing in [#319](https://github.com/DFXswiss/realunit-app/pull/319) |
| KYC: Registration + BitBox EIP-712 sign | always | mvp | widget (`kyc_registration_page_test.dart`) + unit (`eip712_signer_test.dart`); cubit / `registration_submit` / sign-flow integration tests landing in [#319](https://github.com/DFXswiss/realunit-app/pull/319) + [#320](https://github.com/DFXswiss/realunit-app/pull/320) |
| KYC: Nationality | always | mvp | widget (`kyc_nationality_page_test.dart`) |
| KYC: Financial data | always | mvp | widget (`kyc_financial_data_page_test.dart`) |
| KYC: Ident | always | mvp | widget (`kyc_ident_page_test.dart`) |
| KYC: Pending / Completed / Failure | always | mvp | widget (`kyc/subpages/kyc_*_page_test.dart`) |
| KYC: AccountMergeRequested / UnsupportedStepFailure | always | mvp | — (cubit paths landing in [#319](https://github.com/DFXswiss/realunit-app/pull/319)) |
| `DFXAuthService` (lazy auth + 401 retry) | always | mvp | — (unit tests landing in [#319](https://github.com/DFXswiss/realunit-app/pull/319) + [#321](https://github.com/DFXswiss/realunit-app/pull/321)) |
| `balance_service` (balance fetch + cache) | always | mvp | unit (`balance_service_test.dart`) |
| `format_fixed` / `parse_fixed` (decimal helpers) | always | mvp | unit (`format_fixed_test.dart`, `parse_fixed_test.dart`) |
| `ApiException` mapping | always | mvp | unit (`exceptions/api_exception_test.dart`) |
| `ApiConfig` parsing | always | mvp | unit (`api_config_test.dart`) |

### Settings

| Feature | Status | Triage | Tests |
| --- | --- | --- | --- |
| Wallet address (export) | always | defer | widget (`settings_wallet_address/settings_wallet_address_page_test.dart`) |
| User data — overview | always | defer | widget (`settings_user_data/settings_user_data_page_test.dart`) |
| User data — edit name / address / phone | always | defer | widget (3 subpage specs under `settings_user_data/subpages/`) |
| Show seed phrase | always | defer | widget (`settings_seed/settings_seed_page_test.dart`) |
| Legal documents | always | defer | widget (`settings_legal_documents/settings_legal_documents_page_test.dart`) |
| Currencies / Languages / Network | always | defer | — |
| Tax report | always | defer | — |
| Contact | always | defer | — |

### Support

| Feature | Status | Triage | Tests |
| --- | --- | --- | --- |
| Support — chat | always | defer | widget (`support/support_chat_page_test.dart`) |
| Support — create ticket | always | defer | widget (`support/support_create_ticket_page_test.dart`) |
| Support — tickets list | always | defer | widget (`support/support_tickets_page_test.dart`) |

## Triage gaps

Features tagged `mvp` whose current test coverage is insufficient — these block "100% on activated features":

- **Create wallet — BitBox02** — no test today; integration test landing in [#320](https://github.com/DFXswiss/realunit-app/pull/320)
- **Receive** — no test for the address/QR screen
- **Biometric unlock** — no test (`biometric_service.dart` has no unit spec; no widget spec asserts the unlock surface)
- **Legal disclaimer gate** — widget exists, cubit transition not directly tested
- **KYC cubit + sign-flow logic** — widget tests cover individual pages, but state transitions (`KycCubit`, `KycRegistrationSubmitCubit`, `Eip712Signer` guard paths) land in [#319](https://github.com/DFXswiss/realunit-app/pull/319) + [#320](https://github.com/DFXswiss/realunit-app/pull/320)
- **DFX backend services** — `DFXAuthService`, `real_unit_registration_service`, `real_unit_pdf_service`, `dfx_kyc_service`, `dfx_price_service`, `dfx_widget_service`, `dfx_brokerbot_service`, `dfx_bank_account_service`, `dfx_blockchain_api_service`, `dfx_country_service`, `dfx_faucet_service`, `dfx_support_service`, `transaction_history_service`, `wallet_service`, `price_service`, `session_cache`, `settings_service`, `app_store`, `biometric_service`, `debug_auth_service` — none have a unit spec today; in flight via [#319](https://github.com/DFXswiss/realunit-app/pull/319) (`DFXAuthService`) and [#321](https://github.com/DFXswiss/realunit-app/pull/321) (`real_unit_buy_payment_info_service`)
- **Hook / screen state tests** — `home_page` widget renders but the underlying balance/price hook has no spec; same for `dashboard` bloc and most screen-level cubits

## Testing tiers

[#314](https://github.com/DFXswiss/realunit-app/issues/314) defines a 4-tier model for BitBox-touching code:

- **Tier 0 — Cubit unit tests** (`bloc_test` + `mocktail`). Fast, no platform, no BitBox. Covers every state transition.
- **Tier 1 — FakeBitbox integration tests** (`integration_test/` + `FakeBitboxCredentials`). Drives full app flow without hardware. Phase landing in [#320](https://github.com/DFXswiss/realunit-app/pull/320).
- **Tier 2 — Firmware simulator** (TCP transport + Docker `bitbox02-firmware/simulator`). End-to-end with real crypto, no hardware. Planned.
- **Tier 3 — Maestro hardware flows** (`.maestro/*.yaml`). Real BitBox device. Manually triggered before each release.

Non-BitBox code only needs Tier 0 + widget tests; Tier 1+ are reserved for hardware-coupled paths.

## Tests

| Stack    | Command                   | What it covers                                                                                                                                                                                            |
| -------- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Flutter  | `flutter test`            | Unit + widget specs under `test/**` (pure-Dart `test` and `testWidgets`)                                                                                                                                  |
| Coverage | `flutter test --coverage` | Writes `coverage/lcov.info`. CI filters out `lib/generated/**` and `lib/main.dart` so the figure reflects the activated surface. Threshold enforcement is not yet wired — see "Coverage infrastructure roadmap" above. |
| Analyzer | `flutter analyze`         | Dart static analysis per `analysis_options.yaml`                                                                                                                                                          |

Tier 1 (`integration_test/`) and Tier 3 (`.maestro/`) runners are tracked under "Testing tiers" above but not yet committed.

## CI/CD

| Workflow                     | Trigger                                                       | Action                                                                                  |
| ---------------------------- | ------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `pull-request.yaml`          | PR to `develop` / `main` · manual                             | `flutter analyze` + `flutter test --coverage`, filter generated files, upload lcov artifact |
| `bitbox-simulator.yml`       | PR touching `lib/packages/hardware_wallet/**` or `wallet/**`  | Runs the BitBox02 firmware simulator with `bitbox-testkit` baselines (Tier 2)           |
| `bitbox-simulator-slash.yml` | `/bitbox-simulator` comment on any PR                         | Same engine as above, on-demand per PR (variants: default / `ref=main`)                 |
| `auto-release-pr.yaml`       | Push `develop` · manual                                       | Opens Release PR `develop` → `main`                                                     |
| `auto-tag.yaml`              | Push `develop`                                                | Creates the next `vX.Y.Z` patch tag (PATCH = previous + 1, MINOR/MAJOR from pubspec floor) |
| `develop-release.yaml`       | Tag `v*` with PATCH >= 1 · manual                             | Internal release: Android + iOS deploy to Play Internal + TestFlight, GitHub pre-release |
| `beta-release.yaml`          | Tag `v*` with PATCH == 0 · manual                             | Production candidate: Android + iOS deploy to Play Internal + TestFlight, GitHub release (production promotion is manual in the store backends) |
| `beta-release-android.yaml`  | Tag `android/v*` · manual                                     | Android-only deploy (Play Internal Testing)                                             |
| `beta-release-ios.yaml`      | Tag `ios/v*` · manual                                         | iOS-only deploy (TestFlight, Fastlane Match)                                            |
| `handbook-dev.yaml`          | Push `develop` under `docs/handbook/**` · manual              | Builds `dfxswiss/realunit-app-handbook:beta`, redeploys the handbook DEV container      |
| `handbook-prd.yaml`          | Push `main` under `docs/handbook/**` · manual                 | Builds `dfxswiss/realunit-app-handbook:latest`, redeploys the handbook PRD container    |

## Release versioning

Tags follow plain SemVer: `vMAJOR.MINOR.PATCH`. There is no pre-release suffix — the previous `vX.Y.Z-beta.N` schema has been retired.

| Component | When does it bump? | Workflow | Distribution |
| --- | --- | --- | --- |
| `PATCH` (`v1.0.X` with X >= 1) | Automatically on every push to `develop` (see `auto-tag.yaml`). | `develop-release.yaml` ("Internal Release") | TestFlight + Play Internal. |
| `MINOR` (`v1.X.0`) | Manual tag push (App-Store-update marker). | `beta-release.yaml` ("Production Release Candidate") | TestFlight + Play Internal. Production promotion is done manually in the store backends. |
| `MAJOR` (`vX.0.0`) | Manual tag push. | `beta-release.yaml` ("Production Release Candidate") | TestFlight + Play Internal. Production promotion is done manually in the store backends. |

Both release workflows listen on the same tag pattern (`v*`) and use a guard job to route based on the PATCH component: patch tags go through the Internal Release lane, MAJOR/MINOR tags through the Production Release Candidate lane. Either way the build lands in the Test tracks first — the App Store / Play Store production track is never updated by a tag push.

The build number is derived deterministically from the tag by `tool/generate_release_info.dart` using `MAJOR * 10_000_000 + MINOR * 100_000 + PATCH * 1_000 + 999`. The fixed `+999` suffix keeps every new build strictly above the legacy beta build codes; the first new build `v1.0.15` lands at `10_015_999`, comfortably above the highest published legacy beta `v1.0.0-beta.14` at `10_000_014`.

`pubspec.yaml`'s `version:` field has two roles:

- The `+0` build-number sentinel is for local builds — CI always overrides `--build-name` / `--build-number` from the tag. Don't bump the `+N` part manually.
- The `X.Y.Z` part is a **floor** for MAJOR / MINOR jumps. Patch increments come from the latest tag; pubspec is only consulted to trigger jumps. To start a new MINOR / MAJOR train (e.g. `v1.1.0`), bump pubspec on `develop` and the next auto-tag will pick it up.

Typical patch flow: PR merges into `develop` → `auto-tag.yaml` creates `v1.0.X` → `develop-release.yaml` ships the build to TestFlight + Play Internal.

## Getting started

Before getting started, please make sure you have Flutter version 3.41.6 and the latest version of golang and gomobile installed.

```shell
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
```

### 1. Generate translations

```shell
dart run tool/generate_localization.dart
```

### 2. Generate Drift files

```shell
dart run build_runner build --delete-conflicting-outputs
```

### 3. Get dependencies

```shell
flutter pub get
```

### 4. Start the app

```shell
flutter run
```
