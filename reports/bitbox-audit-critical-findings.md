# BitBox audit — /Users/jk/DFXswiss/realunit-app

Files scanned: **428** — Quirks evaluated: **31**

## Coverage

| Bucket | Count | Quirks |
|---|---:|---|
| Static detection | 11 | `E1`, `E7`, `B1`, `B2`, `C2`, `M1`, `P2`, `A1`, `A2`, `A4`, `A3` |
| Not statically checkable, no test results provided | 20 | `E2`, `E3`, `E4`, `E5`, `E6`, `E8`, `E9`, `E10`, `B3`, `B4`, `B5`, `B6`, `B7`, `C1`, `C3`, `C4`, `M2`, `M3`, `P1`, `P3` |

_Pass `--test-results <path>` (Jest `--json --outputFile=…` or `go test -json`) to surface dynamic test coverage._

## Findings summary

| Severity | Count |
|---|---|
| critical | 118 |
| warning | 0 |
| hint | 0 |
| **total** | **118** |

## Critical findings

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:469`
- **Snippet:** `String get accountTypeHuman => '''Natürliche Person''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:471`
- **Snippet:** `String get addBankAccount => '''Bankkonto hinzufügen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:479`
- **Snippet:** `String get aktionariatPrivacyPolicy => '''Datenschutzerklärung''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:493`
- **Snippet:** `String get available => '''Verfügbar''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:519`
- **Snippet:** `String get buyExecutedDescription => '''Sobald Ihre Überweisung eingegangen ist, übertragen wir die REALU-Token in Ihre Wallet. Über den Fortschritt Ihrer Transaktion informieren wir Sie per E-Mail.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:527`
- **Snippet:** `String get buyPaymentConfirm => '''Klicken Sie hier, sobald Sie die Überweisung getätigt haben''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:529`
- **Snippet:** `String get buyPaymentConfirmFailed => '''Es gibt ein technisches Problem. Bitte versuchen Sie es später erneut. Falls der Fehler weiterhin besteht, kontaktieren Sie unseren Support.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:531`
- **Snippet:** `String get buyPaymentConfirmFailedAktionariat => '''Es gibt ein technisches Problem. Bitte überprüfen Sie Ihr E-Mail-Postfach, möglicherweise fehlt noch eine Bestätigung Ihrer Blockchain-Adresse. Andernfalls versuchen Sie es später erneut. Falls der Fehler weiterhin besteht, kontaktieren Sie unseren Support.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:535`
- **Snippet:** `String get buyPaymentInformationDescription => '''Bitte überweisen Sie den Kaufbetrag mit diesen Angaben über Ihre Bankanwendung. Der Verwendungszweck ist wichtig!''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:543`
- **Snippet:** `String get changeAddress => '''Adresse ändern''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:545`
- **Snippet:** `String get changeInReview => '''Änderung in Prüfung''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:547`
- **Snippet:** `String get changeName => '''Name ändern''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:549`
- **Snippet:** `String get changePhoneNumber => '''Telefonnummer ändern''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:551`
- **Snippet:** `String get changeSuccess => '''Änderung erfolgreich eingereicht''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:555`
- **Snippet:** `String get choosePhotoLibrary => '''Aus Galerie wählen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:559`
- **Snippet:** `String get close => '''Schließen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:565`
- **Snippet:** `String get confirm => '''Bestätigen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:567`
- **Snippet:** `String get connectBitboxCheckPairingCode => '''Überprüfen Sie, ob dieser Code mit dem auf Ihrem BitBox-Gerät angezeigten übereinstimmt, und bestätigen Sie anschließend.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:569`
- **Snippet:** `String get connectBitboxConnecting => '''Gerät gefunden. Auf Ihrer BitBox erscheint in Kürze ein Kopplungscode. Bitte lassen Sie ihn stehen – derselbe Code erscheint anschließend auch hier zum Vergleich.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:573`
- **Snippet:** `String get connectBitboxContentIos => '''Bitte verbinden Sie Ihre BitBox mit Ihrem Smartphone und aktivieren Sie zusätzlich Bluetooth.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:577`
- **Snippet:** `String get connectBitboxSignatureCapturing => '''Bitte bestätigen Sie die Anmeldeanfrage auf Ihrem BitBox-Gerät. Diese Signatur wird einmalig erfasst, damit künftige Käufe Ihre BitBox nicht erneut benötigen.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:579`
- **Snippet:** `String get connectBitboxSignatureCapturingTitle => '''Anmeldung bestätigen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:581`
- **Snippet:** `String get connectBitboxSignatureFailed => '''Ihre Anmeldesignatur konnte nicht erfasst werden. Sie können es erneut versuchen oder trotzdem fortfahren – Ihre BitBox wird dann möglicherweise für Ihren ersten Kauf erneut benötigt.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:585`
- **Snippet:** `String get connectBitboxSignInHint => '''Nach der Code-Überprüfung wird die BitBox um eine zusätzliche Bestätigung zur Anmeldung gebeten.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:591`
- **Snippet:** `String get connectedBitboxContent => '''Bitte bestätigen Sie und folgen nun den letzten Anweisungen auf Ihrer BitBox.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:605`
- **Snippet:** `String get countriesLoadFailed => '''Die Länderliste konnte nicht geladen werden. Bitte versuchen Sie es erneut.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:613`
- **Snippet:** `String get createWalletRecoveryKeyTitle => '''Wiederherstellungs-Wörter''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:615`
- **Snippet:** `String get createWalletSubtitle => '''Notieren Sie Ihre Wiederherstellungs-Wörter auf einem Blatt Papier auf und verwahren Sie dieses sicher und vertraulich. Jede Person, die im Besitz dieser 12 Wörter ist, kann auf Ihr Wallet zugreifen! Daher raten wir von einer Speicherung auf Ihrem Mobiltelefon oder Laptop dringend ab.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:627`
- **Snippet:** `String get debugWalletDescription => '''Nur für Debugging: Zum Testen mit einer bestimmten Wallet-Adresse und signierter Nachrichtenauthentifizierung.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:637`
- **Snippet:** `String get dfxPrivacyPolicy => '''Datenschutzerklärung''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:639`
- **Snippet:** `String get dfxTermsAndConditions => '''Allgemeine Geschäftsbedingungen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:655`
- **Snippet:** `String get errorBitboxBtcPsbtInvalid => '''Die BTC-Transaktion hat die Vorprüfung nicht bestanden. Bitte erneut versuchen; bei wiederholtem Auftreten kontaktieren Sie den Support.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:657`
- **Snippet:** `String get errorBitboxChannelHashMismatch => '''Der Pairing-Channel-Hash stimmt nicht überein. Bitte koppeln Sie Ihre BitBox erneut.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:659`
- **Snippet:** `String get errorBitboxInvalidInput => '''Ihre BitBox hat die Anfrage als ungültig zurückgewiesen. Bitte entfernen Sie nicht-lateinische Zeichen aus Ihrer Eingabe und versuchen Sie es erneut.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:669`
- **Snippet:** `String get errorEip1559TypeMismatch => '''Die Transaktion ist fehlerhaft formatiert (EIP-1559 Typ-Byte stimmt nicht überein). Bitte erneut versuchen; bei wiederholtem Auftreten kontaktieren Sie den Support.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:671`
- **Snippet:** `String get errorEip712SchemaDrift => '''Der Server hat ein unerwartetes Signaturschema zurückgegeben. Die Wallet hat zu Ihrer Sicherheit die Signatur verweigert. Bitte erneut versuchen; bei wiederholtem Auftreten kontaktieren Sie den Support.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:673`
- **Snippet:** `String get errorEip7702ExpectedParamsMismatch => '''Der Server hat unerwartete Delegations-Parameter zurückgegeben. Die Wallet hat zu Ihrer Sicherheit die Signatur verweigert. Bitte erneut versuchen; bei wiederholtem Auftreten kontaktieren Sie den Support.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:675`
- **Snippet:** `String get errorEip7702NotSupported => '''Ihre BitBox-Firmware unterstützt EIP-7702-Delegationen noch nicht. Bitte aktualisieren Sie die Firmware, um fortzufahren.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:677`
- **Snippet:** `String get errorSigningCancelled => '''Signatur abgebrochen — bitte BitBox erneut bestätigen.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:679`
- **Snippet:** `String get errorSignRequestInvalid => '''Die Signaturanforderung ist ungültig. Bitte korrigieren Sie Ihre Eingabe und versuchen Sie es erneut.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:681`
- **Snippet:** `String get fee => '''Gebühr''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:691`
- **Snippet:** `String get hardwareWalletSubtitle => '''Verwahren Sie Ihre RealUnit Aktientoken auf diesem separaten, physischen Gerät (einer "Hardware Wallet") aus der Schweiz.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:695`
- **Snippet:** `String get ibanInvalid => '''IBAN ist ungültig''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:699`
- **Snippet:** `String get identityCheck => '''Identitätsprüfung''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:701`
- **Snippet:** `String get identityCheckDescription => '''Klicken Sie auf Weiter, um die Identifikation vorzunehmen. Falls Sie bereits Bestandskunde sind, können Sie im nächsten Schritt Ihre bestehende E-Mail-Adresse verwenden, um eine erneute Identifizierung zu vermeiden.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:703`
- **Snippet:** `String get identityCheckFailed => '''Ein Fehler ist während der Identitätsprüfung aufgetreten. Bitte versuchen Sie es erneut.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:705`
- **Snippet:** `String get identityCheckFinallyFailed => '''Identitätsprüfung endgültig fehlgeschlagen. Bitte kontaktieren Sie unseren Support.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:707`
- **Snippet:** `String get identityCheckProcess => '''Machen Sie sich für die Identitätsprüfung bereit''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:709`
- **Snippet:** `String get identityCheckProcessDescription => '''Als nächstes müssen Sie Ihre Identität verifizieren. Bitte halten Sie Ihren Ausweis bereit und erlauben Sie den Kamerazugriff auf dem Gerät.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:711`
- **Snippet:** `String get identityCheckRequired => '''Identitätsprüfung erforderlich''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:715`
- **Snippet:** `String get kyc => '''Eröffnungsprozess''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:717`
- **Snippet:** `String get kycAccountMergeDescription => '''Ihre Identität wurde bereits in einem anderen Konto gefunden. Eine Zusammenführungsanfrage wurde erstellt. Bitte bestätigen Sie diese über die E-Mail, die Sie erhalten haben.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:719`
- **Snippet:** `String get kycAccountMergeTitle => '''Kontozusammenführung erforderlich''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:723`
- **Snippet:** `String get kycCompletedDescription => '''Danke dass Sie sich Zeit genommen haben für die Verifizierung. Sie haben nun genug Rechte um die Aktion durchzuführen.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:727`
- **Snippet:** `String kycFailureDescription(String message) => '''Es ist ein Fehler beim Laden aufgekommen: $message. Bitte versuchen Sie es zu einem späteren Zeitpunkt. Falls der Fehler weiterhin besteht, kontaktieren Sie unseren Support.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:729`
- **Snippet:** `String get kycPending => '''Daten werden geprüft''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:731`
- **Snippet:** `String kycPendingDescription(String step) => '''Ihr folgender Schritt ist gerade noch unter Prüfung: $step. Bitte haben Sie noch ein wenig Geduld und schauen Sie zu einem späteren Zeitpunkt nochmal rein.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:761`
- **Snippet:** `String get legalDisclaimerCheckboxStockExchangeProspectus => '''CH-Börsenprospekt''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:799`
- **Snippet:** `String get legalDisclaimerTitle => '''Wichtige rechtliche Hinweise für Investoren & Bestätigung des Wohnsitzes''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:825`
- **Snippet:** `String get onboardingCompletedSubtitle => '''Gratulation, Sie haben erfolgreich eine Wallet eröffnet. Sichern Sie im nächsten Schritt den Zugriff auf diese Mobile-App.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:839`
- **Snippet:** `String get paymentInformationFailedDescription => '''Bitte versuchen Sie es später erneut. Wenn der Fehler weiterhin besteht, wenden Sie sich an unseren Support.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:841`
- **Snippet:** `String get payoutAccountAdd => '''Auszahlungskonto hinzufügen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:843`
- **Snippet:** `String get payoutAccountSelect => '''Auszahlungskonto auswählen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:849`
- **Snippet:** `String get personalData => '''Persönliche Daten''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:855`
- **Snippet:** `String get pinConfirm => '''Bestätigen Sie Ihre PIN''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:857`
- **Snippet:** `String get pinConfirmDescription => '''Geben Sie Ihre PIN zur Bestätigung erneut ein''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:859`
- **Snippet:** `String get pinConfirmFailed => '''Die PINs stimmen nicht überein. Versuchen Sie es erneut.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:867`
- **Snippet:** `String get pinForgottenDescription => '''Durch diese Aktion werden Ihre Wallet und alle zugehörigen Daten gelöscht. Stellen Sie sicher, dass Sie Ihre Wiederherstellungsphrase gesichert haben.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:869`
- **Snippet:** `String get pinForgottenTitle => '''Wallet wird zurückgesetzt''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:877`
- **Snippet:** `String get pinVerifyLocked => '''Zu viele Fehlversuche. Nutzen Sie 'PIN vergessen?', um zurückzusetzen.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:883`
- **Snippet:** `String get pleaseSelect => '''Bitte auswählen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:907`
- **Snippet:** `String get realunitWalletLogoutSubtitle => '''Sie können sich abmelden, nachdem Sie bestätigt haben, dass Sie Ihre Wiederherstellungsphrase sicher gespeichert haben.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:909`
- **Snippet:** `String get realunitWalletSubtitle => '''Verwalten Sie Ihre RealUnit Token kostenfrei und bankenunabhängig.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:913`
- **Snippet:** `String get receiver => '''Empfänger''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:915`
- **Snippet:** `String get recoveryWords => '''Wiederherstellungs-Wörter''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:917`
- **Snippet:** `String get recoveryWordsInvalid => '''Wiederherstellungs-Wörter ungültig''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:923`
- **Snippet:** `String get registerCitizenship => '''Staatsangehörigkeit''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:927`
- **Snippet:** `String get registerEmailDoesNotMatch => '''Die eingegebene E-Mail stimmt nicht mit der bereits verifizierten E-Mail überein. Bitte verwenden Sie die E-Mail, mit der Sie sich ursprünglich registriert haben.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:929`
- **Snippet:** `String get registerEmailInvalid => '''E-Mail ist ungültig''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:933`
- **Snippet:** `String get registerEmailVerification => '''E-Mail Bestätigung''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:937`
- **Snippet:** `String get registerEmailVerificationBitboxSignHint => '''Bitte bestätigen Sie die Signatur auf Ihrer BitBox — die Nachricht erstreckt sich über mehrere Seiten, halten Sie den Touchsensor zum Weiterblättern.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:939`
- **Snippet:** `String get registerEmailVerificationButton => '''Ich habe meine E-Mail bestätigt''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:941`
- **Snippet:** `String get registerEmailVerificationDescription => '''Wie es aussieht, haben Sie bereits ein Konto. Wir haben Ihnen gerade eine E-Mail geschickt. Um mit Ihrem bestehenden Konto fortzufahren, bestätigen Sie bitte Ihre E-Mail-Adresse, indem Sie auf den zugesandten Link klicken.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:943`
- **Snippet:** `String get registerEmailVerificationFailed => '''Sie haben Ihre E-Mail noch nicht bestätigt.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:947`
- **Snippet:** `String get registerEmailVerificationTitle => '''Willkommen zurück!''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:958`
- **Snippet:** `String get registrationForwardingFailed => '''Registrierung angenommen, aber die Weiterleitung an die Gesellschaft ist verzögert. Wir versuchen es automatisch erneut.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:962`
- **Snippet:** `String get registrationRequiredDescription => '''Um RealUnit Token kaufen zu können, müssen Sie sich einmalig registrieren.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:964`
- **Snippet:** `String get reset => '''Zurücksetzen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:970`
- **Snippet:** `String get restoreWalletFromSeedDescription => '''Bitte geben Sie Ihre 12 Wiederherstellungs-Wörter in der korrekten Reihenfolge ein, um wieder Zugriff auf Ihre Wallet zu erhalten.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:972`
- **Snippet:** `String get restoreWalletSubtitle => '''Ich habe bereits eine Wallet (z.B. Aktionariat) und möchte dieses Wiederherstellen.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:988`
- **Snippet:** `String get selectToken => '''Token auswählen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:992`
- **Snippet:** `String get sellBitboxCheckingEth => '''Wallet-Guthaben wird geprüft''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:994`
- **Snippet:** `String get sellBitboxDepositDescription => '''Bestätigen Sie auf der BitBox, um ZCHF an die DFX-Einzahlungsadresse zu überweisen.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:998`
- **Snippet:** `String get sellBitboxDepositing => '''ZCHF wird gesendet. Bestätigen Sie auf der Bitbox''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1012`
- **Snippet:** `String get sellBitboxSwapDescription => '''Bestätigen Sie auf Ihrem BitBox, um REALU über den BrokerBot in ZCHF zu tauschen.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1016`
- **Snippet:** `String get sellBitboxSwapping => '''Tausch on-chain. Bestätigen Sie auf der Bitbox.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1022`
- **Snippet:** `String get sellBitboxWaitingForEth => '''Gasgebühren werden angefordert''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1024`
- **Snippet:** `String get sellBitboxWaitingForEthDescription => '''Ein kleiner ETH-Betrag wird an Ihr Wallet gesendet, um die Transaktionsgebühren zu decken. Dies kann einige Minuten dauern.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1030`
- **Snippet:** `String get sellReviewAndConfirm => '''Verkauf prüfen & bestätigen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1045`
- **Snippet:** `String get settingsCurrency => '''Währung''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1047`
- **Snippet:** `String get settingsCurrencyLoadFailed => '''Währungsliste konnte nicht geladen werden''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1049`
- **Snippet:** `String get settingsCurrencyLoadFailedDescription => '''Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1051`
- **Snippet:** `String get settingsDeleteWallet => '''Geschäftsbeziehung beenden''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1055`
- **Snippet:** `String get settingsLanguageLoadFailedDescription => '''Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1065`
- **Snippet:** `String get settingsWalletBackupSubtitle1 => '''Bitte notieren Sie Ihre 12 Wiederherstellungs-Wörter in der exakten Reihenfolge auf einem Blatt Papier und bewahren Sie sie absolut sicher auf.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1067`
- **Snippet:** `String get settingsWalletBackupSubtitle2 => '''Dies ist die einzige Möglichkeit, Ihre Wallet wiederherzustellen.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1073`
- **Snippet:** `String get signingCancelled => '''Signatur abgebrochen — bitte BitBox erneut bestätigen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1079`
- **Snippet:** `String get skip => '''Überspringen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1087`
- **Snippet:** `String get softwareWalletSubtitle => '''Ich möchte eine neue Wallet für den Handel und die Aufbewahrung der RealUnit Token erstellen.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1113`
- **Snippet:** `String get supportMyTicketsDescription => '''Übersicht Ihrer Support-Tickets''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1117`
- **Snippet:** `String get supportSelectType => '''Anliegen auswählen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1131`
- **Snippet:** `String get swissTaxResidenceDescription => '''Aktivieren, falls Ihr primärer Steuerwohnsitz die Schweiz ist. Erforderlich für FATCA / CRS-Meldungen.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1137`
- **Snippet:** `String get taxReportDescription => '''Hier können Sie Ihren Steuerbericht für ein spezifisches Datum generieren.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1169`
- **Snippet:** `String get twoFaDescription => '''Um weiter mit der Identitätsprüfung fortzufahren, müssen Sie sich über die 2-Faktor Authentifizierungsmethode verifizieren. Ein Code wird Ihnen per Mail zugesendet.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1185`
- **Snippet:** `String get verifySeedInvalid => '''Die Wörter stimmen nicht überein''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1187`
- **Snippet:** `String get verifySeedSubtitle => '''Bitte geben Sie die folgenden Wörter aus Ihrer Wiederherstellungsphrase ein, um zu bestätigen, dass Sie sie korrekt notiert haben.''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1189`
- **Snippet:** `String get verifySeedSuccessful => '''Seed erfolgreich überprüft''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go

### `E1` — non-ascii-eip712-string

- **File:** `lib/generated/i18n.dart:1191`
- **Snippet:** `String get verifySeedTitle => '''Sicherung überprüfen''';`
- **Reason:** non-ASCII string literal in a file that touches EIP-712 / signTyped APIs
- **Fix:** transliterate via NFKD + ASCII fallback before sending to BitBox firmware
- **Source:** Observed in production; ErrInvalidInput=101 in api/firmware/error.go
