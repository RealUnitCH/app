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

Das Script führt alle Flows in `.maestro/` aus, die mit `tags: [handbook]`
markiert sind, und bewegt die PNGs nach `docs/handbook/screenshots/`.

## Einen neuen Flow hinzufügen

1. Anlegen: `.maestro/NN-<name>.yaml` mit `tags: [handbook]` und
   `takeScreenshot`-Steps mit Pfad `screenshots/NN-<screen>`.
2. Lauf: `scripts/run-handbook-flows.sh`.
3. HTML: einen neuen `<section class="spec">`-Block in `docs/handbook/de/index.html`
   ergänzen (Muster siehe spec-01).
4. TOC: den Eintrag in `<nav class="toc">` mit Anker zur neuen Section
   ergänzen.

## Beziehung zu den Tier-0/Tier-1-Tests

Tier 0/1 (Unit + Widget + integration-mit-FakeBitboxCredentials) prüfen
einzelne Methoden / Zustände / Branches. Tier 3 (Maestro) prüft den
User-Journey-Layer drüber: dass die Pages in der richtigen Reihenfolge
erscheinen und ihre Inhalte korrekt rendern. Beide Tiers ergänzen sich;
keiner ersetzt den anderen. Siehe [`../testing.md`](../testing.md).
