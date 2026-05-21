# API Authority — Implementation Plan

Sequenced, pair-PR plan to enforce the *"API as Decision Authority"* rule
defined in [`CONTRIBUTING.md`](../CONTRIBUTING.md). Companion to the violation
inventory in [`api-authority-audit.md`](api-authority-audit.md).

**Source of truth:** the DFX API (`DFXswiss/api`, branch `develop`).
**Consumer:** this app (`DFXswiss/realunit-app`, branch `develop`).
**Author:** generated from a 4-stream subagent scan + 3-stream API-side gap analysis (2026-05-21). All file:line citations were verified against the cloned repos.

---

## Executive summary

All counts below are the **canonical numbers** for this PR; the audit file lists every V-ID. Numbers are derived from a single recount of `api-authority-audit.md` on 2026-05-21.

| | Count | Notes |
|---|---|---|
| Distinct violations in audit (P0–P2 bulleted) | 41 | 15 P0 + 10 P1 + 16 P2 |
| Of those, **documented exceptions** (rule does not apply) | 5 | V13b (BitBox backup), V25 (401 refresh), V28 (network mode), V30 (default assets), V33 (BIP-39) |
| **Actionable** P0–P2 (recounted from audit) | 36 | what the waves below close |
| Closed by Wave 1 (app-only, ships today) | 11 across 6 items | V4, V7, V8, V10a, V10b, V10c, V11, V12, V13, V13c, V34 |
| Closed by Wave 2 (KYC routing collapse) | 6 | V1, V2, V3, V5, V21, V22 (session-gate positions move under the API) |
| Closed by Wave 3 (capability flags) | 7 | V6a, V6b, V6c, V6d, V9, V15, V16 |
| Closed by Wave 4 (new endpoints) | 4 | V14, V17, V18, V19 |
| Closed by Wave 5 (remaining P1/P2) | 8 | V20, V23, V24, V26, V27, V29, V31, V32 |
| P3 (DTO mirroring, informational) | 4 | V35–V38, not counted as actionable |
| P4 (already addressed) | 2 | V39, V40 |

**Effort estimate:** 5 sequenced waves over ~7 sprints (14 weeks at 1 dev), or 4-5 weeks if 2 devs work in parallel (one API, one App).

**Risk envelope:** all API changes are additive (new optional fields, new optional status values, new endpoints). No breaking changes — the audit is closed by *enriching* the API, not by *changing* it. Old clients continue to work.

---

## Operating principles

These principles govern every PR generated from this plan. Violating them undoes the audit.

### 1. Pair-PR convention

For each violation that requires an API change:

- **API PR** lands first on `develop` (DFXswiss/api): adds the field/endpoint, fully tested, additive only.
- **App PR** opens within 1 week of API PR merge: consumes the new field and **deletes the corresponding local logic in the same PR**.
- The app PR title references the API PR (`Closes DFXswiss/api#NNNN`).

An API field that ships without a consuming app PR within 4 weeks is a regression — track in [`api-authority-audit.md`](api-authority-audit.md) and address in the next sprint.

### 2. Additive-only API changes

- New fields: `@ApiPropertyOptional`, `nullable: true` in TypeScript, default to safe value in mapper.
- New enum values: append to existing enums, never reorder or remove.
- New endpoints: live alongside old ones; deprecate old endpoints only in a separate later PR.
- DB migrations: see `api/CONTRIBUTING.md:16` (preferred TypeORM-generated, fallback hand-written; immutable once on develop).

### 3. Delete local logic in the same PR

When the app PR consumes a new API field, it **must** delete the local business logic it replaces. Half-migrations (both local and API logic running) are explicitly forbidden — they become permanent.

### 4. Stop adding new violations

PR reviews must check this list. Any new `if`/`switch`/`.filter()` over status / level / capability data needs justification. The lint pass on `CONTRIBUTING.md`'s test rule ("Wer entscheidet?") applies to all new code.

---

## Wave 1 — Quick wins (app-only, ships immediately)

**6 items closing 11 audit findings**, all unblocked **today** — the API already returns what's needed. The app just isn't using it. Smallest, lowest-risk wins; ship first to build confidence in the rule.

