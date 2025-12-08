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

### Transaktions-Übersicht (mit Permit2)

| Schritt | Transaktionen | Wer zahlt Gas |
|---------|---------------|---------------|
| REALU approve | 1 TX (einmalig) | User |
| Brokerbot sell | 1 TX | User |
| ZCHF approve(Permit2) | 1 TX (einmalig) | User |
| ZCHF → DFX | **0 TX** | DFX (gasless) |

> **Vorteil:** Nach den einmaligen Approvals ist nur noch **1 User-Transaktion** (Brokerbot sell) nötig. Der ZCHF-Transfer an DFX ist **gasless**.

### Flow-Diagramm

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
      │  3. ZCHF → DFX (Permit2/Gasless)       │                    │
      │  (Client signiert off-chain)           │                    │
      │───────────────────▶│ permitTransferFrom │                    │
      │                    │───────────────────▶│                    │
      │◀───────────────────│                    │                    │
      │                    │                    │                    │
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

## Schritt 4: ZCHF an DFX verkaufen (Permit2/Gasless)

Nach dem Brokerbot-Swap hat der User ZCHF Tokens. Diese werden via **Permit2** gasless an DFX transferiert.

### Vorteile von Permit2

- **Gasless für User:** DFX zahlt die Gas-Gebühren für den ZCHF-Transfer
- **Einmaliges Approval:** Nach dem ersten Setup sind alle weiteren Transfers gasless
- **Sicher:** User signiert off-chain, behält volle Kontrolle

### API Endpoints

| Endpoint | Status | Beschreibung |
|----------|--------|--------------|
| `POST /sell` | ✅ Existiert | Erstellt Sell-Route |
| `PUT /sell/paymentInfos` | ✅ Existiert | Erstellt TransactionRequest für Permit2 |
| `PUT /sell/paymentInfos/:id/confirm` | ✅ Existiert | Führt Permit2-Transfer aus |

---

### Permit2 Implementierung

Der User signiert eine Nachricht off-chain. DFX führt den Token-Transfer aus und zahlt die Gas-Gebühren.

#### Voraussetzung: Einmaliges Permit2-Approval

Bevor Permit2 genutzt werden kann, muss der User einmalig den Permit2-Contract genehmigen:

```typescript
const PERMIT2_ADDRESS = '0x000000000022D473030F116dDEE9F6B43aC78BA3'; // Uniswap Permit2

// Einmalig: ZCHF für Permit2 genehmigen
async function approvePermit2(wallet: Wallet): Promise<string> {
  const zchfContract = new Contract(ZCHF_ADDRESS, ERC20_ABI, wallet);
  const tx = await zchfContract.approve(PERMIT2_ADDRESS, ethers.MaxUint256);
  return tx.hash;
}
```

#### Permit2-Flow

```
1. PUT /sell/paymentInfos        → TransactionRequest erstellen
2. User signiert Permit2-Message  → Off-chain (kein Gas!)
3. PUT /sell/paymentInfos/:id/confirm → DFX führt permitTransferFrom() aus
4. DFX zahlt CHF aufs Bankkonto
```

#### PermitDto Struktur

```typescript
interface PermitDto {
  address: string;                   // User-Wallet-Adresse
  signature: string;                 // EIP-712 Signatur
  signatureTransferContract: string; // Permit2 Contract Adresse
  permittedAmount: number;           // Max. erlaubter Betrag
  executorAddress: string;           // DFX DEX-Wallet
  nonce: number;                     // Permit2 Nonce
  deadline: string;                  // Gültigkeits-Timestamp (Unix)
}

interface ConfirmDto {
  permit: PermitDto;
}
```

#### Implementierung

