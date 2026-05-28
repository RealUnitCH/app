# App Screens

Complete inventory of every screen in the RealUnit wallet app — one row per screen.

The source of truth for navigable screens is the `GoRouter` definition in
`lib/setup/routing/router_config.dart`; route names live in
`lib/setup/routing/routes/`. Keep this file in sync when routes, screen widgets
or handbook screenshots change.

Column meaning:

- **Route** / **Path** — the `GoRoute` name and path. `—` means the screen is
  **not a route**: it is shown inside a parent route (KYC steps, status
  sub-pages, disclaimer steps).
- **Handbook** — the handbook screenshot slot number(s) that document the
  screen, or `—` if it is not in the handbook. Each slot is a Visual-Regression
  Golden under `test/goldens/screens/`, mapped to its handbook position by
  `scripts/assemble-handbook-screenshots.sh`. The handbook covers the
  new-user onboarding journey (sign-up → dashboard) plus the settings screens
  reachable from it plus the financial-state variants of Buy/Sell/Dashboard/
  TransactionHistory and the legal/KYC step widgets: **52 slots in total**,
  spread across **20 distinct routed pages**. The table below indexes only
  the 20 anchors; the remaining 32 slots are state-variant renderings of
  those same screens (a few inline in the 01–26 range — e.g. slot 05 is
  `CreateWalletPage` with the seed revealed and slot 09 is `SetupPinPage`
  in confirm mode — plus the full 27–52 range: Buy/Sell error banners,
  KYC loading/failure, Dashboard with-balance, Legal-Disclaimer steps,
  etc.). Slot ↔ Golden mapping in
  `scripts/assemble-handbook-screenshots.sh`, slot ↔ HTML block in
  `docs/handbook/de/index.html`. See `docs/handbook/README.md`.

| Area | Widget | Route | Path | Handbook |
|---|---|---|---|---|
| Onboarding | `HomePage` | `home` | `/home` | `01` |
| Onboarding | `WelcomePage` | `welcome` | `/welcome` | `02`, `03` |
| Onboarding | `CreateWalletPage` | `createWallet` | `/createWallet` | `04`, `05` |
| Onboarding | `VerifySeedPage` | `verifySeed` | `/verifySeed` | `06` |
| Onboarding | `RestoreWalletPage` | `restoreWallet` | `/restoreWallet` | `25` |
| Onboarding | `OnboardingCompletedPage` | `onboardingCompleted` | `/onboardingComplete` | `07` |
| Onboarding | `DebugAuthPage` | `debugAuth` | `/debugAuth` | — |
| PIN & lock | `VerifyPinPage` | `pinGate` | `/pinGate` | `17` |
| PIN & lock | `SetupPinPage` | `setupPin` | `/setupPin` | `08`, `09` |
| PIN & lock | `VerifyPinPage` | `verifyPin` | `/verifyPin` | — |
| Dashboard & trading | `DashboardPage` | `dashboard` | `/dashboard` | `11` |
| Dashboard & trading | `TransactionHistoryPage` | `transactionHistory` | `/dashboard/transactionHistory` | — |
| Dashboard & trading | `BuyPage` | `buy` | `/buy` | — |
| Dashboard & trading | `SellPage` | `sell` | `/sell` | — |
| Dashboard & trading | `SellBitboxPage` | `sellBitbox` | `/sellBitbox` | — |
| Dashboard & trading | `SellBankAccountSelectionPage` | — | — | — |
| Dashboard & trading | `ReceivePage` | `receive` | `/receive` | — |
| Dashboard & trading | `WebViewPage` | `webView` | `/webView` | — |
| Legal | `LegalDisclaimerPage` | `legalDisclaimer` | `/legalDisclaimer` | — |
| Legal | `LegalDocumentPage` | `legalDocument` | `/legalDocument` | — |
| Legal | `LegalDocumentPage` | `terms` | `/termsOfUse` | `26` |
| Legal | `LegalDisclaimerStep` | — | — | — |
| Legal | `LegalDfxStep` | — | — | — |
| Legal | `LegalAktionariatStep` | — | — | — |
| Legal | `LegalDocumentsStep` | — | — | — |
| Settings | `SettingsPage` | `settings` | `/settings` | `12` |
| Settings | `SettingsAktionariatDocumentsPage` | `settingsAktionariatDocuments` | `/settings/aktionariatDocuments` | `21` |
| Settings | `SettingsContactPage` | `settingsContact` | `/settings/contact` | `23` |
| Settings | `SettingsCurrenciesPage` | `settingsCurrencies` | `/settings/currencies` | `14` |
| Settings | `SettingsDfxDocumentsPage` | `settingsDfxDocuments` | `/settings/dfxDocuments` | `22` |
| Settings | `SettingsLanguagePage` | `settingsLanguages` | `/settings/languages` | `13` |
| Settings | `SettingsLegalDocumentsPage` | `settingsLegalDocuments` | `/settings/legalDocuments` | `20` |
| Settings | `SettingsNetworkPage` | `settingsNetwork` | `/settings/network` | `15` |
| Settings | `SettingsTaxReportPage` | `settingsTaxReport` | `/settings/taxReport` | — |
| Settings | `SettingsSeedPage` | `settingsSeed` | `/settings/seed` | `18`, `19` |
| Settings | `SettingsWalletAddressPage` | `settingsWalletAddress` | `/settings/walletAddress` | `16` |
| Settings | `SettingsUserDataPage` | `settingsUserData` | `/settings/userData` | — |
| Settings | `SettingsEditNamePage` | `settingsEditName` | `/settings/userData/editName` | — |
| Settings | `SettingsEditAddressPage` | `settingsEditAddress` | `/settings/userData/editAddress` | — |
| Settings | `SettingsEditPhoneNumberPage` | `settingsEditPhone` | `/settings/userData/editPhoneNumber` | — |
| Settings | `SettingsEditLoadingPage` | — | — | — |
| Settings | `SettingsEditPendingPage` | — | — | — |
| Settings | `SettingsEditFailurePage` | — | — | — |
| Support | `SupportPage` | `support` | `/support` | — |
| Support | `SupportTicketsPage` | `supportTickets` | `/support/tickets` | — |
| Support | `SupportCreateTicketPage` | `supportCreateTicket` | `/support/create` | — |
| Support | `SupportChatPage` | `supportChat` | `/support/chat/:uid` | — |
| KYC | `KycPageManager` | `kyc` | `/kyc` | — |
| KYC | `KycRegistrationPage` | — | — | — |
| KYC | `KycRegistrationPersonalStep` | — | — | — |
| KYC | `KycRegistrationAddressStep` | — | — | — |
| KYC | `KycNationalityPage` | — | — | — |
| KYC | `KycEmailPage` | — | — | — |
| KYC | `KycEmailVerificationPage` | — | — | — |
| KYC | `Kyc2faPage` | — | — | — |
| KYC | `KycIdentPage` | — | — | — |
| KYC | `KycFinancialDataPage` | — | — | — |
| KYC | `KycFinancialDataQuestionsPage` | — | — | — |
| KYC | `KycFinancialDataLoadingPage` | — | — | — |
| KYC | `KycFinancialDataFailurePage` | — | — | — |
| KYC | `KycLoadingPage` | — | — | — |
| KYC | `KycPendingPage` | — | — | — |
| KYC | `KycCompletedPage` | — | — | — |
| KYC | `KycFailurePage` | — | — | — |
| KYC | `KycAccountMergePage` | — | — | — |

