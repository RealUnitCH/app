# API Authority Audit

This document inventories every place in the realunit-app where business decisions
are made locally instead of being delegated to the DFX API, as required by the
*"API as Decision Authority"* rule in [`CONTRIBUTING.md`](../CONTRIBUTING.md).

Findings were produced by four parallel scans (2026-05-21) over the KYC, Buy/Sell,
Wallet/Service-layer, and Settings areas, then deduplicated and ranked by impact.

Each item lists:
- The violation ID (`V<N>`) used to cross-reference with [`api-authority-plan.md`](api-authority-plan.md)
- The violation site (`file:line`)
- The local decision being made
- What an API-driven version should look like
- Whether closing it requires an API change in [`DFXswiss/api`](https://github.com/DFXswiss/api)

The `V<N>` anchors are stable: every finding in this audit carries one, and every
wave entry in the plan cites the `V<N>` it closes. To answer *"which wave closes
audit finding V12?"* search for `V12` in `api-authority-plan.md`.

---

## P0 — User-visible blockers caused by app-side gating

These are the items where the app actively prevents a user from doing something
the API would accept. Fixing these directly resolves real user complaints (e.g.
the 2026-05-21 ident-misroute report that triggered this audit).

### KYC routing decided in the cubit instead of by the API

- **V1** — `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:16-22` — `_requiredStepNames` set
  - **Local decision:** which step names count as "required for trading"
  - **Backend already owns this** in `api/src/subdomains/generic/kyc/enums/kyc.enum.ts:requiredKycSteps(userData)` — the app duplicates a subset
  - **API change needed:** add `isRequired: bool` to `KycStepDto`, drop the local set
- **V2** — `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:24, 171` — `_minLevelForActions = 30` + `level < _requiredLevel` check
  - **Local decision:** which numeric level unlocks trading
  - **API change needed:** API returns `canTrade: bool` / `canPerformAction: bool` per user — the app renders, doesn't compute
- **V3** — `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:142, 156-162` — `pendingStatuses` + `actionableStatuses` sets
  - **Local decision:** which `ReviewStatus` values mean "user must act" vs "wait for review"
  - **API change needed:** API's `KycInfoMapper.toDto` already picks `currentStep` — the app should render `currentStep` directly and stop iterating `kycSteps`
- **V5** — `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:134-168` — manual filter + routing chain over `kycSteps`
  - **Local decision:** entire next-step selection algorithm — duplicates `KycService.tryContinue` on the API
  - **API change needed:** none — the `currentStep` field from `PUT /v2/kyc` already contains the answer; remove the loop, route from `currentStep` only
  - **Closed by:** W2.2 (subsumed by the `_runCheckKyc` rewrite that collapses V1, V2, V3 — V5 is *the same loop* those three constants drive). Tagged separately so reviewers can grep the routing-chain code path explicitly.
- **V45** — `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:_continueKyc` — `_continueKyc` repeats the same manual filter over `kycSteps`
  - **Local decision:** `kycStatus.kycSteps.firstWhere((step) => step.isCurrent)` — parallel code path with the same anti-pattern as V5's `_runCheckKyc` loop, called after a realunit registration completes
  - **API change needed:** none — the `currentStep` field is already authoritative; consume it directly. When W2.2 rewrites `_runCheckKyc` to render `currentStep` directly, this loop must also be deleted in the same PR
  - **Closed by:** W2.2 (#494). `_continueKyc` now reads `KycSessionDto.currentStep` directly. A missing `currentStep` surfaces `KycUnsupportedStepFailure(null)` instead of throwing a bare `StateError` (which had been leaking as raw stack-trace text into the user-facing i18n message).
- **V4** — `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:179-182` — `e.statusCode == 403 || e.code == 'TFA_REQUIRED'` → emit 2FA step
  - **Local decision:** translate HTTP status into a UI flow
  - **API change needed:** API returns `nextStep: '2fa'` in the response body — app does not switch on status codes
- **V20** — `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:88-104` — auto-register email when `level < 10`
  - **Local decision:** infer that level<10 means "the email step is implicit, call the registration endpoint silently"
  - **API change needed:** if auto-registration is desired the API performs it server-side; the app calls `continueKyc` and renders what comes back

### Hardcoded transaction limits

- **V7** — `lib/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart:16, 50-60` — `_minAmountChf = 100` pre-flight
  - **API change needed:** `POST /v1/buy/quote` already validates min/max — return `minAmount` / `maxAmount` / `error` from the API, surface its error verbatim
- **V8** — `lib/screens/sell/cubits/sell_payment_info/sell_payment_info_cubit.dart:17, 82-112` — `_minAmountChf = 10` + `validateMinAmount()` pre-flight
  - **API change needed:** same shape on `POST /v1/sell/quote` — remove the local validate method entirely

### Hardcoded routing forks based on wallet type

- **V16** — `lib/screens/sell/widgets/sell_button.dart:60-62` — `if (state.isBitbox) → AppRoutes.sellBitbox`
  - **Local decision:** which sell-flow page to use based on hardware-wallet presence
  - **API change needed:** API returns `requiredWorkflow: 'sell' | 'sellBitbox'` (or a list of steps) — app dispatches on that string

### Feature visibility decided by local heuristics

- **V6a** — `lib/screens/settings_user_data/settings_user_data_page.dart:239` — Edit button hidden if `statusLabel != null` (i.e. `inReview`)
  - **API change needed:** API returns `editable: bool` per field; app does not introspect status to compute editability
- **V6b** — `lib/screens/settings_user_data/subpages/edit_name/cubit/settings_edit_name_cubit.dart:22` — `if (session.currentStep?.status == KycStepStatus.inReview)` blocks editing
  - Same as V6a — render an API capability flag, do not switch on status
- **V6c** — `lib/screens/settings_user_data/subpages/edit_address/cubit/settings_edit_address_cubit.dart:22` — same `if (session.currentStep?.status == KycStepStatus.inReview)` interpretation as V6b
  - Identical shape, separate cubit. Both must be migrated together in W3.2 — listed separately so the grep target is unambiguous.
- **V6d** — `lib/screens/settings_user_data/cubit/settings_user_data_cubit.dart:18-22` — `_changeStepNames` static const set ({nameChange, addressChange, phoneChange})
  - **Local decision:** which KYC step names represent a user-data change flow — same shape as `_requiredStepNames` (V1), just a different subset
  - **API change needed:** API exposes a `category: 'changeRequest'` (or similar) flag on `KycStepDto`, app filters by it
- **V9** — `lib/screens/settings_contact/settings_contact_page.dart:54-67` (the page reads `emailSet`) + `lib/screens/settings_contact/cubit/settings_contact_cubit.dart:22` (the cubit computes `emailSet: userDto.mail != null` from the user DTO) — "Contact Support" only shown if email is set
  - **API change needed:** API exposes `support.available: bool` (or always allow it through the support endpoint and the API returns 400 if not eligible)
- **V13b** — `lib/screens/settings/settings_page.dart:100` — "Wallet Backup" only shown if `walletType == WalletType.software`
  - **Boundary case:** wallet-type is a device-local fact (BitBox cannot expose its seed); this one is **defensible** as a UI capability. **Accepted as documented exception** (see *Documented exceptions* in `api-authority-plan.md`). Tagged for completeness.

---

## P1 — Local interpretation of API state

These do not block users today, but every one accumulates drift between the
backend's understanding of state and the app's interpretation of it.

### Hardcoded language sent to backend on registration

- **V41** — `lib/packages/service/dfx/real_unit_registration_service.dart:117` — `lang: 'DE'` constant sent to the API on registration completion
  - **Local decision:** account language is hardcoded to `'DE'` regardless of the user's actual settings-language / device locale — silently miscategorizes the user's UI language
  - **API change needed:** API derives account language from `Accept-Language` header (or settings-language) on the request; or — interim — the app sends the user's actual settings-language. The app must not pick a fixed value
  - **Closed by:** W4.4 (extended) — handled together with the recommended-language work in W4.3 / W4.4

### Client-side mapping of KYC financial-question key to UI action

- **V43** — `lib/screens/kyc/steps/financial_data/subpages/kyc_financial_data_questions_page.dart:110-122` — switch on `question.key == 'tnc'` / `'notification_of_changes'` to pick action target
  - **Local decision:** which `key` opens a webview (with a hardcoded URL) vs which routes to Support — encoded in the rendering page; any new question type added server-side silently fails to surface the right action
  - **API change needed:** extend `KycFinancialQuestion` DTO with a structured `link: { url?: string, action?: 'support' \| 'webview' }` (or equivalent). The page renders the link metadata; it does not switch on `key` literals
  - **Closed by:** W3.1 / W3.2

### Local session gates that should be positioned by the API

- **V21** — `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:31, 113-115` — `_legalDisclaimerAccepted`
  - The flag itself is a legitimate per-session security gate. **The violation is its position in routing** — the app inserts disclaimer between email and registration unilaterally. **API change needed:** API returns `currentStep: 'legalDisclaimer'` when it wants the disclaimer to show.
- **V22** — `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:40, 117-119` — `_registrationSignProduced`
  - Same shape — per-session sign-gate is fine; deciding *when* to surface the registration page from the cubit is not. **API drives the position.**

### JWT decoded locally to detect merge

- **V23** — `lib/screens/kyc/steps/email/cubits/email_verification/kyc_email_verification_cubit.dart:49-63` — parses JWT, extracts `account` claim, compares before/after to detect merge
  - **API change needed:** `POST /v1/realunit/register/wallet` (or a new `/kyc/check-merge`) returns `{ merged: true, mergedAccountId }` directly — the app does not introspect tokens

### Transaction state interpretation in the UI

- **V24** — `lib/screens/dashboard/widgets/pending_transaction_row.dart:49-51` — `if (transaction.state == .waitingForPayment)` switches label
  - **API change needed:** API returns `statusLabel` / `statusKey` as a string the app can render or translate; app does not switch on enums

### Status code semantics

- **V25** — `lib/packages/service/dfx/dfx_auth_service.dart:233-239` — `401 → refresh token`
  - HTTP-standard behavior, but still a local interpretation. **Accepted as documented exception** (see *Documented exceptions* in `api-authority-plan.md`); 401-on-this-endpoint contractually means "JWT expired". Tagged for completeness.

### Polling/retry orchestration with local generation tokens

- **V26** — `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:42-69` — `_runGeneration` cancellation token + 30s timeout
- **V27** — `lib/screens/kyc/steps/email/cubits/email_verification/kyc_email_verification_cubit.dart:24-37` — `_mergeDetected` + generation tracking, multi-step propagation race handling
  - **Local decision:** when to give up, how to retry, what counts as a recoverable failure
  - **API change needed:** API exposes a single idempotent `/check-merge` endpoint that handles propagation internally — app stops orchestrating

### Registration-submit treats backend rejection as success

- **V15** — `lib/screens/kyc/steps/registration/cubits/registration_submit/kyc_registration_submit_cubit.dart:76, 92` — on `"already registered"` API error, emit `Success` to let `KycCubit` resolve the next state
  - **Local decision:** that an API "no" is actually "yes, with a different next step"
  - **API change needed:** API returns `{ status: 'already_registered', nextStep: 'merge' }` and the app dispatches; the cubit must not paper over a 400

### Bank-account default selection ignores API hint

- **V11** — `lib/screens/sell/widgets/sell_bank_account_field.dart:41-44` — `state.accounts.lastWhereOrNull((a) => a.isActive)`
  - **Local decision:** "the last active bank account is the right default" — duplicates the API's `BankAccountDto.default` flag with a positional heuristic
  - **API change needed:** none — `BankAccountDto.isDefault` already exists in the app's own DTO (`lib/packages/service/dfx/models/bank_account/dto/bank_account_dto.dart:6`) and is parsed from the API's `default` field; the selector just needs to consume it

### Local startup gate that delays API surface

- **V34** — `lib/main.dart:120` — `if (!homeState.softwareTermsAccepted) ...` blocks the dashboard until terms acceptance
  - **Local decision:** that the user cannot reach any *API-allowed* screen until a UI-local preference is set
  - **API change needed:** none — the gate itself is acceptable as a one-time UX overlay, but its *position* (between boot and any API-driven flow) violates the rendering-layer rule. Move to a one-time Dashboard overlay so the API gets to drive routing first

---

## P2 — Hardcoded lists / config that should come from the API

### Currency, language, country, network

- **V12** — `lib/styles/currency.dart:3-22` — `enum Currency { EUR, CHF }`
  - **API change needed:** call `/v1/fiat` and render the list returned for this user's region
- **V46** — `lib/screens/kyc/steps/registration/steps/kyc_registration_personal_step.dart:50-53` — `[RegistrationUserType.values.first]` restricts the account-type dropdown to a single value
  - **Local decision:** the DTO carries multiple `RegistrationUserType` values but the UI only renders `.values.first` (i.e. `human`). Which account types this branded app exposes is a business decision frozen in code
  - **API change needed:** `availableUserTypes: ['human']` capability flag on `UserV2Dto` (or on the registration endpoint response); app renders the returned list. Same shape as V12 / V13
  - **Closed by:** W3.1 / W3.2 (capabilities)
- **V13** — `lib/styles/language.dart:3-22` — `enum Language { EN, DE }`
  - **API change needed:** call `/v1/language` (already exists on the DFX API)
- **V14** — `lib/widgets/form/country_field.dart:65-79` — `['CH', 'DE', 'IT', 'FR']` priority list at top
  - **API change needed:** `/v1/country?priority=true` returns ordered list; UI does not hardcode preference
- **V28** — `lib/packages/config/network_mode.dart:4-20` — `enum NetworkMode { mainnet, testnet }`
  - **Boundary case:** network mode determines *which* API host the app calls. Cannot itself be API-driven (chicken-and-egg). **Accepted as documented exception** (see `api-authority-plan.md`). Tagged for completeness.

### Currency / language dropdowns rendered from local enum

- **V10a** — `lib/screens/buy/widgets/payment_converter.dart:83` — `Currency.values.map()`
- **V10b** — `lib/screens/sell/widgets/sell_converter.dart:201` — `Currency.values.map()`
- **V10c** — `lib/screens/settings_currencies/settings_currencies_page.dart:26` — `Currency.values.map()` (settings currency picker)
- **V13c** — `lib/screens/settings_languages/settings_languages_page.dart:24` — `Language.values.map()` (settings language picker)
  - All four are the same root cause as V12 / V13 — fix the source enum and these surfaces switch to the API list automatically. Closed together by W1.3 (currencies) / W1.4 (languages).

### Legal documents URLs hardcoded

- **V17** — `lib/packages/config/legal_documents_config.dart:69-122, :160-191, :193-236` — Registration-Agreement PDFs (DE/EN), RealUnit Prospekt URLs (`:69-122`), Aktionariat document URLs (`:160-191`), DFX-Docs URLs (`:193-236`)
  - **API change needed:** `/v1/legal-document?type=registration&language=de` returns the current URL + version; app renders without knowing URLs in advance. Same endpoint also covers the Aktionariat and DFX-Docs blocks
- **V44** — `lib/screens/kyc/steps/financial_data/constants/kyc_financial_data_links.dart:2` — hardcoded `https://dfx.swiss/terms-and-conditions`
  - **Local decision:** same root cause as V17 but outside `legal_documents_config.dart` — a separate constants file holds a legal URL
  - **API change needed:** `/v1/legal-document` endpoint (the same endpoint W4.1 introduces); app reads the URL instead of compiling it in
  - **Closed by:** W4.4 (same wave as V17)

### Company contact info hardcoded

- **V18** — `lib/screens/settings_contact/settings_contact_page.dart:82, 93-94, 104, 109, 133-134` — phone, email, website, postal address
  - **API change needed:** `/v1/company-info` (or the existing `/v1/settings`) returns this for the RealUnit branding; allows future white-labeling

### Asset configuration hardcoded

- **V29** — `lib/packages/config/api_config.dart:19-22` — RealUnit token address, chainId, decimals (mainnet + Sepolia variants)
  - **API change needed:** `/v1/asset?app=realunit` returns the canonical token configuration; the app reads + caches per network mode
- **V30** — `lib/packages/utils/default_assets.dart:3-22` — ETH/ZCHF asset IDs per network
  - **Boundary case:** the app *is* the RealUnit wallet, by definition it knows which token it manages. **Out of scope** for the current waves — listed for completeness but explicitly accepted as a boundary case (see Wave 5 rationale in `api-authority-plan.md`). Asset IDs from `/v1/asset` would be cleaner but this is the lowest-priority offender — defer until a multi-asset wallet need surfaces.

### Date / size constants

- **V31** — `lib/screens/transaction_history/transaction_history_page.dart:68-69, :82` — `firstDate: DateTime(2025)` on the start-date picker (`:68-69`) **and** the end-date picker (`:82`)
- **V32** — `lib/screens/settings_tax_report/settings_tax_report_page.dart:73` — `firstDate: DateTime(2025)` on tax-report picker
  - **API change needed:** `/v1/user/account-bounds` returns `{ firstTransactionDate, lastTransactionDate }`; both pickers use that as `firstDate`
- **V33** — `lib/screens/settings_seed/settings_seed_view.dart:98` — `if (wordCount != 12)` mnemonic length check
  - **Local concern — local crypto invariant.** BIP-39 length is structural, not a business rule. **Accepted as documented exception.** Tagged for completeness.

### Default language selection

- **V19** — `lib/packages/repository/settings_repository.dart:18-24` — `systemLang == 'de' ? 'de' : 'en'`
  - **API change needed:** API recommends a default language per user/region; until then, this is acceptable Frontend-only behavior (no user has been onboarded yet).

### Default currency selection

- **V42** — `lib/packages/repository/settings_repository.dart:28` — `_sharedPreferences.getString('currency') ?? 'CHF'`
  - **Local decision:** the fallback currency, used when the user has never picked one, is hardcoded to CHF. Same shape as V19's language fallback, just for currency
  - **API change needed:** API recommends a default currency per user/region (alongside the recommended language from W4.3); app uses it as the fallback. Same wave as V19
  - **Closed by:** W4.4 (extended) — alongside the recommended-language work

### Tax-report date transformation chosen client-side

- **V47** — `lib/screens/settings_tax_report/cubit/settings_tax_report_cubit.dart:53-64` — `_getDateWithLatestTime(selectedDate)` decides whether to ask the API for "now minus 1 minute" (today) or "end of day" (past dates)
  - **Local decision:** which exact UTC timestamp the API should evaluate the balance at, derived locally from "is the selected date today"
  - **API change needed:** `/v1/realunit/balance/pdf` accepts a date (not a timestamp) and the server picks the appropriate evaluation moment. The app sends `date` only; backend owns the time semantics. UX-only — not user-blocking
  - **Closed by:** W5.1 (extended)

### Faucet-vs-ready decision derived from raw API balances

- **V48** — `lib/screens/sell_bitbox/cubit/sell_bitbox_cubit.dart:51, :81` — `if (_paymentInfo.ethBalance >= _paymentInfo.requiredGasEth) … else _requestFaucet()` (and the same comparison in the 5s polling loop at `:81`)
  - **Local decision:** the client compares two API-supplied numbers to decide "request faucet" vs "ready". A semantic decision encoded as a numeric inequality
  - **API change needed:** `SellPaymentInfoDto` (or the sell endpoint response) exposes `needsFaucet: bool` and optionally `faucetPollingHint: int` (seconds). App renders the boolean and the hinted polling interval instead of computing them
  - **Closed by:** W5 (new sub-item)

### Support categories + labels hardcoded

- **V49** — `lib/screens/support/subpages/support_create_ticket_page.dart:85-110` (UI list of `SupportIssueType` tiles) + `lib/screens/support/cubits/support_create_ticket/support_create_ticket_cubit.dart:48-57` (non-i18n English labels in `_getTicketName`)
  - **Local decision:** which support categories this branded app exposes — a business decision baked into the page — and the human-readable label of each category, in English only, baked into the cubit
  - **API change needed:** `/v1/support/issue-types` capability endpoint returning `{ key, icon, label }[]`. App renders the list with localized labels from the API (or i18n keys keyed on `key`). Adding a new category requires no app release
  - **Closed by:** W4 (or a new endpoint slot in W4) — additive

---

## P3 — DTO/enum mirroring (acceptable boilerplate, but watch for drift)

These are not violations of the rule (DTOs *must* mirror the API for type safety),
but they're listed so reviewers know what to keep in sync when the API changes.

- **V35** — `lib/packages/service/dfx/models/kyc/kyc_level.dart` — `KycLevel`, `KycStepName`, `KycStepStatus`, `KycStepType`, `KycStepReason` enums with `fromValue` / `toValue`
- **V36** — `lib/packages/service/dfx/models/registration/registration_status.dart`
- **V37** — `lib/packages/service/dfx/models/registration/registration_email_status.dart`
- **V38** — `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:224-231` — `_mapStepName()` switch from `KycStepName` to UI `KycStep`

The `KycStepName → KycStep` map is borderline: it's a UI-routing decision (which
page to show per backend step). If `KycStepDto` carried a `uiHint: 'identPage'`
field, the app would not need this map at all. **API change suggested but not
required.**

---

## P4 — Already addressed / documented elsewhere

For completeness:

- **V39** — `lib/screens/kyc/steps/email/kyc_email_page.dart:91` — `markRegistrationSignProduced()` after merge confirmation. Local session-gate position, called from a code path where the API already signaled success. Fixed by [`DFXswiss/realunit-app#466`](https://github.com/DFXswiss/realunit-app/pull/466). **OK.**
- **V40** — `KycEmailVerificationCubit._completeRegistration` — surfaces failures correctly ([`DFXswiss/realunit-app#466`](https://github.com/DFXswiss/realunit-app/pull/466) / [`DFXswiss/api#3731`](https://github.com/DFXswiss/api/pull/3731)). Once [`DFXswiss/api#3731`](https://github.com/DFXswiss/api/pull/3731) merges and the `register/wallet` endpoint is idempotent, the client-side retry logic at the email verification page can be simplified further.

---

## Summary

Numbers below are the **canonical counts** used everywhere this audit is referenced (plan, PR body, future PRs). Recounted from this file on 2026-05-21.

| Severity | Count | V-IDs | Primary location |
|---|---|---|---|
| **P0** — blocks users today | 16 | V1–V5, V6a–V6d, V7, V8, V9, V13b, V16, V20, V45 | `kyc_cubit.dart` (7 incl. `_continueKyc`), buy/sell payment-info cubits (2), settings user-data + edit cubits (4), settings_contact (1), settings (1), sell_button (1) |
| **P1** — local interpretation, no immediate block | 12 | V11, V15, V21–V27, V34, V41, V43 | `kyc_cubit.dart` + email-verification + registration-submit cubits + bank-account field + main.dart + real_unit_registration_service + financial-data questions page |
| **P2** — hardcoded lists/config | 22 | V10a–V10c, V12, V13, V13c, V14, V17–V19, V28–V33, V42, V44, V46, V47, V48, V49 | currency/language/country, legal docs, company info, assets, date pickers, default currency, tax-report date, faucet decision, support categories, registration user types |
| **P3** — DTO mirroring (informational) | 4 | V35–V38 | service/dfx/models |
| **P4** — fixed or in-flight | 2 | V39, V40 | tracked in [`DFXswiss/realunit-app#466`](https://github.com/DFXswiss/realunit-app/pull/466) / [`DFXswiss/api#3731`](https://github.com/DFXswiss/api/pull/3731) |

**Total distinct violations across P0–P2:** 50 (16 + 12 + 22). Recounted on 2026-05-21 after a post-initial-review audit pass found 9 additional violations (V41–V49) that the initial four-stream scan had missed.
**Plus boundary cases accepted as documented exceptions:** V13b, V25, V28, V30, V33 — tagged in the audit, not counted as actionable.
**Actionable P0–P2 (excluding documented exceptions):** 45.

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

---

## Shipped (2026-05-21)

Pair-PRs landed against the rule, in dependency order:

| Wave | API PR | App PR | Closes V-IDs |
|---|---|---|---|
| Foundation | — | [realunit-app#491](https://github.com/DFXswiss/realunit-app/pull/491) | rule + audit + plan |
| W1.5 | — | [#492](https://github.com/DFXswiss/realunit-app/pull/492) | V4 — `TFA_REQUIRED` body code |
| W1.1+1.2 | — | [#493](https://github.com/DFXswiss/realunit-app/pull/493) | V7, V8 — buy/sell min from quote |
| W1.2bank | — | [#495](https://github.com/DFXswiss/realunit-app/pull/495) | V11 — bank-account default |
| W1.3+1.4 | — | [#496](https://github.com/DFXswiss/realunit-app/pull/496) | V12, V13 — currency + language from API |
| W2 | [api#3732](https://github.com/DFXswiss/api/pull/3732) | [#494](https://github.com/DFXswiss/realunit-app/pull/494) | V1, V2, V3, V5, V45 — **closes the 2026-05-21 ident-misroute** |
| W3 | [api#3733](https://github.com/DFXswiss/api/pull/3733) | [#497](https://github.com/DFXswiss/realunit-app/pull/497) | V6a, V6b, V9 + structured ALREADY_REGISTERED status |
| W4 | [api#3734](https://github.com/DFXswiss/api/pull/3734) | [#499](https://github.com/DFXswiss/realunit-app/pull/499) | V14, V17, V18 — legal-document + company-info + country.displayOrder |

PRs #491 and #492 are already merged. The remaining 9 are Draft per DFXswiss convention. Every PR has full test coverage; `flutter test` and `npm test` clean across all branches. The W2 pair specifically closes the 2026-05-21 incident report (user_data 338759 ident-misroute).

## Outstanding — next phase

Items not shipped in the 2026-05-21 batch, in priority order:

**P0 remainders:**
- V6c (settings_edit_address_cubit) — same shape as V6b; landed in W3.2 as part of the broader capability migration.
- V6d (`_changeStepNames` static set) — small follow-up to W3.2; the page already reads `capabilities` for the gating decision, the set just hangs around in the cubit for the `pendingSteps` informational badge.
- V16 (sell_button isBitbox routing) — re-evaluated: BitBox vs software-wallet is a device-local fact the API cannot substitute for. Treat as documented exception unless a future `supportedSignMethods` API field changes the picture.
- V20 (auto-register email at level<10) — the cubit still owns this branch; backend-side auto-registration would close it. Spec'd for Wave 5.

**Wave 4 follow-ups (post-merge):**
- V19 (recommended language per region) — not part of W4's initial scope; spec'd for a follow-up alongside V20.
- WebDocumentConfig hardcodes (5 entries in `legal_documents_config.dart`: EU prospectus pages, CH stock-exchange prospectus, articles of association, investment regulations) — these point at marketing-managed download pages, not versioned PDFs; documented exception.

**P1 / P2 long tail:**
- V21, V22 — local session gates whose *position* should be API-driven (separate follow-up after W4).
- V23–V27 — JWT introspection, polling/retry orchestration, transaction state interpretation. Several depend on new API fields not yet scoped.
- V29–V33 — hardcoded asset config, date constants, default language. Tracked but not blocking.
