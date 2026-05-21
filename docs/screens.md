# App Screens

Complete inventory of every screen in the RealUnit wallet app.

The source of truth for navigable screens is the `GoRouter` definition in
`lib/setup/routing/router_config.dart`; route names live in
`lib/setup/routing/routes/`. Screens shown *within* a parent route (KYC steps,
status sub-pages) are not registered as routes and are listed separately below.
Keep this file in sync when routes, screen widgets or handbook screenshots change.

The **Handbook** column gives the handbook screenshot number(s) —
`docs/handbook/screenshots/NN-*.png` — that document the screen, or `—` if it is
not in the handbook. The handbook covers the new-user onboarding journey
(sign-up → dashboard) plus the settings screens reachable from it: 19 screenshots
in total, **14 of the 40 routed screens**. See `docs/handbook/README.md`.

## Routed screens

40 `GoRoute` entries (incl. the debug-only `debugAuth`). Child routes are shown
with their full path.

### Start & onboarding

| Route name | Path | Widget | Handbook |
|---|---|---|---|
| `home` | `/home` | `HomePage` — entry point / routing gate | `01` |
| `welcome` | `/welcome` | `WelcomePage` | `02`, `03` |
| `createWallet` | `/createWallet` | `CreateWalletPage` | `04`, `05` |
| `verifySeed` | `/verifySeed` | `VerifySeedPage` | `06` |
| `restoreWallet` | `/restoreWallet` | `RestoreWalletPage` | — |
| `onboardingCompleted` | `/onboardingComplete` | `OnboardingCompletedPage` | `07` |
| `debugAuth` | `/debugAuth` | `DebugAuthPage` — **debug builds only (`kDebugMode`)** | — |

### PIN & app lock

| Route name | Path | Widget | Handbook |
|---|---|---|---|
| `pinGate` | `/pinGate` | `VerifyPinPage` — action gate (e.g. reveal seed) | `17` |
| `setupPin` | `/setupPin` | `SetupPinPage` | `08`, `09` |
| `verifyPin` | `/verifyPin` | `VerifyPinPage.appLock()` — app unlock | — |

### Main app

| Route name | Path | Widget | Handbook |
|---|---|---|---|
| `dashboard` | `/dashboard` | `DashboardPage` | `11` |
| `transactionHistory` | `/dashboard/transactionHistory` | `TransactionHistoryPage` | — |
| `buy` | `/buy` | `BuyPage` | — |
| `sell` | `/sell` | `SellPage` | — |
| `sellBitbox` | `/sellBitbox` | `SellBitboxPage` | — |
| `receive` | `/receive` | `ReceivePage` | — |
| `kyc` | `/kyc` | `KycPageManager` — orchestrates the KYC steps (see below) | — |
| `webView` | `/webView` | `WebViewPage` | — |

### Legal

| Route name | Path | Widget | Handbook |
|---|---|---|---|
| `legalDisclaimer` | `/legalDisclaimer` | `LegalDisclaimerPage` | — |
| `legalDocument` | `/legalDocument` | `LegalDocumentPage` | — |
| `terms` | `/termsOfUse` | `LegalDocumentPage` (terms of use) | — |

### Settings

