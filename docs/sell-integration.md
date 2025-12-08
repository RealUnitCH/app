# Integration: REALU Token Verkauf

Dieses Dokument beschreibt die native Integration des REALU Token Verkaufs in der RealUnit App.

> **Hinweis:** Technische Details zu Smart Contracts siehe [smart-contracts.md](./smart-contracts.md)

---

## Übersicht

Der Verkauf von REALU Tokens erfolgt in vier Schritten:

1. **KYC-Status prüfen** - Mindestens Level 30 bei DFX erforderlich
2. **ETH für Gas beschaffen** (falls nicht vorhanden) - via Faucet
3. **REALU → ZCHF tauschen** - via Brokerbot Smart Contract
4. **ZCHF verkaufen** - via DFX Sell-Route → CHF aufs Bankkonto

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  RealUnit   │     │   DFX API   │     │  Brokerbot  │     │    Bank     │
│    App      │     │             │     │  (On-Chain) │     │   (CHF)     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                    │                    │                    │
      │  0. GET /kyc       │                    │                    │
      │───────────────────▶│                    │                    │
      │  (Level 30 check)  │                    │                    │
      │◀───────────────────│                    │                    │
      │                    │                    │                    │
      │  1. POST /faucet   │                    │                    │
      │───────────────────▶│  ETH senden        │                    │
      │                    │───────────────────▶│                    │
      │◀───────────────────│                    │                    │
      │                    │                    │                    │
      │  2. REALU → ZCHF   │                    │                    │
      │  (Client signiert) │                    │                    │
      │───────────────────────────────────────▶│                    │
      │◀───────────────────────────────────────│                    │
      │                    │                    │                    │
      │  3. ZCHF → DFX     │                    │                    │
      │───────────────────▶│                    │                    │
      │                    │  4. CHF Auszahlung │                    │
      │                    │───────────────────────────────────────▶│
      │                    │                    │                    │
```

---

## Schritt 1: KYC-Status prüfen

### Warum?

Der Verkauf von REALU Tokens erfordert einen verifizierten DFX-Account mit **mindestens KYC Level 30**. Dies ist eine regulatorische Anforderung.

Ohne KYC Level 30:
- Faucet-Anfragen werden abgelehnt
- Sell-Routen können nicht erstellt werden
- Auszahlungen auf Bankkonten sind nicht möglich

### API Endpoint

```
GET /kyc
Authorization: Bearer {jwt_token}
```

**Response:**
```typescript
interface KycStatusResponse {
  kycLevel: number;           // 0, 10, 20, 30, 40, 50
  kycStatus: string;          // "NotStarted", "InProgress", "Completed"
  tradingLimit: {
    annual: number;           // Jährliches Limit in CHF
    daily: number;            // Tägliches Limit in CHF
  };
}
```

### KYC Levels

| Level | Beschreibung | Verkauf möglich |
|-------|--------------|-----------------|
| 0-20 | Nicht verifiziert | ❌ Nein |
| 30 | Basis-Verifizierung (ID + Selfie) | ✅ Ja |
| 40+ | Erweiterte Verifizierung | ✅ Ja |

### Beispiel

```typescript
interface KycStatus {
  kycLevel: number;
  kycStatus: string;
}