65 screens — 40 routed (`GoRoute`) + 25 non-routed.

## Notes

- **Non-routed screens** are driven inside a parent route: the KYC pages are
  orchestrated by `KycPageManager` under `/kyc`; the `*Step` widgets are steps
  inside a parent (`LegalDisclaimerStep` etc. inside `LegalDisclaimerPage`,
  `KycRegistration*Step` inside `KycRegistrationPage`); the `*Loading` /
  `*Pending` / `*Failure` pages are operation-status screens.
- **`debugAuth`** is registered only in debug builds (`kDebugMode`).
- **Shared widgets.** `LegalDocumentPage` backs two routes (`legalDocument`,
  `terms`); `VerifyPinPage` backs two (`pinGate`, `verifyPin`) via different
  constructors. Handbook screenshot `17` shows `VerifyPinPage` in its `pinGate`
  use; the `verifyPin` app-lock use is not separately documented.
- **Handbook numbering.** Each of the 52 handbook slots is a Visual-Regression
  Golden under `test/goldens/screens/`, mapped to its handbook position by
  `scripts/assemble-handbook-screenshots.sh`. A parallel Tier-3 Maestro flow
  (`.maestro/handbook/NN-*.yaml`) covers the same screen for navigation/
  tap-routing smoke but does not produce the handbook image. Slot
  `10-biometric-prompt` documents the `EnableBiometricBottomSheet` modal — not
  a routed screen — so the table has no `10`.
- **`*Page` / `*View` pattern.** Several screens split into a `*Page` widget
  (provides the bloc/cubit) and a `*View` widget (builds the `Scaffold`):
  `CreateWalletView`, `RestoreWalletView`, `SettingsSeedView`, `DebugAuthView`.
  These are not separate screens — each belongs to its `*Page`.
- **Modal bottom sheets** are not screens and are out of scope: e.g.
  `EnableBiometricBottomSheet`; `ReceivePage` in `isBottomSheet` mode;
  `ConnectBitboxPage` — despite its `Page` suffix it builds no `Scaffold` and is
  shown via `showModalBottomSheet`.
