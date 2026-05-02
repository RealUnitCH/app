# RealUnit Mobile Wallet — Follow-Up Code Review

**Datum:** 2026-05-02
**Repository:** `DFXswiss/realunit-app` (public)
**Branch / Commit:** `develop` @ `8e87709`
**Bezug:** Audit Report Codinglab CDL-0X1750 vom 2026-04-07 (Marco Ricca)
**Methodik:** Statische Source-Analyse, kein Runtime-Test, kein MitM, kein Dependency-CVE-Scan

> Diese Datei ist ein interner Follow-Up zu dem externen Audit. Sie verifiziert die ursprünglichen fünf Findings am aktuellen Code und ergänzt eigene Funde, die ausserhalb des deklarierten Audit-Scope liegen.

---

## 0. Executive Summary

Die fünf Findings aus dem Codinglab-Audit sind **am Code sichtbar adressiert**: Mnemonic-Encryption-Layer, Step-up-PIN vor Seed-Anzeige, FLAG_SECURE, Random-Salt + Lockout, QR-Scanner entfernt, Alchemy-Keys raus.

Bei tieferer Prüfung bleiben jedoch **substantielle Schwächen**, die das gleiche oder ein höheres Risikoniveau erreichen wie die ursprünglich gemeldeten:

- Der gesamte **App-Lock und PIN-Lockout-Mechanismus läuft über SharedPreferences** — auf rootbarem Device durch einfaches Editieren einer XML-Datei umgehbar.
- **PBKDF2 mit 10 000 Iterationen** macht den PIN-Verifier bei Extraktion in Sekunden brute-forcebar.
- **Step-up-PIN-Auth (Seed-Reveal) hat kein Lockout** — `enableLockout` ist `false`.
- **Release-Build wird nicht obfuskiert** — `minifyEnabled` und `shrinkResources` fehlen, ProGuard-Rules sind faktisch wirkungslos.
- **Biometric ist nur ein `bool`-Flag**, nicht an einen Keystore-CryptoObject gebunden — ein Bypass der Biometric-API gibt freien App-Zugriff.
- **Mnemonic-Encryption-Key hat keine User-Auth-Bindung** — er wird automatisch beim App-Start verfügbar; der neue Encryption-Layer schützt damit fast ausschliesslich gegen das gleiche Bedrohungsszenario, das schon der bestehende SQLCipher-Schutz adressierte.
- **Mnemonic bleibt während der gesamten Session als plain-`String` im RAM** (`SoftwareWallet.seed`).

Daneben mehrere kleinere Funde: Lock-Timeout 5 min, kein Cert-Pinning, kein Root/Tamper-Detection, latenter Logik-Bug in `WalletAccount.signMessage`, `ascii.encode` statt `utf8.encode`, ungehärteter WebView, web3dart-Fork ohne unabhängige Prüfung.

**Gesamteinschätzung:** Die App ist nach dem Audit-Fix-Round sicherer als vorher, aber **nicht hinreichend gehärtet für ein Self-Custody-Wallet, das echte Werte verwahrt**. Der externe Auditor hat das Threat-Modell „rooted device / forensic extraction / temporary physical access" mehrfach selbst genannt — gegen genau dieses Modell sind die Fixes unzureichend.

---

## 1. Verifikation der Original-Findings

### 4.1 Mnemonic plaintext in DB — TEILWEISE BEHOBEN

**Status:** Hauptpunkt adressiert, aber unter dem vom Auditor empfohlenen Niveau.

**Geändert:**
- `WalletRepository._encryptSeed` / `_decryptSeed` (`lib/packages/repository/wallet_repository.dart:13,31,35`) verschlüsselt den Seed mit AES-GCM (32-Byte Random-Key, separater 12-Byte-IV pro Schreibvorgang).
- Der Encryption-Key liegt in FlutterSecureStorage (`secure_storage.dart:75-81`, Key `wallet.mnemonic.encryption.key`).

