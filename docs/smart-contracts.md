# RealUnit Smart Contracts - Dokumentation

Diese Dokumentation enthält alle Informationen über die Smart Contracts, die für RealUnit auf der Ethereum Blockchain eingesetzt werden.

> **Hinweis:** Alle Blockchain-Anfragen werden über die **DFX API** geroutet. Kein direkter RPC-Zugriff vom Client.

---

## Übersicht

| Contract | Adresse | Typ |
|----------|---------|-----|
| Brokerbot | `0xcff32c60b87296b8c0c12980de685bed6cb9dd6d` | Automated Market Maker |
| RealUnit Shares (REALU) | `0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B` | ERC-20 Token |

Beide Contracts wurden von **Aktionariat: Deployer** (`0x39e5351e6ce3c4b19b8b0a2f5c82c511782457be`) deployed.

---

## DFX API

Alle Blockchain-Anfragen werden über die DFX API geroutet:

| Umgebung | Base URL |
|----------|----------|
| **Development** | `https://dev.api.dfx.swiss/v1/realunit` |
| **Production** | `https://api.dfx.swiss/v1/realunit` |

### Verfügbare Endpoints

| Endpoint | Methode | Beschreibung |
|----------|---------|--------------|
| `/brokerbot/info` | GET | Brokerbot-Informationen (Adressen, Settings) |
| `/brokerbot/price` | GET | Aktueller Preis pro Share |
| `/brokerbot/buyPrice?shares=10` | GET | Gesamtkosten für X Shares |
| `/brokerbot/shares?amount=1000` | GET | Wie viele Shares für X CHF |
| `/allowlist/:address` | GET | Allowlist-Status einer Wallet |
| `/bank` | GET | Bankverbindung für Überweisungen |
| `/account/:address` | GET | Account-Informationen |
| `/account/:address/history` | GET | Transaktionshistorie |
| `/holders` | GET | Token-Holder Liste |
| `/price` | GET | Aktueller REALU Preis (CHF/EUR/USD) |
| `/price/history` | GET | Historische Preise |
| `/tokenInfo` | GET | Token-Informationen |

---

## 1. RealUnit Shares (REALU) Token

### Basis-Informationen

| Eigenschaft | Wert |
|-------------|------|
| **Contract-Adresse** | `0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B` |
| **Token Name** | RealUnit Shares |
| **Symbol** | REALU |
| **Contract-Typ** | AllowlistShares (ERC-20 basiert) |
| **Decimals** | 0 (repräsentiert ganze Anteile) |
| **Netzwerk** | Ethereum Mainnet |

### Allowlisting-System

Ein flexibles System für Transfer-Restriktionen:

| Kategorie | Beschreibung |
|-----------|--------------|
| **Allowlisted** | Können Tokens empfangen und nur an andere Allowlisted-Adressen senden |
| **Forbidden** | Können nur an Allowlisted senden, aber von niemandem empfangen |
| **Powerlisted** | Privilegierte Adressen, die Empfänger automatisch allowlisten können |

### Allowlist-Status prüfen (via DFX API)

```typescript
const API_BASE = 'https://api.dfx.swiss/v1/realunit';

interface AllowlistStatusResponse {
  address: string;
  canReceive: boolean;
  isForbidden: boolean;
  isPowerlisted: boolean;
}

async function checkAllowlist(address: string): Promise<AllowlistStatusResponse> {
  const response = await fetch(`${API_BASE}/allowlist/${address}`);
  return response.json();
}

// Beispiel
const status = await checkAllowlist('0x1234...');
if (!status.canReceive) {
  console.log('Wallet ist nicht allowlisted');
}
```

---

## 2. Brokerbot (Automated Market Maker)

### Basis-Informationen

| Eigenschaft | Wert |
|-------------|------|
| **Contract-Adresse** | `0xcff32c60b87296b8c0c12980de685bed6cb9dd6d` |
| **Name** | Brokerbot |
| **Typ** | Automated Market Maker (AMM) |
| **Base Currency** | Frankencoin ZCHF (`0xb58e61c3098d85632df34eecfb899a1ed80921cb`) |

