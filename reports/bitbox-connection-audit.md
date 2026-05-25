# BitBox Connection Audit

Date: 2026-05-25
Repository: `/Users/jk/DFXswiss/realunit-app`
Related plugin repository: `/Users/jk/DFXswiss/bitbox_flutter`

## Executive Summary

The local BitBox integration is structurally present and the targeted BitBox test surface passes when forced to use the existing local `.dart_tool/package_config.json`.

The setup is not currently reproducible from a clean checkout. `pubspec.yaml` points to a missing remote branch in `joshuakrueger-dfx/bitbox_flutter`, while `pubspec.lock` still points to `DFXswiss/bitbox_flutter` tag `v0.0.7`, and `.dart_tool/package_config.json` points to the local sibling checkout `../../bitbox_flutter`.

Until dependency resolution is fixed, CI-equivalent validation cannot be trusted.

## Dependency State

Current `pubspec.yaml` dependency:

```yaml
bitbox_flutter:
  git:
    url: https://github.com/joshuakrueger-dfx/bitbox_flutter.git
    ref: joshua/i3-fake-inject-points
```

Current `pubspec.lock` dependency:

```yaml
bitbox_flutter:
  dependency: "direct main"
  description:
    ref: "v0.0.7"
    resolved-ref: ebe0fb04e0fb1d56ae6fa815277598c980ac1940
    url: "https://github.com/DFXswiss/bitbox_flutter.git"
```

Current local package config:

```text
bitbox_flutter rootUri: ../../bitbox_flutter
```

Remote verification:

- `https://github.com/joshuakrueger-dfx/bitbox_flutter.git refs/heads/joshua/i3-fake-inject-points`: no ref returned.
- `https://github.com/joshuakrueger-dfx/bitbox_flutter.git refs/heads/joshua/all-test-infra`: no ref returned.
- `https://github.com/joshuakrueger-dfx/bitbox_flutter.git refs/heads/joshua/generic-bitbox-testkit`: exists at `783ec72d6300d97eece30ae4717514980d2f26b2`.
- `https://github.com/DFXswiss/bitbox_flutter.git refs/heads/develop`: exists at `70fbf4925598e6be166473dd811d35d9d3da9da8`.
- `https://github.com/DFXswiss/bitbox_flutter.git refs/tags/v0.0.7`: exists at `b4a8aacfd98f68b8b37f7276d2c24414957d3c94`.

Local plugin branch:

- `/Users/jk/DFXswiss/bitbox_flutter`
- current branch: `joshua/all-test-infra`
- current commit: `9434571e4b6a1072015d371f59ccca8e950f3825`
- includes local `joshua/i3-fake-inject-points` commit `944f79b9bd0f1101cc9d2d622e5e67455bcdc2cc`.

## Integration Surface Reviewed

Production surfaces:

- `lib/packages/hardware_wallet/bitbox.dart`
- `lib/packages/hardware_wallet/bitbox_credentials.dart`
- `lib/packages/hardware_wallet/bitbox_connection_status.dart`
- `lib/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart`
- `lib/screens/sell_bitbox/cubit/sell_bitbox_cubit.dart`
- `lib/packages/wallet/eip712_signer.dart`
- `lib/packages/wallet/sign_pipeline.dart`
- `lib/packages/service/dfx/real_unit_registration_service.dart`

Test/fake surfaces:

- `test/helper/fake_bitbox_credentials.dart`
- `test/packages/hardware_wallet/**`
- `test/integration/bitbox_lifecycle_test.dart`
- `test/integration/sign_pipeline_pairing_test.dart`
- `test/integration/kyc_sign_flow_test.dart`
- `test/integration/kyc_bitbox_disconnect_mid_sign_test.dart`
- `bitbox_flutter/lib/testing.dart`
- `bitbox_flutter/lib/testing/fake_bitbox_credentials.dart`
- `bitbox_flutter/lib/testing/bitbox_testkit.dart`

## Validation Commands

### Clean command

```text
/Users/jk/fvm/versions/3.41.9/bin/flutter test test/packages/hardware_wallet test/integration/sign_pipeline_pairing_test.dart test/integration/kyc_sign_flow_test.dart test/integration/bitbox_lifecycle_test.dart
```

Result: failed before tests with exit `69`.

Reason:

```text
Because realunit_wallet depends on bitbox_flutter from git which doesn't exist
(Could not find git ref 'joshua/i3-fake-inject-points' ...)
```

### Local non-CI-equivalent BitBox app tests

```text
/Users/jk/fvm/versions/3.41.9/bin/flutter test --no-pub test/packages/hardware_wallet test/integration/sign_pipeline_pairing_test.dart test/integration/kyc_sign_flow_test.dart test/integration/bitbox_lifecycle_test.dart
```

Result: passed.

Evidence:

```text
111 tests passed.
```

Meaning: Real Unit's local BitBox lifecycle, credentials, pairing mismatch, KYC sign flow, and simulator-boundary tests pass against the local `../../bitbox_flutter` checkout.

### Local bitbox_flutter Dart tests

```text
/Users/jk/fvm/versions/3.41.9/bin/flutter test
```

Working directory: `/Users/jk/DFXswiss/bitbox_flutter`

Result: passed.