| Route name | Path | Widget | Handbook |
|---|---|---|---|
| `settings` | `/settings` | `SettingsPage` | `12` |
| `settingsAktionariatDocuments` | `/settings/aktionariatDocuments` | `SettingsAktionariatDocumentsPage` | — |
| `settingsContact` | `/settings/contact` | `SettingsContactPage` | — |
| `settingsCurrencies` | `/settings/currencies` | `SettingsCurrenciesPage` | `14` |
| `settingsDfxDocuments` | `/settings/dfxDocuments` | `SettingsDfxDocumentsPage` | — |
| `settingsLanguages` | `/settings/languages` | `SettingsLanguagePage` | `13` |
| `settingsLegalDocuments` | `/settings/legalDocuments` | `SettingsLegalDocumentsPage` | — |
| `settingsNetwork` | `/settings/network` | `SettingsNetworkPage` | `15` |
| `settingsTaxReport` | `/settings/taxReport` | `SettingsTaxReportPage` | — |
| `settingsSeed` | `/settings/seed` | `SettingsSeedPage` | `18`, `19` |
| `settingsWalletAddress` | `/settings/walletAddress` | `SettingsWalletAddressPage` | `16` |
| `settingsUserData` | `/settings/userData` | `SettingsUserDataPage` | — |
| `settingsEditName` | `/settings/userData/editName` | `SettingsEditNamePage` | — |
| `settingsEditAddress` | `/settings/userData/editAddress` | `SettingsEditAddressPage` | — |
| `settingsEditPhone` | `/settings/userData/editPhoneNumber` | `SettingsEditPhoneNumberPage` | — |

### Support

| Route name | Path | Widget | Handbook |
|---|---|---|---|
| `support` | `/support` | `SupportPage` | — |
| `supportTickets` | `/support/tickets` | `SupportTicketsPage` | — |
| `supportCreateTicket` | `/support/create` | `SupportCreateTicketPage` | — |
| `supportChat` | `/support/chat/:uid` | `SupportChatPage` | — |

## Non-routed screens

Full-screen content the user sees, but driven inside a parent route rather than
registered as its own `GoRoute`. **None of these are documented in the handbook.**

### KYC flow

Orchestrated by `KycPageManager` under the `/kyc` route:

- `KycRegistrationPage` — multi-step form: `KycRegistrationPersonalStep`, `KycRegistrationAddressStep`
- `KycNationalityPage`
- `KycEmailPage` → `KycEmailVerificationPage`
- `Kyc2faPage`
- `KycIdentPage`
- `KycFinancialDataPage` → `KycFinancialDataQuestionsPage`, `KycFinancialDataLoadingPage`, `KycFinancialDataFailurePage`
- Status screens: `KycLoadingPage`, `KycPendingPage`, `KycCompletedPage`, `KycFailurePage`, `KycAccountMergePage`

### Legal disclaimer flow

Steps shown within `LegalDisclaimerPage`:

- `LegalDisclaimerStep`, `LegalDfxStep`, `LegalAktionariatStep`, `LegalDocumentsStep`

### Settings — user-data edit status

Shown during a profile-edit operation:

- `SettingsEditLoadingPage`, `SettingsEditPendingPage`, `SettingsEditFailurePage`

### Sell flow

- `SellBankAccountSelectionPage` — bank-account picker shown within the sell flow

## Notes

- **Handbook coverage.** The 19 handbook screenshots are each the output of a
  Maestro Tier-3 flow (`.maestro/handbook/NN-*.yaml`). Screenshot
  `10-biometric-prompt` documents the `EnableBiometricBottomSheet` modal — not a
  routed screen — which is why the table numbering skips from `09` to `11`.
- **`*Page` / `*View` pattern.** Several screens split into a `*Page` widget
  (provides the bloc/cubit) and a `*View` widget (builds the `Scaffold`):
  `CreateWalletView`, `RestoreWalletView`, `SettingsSeedView`, `DebugAuthView`.
  These are not separate screens — each belongs to its `*Page`.
- **Modal bottom sheets** are not routes/screens and are out of scope for this
  inventory. Examples: `EnableBiometricBottomSheet`; `ReceivePage` in
  `isBottomSheet` mode; `ConnectBitboxPage` — despite its `Page` suffix it
  builds no `Scaffold` and is shown via `showModalBottomSheet` from the welcome
  screen, KYC registration and the BitBox reconnect helper.
- `LegalDocumentPage` backs two routes (`legalDocument`, `terms`) and
  `VerifyPinPage` backs two (`pinGate`, `verifyPin`) via different constructors.
  The handbook screenshot `17` shows `VerifyPinPage` in its `pinGate` use; the
  `verifyPin` app-lock use is not separately documented.