### Brokerbot-Info abrufen (via DFX API)

```typescript
interface BrokerbotInfoResponse {
  brokerbotAddress: string;
  tokenAddress: string;
  baseCurrencyAddress: string;
  pricePerShare: string;
  buyingEnabled: boolean;
  sellingEnabled: boolean;
}

async function getBrokerbotInfo(): Promise<BrokerbotInfoResponse> {
  const response = await fetch(`${API_BASE}/brokerbot/info`);
  return response.json();
}

// Beispiel-Response:
// {
//   brokerbotAddress: "0xCFF32C60B87296B8c0c12980De685bEd6Cb9dD6d",
//   tokenAddress: "0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B",
//   baseCurrencyAddress: "0xb58e61c3098d85632df34eecfb899a1ed80921cb",
//   pricePerShare: "1.33",
//   buyingEnabled: true,
//   sellingEnabled: true
// }
```

### Preis-Funktionen (via DFX API)

```typescript
// Aktueller Preis pro Share
interface BrokerbotPriceResponse {
  pricePerShare: string;      // z.B. "1.33"
  pricePerShareRaw: string;   // Wei-Wert
}

async function getPrice(): Promise<BrokerbotPriceResponse> {
  const response = await fetch(`${API_BASE}/brokerbot/price`);
  return response.json();
}

// Gesamtkosten für X Shares
interface BrokerbotBuyPriceResponse {
  shares: number;
  totalPrice: string;         // z.B. "13.30"
  totalPriceRaw: string;
  pricePerShare: string;
}

async function getBuyPrice(shares: number): Promise<BrokerbotBuyPriceResponse> {
  const response = await fetch(`${API_BASE}/brokerbot/buyPrice?shares=${shares}`);
  return response.json();
}

// Wie viele Shares für X CHF?
interface BrokerbotSharesResponse {
  amount: string;
  shares: number;
  pricePerShare: string;
}

async function getShares(amountChf: string): Promise<BrokerbotSharesResponse> {
  const response = await fetch(`${API_BASE}/brokerbot/shares?amount=${amountChf}`);
  return response.json();
}
```

### Beispiel: Preis-Abfragen

```typescript
const API_BASE = 'https://api.dfx.swiss/v1/realunit';

// Aktuellen Preis abrufen
const price = await getPrice();
console.log(`Preis pro Share: ${price.pricePerShare} CHF`);

// Kosten für 10 Shares
const buyPrice = await getBuyPrice(10);
console.log(`Kosten für 10 Shares: ${buyPrice.totalPrice} CHF`);

// Wie viele Shares für 1000 CHF?
const shares = await getShares('1000');
console.log(`Shares für 1000 CHF: ${shares.shares}`);
```

---

## 3. Dynamisches Preismodell

Der Preis steigt mit jedem Kauf:

```
Neuer Preis = Aktueller Preis + (Anzahl Shares × Increment)
```

### Preisberechnung für mehrere Shares

Bei Kauf von N Shares:
```
Gesamtkosten = N × Startpreis + Increment × N × (N-1) / 2
```

Die DFX API (`/brokerbot/buyPrice`) berechnet dies automatisch.

---

## 4. Kauf per Banküberweisung

Der Brokerbot unterstützt neben Crypto-Zahlungen auch den Kauf per Banküberweisung.

### Bankverbindung abrufen (via DFX API)

```typescript
interface BankDetailsResponse {
  recipient: string;
  address: string;
  iban: string;
  bic: string;
  bankName: string;
  currency: string;
}

async function getBankDetails(): Promise<BankDetailsResponse> {
  const response = await fetch(`${API_BASE}/bank`);
  return response.json();
}

// Beispiel-Response:
// {
//   recipient: "RealUnit Schweiz AG",
//   address: "Schochenmühlestrasse 6, 6340 Baar, Switzerland",
//   iban: "CH22 0830 7000 5609 4630 9",
//   bic: "HYPLCH22XXX",
//   bankName: "Hypothekarbank Lenzburg",
//   currency: "CHF"
// }
```

### Kauf-Flow per Banküberweisung

