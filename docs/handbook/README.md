# RealUnit Handbook

User-Guide + Test-Doku in einem. Jeder Screenshot ist die Ausgabe eines
Maestro-Tier-3-Flows; das Handbook bleibt nur dann visuell korrekt, wenn die
App es auch ist.

## Lokal lesen

```
open docs/handbook/de/index.html
```

(Die Seite verlinkt Screenshots aus `docs/handbook/screenshots/` per relativem
Pfad — kein Web-Server nötig.)

## Screenshots regenerieren

```bash
# 1. iOS-Simulator booten (z.B. iPhone 17)
xcrun simctl boot "iPhone 17"
open -a Simulator

# 2. App im Debug-Bundle bauen + installieren
flutter build ios --simulator --debug
xcrun simctl install booted build/ios/iphonesimulator/Runner.app

# 3. Alle handbook-Flows laufen lassen
scripts/run-handbook-flows.sh
```

Das Script iteriert `.maestro/handbook/*.yaml` alphabetisch durch. Pro Flow:

1. Maestro navigiert zum Ziel-Screen
2. `xcrun simctl io booted screenshot` macht das eigentliche Bild
   (Maestros eigener `takeScreenshot` rendert `BackdropFilter`-Layer schwarz)

Der Filename des Flows ist auch der Filename des PNG. Vor jedem Lauf macht
das Skript `simctl erase` + reinstall, damit das iOS-Keychain (Wallet + PIN)
frisch ist — sonst landen Folgeläufe direkt auf dem App-Lock-Screen.

## Selektive Läufe (Teilmenge)

`scripts/run-handbook-flows.sh` akzeptiert optionale Argumente: Glob-Muster auf
die Flow-Namen. Ohne Argument laufen alle Flows, mit Argument nur die passende
Teilmenge:

```bash
# Nur diesen einen Flow
scripts/run-handbook-flows.sh 25-restore-wallet

# Die ganze 20er-Serie (20..26)
scripts/run-handbook-flows.sh '2*'
```

Achtung: Die handbook-Flows sind eine **sequentielle Kette** und teilen sich den
App-State — jeder Flow greift den Zustand auf, wo der vorherige ihn hingelegt
hat. Ein Flow aus der Mitte der Kette schlägt einzeln fehl, sofern er nicht
selbst mit einem `launchApp` beginnt. Der Flow `26-terms` ist **eigenständig**
(eigener `launchApp`) und kann daher gefahrlos allein laufen.

Auch der Tier-3-GitHub-Workflow hat dafür einen `flows`-`workflow_dispatch`-Input
— so lässt sich in der CI gezielt eine Teilmenge der Flows neu generieren.

## Einen neuen Flow hinzufügen

1. Anlegen: `.maestro/handbook/NN-<name>.yaml`.
   - Erster Flow startet mit `launchApp: clearState: true`.
   - Folgeflows starten ohne `launchApp` — sie greifen den App-State auf,
     wo der vorherige Flow ihn hingelegt hat.
   - Kein `takeScreenshot`-Step — das übernimmt der Wrapper.
   - Beende mit `assertVisible` oder `extendedWaitUntil`, damit der
     Screenshot stabil ist (sonst trifft xcrun mitten in der Transition).
2. Lauf: `scripts/run-handbook-flows.sh`.
3. HTML: in `docs/handbook/de/index.html` einen neuen `<div class="test">`-Block
   in die thematisch passende `<details id="spec-NN" class="spec">`-Sektion
   einfügen (Muster siehe spec-01). Die Screenshots sind in wenige thematische
   spec-Sektionen gruppiert — ein neuer Flow kommt meist in eine bestehende.
4. Nur bei einem neuen Thema: eine neue `<details id="spec-NN" class="spec">`
   anlegen und den Anker `#spec-NN` in `<nav class="toc">` ergänzen.

## E-Mail Previews

Die HTML-Vorschauen aller vom Backend an Endkunden versendeten Mails liegen
**nicht in diesem Repo**. Quelle ist `DFXswiss/api`:

- Generator: `scripts/generate-realunit-previews.js`
- Vorlage: `src/subdomains/supporting/notification/templates/realunit.hbs`
- Übersetzungen: `src/shared/i18n/de/mail-realunit.json` (RealUnit-Texte) mit
  Fallback auf `src/shared/i18n/de/mail.json` (DFX-Defaults)

Der Handbook-CI-Build (`.github/workflows/handbook.yaml`) checkt das api-Repo
zur Build-Zeit aus, führt den Generator aus und kopiert das Ergebnis nach
`docs/handbook/mails/`, bevor das Docker-Image gebaut wird. `docs/handbook/mails/`
ist in `.gitignore` — der Inhalt darf nie ins Repo eingecheckt werden, sonst
divergieren Image-Stand und Source-of-Truth.

### Trigger

Ändert sich im api-Repo eine Mail-Vorlage, eine Übersetzung oder das
Generator-Skript, schickt
`DFXswiss/api/.github/workflows/notify-handbook-on-mail-change.yaml` ein
`repository_dispatch (mails-updated)` an dieses Repo und der
Handbook-Deploy läuft automatisch (DEV → PRD).

### Lokal regenerieren

Mit beiden Repos nebeneinander ausgecheckt:

```bash
# Einmalig: handlebars in den api-Klon installieren (falls noch nicht da)
cd ../api && npm install handlebars

# Generieren + ins Handbook übernehmen
node ../api/scripts/generate-realunit-previews.js
mkdir -p docs/handbook/mails
cp ../api/scripts/email-previews/realunit/*.html docs/handbook/mails/
cp docs/handbook/mails/00_index.html docs/handbook/mails/index.html

# Lokal ansehen
open docs/handbook/mails/index.html
```

(Den finalen Build-Step macht aber immer der CI — lokale Files sind nur fürs
Vorab-Anschauen während eines Template-Refactors.)

## Beziehung zu den Tier-0/Tier-1-Tests

Tier 0/1 (Unit + Widget + integration-mit-FakeBitboxCredentials) prüfen
einzelne Methoden / Zustände / Branches. Tier 3 (Maestro) prüft den
User-Journey-Layer drüber: dass die Pages in der richtigen Reihenfolge
erscheinen und ihre Inhalte korrekt rendern. Beide Tiers ergänzen sich;
keiner ersetzt den anderen. Siehe [`../testing.md`](../testing.md).