### W1.1 — Buy/Sell min-amount validation comes from quote

| | |
|---|---|
| Closes | V7, V8 |
| API change | none — `BuyQuoteDto.minVolume`, `SellQuoteDto.minVolume` already exist (verified: `api/src/subdomains/core/buy-crypto/.../buy-quote.dto.ts:29-39`, `api/src/.../sell-quote.dto.ts:29-39`) |
| App change | Remove `_minAmountChf` constants and `validateMinAmount()`; submit any amount; render error from API |
| Files touched | `lib/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart` (delete lines 16, 50-60) `lib/screens/sell/cubits/sell_payment_info/sell_payment_info_cubit.dart` (delete lines 17, 82-112) `lib/screens/sell/widgets/sell_button.dart` (drop `SellPaymentInfoMinAmountNotMet` state if dependent) |
| Acceptance | App sends amount=1 CHF → API returns 400 with `errors: [{ error: 'AMOUNT_TOO_LOW', limit: minVolume }]` → snackbar renders that error verbatim |
| Test plan | Widget test: submit amount=1, mock API 400 with `limit: 100`, assert snackbar shows "100" |
| Risk | Low — error is already structured, only the source of the limit changes |
| Effort | XS (~2h) |

### W1.2 — Bank-account default selection

| | |
|---|---|
| Closes | V11 |
| API change | none — `BankAccountDto.default: boolean` already exists (verified: `api/src/.../bank-account.dto.ts:17-22`) AND the app's own `BankAccountDto` already exposes it as `isDefault` (verified: `lib/packages/service/dfx/models/bank_account/dto/bank_account_dto.dart:6, 22`). No parsing work needed. |
| App change | `sell_bank_account_field.dart:41-44` → `state.accounts.firstWhereOrNull((a) => a.isDefault)` instead of `.lastWhereOrNull((a) => a.isActive)`. One-line change. |
| Acceptance | App auto-selects the account flagged `default: true` by the API. If multiple defaults (shouldn't happen) → first wins. If no default → no auto-selection. |
| Test plan | Unit test on the field selection logic with three account shapes (one default, no default, multiple defaults) |
| Risk | Low |
| Effort | XS (~30 min) |

### W1.3 — Currency list from `/v1/fiat`

| | |
|---|---|
| Closes | V12 (enum source) + V10a, V10b, V10c (all three `Currency.values` renderers) |
| API change | none for basic list — `GET /v1/fiat` returns `FiatDetailDto[]` with `buyable/sellable` flags (verified: `api/src/shared/models/fiat/fiat.controller.ts:10-34`) |
| App change | Delete `lib/styles/currency.dart` enum. Replace `Currency.values` calls in `payment_converter.dart:83`, `sell_converter.dart:201`, and `settings_currencies_page.dart:26` with a `FiatRepository` that caches the API response. Filter by `buyable: true` for buy converter, `sellable: true` for sell converter; full list for settings picker. |
| Acceptance | New fiats added in the backend appear in the converter without an app release |
| Test plan | Widget tests with mocked `/v1/fiat` response containing CHF, EUR, USD — verify all appear in dropdown |
| Risk | Low — fallback to local enum if `/v1/fiat` fails (degrade gracefully on first launch with no network) |
| Effort | S (~half day) |

### W1.4 — Language list from `/v1/language`

| | |
|---|---|
| Closes | V13 (enum source) + V13c (settings_languages_page renderer) |
| API change | none — `GET /v1/language` returns `LanguageDto[]` (verified: `api/src/shared/models/language/language.controller.ts:8-17`) |
| App change | Replace `lib/styles/language.dart` enum with API-driven list. `settings_languages_page.dart:24` reads from API instead of `Language.values`. |
| Acceptance | New language enabled server-side appears in app within one API refresh cycle |
| Test plan | Same pattern as W1.3 |
| Risk | Low |
| Effort | S |

### W1.5 — Render `TFA_REQUIRED` from response body, not status code

| | |
|---|---|
| Closes | V4 (clean it up — works today, but app reads status code) |
| API change | none — `TfaRequiredException` already returns `{code: 'TFA_REQUIRED', level, message}` in body (verified: `api/src/.../tfa-required.exception.ts`) |
| App change | `kyc_cubit.dart:179-182` → match on `e.code == 'TFA_REQUIRED'` only; remove the `statusCode == 403` part. Long-term the API should also expose this via a body field on the regular `GET /v2/kyc` so the exception path is unnecessary, but that's Wave 3 |
| Acceptance | App routes to 2FA step on body code, regardless of HTTP status |
| Risk | Low |
| Effort | XS |

### W1.6 — `softwareTermsAccepted` gate moves off the boot path

| | |
|---|---|
| Closes | V34 |
| API change | none — local UI state, but the gate must not block the user from reaching any *API-allowed* state |
| App change | `lib/main.dart:120` → drop the `if (!homeState.softwareTermsAccepted)` boot-time gate. Show terms as a one-time overlay on Dashboard if not accepted. App-startup is never gated by terms. |
| Acceptance | First-run user with terms unaccepted lands on Dashboard with the overlay; API-driven KYC routing fires before any local UI gate |
| Risk | Low |
| Effort | S |

**Wave 1 total effort:** ~1.5–2 dev-days. Closes 11 audit findings across 6 items with zero backend dependency.

---

## Wave 2 — KYC routing collapse (one API PR unlocks the central misroute)

This is the single highest-impact wave. **One API PR + one App PR** rewrites the core of `kyc_cubit.dart` and closes the 2026-05-21 ident-misroute that started this audit.

### W2.1 (API PR) — KYC step + level capabilities

| | |
|---|---|
| Closes | V1, V2, V3, V5 (foundation for Wave 2 app work — `currentStep` already exists; V5 needs no field, just the cubit rewrite that V1/V2/V3 enable) |
| Repo | DFXswiss/api, branch `feat/kyc-decision-fields` |
| Changes | 1. `KycStepDto` (`src/subdomains/generic/kyc/dto/output/kyc-info.dto.ts:60-63`): add `@ApiProperty() isRequired: boolean`  2. `UserKycDto` (`src/subdomains/generic/user/models/user/dto/user-v2.dto.ts:116-134`): add `@ApiProperty() canTrade: boolean` (computed: `kycLevel >= LEVEL_30 && all required steps Completed && no Outdated/InProgress on Ident/FinancialData`)  3. `KycLevelDto`: add `@ApiProperty({enum: KycProcessStatus}) processStatus: KycProcessStatus` where `KycProcessStatus = 'InProgress' \| 'PendingReview' \| 'Completed' \| 'Failed'`  4. `KycStepMapper.toStep` + `KycInfoMapper.toDto` populate the new fields |
| Acceptance | `GET /v2/kyc` response: every step has `isRequired`; top-level has `processStatus`. `GET /v2/user` response: `kyc.canTrade` is correctly computed for the level-50-with-outdated-ident edge case |
| Test plan | New tests in `kyc-info.mapper.spec.ts`: user_data 338759 fixture (level 53, ident outdated, ident-seq-1 in-progress) → `canTrade: false`, `processStatus: InProgress`. Level-50-clean fixture → `canTrade: true`, `processStatus: Completed` |
| Risk | Low (additive). Care: `canTrade` semantics must match the existing implicit rule in the *app today* exactly, otherwise the migration changes behavior for users in the wild |
| Effort | M (~1 day) |

### W2.2 (App PR) — Render `currentStep` from API, delete the cubit's business logic

| | |
|---|---|
| Closes | V1, V2, V3, V5, V21, V22, original 2026-05-21 ident-misroute report |
| Repo | DFXswiss/realunit-app, branch `refactor/kyc-cubit-api-driven` |
| Changes | Rewrite `lib/screens/kyc/cubits/kyc/kyc_cubit.dart:_runCheckKyc`. Specifically: 1. Delete `_requiredStepNames` (line 16-22) and `_minLevelForActions` (line 24)  2. Delete `actionableStatuses`, `pendingStatuses`, the iteration at lines 134-168  3. Read `processStatus` and `canTrade` from API response  4. Route purely from `currentStep`: present → render the matching page. Absent → check `processStatus` ∈ {Completed, PendingReview} → emit `KycCompleted` / `KycPending`  5. `_legalDisclaimerAccepted` / `_registrationSignProduced` stay as session security gates BUT no longer drive routing — they only let the app respond when API tells it to show the registration page  6. Drop the `requiredLevel` constructor parameter — it's dead once `canTrade` exists |
| Acceptance | Replay the 2026-05-21 reproduction: user 338759 with InProgress Ident step opens app → API returns `currentStep: ident`. App renders KycIdentPage. **No local computation needed.** Hand-test: clear the InProgress Ident in DB → API returns no currentStep + `canTrade: true` → app lands on Dashboard |
| Test plan | Cubit tests: 1) Mock API: `canTrade: true, currentStep: null, processStatus: Completed` → emit `KycCompleted`. 2) Mock API: `currentStep: {name: 'Ident', status: 'InProgress'}` → emit `KycSuccess(KycStep.ident)`. 3) Mock API: `processStatus: PendingReview, currentStep: null` → emit `KycPending`. Verify cubit code length drops by ~80% |
| Risk | Med — central routing logic. Mitigate with extensive cubit tests covering every state the API can return |
| Effort | M (~1–1.5 days including test rewrite) |

