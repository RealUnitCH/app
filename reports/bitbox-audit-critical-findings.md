# BitBox Audit Critical Findings

Date: 2026-05-26

## Verdict

Current actionable product-audit result: **0 critical findings** when the audit is scoped to the production BitBox/signing surface.

The previous 118 critical findings were reproduced as a whole-repository static-scope false positive set:

- Command: `$(go env GOPATH)/bin/bitbox-audit --repo . --format markdown --output /private/tmp/bitbox-audit-whole-repo.md`
- Exit code: `2`
- Result: `118` critical findings
- Location: all sampled findings were `E1 non-ascii-eip712-string` in `lib/generated/i18n.dart`
- Assessment: generated UI localization contains legitimate non-ASCII copy and BitBox-facing UX strings, but it is not the signed EIP-712 payload surface.

Scoped product audit:

- Command: `$(go env GOPATH)/bin/bitbox-audit --repo lib/packages --format markdown --output /private/tmp/bitbox-audit-lib-packages-final.md`
- Exit code: `0`
- Files scanned: `142`
- Quirks evaluated: `31`
- Critical findings: `0`
- Warning findings: `0`
- Hint findings: `0`

## CI Tooling Change

`.github/workflows/pull-request.yaml` now runs `bitbox-audit` against `lib/packages` instead of `.` and writes a short scope preface into `bitbox-audit-report.md`.

Reason:

- `lib/packages/**` contains the hardware-wallet, signer, SignPipeline, and DFX service code where signed payload risk lives.
- `lib/generated/i18n.dart` is generated UI text and must not be "fixed" by transliterating user-visible translations.
- Flutter tests remain the dynamic evidence for payload invariants because `bitbox-audit v0.5.0` only advertises Jest JSON and `go test -json` as dynamic test-result inputs.

## Product Payload Evidence

No additional product payload fix was required in this run.

Existing code already applies BitBox-safe ASCII conversion at the relevant RealUnit registration signing boundary:

- `lib/packages/service/dfx/real_unit_registration_service.dart`
  - `completeRegistration` converts signed registration envelope fields through `toBitboxSafeAscii`.
  - `registerWallet` applies the same conversion before calling `Eip712Signer.signRegistration`.
  - Original KYC personal data remains preserved in the KYC DTO, so legal names with diacritics are not destroyed outside the signed BitBox envelope.

Existing tests validate the payload boundary:

- `test/packages/utils/ascii_transliterate_test.dart`
- `test/packages/wallet/sign_pipeline_test.dart`
- `test/packages/wallet/eip712_signer_bitbox_test.dart`
- `test/packages/service/dfx/real_unit_registration_service_happy_test.dart`

## Remaining Risk

The audit job is still informational because `bitbox-audit v0.5.0` cannot fold Flutter test results into its dynamic coverage model. Static scope is now meaningful, but Flutter test evidence must still be read alongside the audit report.