**Nicht adressiert (vom Auditor explizit empfohlen):**
- Encryption-Key ohne `setUserAuthenticationRequired(true)` — Android-Keystore non-exportable + biometric-gated wird nicht genutzt.
- `SoftwareWallet.seed: String` (`wallet.dart:28`) hält die volle BIP39-Phrase während der gesamten App-Session im Prozess-Memory.
- Der neue Layer schützt vor demselben Bedrohungsszenario, das SQLCipher schon adressiert hat (rohe DB-Datei-Extraktion ohne Schlüssel). Gegen einen Angreifer mit App-Sandbox-Zugriff (root, run-as) ist der Schutz minimal, weil sowohl Schlüssel als auch Ciphertext im selben Trust-Anchor (FlutterSecureStorage) liegen.

---

### 4.2 Seed-Display Step-up + Screenshot-Hardening — BEHOBEN

**Geändert:**
- Step-up-PIN: `lib/screens/settings/settings_page.dart:104-110` ruft `PinRoutes.gate` mit `VerifyPinParams.onAuthenticated` vor `SettingsRoutes.seed`.
- FLAG_SECURE: `NoScreenshot.instance.screenshotOff()` in `lib/screens/settings_seed/settings_seed_view.dart:21` (initState) und `lib/screens/create_wallet/create_wallet_view.dart:23`.

**Restpunkt:**
- Kein Auto-Hide-Timer. Nach Reveal kann der User den Seed beliebig lange anzeigen lassen (`SettingsSeedCubit.toggleShowSeed()`). Auditor empfahl „limit how long it stays visible".

---

### 4.3 PIN Random Salt + Throttling — TEILWEISE BEHOBEN

**Geändert:**
- Random Salt 16 Bytes pro Installation: `secure_storage.dart:36-39` (`generatePinSalt`).
- Throttling-Stufen: `verify_pin_cubit.dart:100-107` — 5/6/7/8 Fehlversuche → 1/2/5/10 min, ab 9 permanent (`pin_constants.dart:3`).

**Nicht adressiert (siehe NEW-1, NEW-2, NEW-3):**
- Lockout-State liegt in SharedPreferences statt SecureStorage.
- Step-up-Auth (Seed-Reveal) hat `enableLockout: false`.
- PBKDF2-Iterationen mit 10 000 deutlich unter aktuellen Empfehlungen.

---

### 4.4 QR-Scanner Payload-Logging — BEHOBEN (durch Code-Entfernung)

