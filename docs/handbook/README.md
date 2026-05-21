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

## Beziehung zu den Tier-0/Tier-1-Tests

Tier 0/1 (Unit + Widget + integration-mit-FakeBitboxCredentials) prüfen
einzelne Methoden / Zustände / Branches. Tier 3 (Maestro) prüft den
User-Journey-Layer drüber: dass die Pages in der richtigen Reihenfolge
erscheinen und ihre Inhalte korrekt rendern. Beide Tiers ergänzen sich;
keiner ersetzt den anderen. Siehe [`../testing.md`](../testing.md).