```typescript
const API_BASE = 'https://api.dfx.swiss/v1';
const PERMIT2_ADDRESS = '0x000000000022D473030F116dDEE9F6B43aC78BA3';
const ZCHF_ADDRESS = '0xb58e61c3098d85632df34eecfb899a1ed80921cb';

// 1. PaymentInfo erstellen
interface SellPaymentInfoRequest {
  routeId: number;
  amount: number;          // ZCHF Betrag
  targetAmount?: number;   // Optional: CHF Zielbetrag
}

async function createPaymentInfo(
  accessToken: string,
  request: SellPaymentInfoRequest
): Promise<SellPaymentInfo> {
  const response = await fetch(`${API_BASE}/sell/paymentInfos`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(request),
  });
  return response.json();
}

// 2. Permit2-Signatur erstellen
async function createPermit2Signature(
  wallet: Wallet,
  params: {
    token: string;
    amount: bigint;
    spender: string;
    nonce: number;
    deadline: number;
  }
): Promise<string> {
  const domain = {
    name: 'Permit2',
    chainId: 1, // Ethereum Mainnet
    verifyingContract: PERMIT2_ADDRESS,
  };

  const types = {
    PermitTransferFrom: [
      { name: 'permitted', type: 'TokenPermissions' },
      { name: 'spender', type: 'address' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
    TokenPermissions: [
      { name: 'token', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
  };

  const message = {
    permitted: {
      token: params.token,
      amount: params.amount,
    },
    spender: params.spender,
    nonce: params.nonce,
    deadline: params.deadline,
  };

  return wallet.signTypedData(domain, types, message);
}

// 3. Nonce abrufen (vom Permit2 Contract)
async function getPermit2Nonce(
  provider: Provider,
  owner: string
): Promise<number> {
  const permit2 = new Contract(
    PERMIT2_ADDRESS,
    ['function nonceBitmap(address, uint256) view returns (uint256)'],
    provider
  );
  // Vereinfachte Nonce-Berechnung - für Produktion: freie Nonce finden
  return Date.now();
}

// 4. Gasless ZCHF-Transfer via Permit2
async function sendZchfWithPermit2(
  wallet: Wallet,
  accessToken: string,
  sellRouteId: number,
  amount: number,
  executorAddress: string
): Promise<void> {
  // 4.1 PaymentInfo erstellen
  const paymentInfo = await createPaymentInfo(accessToken, {
    routeId: sellRouteId,
    amount: amount,
  });

  // 4.2 Permit2 Parameter vorbereiten
  const amountWei = parseUnits(amount.toString(), 18);
  const nonce = await getPermit2Nonce(wallet.provider!, wallet.address);
  const deadline = Math.floor(Date.now() / 1000) + 1800; // 30 Minuten gültig

  // 4.3 Signatur erstellen (off-chain, kein Gas!)
  const signature = await createPermit2Signature(wallet, {
    token: ZCHF_ADDRESS,
    amount: amountWei,
    spender: executorAddress,
    nonce,
    deadline,
  });

  // 4.4 Confirm mit PermitDto senden
  const confirmDto: ConfirmDto = {
    permit: {
      address: wallet.address,
      signature,
      signatureTransferContract: PERMIT2_ADDRESS,
      permittedAmount: amount,
      executorAddress,
      nonce,
      deadline: deadline.toString(),
    },
  };

  const response = await fetch(
    `${API_BASE}/sell/paymentInfos/${paymentInfo.id}/confirm`,
    {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(confirmDto),
    }
  );

  if (!response.ok) {
    throw new Error('Permit2 Transfer fehlgeschlagen');
  }

  console.log('ZCHF erfolgreich an DFX transferiert (gasless)');
}
```

#### Executor-Adresse

Die `executorAddress` ist die DFX DEX-Wallet, die den `permitTransferFrom()` Call ausführt. Diese Adresse wird in der PaymentInfo-Response zurückgegeben oder kann über die API abgefragt werden.

#### Fehlerbehandlung

```typescript
const PERMIT2_ERRORS = {
  INVALID_SIGNATURE: 'Signatur ungültig oder abgelaufen',
  INVALID_EXECUTOR: 'Executor-Adresse stimmt nicht mit DFX-Wallet überein',
  INVALID_CONTRACT: 'SignatureTransferContract ist kein gültiger Permit2-Contract',
  DEADLINE_EXPIRED: 'Permit2 Deadline überschritten',
  NONCE_USED: 'Nonce wurde bereits verwendet',
  INSUFFICIENT_ALLOWANCE: 'Permit2 hat keine Genehmigung für ZCHF',
};
```

---

## Vollständiger Verkaufs-Flow

