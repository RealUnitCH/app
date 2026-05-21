# API Authority Audit

This document inventories every place in the realunit-app where business decisions
are made locally instead of being delegated to the DFX API, as required by the
*"API as Decision Authority"* rule in [`CONTRIBUTING.md`](../CONTRIBUTING.md).

Findings were produced by four parallel scans (2026-05-21) over the KYC, Buy/Sell,
Wallet/Service-layer, and Settings areas, then deduplicated and ranked by impact.

Each item lists:
- The violation site (`file:line`)
- The local decision being made
- What an API-driven version should look like
- Whether closing it requires an API change in [`DFXswiss/api`](https://github.com/DFXswiss/api)

---

## P0 — User-visible blockers caused by app-side gating

These are the items where the app actively prevents a user from doing something
the API would accept. Fixing these directly resolves real user complaints (e.g.
the 2026-05-21 ident-misroute report that triggered this audit).

### KYC routing decided in the cubit instead of by the API

- `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:16-22` — `_requiredStepNames` set
  - **Local decision:** which step names count as "required for trading"
  - **Backend already owns this** in `api/src/subdomains/generic/kyc/enums/kyc.enum.ts:requiredKycSteps(userData)` — the app duplicates a subset
  - **API change needed:** add `isRequired: bool` to `KycStepDto`, drop the local set
- `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:24, 171` — `_minLevelForActions = 30` + `level < _requiredLevel` check
  - **Local decision:** which numeric level unlocks trading
  - **API change needed:** API returns `canTrade: bool` / `canPerformAction: bool` per user — the app renders, doesn't compute
- `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:142, 156-162` — `pendingStatuses` + `actionableStatuses` sets
  - **Local decision:** which `ReviewStatus` values mean "user must act" vs "wait for review"
  - **API change needed:** API's `KycInfoMapper.toDto` already picks `currentStep` — the app should render `currentStep` directly and stop iterating `kycSteps`
- `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:134-168` — manual filter + routing chain over `kycSteps`
  - **Local decision:** entire next-step selection algorithm — duplicates `KycService.tryContinue` on the API
  - **API change needed:** none — the `currentStep` field from `PUT /v2/kyc` already contains the answer; remove the loop, route from `currentStep` only
- `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:179-182` — `e.statusCode == 403 || e.code == 'TFA_REQUIRED'` → emit 2FA step
  - **Local decision:** translate HTTP status into a UI flow
  - **API change needed:** API returns `nextStep: '2fa'` in the response body — app does not switch on status codes
- `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:88-104` — auto-register email when `level < 10`
  - **Local decision:** infer that level<10 means "the email step is implicit, call the registration endpoint silently"
  - **API change needed:** if auto-registration is desired the API performs it server-side; the app calls `continueKyc` and renders what comes back

### Hardcoded transaction limits

- `lib/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart:16, 50-60` — `_minAmountChf = 100` pre-flight
  - **API change needed:** `POST /v1/buy/quote` already validates min/max — return `minAmount` / `maxAmount` / `error` from the API, surface its error verbatim
- `lib/screens/sell/cubits/sell_payment_info/sell_payment_info_cubit.dart:17, 82-112` — `_minAmountChf = 10` + `validateMinAmount()` pre-flight
  - **API change needed:** same shape on `POST /v1/sell/quote` — remove the local validate method entirely

### Hardcoded routing forks based on wallet type

- `lib/screens/sell/widgets/sell_button.dart:60-62` — `if (state.isBitbox) → AppRoutes.sellBitbox`
  - **Local decision:** which sell-flow page to use based on hardware-wallet presence
  - **API change needed:** API returns `requiredWorkflow: 'sell' | 'sellBitbox'` (or a list of steps) — app dispatches on that string

### Feature visibility decided by local heuristics

- `lib/screens/settings_user_data/settings_user_data_page.dart:239` — Edit button hidden if `statusLabel != null` (i.e. `inReview`)
  - **API change needed:** API returns `editable: bool` per field; app does not introspect status to compute editability
- `lib/screens/settings_user_data/subpages/edit_name/cubit/settings_edit_name_cubit.dart:22` — `if (session.currentStep?.status == KycStepStatus.inReview)` blocks editing
  - Same as above — render an API capability flag, do not switch on status
- `lib/screens/settings_contact/settings_contact_page.dart:54-67` — "Contact Support" only shown if email is set
  - **API change needed:** API exposes `support.available: bool` (or always allow it through the support endpoint and the API returns 400 if not eligible)
- `lib/screens/settings/settings_page.dart:100` — "Wallet Backup" only shown if `walletType == WalletType.software`
  - **Boundary case:** wallet-type is a device-local fact (BitBox cannot expose its seed); this one is **defensible** as a UI capability. Document the exception or accept it.

---

## P1 — Local interpretation of API state

These do not block users today, but every one accumulates drift between the
backend's understanding of state and the app's interpretation of it.

### Local session gates that should be positioned by the API

- `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:31, 113-115` — `_legalDisclaimerAccepted`
  - The flag itself is a legitimate per-session security gate. **The violation is its position in routing** — the app inserts disclaimer between email and registration unilaterally. **API change needed:** API returns `currentStep: 'legalDisclaimer'` when it wants the disclaimer to show.
- `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:40, 117-119` — `_registrationSignProduced`
  - Same shape — per-session sign-gate is fine; deciding *when* to surface the registration page from the cubit is not. **API drives the position.**

### JWT decoded locally to detect merge

- `lib/screens/kyc/steps/email/cubits/email_verification/kyc_email_verification_cubit.dart:49-63` — parses JWT, extracts `account` claim, compares before/after to detect merge
  - **API change needed:** `POST /v1/realunit/register/wallet` (or a new `/kyc/check-merge`) returns `{ merged: true, mergedAccountId }` directly — the app does not introspect tokens

### Transaction state interpretation in the UI

- `lib/screens/dashboard/widgets/pending_transaction_row.dart:49-51` — `if (transaction.state == .waitingForPayment)` switches label
  - **API change needed:** API returns `statusLabel` / `statusKey` as a string the app can render or translate; app does not switch on enums

### Status code semantics

- `lib/packages/service/dfx/dfx_auth_service.dart:233-239` — `401 → refresh token`
  - HTTP-standard behavior, but still a local interpretation. **Accept as conventional**, or document that 401-on-this-endpoint specifically means "JWT expired" so the convention is contractual.

### Polling/retry orchestration with local generation tokens

- `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:42-69` — `_runGeneration` cancellation token + 30s timeout
- `lib/screens/kyc/steps/email/cubits/email_verification/kyc_email_verification_cubit.dart:24-37` — `_mergeDetected` + generation tracking, multi-step propagation race handling
  - **Local decision:** when to give up, how to retry, what counts as a recoverable failure
  - **API change needed:** API exposes a single idempotent `/check-merge` endpoint that handles propagation internally — app stops orchestrating

### Registration-submit treats backend rejection as success

- `lib/screens/kyc/steps/registration/cubits/registration_submit/kyc_registration_submit_cubit.dart:76, 92` — on `"already registered"` API error, emit `Success` to let `KycCubit` resolve the next state
  - **Local decision:** that an API "no" is actually "yes, with a different next step"
  - **API change needed:** API returns `{ status: 'already_registered', nextStep: 'merge' }` and the app dispatches; the cubit must not paper over a 400

---

## P2 — Hardcoded lists / config that should come from the API

### Currency, language, country, network

- `lib/styles/currency.dart:3-22` — `enum Currency { EUR, CHF }`
  - **API change needed:** call `/v1/fiat` and render the list returned for this user's region
- `lib/styles/language.dart:3-22` — `enum Language { EN, DE }`
  - **API change needed:** call `/v1/language` (already exists on the DFX API)
- `lib/widgets/form/country_field.dart:65-79` — `['CH', 'DE', 'IT', 'FR']` priority list at top
  - **API change needed:** `/v1/country?priority=true` returns ordered list; UI does not hardcode preference
- `lib/packages/config/network_mode.dart:4-20` — `enum NetworkMode { mainnet, testnet }`
  - **Boundary case:** network mode determines *which* API host the app calls. Cannot itself be API-driven (chicken-and-egg). **Document as legitimate exception.**

### Currency dropdowns rendered from local enum

- `lib/screens/buy/widgets/payment_converter.dart:83` — `Currency.values.map()`
- `lib/screens/sell/widgets/sell_converter.dart:201` — `Currency.values.map()`
  - Same root cause as `styles/currency.dart` — fix the source

### Legal documents URLs hardcoded

- `lib/packages/config/legal_documents_config.dart:69-122` — Registration-Agreement PDFs (DE/EN), RealUnit Prospekt, Aktionariat, DFX-Docs URLs
  - **API change needed:** `/v1/legal-document?type=registration&language=de` returns the current URL + version; app renders without knowing URLs in advance

### Company contact info hardcoded

- `lib/screens/settings_contact/settings_contact_page.dart:82, 93-94, 104, 109, 133-134` — phone, email, website, postal address
  - **API change needed:** `/v1/company-info` (or the existing `/v1/settings`) returns this for the RealUnit branding; allows future white-labeling

### Asset configuration hardcoded

- `lib/packages/config/api_config.dart:19-22` — RealUnit token address, chainId, decimals (mainnet + Sepolia variants)
- `lib/packages/utils/default_assets.dart:3-22` — ETH/ZCHF asset IDs per network
  - **Boundary case:** the app *is* the RealUnit wallet, by definition it knows which token it manages. Asset IDs from `/v1/asset` would be cleaner but this is the lowest-priority offender — leave for last.

### Date / size constants

- `lib/screens/transaction_history/transaction_history_page.dart:68-69` — `firstDate: DateTime(2025)` on history picker
- `lib/screens/settings_tax_report/settings_tax_report_page.dart:73` — `firstDate: DateTime(2025)` on tax-report picker
  - **API change needed:** `/v1/user/account-bounds` returns `{ firstTransactionDate, lastTransactionDate }`
- `lib/screens/settings_seed/settings_seed_view.dart:98` — `if (wordCount != 12)` mnemonic length check
  - **Local concern — local crypto invariant.** BIP-39 length is structural, not a business rule. **Accept as legitimate.**

### Default language selection

- `lib/packages/repository/settings_repository.dart:18-24` — `systemLang == 'de' ? 'de' : 'en'`
  - **API change needed:** API recommends a default language per user/region; until then, this is acceptable Frontend-only behavior (no user has been onboarded yet).

---

## P3 — DTO/enum mirroring (acceptable boilerplate, but watch for drift)

These are not violations of the rule (DTOs *must* mirror the API for type safety),
but they're listed so reviewers know what to keep in sync when the API changes.

- `lib/packages/service/dfx/models/kyc/kyc_level.dart` — `KycLevel`, `KycStepName`, `KycStepStatus`, `KycStepType`, `KycStepReason` enums with `fromValue` / `toValue`
- `lib/packages/service/dfx/models/registration/registration_status.dart`
- `lib/packages/service/dfx/models/registration/registration_email_status.dart`
- `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:224-231` — `_mapStepName()` switch from `KycStepName` to UI `KycStep`

The `KycStepName → KycStep` map is borderline: it's a UI-routing decision (which
page to show per backend step). If `KycStepDto` carried a `uiHint: 'identPage'`
field, the app would not need this map at all. **API change suggested but not
required.**