Evidence:

```text
31 tests passed.
```

### Local bitbox_flutter Go tests

```text
go test ./...
```

Working directory: `/Users/jk/DFXswiss/bitbox_flutter/go`

Result: passed.

Evidence:

```text
ok github.com/DFXswiss/bitbox_flutter/api
ok github.com/DFXswiss/bitbox_flutter/u2fhid
```

### Sign pipeline and ASCII safety tests

```text
/Users/jk/fvm/versions/3.41.9/bin/flutter test --no-pub test/packages/utils/ascii_transliterate_test.dart test/packages/wallet/sign_pipeline_test.dart test/packages/wallet/eip712_signer_bitbox_test.dart test/packages/service/dfx/real_unit_registration_service_happy_test.dart
```

Result: passed.

Evidence:

```text
34 tests passed.
```

Meaning: existing tests cover BitBox-safe ASCII transliteration, SignPipeline romanisation invariants, EIP-712 BitBox signing, and registration payload/signature consistency.

## bitbox-audit Result

Command:

```text
/Users/jk/go/bin/bitbox-audit --repo /Users/jk/DFXswiss/realunit-app --format markdown
```

Result: exit `2`.

Full report committed at:

```text
reports/bitbox-audit-critical-findings.md
```

Summary:

- Files scanned: `428`
- Quirks evaluated: `31`
- Critical findings: `118`
- Dominant quirk: `E1 non-ascii-eip712-string`
- Reported locations are mostly `lib/generated/i18n.dart`.

Interpretation:

The audit signal is actionable as a guardrail, but the static detector appears over-broad for this repo because generated localization strings are not automatically EIP-712 payload fields. The actual registration and sign-pipeline code contains `toBitboxSafeAscii`, and the targeted tests above passed. This means the audit does not currently prove a product bug, but it does prove the CI audit can fail noisily unless scoped or paired with dynamic test evidence.

## Findings

### Finding 1: Clean checkout dependency resolution is broken

Severity: CRITICAL

The current `pubspec.yaml` ref cannot be resolved from the configured remote. This prevents `flutter pub get`, `flutter test`, `flutter analyze`, and the full agent workflow from running in a clean checkout.

Required fix:

- Publish the needed branch/commit to a remote, or
- point `pubspec.yaml` to an existing reviewed ref/tag/commit, or
- deliberately use a local path override only for local validation, never as CI evidence.

### Finding 2: Local tests rely on `.dart_tool/package_config.json`

Severity: HIGH

The passing Real Unit tests used `--no-pub` and therefore relied on the existing local package config that points at `../../bitbox_flutter`. This is useful for local integration confidence, but it is not reproducible evidence for CI or another developer's machine.

Required fix:

- Restore reproducible package resolution first, then rerun the same tests without `--no-pub`.

### Finding 3: Two different BitBox fakes exist

Severity: MEDIUM

Real Unit has `test/helper/fake_bitbox_credentials.dart`, while `bitbox_flutter` also exports `package:bitbox_flutter/testing.dart` with its own `FakeBitboxCredentials` and `SimulatedBitboxPlatform`.

This is not automatically wrong because they sit at different seams:

- Real Unit helper fake extends Real Unit `BitboxCredentials`.
- Plugin fake/simulator replaces `BitboxUsbPlatform.instance`.

Risk:

- Same class name and overlapping concepts can drift or confuse future tests.

Recommended action:

- Keep both only if the distinction is documented as "credentials-boundary fake" vs "platform-boundary fake".
- Prefer the plugin-level fake/simulator for lifecycle, pairing, channel-hash, disconnect, timeout, and platform-call tests.
- Keep the Real Unit helper fake only for high-level sign-pipeline tests where `is BitboxCredentials` is the behaviour under test.

### Finding 4: bitbox-audit is too noisy without dynamic evidence

Severity: MEDIUM

`bitbox-audit` currently reports many `E1` criticals from localization output. The actual sign paths have ASCII guards and tests, but the audit job exits non-zero.

Recommended action:

- Feed dynamic test evidence into `bitbox-audit --test-results` where supported, or
- tune/suppress generated localization false positives in the audit tooling, not in product code, or
- add a repo-level audit note explaining why generated i18n strings are not sign payloads.

## Current Confidence

Local integration confidence: MEDIUM-HIGH.

Reason:

- Targeted BitBox tests pass locally.
- Plugin Dart and Go tests pass locally.
- Pairing mismatch, lifecycle loss, reconnect, sign queue timeout, KYC sign, and ASCII-safety behaviours are covered.

CI/reproducibility confidence: LOW.

Reason:

- `pub get` fails from the declared dependency graph.
- The passing app tests require `--no-pub`.
- The dependency source differs across `pubspec.yaml`, `pubspec.lock`, and `.dart_tool/package_config.json`.

## Safe Next Steps

1. Make `bitbox_flutter` reproducible from a clean checkout.
2. Run `flutter pub get` without local overrides.
3. Rerun the BitBox test scope without `--no-pub`.
4. Run `flutter analyze`.
5. Re-run `bitbox-audit` and decide whether remaining `E1` findings are real payload risks or generated-code false positives.
6. Only after those pass should the full agent workflow continue beyond Gate 1.
