# Entwickler-Anleitung: REALU Kauf Integration

Diese Anleitung beschreibt, wie der Kauf von REALU Tokens per Banküberweisung in die RealUnit App integriert wird.

---

## Übersicht

Die Integration nutzt die **DFX API** als einzigen Zugangspunkt für alle Blockchain-Operationen. Die App kommuniziert nie direkt mit der Ethereum Blockchain.

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  RealUnit   │  HTTP   │   DFX API   │  RPC    │  Ethereum   │
│    App      │────────▶│             │────────▶│  Blockchain │
└─────────────┘         └─────────────┘         └─────────────┘
```

---

## Was passiert im Hintergrund?

### Die Smart Contracts

Die DFX API interagiert mit zwei Smart Contracts auf Ethereum Mainnet:

| Contract | Adresse | Funktion |
|----------|---------|----------|
| **Brokerbot** | `0xcff32c60b87296b8c0c12980de685bed6cb9dd6d` | Automated Market Maker - berechnet Preise und führt Trades aus |
| **REALU Token** | `0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B` | ERC-20 Token mit Allowlist-System |

### Wie die DFX API funktioniert

Wenn du einen API-Endpoint aufrufst, passiert folgendes:

```
App: GET /brokerbot/price
         │
         ▼
DFX API: Ruft Brokerbot.getPrice() auf der Blockchain auf
         │
         ▼
DFX API: Formatiert Wei-Wert (1330000000000000000) zu CHF ("1.33")
         │
         ▼
App: Erhält { pricePerShare: "1.33", pricePerShareRaw: "1330000000000000000" }
```

Die API übernimmt:
- Ethereum RPC-Kommunikation
- Wei ↔ CHF Konvertierung (ZCHF hat 18 Decimals)
- Error Handling und Retry-Logik

---

## API Konfiguration

```typescript
const API_BASE = 'https://dev.api.dfx.swiss/v1/realunit';
```

---

## Schritt 1: Allowlist-Status prüfen

**Warum?** Der REALU Token hat ein Allowlist-System. Nur allowlisted Wallets können Tokens empfangen. Dies ist eine regulatorische Anforderung für Security Tokens.

**Was die API macht:** Ruft `REALU.canReceiveFromAnyone(address)` auf dem Token-Contract auf.

```typescript
interface AllowlistStatus {
  address: string;
  canReceive: boolean;    // true = kann REALU empfangen
  isForbidden: boolean;   // true = Adresse ist gesperrt
  isPowerlisted: boolean; // true = privilegierte Adresse
}

async function checkAllowlist(walletAddress: string): Promise<AllowlistStatus> {
  const response = await fetch(`${API_BASE}/allowlist/${walletAddress}`);

  if (!response.ok) {
    throw new Error('Allowlist-Prüfung fehlgeschlagen');
  }

  return response.json();
}

// Verwendung
const status = await checkAllowlist('0x1234...');

if (status.isForbidden) {
  // Wallet ist gesperrt - Kauf nicht möglich
  showError('Diese Wallet-Adresse ist gesperrt.');
} else if (!status.canReceive) {
  // Nicht allowlisted - Kunde muss sich bei RealUnit registrieren
  showError('Wallet ist nicht registriert. Bitte kontaktieren Sie RealUnit.');
} else {
  // OK - weiter mit Preisabfrage
}
```

---

## Schritt 2: Preis berechnen

**Wichtig:** Der Brokerbot verwendet ein **dynamisches Preismodell**. Der Preis steigt mit jedem Kauf:

```
Neuer Preis = Aktueller Preis + (Anzahl Shares × Increment)
```

### Option A: Preis für eine bestimmte Anzahl Shares

**Was die API macht:** Ruft `Brokerbot.getBuyPrice(shares)` auf und berechnet die Gesamtkosten inkl. Preisanstieg.

```typescript
interface BuyPriceResponse {
  shares: number;           // Anzahl Shares
  totalPrice: string;       // Gesamtkosten in CHF (z.B. "133.00")
  totalPriceRaw: string;    // Gesamtkosten in Wei
  pricePerShare: string;    // Durchschnittspreis pro Share
}

async function getBuyPrice(shares: number): Promise<BuyPriceResponse> {
  const response = await fetch(`${API_BASE}/brokerbot/buyPrice?shares=${shares}`);

  if (!response.ok) {
    throw new Error('Preisabfrage fehlgeschlagen');
  }

  return response.json();
}