async function checkKycLevel(accessToken: string): Promise<KycStatus> {
  const response = await fetch('https://api.dfx.swiss/v1/kyc', {
    headers: {
      'Authorization': `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    throw new Error('KYC-Status konnte nicht abgerufen werden');
  }

  return response.json();
}

async function validateKycForSell(accessToken: string): Promise<void> {
  const kyc = await checkKycLevel(accessToken);

  if (kyc.kycLevel < 30) {
    throw new Error(
      `KYC Level ${kyc.kycLevel} ist nicht ausreichend. ` +
      `Mindestens Level 30 erforderlich für den Verkauf.`
    );
  }
}
```

### UI-Hinweis

Falls der User noch nicht verifiziert ist, zeige einen Hinweis:

```tsx
function KycRequiredBanner({ kycLevel }: { kycLevel: number }) {
  if (kycLevel >= 30) return null;

  return (
    <Banner type="warning">
      <Text>
        Für den Verkauf von REALU ist eine Verifizierung erforderlich.
        Aktueller Status: Level {kycLevel}
      </Text>
      <Button onPress={() => openKycFlow()}>
        Jetzt verifizieren
      </Button>
    </Banner>
  );
}
```

### Status

| Endpoint | Status | Beschreibung |
|----------|--------|--------------|
| `GET /kyc` | ✅ Existiert | KYC-Status und Level abrufen |

---

## Schritt 2: ETH für Gas-Gebühren

### Problem

Der Brokerbot Smart Contract erfordert ETH für Gas-Gebühren. Neue Benutzer haben oft kein ETH.

### Lösung: Faucet Endpoint

DFX bietet einen Faucet-Endpoint, der einmalig ETH an verifizierte Benutzer sendet.

### Voraussetzungen

- Benutzer muss authentifiziert sein (JWT)
- KYC Level 30 (verifizierter Account)
- Faucet wurde noch nicht genutzt (einmalig pro Account)
- Ethereum Blockchain muss aktiviert sein

### API Endpoint

```
POST /faucet
Authorization: Bearer {jwt_token}
```

**Response:**
```typescript
interface FaucetResponse {
  txId: string;           // Ethereum Transaction Hash
  amount: number;         // ETH Betrag (ca. 5 CHF Gegenwert)
  asset: {
    name: string;         // "Ethereum"
    symbol: string;       // "ETH"
    blockchain: string;   // "Ethereum"
  };
}
```

### Status

| Endpoint | Status | Beschreibung |
|----------|--------|--------------|
| `POST /faucet` | ✅ Existiert | Sendet ETH für Gas-Gebühren |

### Beispiel

```typescript
async function requestFaucet(accessToken: string): Promise<FaucetResponse> {
  const response = await fetch('https://api.dfx.swiss/v1/faucet', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    const error = await response.json();
    // Mögliche Fehler:
    // - 400: "Faucet already used for this account"
    // - 400: "Faucet not available for this user"
    // - 403: "Account not verified" (KYC Level < 30)
    // - 503: "Faucet currently not available"
    throw new Error(error.message);
  }

  return response.json();
}
```

---

## Schritt 3: REALU → ZCHF tauschen

### Brokerbot Sell-Funktion

Der Brokerbot Smart Contract hat eine `sell()` Funktion, die REALU gegen ZCHF tauscht.

### Dynamisches Preismodell

Der Preis **sinkt** mit jedem Verkauf:

```
Neuer Preis = Aktueller Preis - (Anzahl Shares × Decrement)
```

### API Endpoints

| Endpoint | Status | Beschreibung |
|----------|--------|--------------|
| `GET /brokerbot/info` | ✅ Existiert | Prüft ob `sellingEnabled: true` |
| `GET /brokerbot/price` | ✅ Existiert | Aktueller Preis pro Share |
| `GET /brokerbot/sellPrice?shares=X` | 🔜 Geplant | Verkaufspreis für X Shares |
| `POST /brokerbot/sell` | 🔜 Geplant | Bereitet Sell-TX vor (Client signiert) |

### Geplante Sell-Price Response

```typescript
interface BrokerbotSellPriceDto {
  shares: number;           // Anzahl Shares
  totalPrice: string;       // Erlös in CHF (z.B. "132.50")
  totalPriceRaw: string;    // Erlös in Wei
  pricePerShare: string;    // Durchschnittspreis pro Share
}
```

### Geplante Sell-TX Vorbereitung

Der Client signiert die Transaktion selbst. Die DFX API liefert nur die Transaktionsdaten:

```typescript
// Request
interface BrokerbotSellRequest {
  shares: number;           // Anzahl zu verkaufender Shares
  walletAddress: string;    // Wallet des Verkäufers
}

// Response
interface BrokerbotSellTxDto {
  to: string;               // Brokerbot Contract Adresse
  data: string;             // Encoded Function Call
  value: string;            // "0" (kein ETH wird gesendet)
  gasLimit: string;         // Geschätztes Gas-Limit
  chainId: number;          // 1 (Ethereum Mainnet)
}
```

### Client-seitige Implementierung (geplant)

```typescript
const API_BASE = 'https://api.dfx.swiss/v1/realunit';

// 1. Prüfen ob Verkauf aktiviert ist
async function checkSellingEnabled(): Promise<boolean> {
  const info = await fetch(`${API_BASE}/brokerbot/info`);
  const data = await info.json();
  return data.sellingEnabled;
}

// 2. Verkaufspreis abrufen
async function getSellPrice(shares: number): Promise<BrokerbotSellPriceDto> {
  const response = await fetch(`${API_BASE}/brokerbot/sellPrice?shares=${shares}`);
  return response.json();
}

// 3. Sell-Transaktion vorbereiten
async function prepareSellTx(shares: number, walletAddress: string): Promise<BrokerbotSellTxDto> {
  const response = await fetch(`${API_BASE}/brokerbot/sell`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ shares, walletAddress }),
  });
  return response.json();
}

// 4. Client signiert und sendet TX
async function executeSell(shares: number, wallet: Wallet): Promise<string> {
  const txData = await prepareSellTx(shares, wallet.address);

  const tx = await wallet.sendTransaction({
    to: txData.to,
    data: txData.data,
    value: txData.value,
    gasLimit: txData.gasLimit,
  });

  return tx.hash;
}
```

### Smart Contract Details

**Brokerbot `sell()` Funktion:**
- Prüft ob `SELLING_ENABLED` aktiv ist
- Berechnet Verkaufspreis via `getSellPrice(shares)`
- Transferiert ZCHF an den Verkäufer
- Aktualisiert den Preis (sinkt)

**Voraussetzungen:**
- User muss REALU Tokens besitzen
- User muss Brokerbot Approval geben (ERC-20 `approve`)
- Genügend ZCHF-Liquidität im Brokerbot

---

## Schritt 4: ZCHF an DFX verkaufen

Nach dem Brokerbot-Swap hat der User ZCHF Tokens. Diese werden an DFX verkauft für CHF Auszahlung.

### Flow

1. Sell-Route bei DFX erstellen
2. ZCHF an DFX Deposit-Adresse senden
3. DFX zahlt CHF aufs Bankkonto

### API Endpoints

| Endpoint | Status | Beschreibung |
|----------|--------|--------------|
| `POST /sell` | ✅ Existiert | Erstellt Sell-Route |
| `GET /sell/{routeId}` | ✅ Existiert | Deposit-Adresse abrufen |

### Implementierung

```typescript
// 1. Sell-Route erstellen (via DFX Services oder API)
interface CreateSellRouteRequest {
  asset: string;            // "ZCHF"
  blockchain: string;       // "Ethereum"
  currency: string;         // "CHF"
  iban: string;             // Ziel-IBAN für Auszahlung
}

interface CreateSellRouteResponse {
  routeId: string;
  depositAddress: string;   // DFX-verwaltete Adresse
  minDeposit: string;       // Minimum ZCHF
  fee: string;              // DFX Gebühr in %
}

// 2. ZCHF an Deposit-Adresse senden
async function sendZchfToDfx(
  wallet: Wallet,
  depositAddress: string,
  amount: string
): Promise<string> {
  const zchfContract = new Contract(ZCHF_ADDRESS, ERC20_ABI, wallet);
  const tx = await zchfContract.transfer(depositAddress, parseUnits(amount, 18));
  return tx.hash;
}
```

---

## Vollständiger Verkaufs-Flow

```typescript
async function sellRealu(
  shares: number,
  wallet: Wallet,
  accessToken: string,
  targetIban: string
): Promise<void> {
  const API_BASE = 'https://api.dfx.swiss/v1/realunit';

  // 1. KYC-Level prüfen (MUSS zuerst erfolgen)
  const kyc = await fetch('https://api.dfx.swiss/v1/kyc', {
    headers: { 'Authorization': `Bearer ${accessToken}` },
  }).then(r => r.json());

  if (kyc.kycLevel < 30) {
    throw new Error(
      `KYC Level ${kyc.kycLevel} nicht ausreichend. Mindestens Level 30 erforderlich.`
    );
  }

  // 2. ETH-Balance prüfen
  const ethBalance = await wallet.getBalance();
  if (ethBalance.lt(parseEther('0.001'))) {
    // Faucet nutzen (nur möglich mit KYC Level 30+)
    await requestFaucet(accessToken);
    // Warten auf TX-Bestätigung...
  }

  // 3. Prüfen ob Verkauf aktiviert
  const info = await fetch(`${API_BASE}/brokerbot/info`).then(r => r.json());
  if (!info.sellingEnabled) {
    throw new Error('Verkauf ist derzeit deaktiviert');
  }

  // 4. Verkaufspreis abrufen
  const sellPrice = await fetch(`${API_BASE}/brokerbot/sellPrice?shares=${shares}`)
    .then(r => r.json());

  console.log(`Verkauf: ${shares} REALU für ${sellPrice.totalPrice} ZCHF`);

  // 5. REALU Approval für Brokerbot (falls nicht vorhanden)
  const realuContract = new Contract(REALU_ADDRESS, ERC20_ABI, wallet);
  const allowance = await realuContract.allowance(wallet.address, BROKERBOT_ADDRESS);
  if (allowance.lt(shares)) {
    const approveTx = await realuContract.approve(BROKERBOT_ADDRESS, shares);
    await approveTx.wait();
  }

  // 6. REALU → ZCHF Swap via Brokerbot
  const sellTx = await prepareSellTx(shares, wallet.address);
  const swapTx = await wallet.sendTransaction(sellTx);
  await swapTx.wait();

  // 7. Sell-Route bei DFX erstellen
  const sellRoute = await createSellRoute({
    asset: 'ZCHF',
    blockchain: 'Ethereum',
    currency: 'CHF',
    iban: targetIban,
  });

  // 8. ZCHF an DFX senden
  const zchfContract = new Contract(ZCHF_ADDRESS, ERC20_ABI, wallet);
  const transferTx = await zchfContract.transfer(
    sellRoute.depositAddress,
    parseUnits(sellPrice.totalPrice, 18)
  );
  await transferTx.wait();

  console.log('Verkauf abgeschlossen. CHF wird auf Bankkonto überwiesen.');
}
```

---

## API Status Übersicht

### Existierende Endpoints

| Endpoint | Beschreibung |
|----------|--------------|
| `GET /kyc` | KYC-Status und Level prüfen (authentifiziert) |
| `POST /faucet` | ETH für Gas-Gebühren (authentifiziert, KYC 30) |
| `GET /brokerbot/info` | Brokerbot-Status inkl. `sellingEnabled` |
| `GET /brokerbot/price` | Aktueller Preis pro Share |
| `POST /sell` | DFX Sell-Route erstellen |
| `GET /sell/{routeId}` | Deposit-Adresse abrufen |

### Geplante Endpoints

| Endpoint | Beschreibung |
|----------|--------------|
| `GET /brokerbot/sellPrice?shares=X` | Verkaufspreis für X Shares berechnen |
| `POST /brokerbot/sell` | Sell-TX Daten vorbereiten (Client signiert) |
| `GET /brokerbot/approval` | Prüft ob Approval für Brokerbot vorhanden |
| `POST /brokerbot/approve` | Approval-TX Daten vorbereiten |

---

## Wichtige Hinweise

1. **Gas-Gebühren erforderlich** - Der User braucht ETH für die Blockchain-Transaktionen. Der Faucet ist einmalig und nur für verifizierte Accounts verfügbar.

2. **Zwei Transaktionen nötig** - Für den Verkauf sind mindestens zwei Transaktionen erforderlich:
   - Approval (falls nicht vorhanden)
   - Sell-Transaktion

3. **Client signiert** - Alle Transaktionen werden vom Client signiert. DFX speichert keine Private Keys.

4. **Preis sinkt bei Verkauf** - Der Brokerbot-Preis sinkt mit jedem Verkauf (dynamisches Preismodell).

5. **ZCHF-Liquidität** - Der Brokerbot muss genügend ZCHF haben, um den Verkauf zu bedienen.

6. **DFX Gebühren** - Für den ZCHF → CHF Verkauf fallen DFX-Gebühren an.

---

## Fehlerbehandlung

```typescript
// Mögliche Fehler beim Verkauf
const SELL_ERRORS = {
  // Schritt 1: KYC
  KYC_LEVEL_INSUFFICIENT: 'KYC Level nicht ausreichend. Mindestens Level 30 erforderlich.',
  KYC_CHECK_FAILED: 'KYC-Status konnte nicht abgerufen werden',

  // Schritt 2: Faucet
  FAUCET_USED: 'Faucet wurde bereits genutzt',
  FAUCET_NOT_AVAILABLE: 'Faucet derzeit nicht verfügbar',

  // Schritt 3: Brokerbot
  SELLING_DISABLED: 'Verkauf ist derzeit deaktiviert',
  INSUFFICIENT_BALANCE: 'Nicht genügend REALU Tokens',
  INSUFFICIENT_ETH: 'Nicht genügend ETH für Gas-Gebühren',
  INSUFFICIENT_LIQUIDITY: 'Nicht genügend ZCHF-Liquidität im Brokerbot',
  APPROVAL_REQUIRED: 'Approval für Brokerbot erforderlich',

  // Schritt 4: DFX Sell
  SELL_ROUTE_FAILED: 'Sell-Route konnte nicht erstellt werden',
  TRANSFER_FAILED: 'ZCHF-Transfer fehlgeschlagen',
};
```

---

*Dokumentation erstellt am: 2025-12-06*