**Geändert:**
- `lib/widgets/qr_scanner.dart` entfernt (Commit `b8a9a60`, „Remove dead code and unused files").
- Keine `mobile_scanner` / `qr_code_scanner` Dependency mehr in `pubspec.yaml`.

**Anmerkung:**
- Funktional ist QR-Scan damit ganz aus der App raus — Restore- und Empfangs-Flows nutzen kein Scannen mehr. Das ist ein bewusster Funktions-Tradeoff, kein Security-Fix im engeren Sinn. Wenn die Funktion zurückkommt, muss das Logging-Verhalten erneut geprüft werden.
- `lib/packages/utils/fuck_firebase.dart` ist als Workaround-Datei zur MLKit-Telemetrie noch vorhanden — siehe NEW-15.

---

### 4.5 Hardcoded Alchemy Endpoints/Keys — BEHOBEN

**Geändert:**
- `lib/packages/utils/default_nodes.dart` existiert nicht mehr.
- `lib/packages/service/app_store.dart` ist clean — keine Endpoint/Key-Konstanten.
- Backend ist ausschliesslich `api.dfx.swiss` / `dev.api.dfx.swiss` (`lib/packages/config/api_config.dart:13-17`), aufgebaut über `buildUri()` mit HTTPS.

**Anmerkung:**
- Das ist eine bewusste Verlagerung des Trust-Anchors auf das DFX-Backend — der Wallet ist für Chain-Daten (Balance, Tx-History, Preise) jetzt vollständig vom DFX-API abhängig. Privacy-Tradeoff, aber Signing bleibt lokal.

---

## 2. Neue Findings (über den ursprünglichen Audit-Scope hinaus)

### NEW-1 — App-Lock und PIN-Lockout via SharedPreferences umgehbar

**Severity:** Critical
**Pfade:**
- `lib/packages/repository/settings_repository.dart:46-79`
- `lib/screens/pin/bloc/auth/pin_auth_cubit.dart:22-30`
- `lib/main.dart:116-122`

**Beobachtung:**
Drei sicherheitsrelevante Flags liegen in `shared_prefs.xml` (Klartext-XML im App-Datadir):
- `isPinEnabled`
- `pinFailedAttempts`
- `pinLockedUntil`

Auf einem rootbaren Gerät (oder bei forensischer Extraktion) kann ein Angreifer diese Datei direkt editieren:

1. **Lockout zurücksetzen:** `pinFailedAttempts=0`, `pinLockedUntil` löschen → unbegrenztes PIN-Brute-Force trotz konfigurierter Throttling-Stufen.
2. **App-Lock umgehen via PIN-Reset:** `isPinEnabled=false` setzen. `PinAuthCubit.initialize()` (`pin_auth_cubit.dart:23-29`) macht daraus `isPinSetup: false`. `main.dart:116-117` routet die App auf `PinRoutes.setup`. Der Angreifer wählt einen neuen PIN — `SetupPinCubit._confirmPin` (`setup_pin_cubit.dart:64-72`) schreibt frischen Salt+Hash in SecureStorage und überschreibt damit den ursprünglichen PIN-Hash. Anschliessend offenes Dashboard. Wegen NEW-4 ist der Mnemonic-Encryption-Key auch ohne den ursprünglichen PIN dekryptierbar — `WalletRepository._decryptSeed` liefert die Phrase im Klartext. Settings → Show Seed → Step-up mit dem neu gesetzten PIN (NEW-3 ohne Lockout) → Mnemonic-Exfiltration. Nebeneffekt: Der legitime User kann sich nach dem Angriff nicht mehr einloggen (Denial-of-Service durch Hash-Überschreibung).

**Empfehlung:**
- Migration aller drei Werte in FlutterSecureStorage (Android Keystore-backed).
- Zusätzlich: App-Lock-Status nicht aus einem booleschen Settings-Flag ableiten, sondern aus der Existenz von `pinHash` + `pinSalt` in SecureStorage.

---

### NEW-2 — PBKDF2 mit nur 10 000 Iterationen

**Severity:** High
**Pfad:** `lib/packages/storage/secure_storage.dart:42-46`

**Beobachtung:**
```dart
final params = Pbkdf2Parameters(salt, 10000, 32);
```
Bei einem 6-stelligen PIN existieren 10⁶ Kombinationen. Moderne GPUs schaffen mehr als 10⁹ PBKDF2-HMAC-SHA256/Sekunde — bei extrahiertem Verifier ist der PIN damit sub-Sekunde brute-forcebar.

**Empfehlung:**
- Iterationen auf 600 000+ erhöhen (entspricht aktuellen NIST-Empfehlungen).
- Oder migrieren auf Argon2id (Memory-Hard, GPU-resistent). Erfordert ein zusätzliches Dart-Package.
- Migration der bestehenden Hashes: beim nächsten erfolgreichen PIN-Login transparent mit neuen Parametern rehashen.

---

### NEW-3 — Step-up PIN-Verify ohne Lockout

**Severity:** High
**Pfade:**
- `lib/screens/pin/verify_pin_page.dart:38` (Default `enableLockout = false`)
- `lib/screens/settings/settings_page.dart:104-110` (Aufruf des Step-up ohne Override)

**Beobachtung:**
`VerifyPinPage.appLock()` setzt `enableLockout: true`. Alle anderen Aufrufer (insbesondere der Step-up vor Seed-Reveal) nutzen den Default `false`. In `verify_pin_cubit.dart:45-48` wird bei `!enableLockout` immer `VerifyPinFailure(failedAttempts: 0)` emittiert — keine Counter-Erhöhung, kein Lockout.

Konsequenz: Wer App-Lock geknackt oder umgangen hat (z.B. via NEW-1), kann den Step-up-PIN unbegrenzt erraten und damit den Seed exfiltrieren.

**Empfehlung:** `enableLockout: true` für alle Aufrufer, oder Lockout im Cubit immer aktiv (gemeinsamer Counter mit App-Lock).

---

### NEW-4 — Mnemonic-Encryption-Key ohne User-Auth-Gate

**Severity:** High
**Pfade:**
- `lib/packages/storage/secure_storage.dart:75-81` (`getOrCreateMnemonicKey`)
- `lib/packages/repository/wallet_repository.dart:30-38`

**Beobachtung:**
Der AES-GCM-Encryption-Key für den Seed liegt in FlutterSecureStorage und ist beim App-Start ohne User-Interaktion lesbar. Der Auditor (4.1) hat explizit Android-Keystore mit non-exportable Keys und Use-Restrictions empfohlen — diese Empfehlung ist nicht umgesetzt.

Effektiv liegt damit der Trust-Anchor des neuen Encryption-Layers identisch zum bestehenden SQLCipher-Layer (Schlüssel in FlutterSecureStorage). Der Schutzgewinn gegenüber „nur SQLCipher" ist gering.

**Empfehlung:**
- Native Plattform-Code: AES-Key im Android Keystore generieren mit `setUserAuthenticationRequired(true)` und `setInvalidatedByBiometricEnrollment(true)`.
- Beim Seed-Decrypt einen `BiometricPrompt.CryptoObject` mit dem Keystore-Cipher binden.
- Plugin-Optionen: `biometric_storage` oder eigenes MethodChannel.

---

### NEW-5 — Biometric ohne CryptoObject-Bindung

**Severity:** High
**Pfad:** `lib/packages/service/biometric_service.dart:26-37`

**Beobachtung:**
```dart
return await _auth.authenticate(
  localizedReason: 'Authenticate to unlock your wallet',
  biometricOnly: true,
  persistAcrossBackgrounding: true,
);
```
`local_auth` gibt nur einen `bool` zurück — die Biometric-Authentifizierung ist ein UI-Gate, kein kryptographisches Gate. Ein Bypass der Biometric-API (z.B. via Frida-Hook auf `BiometricPrompt.AuthenticationCallback.onAuthenticationSucceeded`) gibt freien App-Zugriff.

**Empfehlung:** Biometric an einen Keystore-`CryptoObject` binden (siehe NEW-4) — der Cipher entsperrt den Mnemonic-Key, statt nur einen Bool an die App zurückzugeben.

---

### NEW-6 — Release-Build nicht obfuskiert

**Severity:** High
**Pfad:** `android/app/build.gradle` Block `buildTypes.release`

**Beobachtung:**
```groovy
release {
    signingConfig signingConfigs.release
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
}
```
Es fehlen `minifyEnabled true` und `shrinkResources true`. Ohne `minifyEnabled` werden ProGuard/R8-Rules zwar registriert, aber **nicht ausgeführt**. Konsequenz: Release-APK enthält Klartext-Klassennamen, Methodennamen, Strings — Reverse-Engineering mit `jadx` in Sekunden möglich.

**Empfehlung:**
```groovy
release {
    minifyEnabled true
    shrinkResources true
    signingConfig signingConfigs.release
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
}
```
Anschliessend sorgfältig testen — Flutter-Plugins reagieren teils auf R8 (Reflection). Die bestehende `proguard-rules.pro` deckt `flutter_secure_storage`, Tink, AndroidX Crypto und Sumsub bereits ab.

---

### NEW-7 — Lock-Timeout 5 Minuten

**Severity:** Medium
**Pfad:** `lib/screens/pin/constants/pin_constants.dart:1`

**Beobachtung:** `lockoutDuration = Duration(minutes: 5)`. Nach Backgrounding bleibt die App fünf Minuten lang ohne Reauth nutzbar. Banking-Apps bewegen sich typischerweise im Bereich 30–60 Sekunden.

**Empfehlung:** Auf 30–60 Sekunden reduzieren. Optional konfigurierbar in den App-Settings.

---

### NEW-8 — Kein TLS Certificate Pinning

**Severity:** Medium
**Pfad:** `lib/packages/service/app_store.dart:9` (`final httpClient = Client();`)

**Beobachtung:**
API-Calls zu `api.dfx.swiss` / `dev.api.dfx.swiss` laufen über den Default-`http.Client()` ohne Pinning. Mit einem im OS-Trust-Store installierten User-CA (Schul-Devices, Corporate-MDM, Forensik) ist eine MitM-Inspektion möglich. Für Wallet-Daten primär ein Privacy-Issue (Balance, Tx-History, KYC-Daten); wenn Token-/Asset-Metadaten manipulierbar sind, kann das auch UI-Spoofing ermöglichen.

**Empfehlung:**
- Cert-Pinning gegen die DFX-API einführen (z.B. `http_certificate_pinning` oder `dio` mit Pinning-Interceptor).
- Pin-Set mit Current + Backup-Pin.
- Kontrollierter Cert-Rotation-Prozess mit App-Release-Koordination notwendig — sonst Risiko eines App-Tot-Releases.

---

### NEW-9 — Kein Root/Tamper-Detection

**Severity:** Medium
**Pfad:** Repository-weit (kein entsprechendes Plugin in `pubspec.yaml`).

**Beobachtung:**
- Keine Detection für Root, Magisk, Frida, Xposed.
- Keine SafetyNet/Play-Integrity-Attestation.
- Keine Anti-Debug-Massnahmen.

Für ein Wallet, das Self-Custody-Werte hält, ist das im 2026er-Threat-Modell ein Standardpunkt. Tradeoff: False Positives auf Custom-ROMs / MagiskHide-Setups können legitime User aussperren.

**Empfehlung:**
- Plugin: `freerasp` (umfasst Root/Frida/Hook-Detection, Anti-Debug, Repackaging-Detection).
- Soft-Warn-Banner statt Hard-Block beim ersten Schritt — User wird informiert, kann fortfahren.
- Telemetrie zur Detection-Häufigkeit, bevor Hard-Block-Eskalation entschieden wird.

---

### NEW-10 — Mnemonic permanent im Prozess-Memory

**Severity:** Medium
**Pfad:** `lib/packages/wallet/wallet.dart:28` (`final String seed`)

**Beobachtung:**
`SoftwareWallet` hält die BIP39-Mnemonic während der gesamten App-Session als Dart-`String`. Dart-Strings sind unveränderlich und können nicht zuverlässig aus dem RAM gewipt werden. Bei Memory-Dump (Frida, gdb auf rooted Device, Crash-Dump-Übermittlung) ist die Phrase entnehmbar.

**Empfehlung:**
- Mnemonic nicht persistent im Wallet-Objekt halten — nur on-demand laden, signieren, sofort wieder freigeben.
- Tieferer Refactor: BIP32-Derivate vorberechnen und nur die für Signing benötigten Teile im Memory halten, Master-Mnemonic nur kurzlebig.

---

### NEW-11 — Latenter Logik-Bug in `WalletAccount.signMessage`

**Severity:** Low (latent)
**Pfad:** `lib/packages/wallet/wallet_account.dart:31-32`

**Beobachtung:**
```dart
Future<String> signMessage(String message, {int addressIndex = 0}) async =>
    '0x${hex.encode(_getPrivateKeyAt(root, addressIndex, addressIndex)
      .signPersonalMessageToUint8List(ascii.encode(message)))}';
```
Es wird `_getPrivateKeyAt(root, addressIndex, addressIndex)` aufgerufen — der erste Parameter sollte aber `accountIndex` (Member der Klasse) sein, nicht `addressIndex`. Der BIP44-Path wird dadurch beim Signieren falsch konstruiert, sobald `accountIndex != 0` oder `addressIndex != 0` ist.

Aktuell unkritisch, weil der Code-Pfad nur mit Default-Argumenten und Account 0 aufgerufen wird (`SoftwareWallet.primaryAccount = WalletAccount(_bip32, 0)`). Sobald Multi-Account oder Multi-Address-Funktionalität aktiviert wird, signiert die App mit dem falschen Schlüssel und produziert ungültige Signaturen.

**Empfehlung:** `_getPrivateKeyAt(root, accountIndex, addressIndex)`. Test-Coverage über Multi-Account-Pfade hinzufügen.

---

### NEW-12 — `ascii.encode` statt `utf8.encode` bei Sign-Message

**Severity:** Low
**Pfad:** `lib/packages/wallet/wallet_account.dart:32, 40`

**Beobachtung:**
`ascii.encode(message)` wirft `ArgumentError` bei Code-Points jenseits von 0x7F. Wenn die zu signierende Message vom Backend Umlaute, Emojis oder UTF-8-Sonderzeichen enthält, scheitert das Signieren — typisch für Auth-Flows mit lokalisiertem Challenge-Text.

**Empfehlung:** `utf8.encode(message)`. EIP-191 (`personal_sign`) erwartet UTF-8-Bytes vor der Hash-Berechnung.

---

### NEW-13 — WebView ohne explizite Härtung

**Severity:** Low
**Pfad:** `lib/screens/web_view/web_view_page.dart:68-75`

**Beobachtung:**
```dart
InAppWebView(
  initialSettings: InAppWebViewSettings(transparentBackground: true),
  initialUrlRequest: URLRequest(url: WebUri.uri(uri)),
);
```
Es fehlen explizite Settings für:
- `javaScriptEnabled` (Default: true)
- `mixedContentMode`
- `allowFileAccess` / `allowFileAccessFromFileURLs` / `allowUniversalAccessFromFileURLs`
- `userAgent`
- `useShouldOverrideUrlLoading` mit Allowlist-Filter

Aktuell werden nur fixe Konfigurations-URLs (DFX, RealUnit, Aktionariat, dfx.swiss-Docs) übergeben. Wenn künftig User-controlled oder API-controlled URLs in den WebView fliessen, fehlt jede Schicht-Verteidigung.

**Empfehlung:**
- JavaScript explizit auf `false` setzen für rein dokumentbasierte Anzeigen (Legal-Texts, PDFs).
- URL-Allowlist (`shouldOverrideUrlLoading`) auf den Set bekannter Hosts.
- Mixed-Content blockieren.

---

### NEW-14 — web3dart als nicht-unabhängig auditierter Fork

**Severity:** Low (Supply-Chain)
**Pfade:** `pubspec.yaml`, `pubspec.lock`

**Beobachtung:**
```yaml
web3dart:
  url: https://github.com/cake-tech/web3dart.git
  ref: cake
```
Die Crypto-Bibliothek für Transaction-Signing ist ein Fork (`cake-tech/web3dart`, Branch `cake`). Das Lock-File pinnt zwar einen konkreten Commit-Hash, aber:
- Der Fork wurde nicht unabhängig auditiert.
- Diff zum Upstream `simolus3/web3dart` ist nicht dokumentiert.
- `ref: cake` ist ein Branch, nicht ein Tag — Lock-Hash bleibt zwar bei `pub get`, aber jede Lock-File-Regeneration kann einen neuen Branch-HEAD ziehen.

**Empfehlung:**
- Auf konkreten Commit-Hash oder Tag pinnen statt auf Branch.
- Diff Upstream ↔ Fork dokumentieren oder auf Upstream zurückgehen, wenn die forkspezifischen Änderungen nicht zwingend nötig sind.
- Periodisches Re-Audit des Forks.

---

### NEW-15 — `fuck_firebase.dart` als Workaround

**Severity:** Informational
**Pfad:** `lib/packages/utils/fuck_firebase.dart`

**Beobachtung:**
Die App schreibt aktiv eine Fake-SQLite-Datei nach `<app>/databases/com.google.android.datatransport.events`, um Google-Telemetrie aus MLKit/Play-Services zu unterbinden. Das ist ein bewusst gesetzter Workaround.

Risiko: Bei Updates von MLKit / Google Play Services kann das erwartete Verhalten ändern (zusätzliche DB-Files, andere Pfade, andere Error-Handling-Pfade). Die Crash-Logik ist heute vermutlich abgefangen, aber die Schicht ist fragil.

Da der QR-Scanner inzwischen ohnehin entfernt ist (Finding 4.4), könnte MLKit unter Umständen ganz aus den Dependencies fallen — dann wird auch dieser Workaround obsolet.

**Empfehlung:**
- Prüfen, ob MLKit nach QR-Scanner-Entfernung noch in den Build kommt.
- Wenn ja: dokumentieren, warum der Workaround nötig ist, und einen Test einbauen, der bei Plugin-Updates anschlägt.
- Wenn nein: Workaround entfernen.

---

## 3. Audit-Methodologie-Lücken (von Codinglab explizit ausgeschlossen)

Der externe Audit-Bericht (Kapitel 2) schliesst folgende Bereiche aus. Diese Lücken bleiben damit ungedeckt:

- **Runtime-Instrumentierung** — keine Frida/Objection-Tests, keine Memory-Inspektion, keine Hook-Resistenz-Prüfung.
- **Traffic-Interception** — kein MitM-Test gegen `api.dfx.swiss` (siehe NEW-8).
- **Anti-Tamper-Validation** — keine APK-Repackaging-Tests, keine Signature-Verification-Prüfung (siehe NEW-9).
- **Dependency-CVE-Enumeration** — kein Scan gegen Snyk/OSV/GitHub-Advisory-DB. Insbesondere die Pointycastle-, Drift-, web3dart-Versionen sind nicht gegen bekannte CVEs geprüft.
- **Live-Pen-Test** — kein dynamischer Test mit gebauter Release-APK.

Empfehlung: Diese Schritte in einer zweiten Audit-Phase nachholen, idealerweise nach Adressierung der oben gelisteten Findings.

---

## 4. Summary of Findings

| ID | Finding | Severity | Status |
|---|---|---|---|
| 4.1 | Mnemonic plaintext in DB | High | Teilweise behoben (Layer hinzugefügt, Architektur unverändert) |
| 4.2 | Seed-Display Step-up + FLAG_SECURE | High | Behoben |
| 4.3 | PIN Random Salt + Throttling | High | Teilweise behoben (siehe NEW-1, NEW-2, NEW-3) |
| 4.4 | QR-Scanner Logging | Medium | Behoben (durch Code-Entfernung) |
| 4.5 | Hardcoded Alchemy Keys | Low | Behoben |
| NEW-1 | App-Lock-Bypass via SharedPreferences | Critical | Offen |
| NEW-2 | PBKDF2 nur 10 000 Iterationen | High | Offen |
| NEW-3 | Step-up PIN ohne Lockout | High | Offen |
| NEW-4 | Mnemonic-Key ohne User-Auth-Gate | High | Offen |
| NEW-5 | Biometric ohne CryptoObject-Bindung | High | Offen |
| NEW-6 | Release-Build nicht obfuskiert | High | Offen |
| NEW-7 | Lock-Timeout 5 Minuten | Medium | Offen |
| NEW-8 | Kein TLS-Cert-Pinning | Medium | Offen |
| NEW-9 | Kein Root/Tamper-Detection | Medium | Offen |
| NEW-10 | Mnemonic permanent im RAM | Medium | Offen |
| NEW-11 | `signMessage`-Bug (latent) | Low | Offen |
| NEW-12 | `ascii.encode` statt `utf8.encode` | Low | Offen |
| NEW-13 | WebView ohne explizite Härtung | Low | Offen |
| NEW-14 | web3dart-Fork ohne Pinning auf Hash | Low | Offen |
| NEW-15 | `fuck_firebase.dart` Workaround | Informational | Offen |

---

## 5. Empfohlene Priorisierung

**Sofort (vor nächstem Release):**
- NEW-1 (Lockout/App-Lock in SecureStorage migrieren)
- NEW-6 (R8/ProGuard aktivieren)
- NEW-2 (PBKDF2-Iterationen erhöhen mit transparentem Rehash)
- NEW-3 (Step-up `enableLockout: true`)
- NEW-11 + NEW-12 (Bugfixes in `signMessage`)

**Kurzfristig (nächste Iteration):**
- NEW-4 + NEW-5 (Biometric-CryptoObject-Bindung — gemeinsamer Architektur-Refactor)
- NEW-7 (Lock-Timeout 5 min → 60 s)
- NEW-10 (Mnemonic-Memory-Hygiene)

**Mittelfristig:**
- NEW-8 (Cert-Pinning, koordiniert mit DFX-Cert-Rotation)
- NEW-9 (Root/Tamper-Detection mit Soft-Warn)
- NEW-13 (WebView-Härtung)
- NEW-14 (web3dart-Fork-Diff dokumentieren oder zurück zu Upstream)

**Folge-Audit:**
- Runtime/Frida/Tamper-Tests nachholen.
- Dependency-CVE-Scan.
- MitM-Test gegen DFX-API.

---

*Erstellt im Anschluss an die statische Code-Review des Codinglab-Audits, ohne dynamische Tests. Änderungen am Code zwischen `8e87709` und einem späteren Stand sind hier nicht reflektiert.*