---

## P4 — Already addressed / documented elsewhere

For completeness:

- `lib/screens/kyc/steps/email/kyc_email_page.dart:91` — `markRegistrationSignProduced()` after merge confirmation. Local session-gate position, called from a code path where the API already signaled success. Fixed by PR #466. **OK.**
- `KycEmailVerificationCubit._completeRegistration` — surfaces failures correctly (PR #466 / API PR #3731). Once API PR #3731 merges and the `register/wallet` endpoint is idempotent, the client-side retry logic at the email verification page can be simplified further. Track in [#3731](https://github.com/DFXswiss/api/pull/3731).

---

## Summary

| Severity | Count | Primary location |
|---|---|---|
| **P0** — blocks users today | 11 | `kyc_cubit.dart` (6), buy/sell payment-info cubits (2), settings user-data (2), sell_button (1) |
| **P1** — local interpretation, no immediate block | 9 | `kyc_cubit.dart` + email-verification + registration-submit cubits |
| **P2** — hardcoded lists/config | ~15 | currency/language/country, legal docs, company info, assets |
| **P3** — DTO mirroring (informational) | 5 | service/dfx/models |
| **P4** — fixed or in-flight | 2 | tracked in PR #466 / #3731 |

**Most-affected single file:** `lib/screens/kyc/cubits/kyc/kyc_cubit.dart` —
~10 distinct violations. The entire `_runCheckKyc` body should be replaceable by
"render `currentStep` from the API, that's it" once the matching API fields land.

## How to use this list

- **For new PRs:** check whether your change touches any line in this file. If yes,
  prefer to *remove* a violation (P0 → P3 in that order) rather than add one.
- **For backend PRs:** every P0/P1 item has a paired API field that's missing.
  When you extend the API to deliver that field, the app PR that consumes it
  should also delete the corresponding local logic in the same PR.
- **For the architecture review on 2026-05-21:** the P0 list is the actionable
  short-list. P2 is a longer-term cleanup. P3/P4 are acknowledged exceptions.
