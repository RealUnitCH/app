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

Bei tieferer Prüfung bleiben jedoch **substantielle Schwächen**, von denen mindestens eine fundamentaler ist als sämtliche ursprünglich gemeldeten Findings zusammen:

- **NEW-16 — Blind-Signing einer EIP-7702-Authorization mit Server-kontrollierten Adressen.** Im Sell-Flow signiert die App eine EIP-7702-Authorization, deren `delegateAddress`, `verifyingContract` und `caveats` vollständig aus dem DFX-Backend stammen, ohne UI-Bestätigung und ohne Allowlist. Bei Backend-Kompromittierung oder MitM (NEW-8) kann ein Angreifer die Adresse durch eine bösartige Contract-Adresse ersetzen — der User signiert blind und das Wallet wird in einer einzigen On-Chain-Transaktion geleert. Diese Schwachstelle erfordert **weder physischen Zugriff noch ein rooted Device** und betrifft jeden regulären User des Sell-Flows.
- Der gesamte **App-Lock und PIN-Lockout-Mechanismus läuft über SharedPreferences** — auf rootbarem Device durch einfaches Editieren einer XML-Datei umgehbar (NEW-1).
- **PBKDF2 mit 10 000 Iterationen** macht den PIN-Verifier bei Extraktion in Sekunden brute-forcebar (NEW-2).
- **Step-up-PIN-Auth (Seed-Reveal) hat kein Lockout** — `enableLockout` ist `false` (NEW-3).
- **Release-Build wird nicht obfuskiert** — `minifyEnabled` und `shrinkResources` fehlen, ProGuard-Rules sind faktisch wirkungslos (NEW-6).
- **Biometric ist nur ein `bool`-Flag**, nicht an einen Keystore-CryptoObject gebunden (NEW-5).
- **Mnemonic-Encryption-Key hat keine User-Auth-Bindung** — er wird automatisch beim App-Start verfügbar (NEW-4).
- **Mnemonic bleibt während der gesamten Session als plain-`String` im RAM** (NEW-10).
- **Debug-Auth-Route ist im Production-Build via Custom URL-Scheme erreichbar** (NEW-18).
- **iOS-DB liegt im iCloud-Backup-Pfad** (NEW-20).

Daneben weitere Funde: persistierte Auth-Signatur in DB, KYC-PII via EIP-712 signiert, Custom URL-Scheme statt Universal Links, fehlendes Cert-Pinning, fehlendes Root/Tamper-Detection, Lock-Timeout 5 min, latente Bugs in `WalletAccount.signMessage`, ungehärteter WebView, web3dart-Fork ohne unabhängige Prüfung, breites Exception-Logging in BLoC-Catches.

**Gesamteinschätzung:** Die App ist nach dem Audit-Fix-Round sicherer als vorher, aber **deutlich nicht produktionsreif für ein Self-Custody-Wallet, das echte Werte verwahrt**. Insbesondere NEW-16 ist eine fundamentale Architektur-Schwäche, die unabhängig vom lokalen Threat-Modell besteht: Selbst auf einem perfekt geschützten, nicht rootbaren Gerät kann ein kompromittiertes Backend die Wallet leeren. Der externe Audit hat diesen Pfad nicht abgedeckt, weil EIP-7702-Spezifika und Confused-Deputy-Pattern nicht im Scope waren.

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

### NEW-16 — Blind-Signing einer EIP-7702-Authorization mit Server-kontrollierten Adressen

**Severity:** Critical (Catastrophic)
**Pfade:**
- `lib/packages/wallet/eip7702_signer.dart:17-23`
- `lib/packages/wallet/eip712_signer.dart:70-106`
- `lib/packages/service/dfx/real_unit_sell_payment_info_service.dart:69-113`
- `lib/screens/sell/widgets/sell_confirm_sheet.dart`

**Beobachtung:**
Im Sell-Flow signiert die App eine **EIP-7702-Authorization** und eine **EIP-712-Delegation**, deren sicherheitsrelevante Felder vollständig aus dem Backend-Response stammen:

