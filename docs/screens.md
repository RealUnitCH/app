# App Screens

Complete inventory of every screen in the RealUnit wallet app.

The source of truth for navigable screens is the `GoRouter` definition in
`lib/setup/routing/router_config.dart`; route names live in
`lib/setup/routing/routes/`. Screens shown *within* a parent route (KYC steps,
status sub-pages) are not registered as routes and are listed separately below.
Keep this file in sync when routes or screen widgets change.

## Routed screens

40 `GoRoute` entries (incl. the debug-only `debugAuth`). Child routes are shown
with their full path.

### Start & onboarding

| Route name | Path | Widget |
|---|---|---|
| `home` | `/home` | `HomePage` — entry point / routing gate |
| `welcome` | `/welcome` | `WelcomePage` |
| `createWallet` | `/createWallet` | `CreateWalletPage` |
| `verifySeed` | `/verifySeed` | `VerifySeedPage` |
| `restoreWallet` | `/restoreWallet` | `RestoreWalletPage` |
| `onboardingCompleted` | `/onboardingComplete` | `OnboardingCompletedPage` |
| `debugAuth` | `/debugAuth` | `DebugAuthPage` — **debug builds only (`kDebugMode`)** |

### PIN & app lock

| Route name | Path | Widget |
|---|---|---|
| `pinGate` | `/pinGate` | `VerifyPinPage` — action gate (e.g. reveal seed) |
| `setupPin` | `/setupPin` | `SetupPinPage` |
| `verifyPin` | `/verifyPin` | `VerifyPinPage.appLock()` — app unlock |

### Main app

| Route name | Path | Widget |
|---|---|---|
| `dashboard` | `/dashboard` | `DashboardPage` |
| `transactionHistory` | `/dashboard/transactionHistory` | `TransactionHistoryPage` |
| `buy` | `/buy` | `BuyPage` |
| `sell` | `/sell` | `SellPage` |
| `sellBitbox` | `/sellBitbox` | `SellBitboxPage` |
| `receive` | `/receive` | `ReceivePage` |
| `kyc` | `/kyc` | `KycPageManager` — orchestrates the KYC steps (see below) |
| `webView` | `/webView` | `WebViewPage` |

### Legal

| Route name | Path | Widget |
|---|---|---|
| `legalDisclaimer` | `/legalDisclaimer` | `LegalDisclaimerPage` |
| `legalDocument` | `/legalDocument` | `LegalDocumentPage` |
| `terms` | `/termsOfUse` | `LegalDocumentPage` (terms of use) |

### Settings

| Route name | Path | Widget |
|---|---|---|
| `settings` | `/settings` | `SettingsPage` |
| `settingsAktionariatDocuments` | `/settings/aktionariatDocuments` | `SettingsAktionariatDocumentsPage` |
| `settingsContact` | `/settings/contact` | `SettingsContactPage` |
| `settingsCurrencies` | `/settings/currencies` | `SettingsCurrenciesPage` |
| `settingsDfxDocuments` | `/settings/dfxDocuments` | `SettingsDfxDocumentsPage` |
| `settingsLanguages` | `/settings/languages` | `SettingsLanguagePage` |
| `settingsLegalDocuments` | `/settings/legalDocuments` | `SettingsLegalDocumentsPage` |
| `settingsNetwork` | `/settings/network` | `SettingsNetworkPage` |
| `settingsTaxReport` | `/settings/taxReport` | `SettingsTaxReportPage` |
| `settingsSeed` | `/settings/seed` | `SettingsSeedPage` |
| `settingsWalletAddress` | `/settings/walletAddress` | `SettingsWalletAddressPage` |
| `settingsUserData` | `/settings/userData` | `SettingsUserDataPage` |
| `settingsEditName` | `/settings/userData/editName` | `SettingsEditNamePage` |
| `settingsEditAddress` | `/settings/userData/editAddress` | `SettingsEditAddressPage` |
| `settingsEditPhone` | `/settings/userData/editPhoneNumber` | `SettingsEditPhoneNumberPage` |

### Support

| Route name | Path | Widget |
|---|---|---|
| `support` | `/support` | `SupportPage` |
| `supportTickets` | `/support/tickets` | `SupportTicketsPage` |
| `supportCreateTicket` | `/support/create` | `SupportCreateTicketPage` |
| `supportChat` | `/support/chat/:uid` | `SupportChatPage` |

## Non-routed screens

Full-screen content the user sees, but driven inside a parent route rather than
registered as its own `GoRoute`.

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