```
┌─────────────────────────────────────────────────────────────────────────┐
│  1. Preis und Allowlist prüfen (via DFX API)                            │
│     - GET /brokerbot/buyPrice?shares=X                                  │
│     - GET /allowlist/{walletAddress}                                    │
│     - GET /bank                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  2. Order erstellen (via Aktionariat API)                               │
│     - Zahlungsreferenz erhalten (z.B. "REALU-752191")                   │
│     - API-Zugang bei Aktionariat erforderlich                           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  3. Banküberweisung (Off-Chain)                                         │
│     - Kunde überweist CHF mit Referenz                                  │
│     - Aktionariat/RealUnit matcht Zahlungseingang                       │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  4. On-Chain Settlement (durch Aktionariat)                             │
│     - notifyTradeAndTransfer() wird aufgerufen                          │
│     - REALU Shares werden an Kunden-Wallet transferiert                 │
└─────────────────────────────────────────────────────────────────────────┘
```

### Währung

**Nur CHF** - Der Brokerbot Smart Contract arbeitet ausschliesslich mit ZCHF (Frankencoin).

---

## 5. Account-Informationen

### Account-Daten abrufen (via DFX API)

```typescript
// Account-Übersicht
const account = await fetch(`${API_BASE}/account/0x1234...`);
const accountData = await account.json();

// Transaktionshistorie
const history = await fetch(`${API_BASE}/account/0x1234.../history`);
const historyData = await history.json();
```

### Token-Holder Liste

```typescript
const holders = await fetch(`${API_BASE}/holders`);
const holderData = await holders.json();
```

### Historische Preise

```typescript
// Aktueller Preis in CHF/EUR/USD
const price = await fetch(`${API_BASE}/price`);
const priceData = await price.json();

// Historische Preise
const history = await fetch(`${API_BASE}/price/history`);
const historyData = await history.json();
```

---

## 6. Zusammenhang der Contracts

```
┌─────────────────────────────────────────────────────────────────┐
│                         DFX API                                  │
│                  api.dfx.swiss/v1/realunit                       │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  │ Blockchain Calls
                                  ▼
┌───────────────────────────┐     ┌───────────────────────────────┐
│     REALU Token           │     │         Brokerbot              │
│     (ERC-20 Shares)       │◄────│     (Market Maker)             │
│                           │     │                                │
│ • Allowlist-basiert       │     │ • Handelt REALU gegen ZCHF     │
│ • Ganze Anteile (dec: 0)  │     │ • Dynamische Preise            │
│ • Transfer-Restriktionen  │     │ • Hält Liquidität              │
└───────────────────────────┘     └───────────────────────────────┘
                                              │
                                              │ trades against
                                              ▼
                                  ┌───────────────────────────────┐
                                  │     Frankencoin (ZCHF)         │
                                  │     0xb58e61c3...              │
                                  │                                │
                                  │ • CHF-Stablecoin               │
                                  │ • Zahlungsmittel               │
                                  └───────────────────────────────┘
```

---

## 7. Wichtige Hinweise

1. **Allowlisting erforderlich**
   - Wallet muss auf der REALU-Allowlist stehen
   - Prüfung via DFX API: `GET /allowlist/{address}`
   - Ohne Allowlisting schlägt der Transfer fehl

2. **Dynamische Preise**
   - Preis steigt/fällt mit jedem Trade
   - Immer `/brokerbot/buyPrice` vor dem Kauf prüfen

3. **Token Decimals**
   - ZCHF: 18 Decimals
   - REALU: 0 Decimals (ganze Zahlen)

4. **Nur CHF**
   - Smart Contract arbeitet nur mit ZCHF
   - Banküberweisung nur in CHF möglich

---

## Etherscan Links

- **REALU Token**: [Etherscan](https://etherscan.io/address/0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B)
- **Brokerbot**: [Etherscan](https://etherscan.io/address/0xcff32c60b87296b8c0c12980de685bed6cb9dd6d)
- **REALU Token Tracker**: [Etherscan Token](https://etherscan.io/token/0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B)

---

*Dokumentation erstellt am: 2025-12-05*
*Aktualisiert: 2025-12-06*