```dart
// eip7702_signer.dart
final eip7702.UnsignedAuthorization unsignedAuth = (
  chainId: BigInt.from(eip7702Data.domain.chainId),
  delegateAddress: eip7702Data.delegatorAddress,    // server-controlled
  nonce: BigInt.from(eip7702Data.userNonce),         // server-controlled
);
```

```dart
// eip712_signer.dart - signDelegation
'domain': {
  'name': eip7702Data.domain.name,
  'version': eip7702Data.domain.version,
  'chainId': eip7702Data.domain.chainId,
  'verifyingContract': eip7702Data.domain.verifyingContract,  // server-controlled
},
'message': {
  'delegate': eip7702Data.message.delegate,         // server-controlled
  'delegator': eip7702Data.message.delegator,
  'authority': eip7702Data.message.authority,
  'caveats': eip7702Data.message.caveats,           // server-controlled
  'salt': eip7702Data.message.salt,
},
```

Es gibt **keine Validierung** dieser Adressen gegen eine Allowlist, keinen Vergleich mit einer On-Chain-Konstanten und **keine UI-Anzeige** der zu autorisierenden Delegate-Adresse oder der Caveat-Inhalte. `SellConfirmSheetView` zeigt dem User nur Asset-Symbol, Amount und IBAN — die EIP-7702-Authorization und ihre Tragweite werden nirgends erwähnt.

**Bedeutung von EIP-7702:**
EIP-7702 (Ethereum Pectra-Hardfork) erlaubt einer EOA, einer Delegate-Adresse Code-Ausführungsrechte unter ihrer eigenen Identität zu gewähren. Eine signierte Authorization-Tuple `(chainId, delegateAddress, nonce)` ist ausreichend, um den EOA in einer einzigen Transaktion zu einem Contract-Account mit Code des Delegate-Targets zu „upgraden". Wenn dieses Code beliebige Token-Transfers durchführt, sind alle Assets der Adresse exfiltrierbar.

**Threat-Modell:**
1. **DFX-Backend kompromittiert:** Angreifer ersetzt `delegatorAddress` / `delegate` durch eine bösartige Adresse → User signiert blind → Wallet wird in einer einzigen On-Chain-Transaktion geleert.
2. **MitM (siehe NEW-8 fehlendes Cert-Pinning):** Aktive MitM zwischen App und API → identische Auswirkung.
3. **Insider-Threat:** Ein DFX-Operator mit API-Schreibzugriff könnte gezielt Wallets drainen.
4. **Backend-Bug (IDOR, Auth-Bypass, SQL-Injection):** Wenn das Backend einen Bug hat, der das Setzen einer beliebigen Adresse erlaubt, wird daraus ein Wallet-Drainer für alle App-User.

Im Gegensatz zu NEW-1 / NEW-4 setzt diese Schwachstelle **weder physischen Zugriff noch ein rooted Device** voraus. Jeder reguläre Sell-Flow ist potentielles Angriffsziel. Die App ist ein **Confused Deputy** zwischen User und Backend.

**Vergleich mit Industry-Standard:**
Standard-Wallets (MetaMask, Rainbow, Frame) zeigen jede EIP-7702-Authorization mit deutlichen Warnungen — Empfänger-Adresse, Caveats, Domain, Risiken — bevor der User signiert. Eine Self-Custody-App, die das auslässt, ist im 2026er-Threat-Modell nicht produktionstauglich.