**Wave 2 total:** ~2.5 dev-days. **Closes the original incident** + structurally removes 6 audit findings (V1, V2, V3, V5, V21, V22).

---

## Wave 3 — Capability flags + structured registration response

Closes the rest of the P0/P1 KYC-adjacent items.

### W3.1 (API PR) — User capabilities + structured registration error

| | |
|---|---|
| Closes | V6a, V6b, V6c, V6d, V9, V15, V16 |
| Repo | DFXswiss/api, branch `feat/user-capabilities` |
| Changes | 1. `UserV2Dto`: add `capabilities: UserCapabilitiesDto { canEditName: bool, canEditMail: bool, canEditPhone: bool, canEditAddress: bool, supportAvailable: bool }`. Computed from KYC step states and other server-side conditions. (Closes V6a, V6b, V6c, V9.) Additionally expose a `category` on `KycStepDto` (e.g. `'changeRequest' | 'registration' | 'verification'`) so the app can filter change-flow steps without a hardcoded `_changeStepNames` set. (Closes V6d.)  2. `RealUnitRegistrationStatus` (`src/.../realunit-registration.dto.ts:26-30`): add `ALREADY_REGISTERED`. Change `realunit.service.ts:608, 670` from `throw BadRequestException` to `return RealUnitRegistrationStatus.ALREADY_REGISTERED` (different-signature path still throws — [`DFXswiss/api#3731`](https://github.com/DFXswiss/api/pull/3731) handles that nuance). (Closes V15.)  3. `SellPaymentInfoDto`: add `@ApiPropertyOptional() requiredWorkflow?: 'standard' \| 'sellBitbox' \| 'gasless'`. Compute server-side based on user wallet type + asset chain. (Closes V16.) |
| Acceptance | `GET /v2/user` includes `capabilities`. `POST /realunit/register/wallet` for already-registered same-wallet returns 201 + `ALREADY_REGISTERED` (not 400). `PUT /sell/paymentInfos` includes `requiredWorkflow` |
| Test plan | New unit tests for the mapper (`user.mapper.spec.ts`): InReview KYC user → `canEditName: false`. No-mail user → `supportAvailable: false`. Realunit service test for `ALREADY_REGISTERED` path. Sell-payment-info service: BitBox-credentials → `requiredWorkflow: 'sellBitbox'` |
| Risk | Med — `capabilities` is a new contract; missing a flag means apps stay on local logic. Be exhaustive |
| Effort | M (~1.5 days) |

### W3.2 (App PR) — Consume capabilities + ALREADY_REGISTERED + requiredWorkflow

| | |
|---|---|
| Closes | V6a, V6b, V6c, V6d, V9, V15, V16 |
| Repo | DFXswiss/realunit-app, branch `refactor/use-user-capabilities` |
| Changes | 1. `settings_user_data_page.dart:239` + `settings_edit_name_cubit.dart:22` + `settings_edit_address_cubit.dart:22`: drop status interpretation → `user.capabilities.canEditName` / `canEditAddress` (V6a/V6b/V6c)  2. `settings_user_data_cubit.dart:18-22`: delete `_changeStepNames` set → use the new step `category` flag or API capabilities to filter change-flow steps (V6d)  3. `settings_contact_page.dart:54-67`: drop email check → `user.capabilities.supportAvailable` (V9)  4. `kyc_registration_submit_cubit.dart:76, 92`: drop the "treat error as success" hack — handle `ALREADY_REGISTERED` as an explicit success status returned by the API (V15)  5. `sell_button.dart:60-62`: drop `isBitbox` local check → `state.paymentInfo.requiredWorkflow == 'sellBitbox' ? AppRoutes.sellBitbox : AppRoutes.sell` (V16) |
| Acceptance | All four spots stop interpreting status / wallet type / exception body |
| Risk | Low (App-side, mechanical) |
| Effort | M (~1 day) |

**Wave 3 total:** ~2.5 dev-days.

---

## Wave 4 — New endpoints (legal docs, company info, country priority)

The remaining P2 items that require entirely new API surface. Lower urgency — no user is blocked today by these.

### W4.1 (API PR) — `GET /v1/legal-document`

| | |
|---|---|
| Closes | V17 |
| Repo | DFXswiss/api, branch `feat/legal-document-endpoint` |
| Changes | New module `src/shared/models/legal-document/`: entity (`type, language, version, url, enabled`), repository, service, controller (`GET /v1/legal-document`, optional `?type=` and `?language=` filters), DTO. Migration creates `legal_document` table with seed data from the current `lib/packages/config/legal_documents_config.dart` hardcoded URLs. Admin endpoint to update URLs (compliance role) |
| Acceptance | `GET /v1/legal-document?type=registrationAgreement&language=de` returns the agreement PDF URL + current version |
| Risk | Low — net-new module, no existing behavior touched |
| Effort | M (~2 days, mostly seed-data + admin endpoints) |

### W4.2 (API PR) — `GET /v1/company-info`

| | |
|---|---|
| Closes | V18 |
| Repo | DFXswiss/api, same branch as W4.1 or separate |
| Changes | New module + endpoint returning company contact info for the realunit-app brand. Public (no auth). Future-proofs white-labeling |
| Effort | S (~half day) |

### W4.3 (API PR) — Country priority + recommended language

| | |
|---|---|
| Closes | V14, V19 |
| Repo | DFXswiss/api, branch `feat/country-priority-recommended-language` |
| Changes | 1. `GET /v1/country` accepts `?priorityForRegion=CH` query → returns countries sorted with Swiss-preferred ones first. Or simpler: add `displayOrder: int` to the country entity for backend-configurable priority  2. `UserV2Dto` (or new endpoint `GET /v1/language/recommended?ip=…&acceptLanguage=…`): return a recommended language code |
| Effort | S |

### W4.4 (App PR) — Consume W4.1–W4.3

| | |
|---|---|
| Closes | V14, V17, V18, V19 |
| Changes | 1. Delete `lib/packages/config/legal_documents_config.dart` hardcoded URLs → call `/v1/legal-document`. Cache locally for offline  2. Delete hardcoded contact info in `settings_contact_page.dart:82-134` → render from `/v1/company-info`. Cache  3. Delete `priorityCountries` in `country_field.dart:65-79` → use API order  4. Replace `settings_repository.dart:18-24` system-locale default with API recommendation, fallback to system locale only on first-launch-no-network |
| Effort | M (~1 day) |

**Wave 4 total:** ~3.5 dev-days.

---

## Wave 5 — Remaining P1/P2 (JWT merge, polling, transaction state, account bounds, asset config)

The tail items the first four waves don't cover. Lower urgency than Waves 1–3 but explicitly tracked so the audit can be driven to zero actionable items.

### W5.1 (API PR) — Idempotent merge-detection + transaction status label + account bounds + auto-register

| | |
|---|---|
| Closes | V20, V23, V24, V26, V27, V31, V32 |
| Repo | DFXswiss/api, branch `feat/api-authority-tail` |
| Changes | 1. `POST /v1/realunit/register/wallet` (or new `POST /v1/kyc/check-merge`): return `{ merged: bool, mergedAccountId?: string, propagated: bool }` directly. Server polls internally until propagated, so the client does not need its own generation/retry orchestration. (Closes V23, V26, V27.)  2. `Transaction` mapper: add `statusKey: string` and `statusLabel: string` so the app renders text instead of switching on `state == waitingForPayment`. (Closes V24.)  3. New `GET /v1/user/account-bounds` returning `{ firstTransactionDate, lastTransactionDate }` — both `transaction_history_page.dart:68-69` and `settings_tax_report_page.dart:73` use it for `firstDate`. (Closes V31, V32.)  4. Auto-registration of email at `level < 10` becomes server-side: `PUT /v2/kyc` performs it before returning `currentStep`. App stops doing `if (level < 10) register()`. (Closes V20.) |
| Acceptance | (1) Client calls `check-merge` exactly once → no client-side 30s timeout needed. (2) `pending_transaction_row.dart` switches on `statusKey`, not on the typed enum. (3) Pickers' `firstDate` comes from API. (4) New-user flow shows `currentStep: 'email'` without the app pre-calling register. |
| Risk | Med — V20 in particular changes when the email registration POST fires; needs careful regression testing. |
| Effort | M (~2 days) |

### W5.2 (API PR) — Asset configuration endpoint

| | |
|---|---|
| Closes | V29 |
| Repo | DFXswiss/api, branch `feat/realunit-asset-config` |
| Changes | `GET /v1/asset?app=realunit` returns the canonical RealUnit token configuration (address, chainId, decimals, mainnet + Sepolia). App reads this on boot and caches per network mode. Replaces hardcoded `ApiConfig` constants. |
| Acceptance | App calls `/v1/asset?app=realunit` after `NetworkMode` is resolved (the boot-time API host is still local), and uses the returned config for chainId/address/decimals. |
| Risk | Low (read-only endpoint, additive) |
| Effort | S (~half day) |

### W5.3 (App PR) — Consume W5.1 + W5.2

| | |
|---|---|
| Closes | V20, V23, V24, V26, V27, V29, V31, V32 |
| Repo | DFXswiss/realunit-app, branch `refactor/api-authority-tail` |
| Changes | Apply the per-item changes from W5.1 + W5.2 in the app: delete `_runGeneration` (kyc_cubit.dart:42-69), `_mergeDetected` orchestration (kyc_email_verification_cubit.dart:24-37), JWT-decode merge detection (kyc_email_verification_cubit.dart:49-63), the `level < 10 → register` branch (kyc_cubit.dart:88-104), the pending-row state switch (pending_transaction_row.dart:49-51), the picker `firstDate` constants (transaction_history_page.dart:68-69, settings_tax_report_page.dart:73), and the hardcoded `ApiConfig` token block (api_config.dart:19-22). |
| Risk | Med — JWT decode and polling are critical paths; cover with cubit tests before merge. |
| Effort | M (~1.5 days) |

### Out of scope — explicitly accepted boundary cases

These items appear in the audit but are **not** closed by any wave. Future PRs should not try to "fix" them.

| Item | V-ID | Why out of scope |
|---|---|---|
| `lib/packages/utils/default_assets.dart:3-22` (ETH/ZCHF asset IDs) | V30 | The app **is** the RealUnit wallet; the default asset list is part of the product identity, not a backend decision. Revisit only if a multi-asset use case emerges. |
| `lib/packages/config/network_mode.dart` (`mainnet` / `testnet`) | V28 | Determines *which* API host the app talks to — cannot itself be API-driven (chicken-and-egg). |
| BIP-39 12-word check (`settings_seed_view.dart:98`) | V33 | Structural crypto invariant. |
| `WalletType == software` for backup visibility (`settings_page.dart:100`) | V13b | Device-capability fact; BitBox cannot expose its seed. |
| `401 → token refresh` (`dfx_auth_service.dart:233-239`) | V25 | HTTP-standard convention; the 401 contract is contractual. |

**Wave 5 total:** ~4 dev-days.

---

## Documented exceptions — the rule explicitly does not apply

These are listed in the audit ([`api-authority-audit.md`](api-authority-audit.md) P3/P4) and documented here as accepted exceptions. Future maintainers should not "fix" these into the audit again.

| Exception | Reason |
|---|---|
| `NetworkMode { mainnet, testnet }` (`api_config.dart`) | Chicken-and-egg: the network mode determines *which* API the app calls. Cannot itself come from the API |
| BIP-39 seed = 12 words (`settings_seed_view.dart:98`) | Structural crypto invariant, not a business rule |
| `WalletType == software` check for backup visibility | Physical reality: a BitBox cannot expose its seed; this is a device-capability fact, not a backend policy |
| `401 → token refresh` (`dfx_auth_service.dart:233-239`) | HTTP-standard convention; the 401 contract is well-defined and external |
| PIN validation, wallet lock, BitBox connection state | Local security boundary; API has no view of device-side security state |
| EIP-712 signing, hashing, key derivation | Must run locally on the user's device |
| DTO mirroring (`KycLevel`, `KycStepName`, etc. enums) | Type safety; values must stay in sync but mirroring is acceptable boilerplate |

---

## Sequencing & dependencies

```
Wave 1  (app-only, no API dep)                ── ship first, validates mechanics
Wave 2  W2.1 API  ──►  W2.2 App               ─┐
Wave 3  W3.1 API  ──►  W3.2 App               ─┤  Waves 2/3/4/5 independent
Wave 4  W4.1–W4.3 API  ──►  W4.4 App          ─┤  of each other —
Wave 5  W5.1 + W5.2 API  ──►  W5.3 App        ─┘  ship in parallel if 2 devs
```

- Wave 1 has no API dependency; ship it first to validate the pair-PR mechanics on something low-risk.
- Within each later wave, the API PR strictly blocks the App PR (`──►` arrow).
- Waves 2, 3, 4, 5 are **independent of each other** — they touch disjoint API surface and disjoint app surface, so any two devs can pick two waves and run them concurrently after Wave 1 lands.

**Aggressive timeline (2 devs, parallel):** ~2.5 weeks calendar.
**Conservative timeline (1 dev, sequential):** ~7 sprints / 14 weeks calendar.

---

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| API field added but never consumed (audit regresses) | Med | High | Pair-PR convention enforced in PR review checklist |
| `canTrade` semantics drift from current implicit rule | Med | High | Fixture-based mapper tests covering edge cases (level 53 + outdated ident) BEFORE Wave 2.2 ships |
| Old app version + new API: missing field crashes | Low | Med | All API additions are optional / nullable; app handles `null` gracefully |
| Compliance objection to `canTrade` based on level only | Low | High | `canTrade` is computed server-side from the *same* signals the app uses today (level + step state) — semantic identity, not relaxation. Loop in compliance before W2.1 merge |
| Legal-document migration data error | Med | Low | Seed script runs in a dry-run + diff-review mode first; admin endpoint allows hotfix |

---

## Forward contract

Once this plan is executed:

- New PRs that introduce a violation pattern (local `_requiredX`, status enum interpretation, hardcoded business limit) are **blocked** by review until the API field exists.
- The CONTRIBUTING.md rule is enforceable: every Reviewer can point at this plan and ask *"which wave does your change belong to?"* If the answer is "none — I added a new local decision", the PR doesn't merge.
- Audit ([`api-authority-audit.md`](api-authority-audit.md)) becomes a regression test: ideally only shrinks PR by PR.

---

## What to do next (concrete first action)

1. **Now:** review this plan + the audit doc. Decide if any item is mis-prioritized.
2. **Day 1:** open W1.1 + W1.2 + W1.5 as small App-only PRs. They're the lowest-risk validation that the pair-PR mechanics work.
3. **Day 2:** open W2.1 (API) as the first paired wave. Loop in compliance on the `canTrade` semantics before merge.
4. **Day 3-4:** open W2.2 (App) once W2.1 is on `develop`.
5. **Day 5+:** schedule Wave 3, Wave 4, and Wave 5 in the regular sprint planning. Waves 2–5 are independent and can run concurrently if staffed.

---

*Generated 2026-05-21. Companion to [`api-authority-audit.md`](api-authority-audit.md) and the rule definition in [`CONTRIBUTING.md`](../CONTRIBUTING.md#api-as-decision-authority--critical).*