// Beispiel: Kosten für 100 Shares
const quote = await getBuyPrice(100);
// { shares: 100, totalPrice: "133.00", pricePerShare: "1.33", ... }
```

### Option B: Shares für einen bestimmten CHF-Betrag

**Was die API macht:** Verwendet Binary Search auf `Brokerbot.getShares(amount)` um die maximale Anzahl Shares zu berechnen.

```typescript
interface SharesResponse {
  amount: string;           // Eingegebener CHF-Betrag
  shares: number;           // Anzahl Shares die man erhält
  pricePerShare: string;    // Aktueller Preis pro Share
}

async function getSharesForAmount(amountChf: string): Promise<SharesResponse> {
  const response = await fetch(`${API_BASE}/brokerbot/shares?amount=${amountChf}`);

  if (!response.ok) {
    throw new Error('Berechnung fehlgeschlagen');
  }

  return response.json();
}

// Beispiel: Wie viele Shares für 1000 CHF?
const quote = await getSharesForAmount('1000');
// { amount: "1000", shares: 751, pricePerShare: "1.33" }
```

---

## Schritt 3: Bankverbindung abrufen

**Was die API macht:** Gibt die konfigurierten Bankdaten für RealUnit zurück (aus Environment-Variablen).

```typescript
interface BankDetails {
  recipient: string;    // "RealUnit Schweiz AG"
  address: string;      // "Schochenmühlestrasse 6, 6340 Baar, Switzerland"
  iban: string;         // "CH22 0830 7000 5609 4630 9"
  bic: string;          // "HYPLCH22XXX"
  bankName: string;     // "Hypothekarbank Lenzburg"
  currency: string;     // "CHF"
}

async function getBankDetails(): Promise<BankDetails> {
  const response = await fetch(`${API_BASE}/bank`);

  if (!response.ok) {
    throw new Error('Bankdaten konnten nicht geladen werden');
  }

  return response.json();
}
```

---

## Schritt 4: Kaufübersicht anzeigen

Zeige dem Benutzer alle Informationen die er für die Banküberweisung benötigt:

```typescript
interface PurchaseInfo {
  // Kauf-Details
  shares: number;
  pricePerShare: string;
  totalPrice: string;

  // Bankverbindung
  recipient: string;
  iban: string;
  bic: string;
  bankName: string;
}

async function getPurchaseInfo(shares: number, walletAddress: string): Promise<PurchaseInfo> {
  // 1. Allowlist prüfen
  const allowlist = await checkAllowlist(walletAddress);
  if (!allowlist.canReceive) {
    throw new Error('Wallet ist nicht allowlisted');
  }

  // 2. Preis und Bankdaten parallel abrufen
  const [quote, bank] = await Promise.all([
    getBuyPrice(shares),
    getBankDetails(),
  ]);

  return {
    shares: quote.shares,
    pricePerShare: quote.pricePerShare,
    totalPrice: quote.totalPrice,
    recipient: bank.recipient,
    iban: bank.iban,
    bic: bank.bic,
    bankName: bank.bankName,
  };
}
```

### UI-Darstellung

```tsx
function PurchaseSummary({ info }: { info: PurchaseInfo }) {
  return (
    <View>
      {/* Kauf-Details */}
      <Section title="Ihre Bestellung">
        <Row label="Anzahl REALU" value={info.shares} />
        <Row label="Preis pro Share" value={`${info.pricePerShare} CHF`} />
        <Row label="Gesamtbetrag" value={`${info.totalPrice} CHF`} highlight />
      </Section>

      {/* Banküberweisung */}
      <Section title="Banküberweisung">
        <Row label="Empfänger" value={info.recipient} copyable />
        <Row label="IBAN" value={info.iban} copyable />
        <Row label="BIC" value={info.bic} copyable />
        <Row label="Bank" value={info.bankName} />
        <Row label="Betrag" value={`${info.totalPrice} CHF`} copyable highlight />
      </Section>

      {/* Hinweis */}
      <Info>
        Nach Zahlungseingang werden die REALU Tokens automatisch
        an Ihre Wallet übertragen.
      </Info>
    </View>
  );
}
```

---

## Vollständiges Beispiel

```typescript
// api.ts
const API_BASE = 'https://dev.api.dfx.swiss/v1/realunit';