**Empfehlung:**
1. **Sofort:** UI-Bestätigung mit Anzeige von Delegate-Address, Caveats, Domain (`name`, `version`, `verifyingContract`) und einer Warnung, dass die Delegation Wallet-Inhalt zugänglich macht.
2. **Allowlist:** On-Chain-Validierung der `delegatorAddress` / `relayerAddress` gegen eine in der App hartcodierte (oder von einem unabhängig signierten Quelldokument verifizierte) Liste bekannter RealUnit-Relayer-Contracts. Falls keine Übereinstimmung → Sign verweigern.
3. **Verifying-Contract-Pinning:** `eip7702Data.domain.verifyingContract` muss gegen einen bekannten Contract gepinnt werden.
4. **Caveat-Inspection:** Caveats müssen mindestens auf einen erwarteten Set (z.B. „nur RealUnit-Token-Transfer in Höhe X an IBAN-Beneficiary") parsbar und überprüfbar sein.
5. **Nonce-Range-Check:** Nonce-Werte ausserhalb plausibler Range ablehnen.
6. **Mittelfristig:** EIP-7702 zugunsten Permit2/EIP-2612 oder klassischer signedTransaction-Flows aufgeben. EIP-7702 ist mit erheblichem User-Risiko verbunden, das eine Wallet-App bewusst tragen muss.

---

### NEW-17 — Persistierte Auth-Signatur in DB ermöglicht Endless-Auth

**Severity:** Medium
**Pfade:**
- `lib/packages/service/session_cache.dart:23-33`
- `lib/packages/service/debug_auth_service.dart:54-57`

**Beobachtung:**
Nach erfolgreicher Authentifizierung gegen `/v1/auth` wird die zur Address gehörige Signatur (`personal_sign`-Antwort auf eine Server-Challenge) per `SessionCache.saveSignature(...)` in der SQLCipher-DB persistiert (`cached_signature`, `cached_signature_address`).

Die Signatur ist nicht zeitlich gebunden (kein Expiry, kein Replay-Schutz aus Sicht der App). Wenn das Backend solche Signaturen langfristig akzeptiert, kann ein Angreifer mit Zugriff auf:
- die SQLCipher-DB **plus** den DB-Encryption-Key in FlutterSecureStorage (z.B. via NEW-1 + NEW-4-Kette)

beliebig oft neue Auth-Tokens erzeugen, ohne den Mnemonic zu kennen — die Signatur ist alles, was die `/v1/auth`-API verifiziert.

**Empfehlung:**
- Signatur nicht persistieren — bei jedem App-Start neu signieren.
- Alternativ: Signatur an einen kurzlebigen Nonce binden, sodass eine alte Signatur nach z.B. 24h ungültig wird (Server-side enforcement).

---

### NEW-18 — Debug-Auth-Route in Production-Build erreichbar

**Severity:** Medium
**Pfade:**
- `lib/setup/routing/router_config.dart:88-90` (Route immer registriert)
- `lib/screens/welcome/welcome_page.dart:120-124` (Button nur in `kDebugMode`)
- `ios/Runner/Info.plist:25-37` (Custom URL-Scheme `realunit-wallet`)
- `android/app/src/main/AndroidManifest.xml` (kein scheme-Filter, aber Flutter-Deep-Links sind über Default-Intent-Filter erreichbar)

**Beobachtung:**
Der Welcome-Screen zeigt den Debug-Auth-Button nur in `kDebugMode`. Die GoRoute `/debugAuth` ist jedoch in `router_config.dart` **unbedingt registriert** — auch im Release-Build. Die App registriert ein Custom URL-Scheme `realunit-wallet`. `FlutterDeepLinkingEnabled = true` (iOS Plist).

Damit ist die Debug-Route potentiell über `realunit-wallet:///debugAuth` aufrufbar — auch in Production-Builds. `DebugAuthService` speichert Address + Signatur in **SharedPreferences** (Klartext-XML), bypassing die normale PIN-Setup-/Verify-Kette.

**Empfehlung:**
- Route nur registrieren, wenn `kDebugMode == true` oder über einen build-time-Flag gegated.
- Komplettes Removal der Debug-Auth-Pfade aus Release-Builds (CI-Build-Variant trennen).
- Auf Universal Links / App Links umstellen statt Custom URL-Schemes (siehe NEW-22).

---

### NEW-19 — KYC-PII via EIP-712 signiert, Signatur potentiell publishbar

**Severity:** Medium (Privacy)
**Pfad:** `lib/packages/wallet/eip712_signer.dart:10-68`

**Beobachtung:**
`Eip712Signer.signRegistration` baut eine TypedData-Struktur mit vollständigen KYC-Daten:
- Email, Vor- und Nachname, Telefonnummer, Geburtsdatum, Nationalität
- Vollständige Adresse (Street, PostalCode, City, Country)
- Steuerwohnsitz, Wallet-Adresse

Diese Daten werden mit dem Wallet-Schlüssel EIP-712-signiert. Falls das DFX-Backend die signedData (Domain + Message + Signatur) jemals on-chain veröffentlicht oder in einem öffentlichen API-Endpunkt offenlegt, sind sämtliche PII inklusive der zugehörigen Wallet-Adresse permanent öffentlich.

Auch ohne On-Chain-Publish: Die Signatur ist ein kryptographischer Beweis, dass die Wallet-Adresse zu Person X gehört — wer immer diese Signatur erhält (DFX-Backend, dessen DB-Backups, Log-Aggregation, Third-Party-Anbieter), hält perpetual eine signierte De-Anonymisierung der Adresse.

**Empfehlung:**
- Klären, ob die Signatur tatsächlich Pflicht ist oder ob ein einfacher API-Auth-Token reicht.
- Falls erforderlich: Hash der PII signieren statt PII selbst (Backend prüft Hash gegen serverseitig gespeicherte Daten).
- Datenschutz-Folgenabschätzung (DSFA): Die Verknüpfung von Wallet-Adresse + KYC-Daten via Signatur ist DSGVO-relevant.

---

### NEW-20 — iOS: SQLCipher-DB im iCloud-Backup-Pfad

**Severity:** Medium
**Pfade:**
- `lib/packages/storage/database.dart:69-72` (`getApplicationDocumentsDirectory()` → iOS `Documents/`)
- `ios/Runner/Info.plist` (kein `UIFileSharingEnabled`-Override, aber `Documents/` wird per Default in iCloud-Backup eingeschlossen)

**Beobachtung:**
Die SQLCipher-DB (`wallet.db.enc`) liegt auf iOS in `Documents/` (`getApplicationDocumentsDirectory`). Per Default wird der Inhalt von `Documents/` in iCloud-Backups eingeschlossen — das verschlüsselte DB-File wird damit auf Apple-Server hochgeladen.

Der DB-Encryption-Key liegt in der iOS-Keychain (via `flutter_secure_storage`). Default-Accessibility ist `kSecAttrAccessibleAfterFirstUnlock` (nicht `*ThisDeviceOnly`), wodurch der Keychain-Eintrag bei verschlüsseltem iCloud-Backup migrierbar ist.

Konsequenz: Bei iCloud-Account-Compromise oder bei Apple-internem Zugriff (Strafverfolgung, Apple-Mitarbeiter mit Zugriff) sind theoretisch sowohl DB als auch Schlüssel rekonstruierbar.

**Empfehlung:**
- DB in `Library/Application Support/` ablegen (auf iOS via `getApplicationSupportDirectory()` statt `getApplicationDocumentsDirectory()`).
- Datei explizit mit `NSURLIsExcludedFromBackupKey = true` markieren.
- `flutter_secure_storage` mit `IOSAccessibility.first_unlock_this_device` oder `passcode_this_device` konfigurieren, damit Keychain-Items nicht in iCloud landen.

---

### NEW-21 — `ITSAppUsesNonExemptEncryption = false` trotz Custom-Crypto

**Severity:** Low (Compliance)
**Pfad:** `ios/Runner/Info.plist:42-43`

**Beobachtung:**
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```
Die App nutzt SQLCipher (AES-256), AES-GCM-Encryption für den Mnemonic, PBKDF2-HMAC-SHA256, secp256k1-Signing, BIP32/BIP39 — sämtlich „non-exempt encryption" aus US-Export-Control-Sicht. Die Deklaration `false` ist potentiell falsch.

Für Open-Source-Apps mit Standard-Crypto bestehen Erleichterungen (Notification statt Classification), aber diese müssen entsprechend dokumentiert sein. Eine falsche Deklaration kann bei App-Store-Review zu Beanstandungen oder bei Audits zu rechtlichen Konsequenzen führen.

**Empfehlung:**
- Mit Apple-Compliance / Rechtsabteilung abklären, ob die App unter eine der Encryption-Exemptions fällt (z.B. „proprietary encryption used solely for authentication") oder ob sie einer ECCN-Klassifizierung bedarf.
- Eintrag entsprechend korrigieren.

---

### NEW-22 — Custom URL-Scheme statt Universal Links / App Links

**Severity:** Medium
**Pfade:**
- `ios/Runner/Info.plist:25-37` (`CFBundleURLSchemes: realunit-wallet`)
- Android: `FlutterDeepLinkingEnabled = true` ohne dedizierte App-Links-Einrichtung

**Beobachtung:**
Die App registriert ein Custom URL-Scheme `realunit-wallet`. Auf iOS ist die Scheme-Auflösung „first-come-first-served" — eine andere App, die zuerst installiert wurde und dasselbe Scheme registriert, gewinnt. Auf Android ist es ähnlich, mit Disambiguation-Dialog beim User.

Damit kann eine bösartige App das Scheme „kapern" und Deep-Links abfangen, die für die RealUnit-App gedacht waren (z.B. Auth-Callbacks, Magic-Links). Universal Links (iOS) / App Links (Android) lösen das via Domain-verified Associations.

**Empfehlung:**
- Universal Links + App Links auf einer kontrollierten Domain (`realunit.ch` oder `app.realunit.ch`) einrichten.
- Custom URL-Scheme parallel beibehalten nur für Backwards-Compatibility, mit kritischer Daten-Validierung im Handler.

---

### NEW-23 — SQL-Pragma-Key über String-Interpolation

**Severity:** Low (Defense-in-Depth)
**Pfad:** `lib/packages/storage/database.dart:81-87`

**Beobachtung:**
```dart
final escapedKey = encryptionPassword.replaceAll("'", "''");
db.execute("pragma key = '$escapedKey'");
```
Der DB-Encryption-Key wird via String-Interpolation in das Pragma eingebettet, mit naivem Quote-Escaping. Heute unkritisch, weil `getNewEncryptionKey` ausschliesslich Hex-Bytes generiert (kein Quote-Risk), aber:
- Wenn jemals eine andere Key-Quelle genutzt wird (User-input, Migration alter Keys, Bug), ist das ein potentieller SQL-Injection-Vektor.
- SQLCipher unterstützt das raw-Hex-Format `pragma key = "x'...'"` direkt — robuster und ohne Escaping-Risiko.

**Empfehlung:**
```dart
db.execute("pragma key = \"x'$encryptionPassword'\"");
```
(setzt voraus, dass `encryptionPassword` ein Hex-String ist; das ist mit `getNewEncryptionKey` gegeben).

---

### NEW-24 — Logging von Exception-Strings in BLoC-Catches

**Severity:** Low (Privacy)
**Pfade:**
- `lib/screens/sell/cubits/sell_payment_info/sell_payment_info_cubit.dart:58, 93`
- `lib/screens/buy/cubits/buy_*/...`
- `lib/screens/kyc/steps/.../...`
- ca. 30 weitere Cubits

**Beobachtung:**
Vielfach finden sich Pattern wie:
```dart
} catch (e) {
  developer.log(e.toString());
  emit(...);
}
```
Wenn die Exception API-Response-Bodies, IBAN, KYC-Daten oder Wallet-Adressen enthält (was bei `Exception('Failed: ${response.body}')` durchaus vorkommt), landet das im `adb logcat`. Das ist die gleiche Klasse von Issue, die Codinglab in 4.4 für QR-Payloads moniert hat — nur breiter verteilt.

**Empfehlung:**
- Keine `e.toString()` in Production loggen. Nur strukturierte, nicht-PII-haltige Logs.
- Logger-Wrapper, der in Release-Builds (`!kDebugMode`) auf no-op fällt oder nur Severity + Anonymized-Type emittiert.

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
| NEW-16 | Blind-Signing EIP-7702 mit Server-Adressen | Critical (Catastrophic) | Offen |
| NEW-17 | Persistierte Auth-Signatur in DB | Medium | Offen |
| NEW-18 | Debug-Auth-Route in Production-Build | Medium | Offen |
| NEW-19 | KYC-PII via EIP-712 signiert | Medium (Privacy) | Offen |
| NEW-20 | iOS: DB im iCloud-Backup-Pfad | Medium | Offen |
| NEW-21 | Falsche `ITSAppUsesNonExemptEncryption`-Deklaration | Low (Compliance) | Offen |
| NEW-22 | Custom URL-Scheme statt Universal Links | Medium | Offen |
| NEW-23 | SQL-Pragma-Key via String-Interpolation | Low | Offen |
| NEW-24 | Exception-Strings im Production-Log | Low (Privacy) | Offen |

---

## 5. Empfohlene Priorisierung

**Blocker (vor jedem Production-Release zwingend zu beheben):**
- **NEW-16 (EIP-7702 Blind-Signing)** — UI-Bestätigung + Allowlist + Verifying-Contract-Pinning. Ohne diesen Fix ist jeder User-Wallet bei Backend-Compromise oder MitM gefährdet.
- NEW-1 (Lockout / App-Lock in SecureStorage migrieren)
- NEW-6 (R8/ProGuard aktivieren)
- NEW-18 (Debug-Auth-Route aus Release-Builds entfernen)

**Sofort (vor nächstem Release):**
- NEW-2 (PBKDF2-Iterationen ≥600k mit transparentem Rehash)
- NEW-3 (Step-up `enableLockout: true`)
- NEW-11 + NEW-12 (Bugfixes in `signMessage`)
- NEW-17 (Auth-Signatur nicht persistieren oder zeitlich limitieren)
- NEW-20 (iOS: DB-Pfad ändern + iCloud-Exclusion)

**Kurzfristig (nächste Iteration):**
- NEW-4 + NEW-5 (Biometric-CryptoObject-Bindung — gemeinsamer Architektur-Refactor)
- NEW-7 (Lock-Timeout 5 min → 60 s)
- NEW-10 (Mnemonic-Memory-Hygiene)
- NEW-19 (KYC-PII-Signing prüfen oder durch Hash ersetzen)
- NEW-22 (Universal Links / App Links statt Custom URL-Scheme)
- NEW-24 (Production-Logging-Wrapper ohne Exception-Strings)

**Mittelfristig:**
- NEW-8 (Cert-Pinning, koordiniert mit DFX-Cert-Rotation)
- NEW-9 (Root/Tamper-Detection mit Soft-Warn)
- NEW-13 (WebView-Härtung)
- NEW-14 (web3dart-Fork-Diff dokumentieren oder zurück zu Upstream)
- NEW-21 (`ITSAppUsesNonExemptEncryption`-Deklaration prüfen)
- NEW-23 (SQL-Pragma-Key auf raw-Hex-Format umstellen)

**Folge-Audit:**
- Runtime/Frida/Tamper-Tests nachholen.
- Dependency-CVE-Scan (Snyk / OSV / GitHub Advisory).
- MitM-Test gegen DFX-API mit Fokus auf EIP-7702-Manipulation.
- Architektur-Review der EIP-7702-Integration mit externem Smart-Contract-Auditor.

---

*Erstellt im Anschluss an die statische Code-Review des Codinglab-Audits, ohne dynamische Tests. Änderungen am Code zwischen `8e87709` und einem späteren Stand sind hier nicht reflektiert.*