```typescript
async function sellRealu(
  shares: number,
  wallet: Wallet,
  accessToken: string,
  targetIban: string,
  executorAddress: string  // DFX DEX-Wallet
): Promise<void> {
  const API_BASE = 'https://api.dfx.swiss/v1';
  const REALUNIT_API = `${API_BASE}/realunit`;

  // 1. KYC-Level prüfen (MUSS zuerst erfolgen)
  const kyc = await fetch(`${API_BASE}/kyc`, {
    headers: { 'Authorization': `Bearer ${accessToken}` },
  }).then(r => r.json());

  if (kyc.kycLevel < 30) {
    throw new Error(
      `KYC Level ${kyc.kycLevel} nicht ausreichend. Mindestens Level 30 erforderlich.`
    );
  }

  // 2. ETH-Balance prüfen (nur für Brokerbot-TX nötig)
  const ethBalance = await wallet.provider!.getBalance(wallet.address);
  if (ethBalance < parseEther('0.001')) {
    await requestFaucet(accessToken);
    // Warten auf TX-Bestätigung...
  }

  // 3. Prüfen ob Verkauf aktiviert
  const info = await fetch(`${REALUNIT_API}/brokerbot/info`).then(r => r.json());
  if (!info.sellingEnabled) {
    throw new Error('Verkauf ist derzeit deaktiviert');
  }

  // 4. Verkaufspreis abrufen
  const sellPrice = await fetch(`${REALUNIT_API}/brokerbot/sellPrice?shares=${shares}`)
    .then(r => r.json());

  console.log(`Verkauf: ${shares} REALU für ${sellPrice.totalPrice} ZCHF`);

  // 5. REALU Approval für Brokerbot (falls nicht vorhanden)
  const realuContract = new Contract(REALU_ADDRESS, ERC20_ABI, wallet);
  const brokerbotAllowance = await realuContract.allowance(wallet.address, BROKERBOT_ADDRESS);
  if (brokerbotAllowance < BigInt(shares)) {
    const approveTx = await realuContract.approve(BROKERBOT_ADDRESS, ethers.MaxUint256);
    await approveTx.wait();
  }

  // 6. REALU → ZCHF Swap via Brokerbot (User zahlt Gas)
  const sellTxData = await prepareSellTx(shares, wallet.address);
  const swapTx = await wallet.sendTransaction(sellTxData);
  await swapTx.wait();

  // 7. Permit2 Approval prüfen (einmalig)
  const zchfContract = new Contract(ZCHF_ADDRESS, ERC20_ABI, wallet);
  const permit2Allowance = await zchfContract.allowance(wallet.address, PERMIT2_ADDRESS);
  if (permit2Allowance === 0n) {
    console.log('Einmaliges Permit2-Approval erforderlich...');
    const approveTx = await zchfContract.approve(PERMIT2_ADDRESS, ethers.MaxUint256);
    await approveTx.wait();
  }

  // 8. Sell-Route bei DFX erstellen
  const sellRoute = await createSellRoute(accessToken, {
    asset: 'ZCHF',
    blockchain: 'Ethereum',
    currency: 'CHF',
    iban: targetIban,
  });

  // 9. ZCHF an DFX senden via Permit2 (GASLESS!)
  const zchfAmount = parseFloat(sellPrice.totalPrice);
  await sendZchfWithPermit2(
    wallet,
    accessToken,
    sellRoute.routeId,
    zchfAmount,
    executorAddress
  );

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
| `PUT /sell/paymentInfos` | TransactionRequest für Permit2 erstellen |
| `PUT /sell/paymentInfos/:id/confirm` | Permit2-Transfer ausführen (gasless) |

### Geplante Endpoints (Brokerbot)

| Endpoint | Beschreibung |
|----------|--------------|
| `GET /brokerbot/sellPrice?shares=X` | Verkaufspreis für X Shares berechnen |
| `POST /brokerbot/sell` | Sell-TX Daten vorbereiten (Client signiert) |
| `GET /brokerbot/approval` | Prüft ob Approval für Brokerbot vorhanden |
| `POST /brokerbot/approve` | Approval-TX Daten vorbereiten |

---

## Wichtige Hinweise

1. **Gas-Gebühren nur für Brokerbot** - Der User braucht ETH nur für den Brokerbot-Swap. Der Faucet ist einmalig und nur für verifizierte Accounts (KYC 30+) verfügbar.

2. **Gasless ZCHF-Transfer** - Der ZCHF-Transfer an DFX erfolgt via Permit2 gasless. DFX übernimmt die Gas-Kosten.

3. **Einmalige Approvals** - Sowohl das REALU-Approval für den Brokerbot als auch das ZCHF-Approval für Permit2 sind einmalig. Bei folgenden Verkäufen ist nur noch die Brokerbot-Transaktion nötig.

4. **Client signiert** - Alle Transaktionen und Permit2-Signaturen werden vom Client erstellt. DFX speichert keine Private Keys.

5. **Preis sinkt bei Verkauf** - Der Brokerbot-Preis sinkt mit jedem Verkauf (dynamisches Preismodell).

6. **ZCHF-Liquidität** - Der Brokerbot muss genügend ZCHF haben, um den Verkauf zu bedienen.

7. **DFX Gebühren** - Für den ZCHF → CHF Verkauf fallen DFX-Gebühren an.

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
*Aktualisiert: 2025-12-08 (Permit2/Gasless Flow hinzugefügt)*