export async function checkAllowlist(address: string) {
  const res = await fetch(`${API_BASE}/allowlist/${address}`);
  if (!res.ok) throw new Error('Allowlist check failed');
  return res.json();
}

export async function getBuyPrice(shares: number) {
  const res = await fetch(`${API_BASE}/brokerbot/buyPrice?shares=${shares}`);
  if (!res.ok) throw new Error('Price fetch failed');
  return res.json();
}

export async function getSharesForAmount(amount: string) {
  const res = await fetch(`${API_BASE}/brokerbot/shares?amount=${amount}`);
  if (!res.ok) throw new Error('Shares calculation failed');
  return res.json();
}

export async function getBankDetails() {
  const res = await fetch(`${API_BASE}/bank`);
  if (!res.ok) throw new Error('Bank details fetch failed');
  return res.json();
}

export async function getCurrentPrice() {
  const res = await fetch(`${API_BASE}/brokerbot/price`);
  if (!res.ok) throw new Error('Current price fetch failed');
  return res.json();
}
```

```tsx
// BuyScreen.tsx
import { checkAllowlist, getBuyPrice, getBankDetails } from './api';

export function BuyScreen({ walletAddress }: Props) {
  const [shares, setShares] = useState(10);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [purchaseInfo, setPurchaseInfo] = useState<PurchaseInfo | null>(null);

  const handleCalculate = async () => {
    setLoading(true);
    setError(null);

    try {
      // Allowlist prüfen
      const allowlist = await checkAllowlist(walletAddress);
      if (!allowlist.canReceive) {
        throw new Error('Wallet nicht registriert. Kontaktieren Sie RealUnit.');
      }

      // Preis und Bank parallel laden
      const [quote, bank] = await Promise.all([
        getBuyPrice(shares),
        getBankDetails(),
      ]);

      setPurchaseInfo({
        shares: quote.shares,
        pricePerShare: quote.pricePerShare,
        totalPrice: quote.totalPrice,
        recipient: bank.recipient,
        iban: bank.iban,
        bic: bank.bic,
        bankName: bank.bankName,
      });
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View>
      <Input
        label="Anzahl REALU"
        value={shares}
        onChangeText={setShares}
        keyboardType="numeric"
      />

      <Button
        title="Preis berechnen"
        onPress={handleCalculate}
        loading={loading}
      />

      {error && <ErrorMessage>{error}</ErrorMessage>}

      {purchaseInfo && <PurchaseSummary info={purchaseInfo} />}
    </View>
  );
}
```

---

## API Referenz

| Endpoint | Beschreibung | Blockchain-Call |
|----------|--------------|-----------------|
| `GET /brokerbot/price` | Aktueller Preis pro Share | `Brokerbot.getPrice()` |
| `GET /brokerbot/buyPrice?shares=X` | Gesamtkosten für X Shares | `Brokerbot.getBuyPrice(X)` |
| `GET /brokerbot/shares?amount=X` | Shares für X CHF | `Brokerbot.getShares(X)` |
| `GET /brokerbot/info` | Brokerbot-Konfiguration | Multiple view calls |
| `GET /allowlist/:address` | Allowlist-Status | `REALU.canReceiveFromAnyone()` |
| `GET /bank` | Bankverbindung | - (aus Config) |

---

## Fehlerbehandlung

```typescript
async function safeFetch<T>(url: string): Promise<T> {
  try {
    const response = await fetch(url);

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || `HTTP ${response.status}`);
    }

    return response.json();
  } catch (e) {
    if (e.name === 'TypeError') {
      throw new Error('Netzwerkfehler. Bitte Internetverbindung prüfen.');
    }
    throw e;
  }
}
```

---

## Wichtige Hinweise

1. **Preise sind volatil** - Der Preis kann sich zwischen Abfrage und Überweisung ändern. Zeige dem Benutzer an, dass der angezeigte Preis eine Momentaufnahme ist.

2. **Nur CHF** - Der Brokerbot akzeptiert ausschliesslich CHF-Überweisungen.

3. **Allowlist erforderlich** - Ohne Allowlisting kann die Wallet keine REALU empfangen. Der Transfer würde on-chain fehlschlagen.

4. **REALU hat 0 Decimals** - Es gibt nur ganze Shares, keine Bruchteile.

---

*Dokumentation erstellt am: 2025-12-06*
