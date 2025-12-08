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
| REALU approve | 1 TX (einmalig) | User signiert, DFX broadcastet |
| ZCHF approve(Permit2) | 1 TX (einmalig) | User signiert, DFX broadcastet |
| Brokerbot sell + ZCHF → DFX | **1 API Call** | DFX broadcastet alles |

> **Vorteil:** Nach den einmaligen Approvals braucht der User nur noch **Signaturen** - kein Broadcasting nötig. Alles läuft über die DFX API.

### Flow-Diagramm

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  RealUnit   │     │   DFX API   │     │  Blockchain │     │    Bank     │
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
      │  2. POST /realunit/sell                 │                    │
      │  (signedTx + Permit2 Signatur)          │                    │
      │───────────────────▶│                    │                    │
      │                    │  2a. Brokerbot TX  │                    │
      │                    │     broadcasten    │                    │
      │                    │───────────────────▶│                    │
      │                    │◀───────────────────│                    │
      │                    │                    │                    │
      │                    │  2b. permitTransfer│                    │
      │                    │      From()        │                    │
      │                    │───────────────────▶│                    │
      │                    │◀───────────────────│                    │
      │◀───────────────────│                    │                    │
      │                    │                    │                    │
      │                    │  3. CHF Auszahlung │                    │
      │                    │───────────────────────────────────────▶│
      │                    │                    │                    │
```

> **Wichtig:** Die RealUnit App broadcastet keine Transaktionen selbst. Alle signierten Transaktionen werden an die DFX API übergeben, die das Broadcasting übernimmt.

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

## Atomarer Sell-Endpoint: POST /realunit/sell

Der zentrale Endpoint für den REALU-Verkauf. Die RealUnit App kann keine Transaktionen selbst broadcasten - alles läuft über diesen Endpoint.

### Konzept

Der User:
1. Signiert die Brokerbot-Sell-Transaktion (off-chain)
2. Signiert die Permit2-Message für den ZCHF-Transfer (off-chain)
3. Sendet beides in **einem API-Call** an DFX

DFX:
1. Validiert beide Signaturen
2. Prüft ob Permit2-Betrag mit erwartetem Brokerbot-Output übereinstimmt
3. Broadcastet die Brokerbot-TX
4. Führt `permitTransferFrom()` aus
5. Initiiert CHF-Auszahlung

### API Endpoint

```
POST /realunit/sell
Authorization: Bearer {jwt_token}
```

### Request Body

```typescript
interface RealUnitSellRequest {
  // Signierte Brokerbot Sell TX (vom User signiert, nicht broadcastet)
  signedTransaction: string;  // Hex-encoded signed TX

  // Permit2 Signatur für ZCHF Transfer
  permit: {
    address: string;                   // User-Wallet
    signature: string;                 // Permit2 Signatur
    signatureTransferContract: string; // Permit2 Contract
    permittedAmount: string;           // Muss mit Brokerbot Output matchen!
    executorAddress: string;           // DFX DEX-Wallet
    nonce: number;
    deadline: string;
  };

  // Sell-Route für CHF Auszahlung
  sellRouteId: number;
}
```

### DFX Validierung

| Prüfung | Beschreibung |
|---------|--------------|
| TX Ziel-Adresse | Muss Brokerbot `0xcff32c60...` sein |
| TX Method | Muss gültiger Brokerbot-Call sein |
| TX Sender | Muss mit `permit.address` übereinstimmen |
| ZCHF Output | Berechnen via `getSellPrice(shares)` |
| Permit Amount | Muss **exakt** dem erwarteten ZCHF Output entsprechen |
| Permit Deadline | Muss in der Zukunft liegen |
| Permit Nonce | Muss unverbraucht sein |
| Allowlist | User muss REALU-allowlisted sein |
| Sell-Route | Muss existieren und zum User gehören |

### Response

```typescript
interface RealUnitSellResponse {
  id: string;                    // Transaction ID
  status: 'pending' | 'processing' | 'completed' | 'failed';
  brokerbotTxHash: string;       // Brokerbot TX Hash
  permitTxHash?: string;         // Permit2 TX Hash (wenn ausgeführt)
  realuSold: number;             // Verkaufte REALU
  zchfReceived: string;          // Erhaltene ZCHF
  estimatedChfPayout: string;    // Geschätzte CHF Auszahlung
}
```

### DFX Execution Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. Validierung                                                  │
│     - Decode signedTransaction                                   │
│     - Prüfe Brokerbot-Call (Adresse, Method, Shares)            │
│     - Berechne erwarteten ZCHF Output                           │
│     - Prüfe Permit2: Amount == ZCHF Output?                     │
│     - Prüfe Permit2: Signatur gültig?                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ Alles OK
┌─────────────────────────────────────────────────────────────────┐
│  2. Broadcast Brokerbot TX                                       │
│     - eth_sendRawTransaction(signedTransaction)                  │
│     - Warte auf Confirmation                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ TX Confirmed
┌─────────────────────────────────────────────────────────────────┐
│  3. Execute Permit2 Transfer                                     │
│     - permitTransferFrom(permit)                                 │
│     - ZCHF → DFX Deposit Wallet                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. CHF Auszahlung initiieren                                    │
│     - Über bestehenden Sell-Flow                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Error Codes

```typescript
type RealUnitSellError =
  | 'INVALID_TRANSACTION'        // TX nicht decodierbar
  | 'WRONG_CONTRACT'             // Nicht Brokerbot-Adresse
  | 'WRONG_METHOD'               // Kein gültiger Brokerbot-Call
  | 'ADDRESS_MISMATCH'           // TX Sender ≠ Permit Address
  | 'AMOUNT_MISMATCH'            // Permit Amount ≠ erwarteter ZCHF Output
  | 'PERMIT_EXPIRED'             // Deadline überschritten
  | 'PERMIT_INVALID'             // Signatur ungültig
  | 'NONCE_USED'                 // Permit2 Nonce bereits verbraucht
  | 'INSUFFICIENT_REALU'         // User hat nicht genug REALU
  | 'NOT_ALLOWLISTED'            // User nicht auf REALU-Allowlist
  | 'SELLING_DISABLED'           // Brokerbot Verkauf deaktiviert
  | 'INSUFFICIENT_LIQUIDITY'     // Nicht genug ZCHF im Brokerbot
  | 'BROADCAST_FAILED'           // TX Broadcast fehlgeschlagen
  | 'PERMIT_EXECUTION_FAILED'    // Permit2 Transfer fehlgeschlagen
  | 'SELL_ROUTE_INVALID';        // Sell-Route existiert nicht
```

### Wichtig: Permit2-Signatur vor Brokerbot-TX

Die Permit2-Signatur kann **vor** der Brokerbot-Transaktion erstellt werden, da:
- Die Signatur nur eine off-chain Autorisierung ist
- Die Balance-Prüfung erst bei `permitTransferFrom()` erfolgt
- Der User den erwarteten ZCHF-Betrag via `getSellPrice()` vorab kennt

Dies ermöglicht einen optimalen UX-Flow: User signiert alles in einem Schritt.

---

## Vollständiger Verkaufs-Flow

```typescript
async function sellRealu(
  shares: number,
  wallet: Wallet,
  accessToken: string,
  sellRouteId: number,
  executorAddress: string  // DFX DEX-Wallet
): Promise<RealUnitSellResponse> {
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

  // 2. Prüfen ob Verkauf aktiviert
  const info = await fetch(`${REALUNIT_API}/brokerbot/info`).then(r => r.json());
  if (!info.sellingEnabled) {
    throw new Error('Verkauf ist derzeit deaktiviert');
  }

  // 3. Verkaufspreis abrufen (für Permit2-Betrag)
  const sellPrice = await fetch(`${REALUNIT_API}/brokerbot/sellPrice?shares=${shares}`)
    .then(r => r.json());

  console.log(`Verkauf: ${shares} REALU für ${sellPrice.totalPrice} ZCHF`);

  // 4. Brokerbot Sell-TX vorbereiten (NICHT broadcasten!)
  const sellTxData = await fetch(`${REALUNIT_API}/brokerbot/sell`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ shares, walletAddress: wallet.address }),
  }).then(r => r.json());

  // 5. TX signieren (NICHT senden!)
  const signedTransaction = await wallet.signTransaction({
    to: sellTxData.to,
    data: sellTxData.data,
    value: sellTxData.value,
    gasLimit: sellTxData.gasLimit,
    chainId: sellTxData.chainId,
    nonce: await wallet.getNonce(),
  });

  // 6. Permit2-Signatur erstellen (off-chain, kein Gas!)
  const zchfAmountWei = parseUnits(sellPrice.totalPrice, 18);
  const nonce = await getPermit2Nonce(wallet.provider!, wallet.address);
  const deadline = Math.floor(Date.now() / 1000) + 1800; // 30 min

  const permitSignature = await createPermit2Signature(wallet, {
    token: ZCHF_ADDRESS,
    amount: zchfAmountWei,
    spender: executorAddress,
    nonce,
    deadline,
  });

  // 7. Alles an DFX API senden (EIN Call!)
  const response = await fetch(`${REALUNIT_API}/sell`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      signedTransaction,
      permit: {
        address: wallet.address,
        signature: permitSignature,
        signatureTransferContract: PERMIT2_ADDRESS,
        permittedAmount: sellPrice.totalPrice,
        executorAddress,
        nonce,
        deadline: deadline.toString(),
      },
      sellRouteId,
    }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Verkauf fehlgeschlagen: ${error.message}`);
  }

  const result: RealUnitSellResponse = await response.json();
  console.log(`Verkauf initiiert. TX: ${result.brokerbotTxHash}`);
  console.log(`CHF Auszahlung: ~${result.estimatedChfPayout} CHF`);

  return result;
}
```

---

## API Status Übersicht

### Existierende Endpoints

| Endpoint | Beschreibung |
|----------|--------------|
| `GET /kyc` | KYC-Status und Level prüfen (authentifiziert) |
| `POST /faucet` | ETH für Gas-Gebühren (authentifiziert, KYC 30) |
| `GET /realunit/brokerbot/info` | Brokerbot-Status inkl. `sellingEnabled` |
| `GET /realunit/brokerbot/price` | Aktueller Preis pro Share |
| `POST /sell` | DFX Sell-Route erstellen |
| `GET /sell/{routeId}` | Deposit-Adresse abrufen |
| `PUT /sell/paymentInfos` | TransactionRequest für Permit2 erstellen |
| `PUT /sell/paymentInfos/:id/confirm` | Permit2-Transfer ausführen (gasless) |

### Geplante Endpoints (RealUnit)

| Endpoint | Priorität | Beschreibung |
|----------|-----------|--------------|
| `POST /realunit/sell` | **P0** | Atomarer Sell-Endpoint (signedTx + Permit2) |
| `GET /realunit/brokerbot/sellPrice?shares=X` | P1 | Verkaufspreis für X Shares berechnen |
| `POST /realunit/brokerbot/prepareSell` | P1 | Sell-TX Daten vorbereiten (Client signiert) |
| `GET /realunit/brokerbot/approval` | P2 | Prüft ob Approval für Brokerbot vorhanden |
| `POST /realunit/brokerbot/prepareApproval` | P2 | Approval-TX Daten vorbereiten |

---

## Wichtige Hinweise

1. **Kein Broadcasting durch die App** - Die RealUnit App broadcastet keine Transaktionen selbst. Alle signierten Transaktionen werden an die DFX API übergeben.

2. **Atomarer Sell-Endpoint** - Der `POST /realunit/sell` Endpoint nimmt die signierte Brokerbot-TX und die Permit2-Signatur in einem Call entgegen. DFX validiert alles und führt beide Operationen aus.

3. **Gas-Gebühren** - DFX zahlt alle Gas-Gebühren (Brokerbot-Broadcast + Permit2 Transfer). Der Faucet ist nur für einmalige Approvals nötig.

4. **Einmalige Approvals** - REALU-Approval für Brokerbot und ZCHF-Approval für Permit2 sind einmalig. Diese TXs werden ebenfalls über die DFX API signiert und broadcastet.

5. **Client signiert nur** - Der Client signiert Transaktionen und Permit2-Messages, aber sendet nie direkt an die Blockchain. DFX speichert keine Private Keys.

6. **Permit2 vor Brokerbot-TX** - Die Permit2-Signatur kann erstellt werden bevor der User die ZCHF-Balance hat. Der Betrag muss aber exakt dem erwarteten Brokerbot-Output entsprechen.

7. **Preis sinkt bei Verkauf** - Der Brokerbot-Preis sinkt mit jedem Verkauf (dynamisches Preismodell).

8. **ZCHF-Liquidität** - Der Brokerbot muss genügend ZCHF haben, um den Verkauf zu bedienen.

9. **DFX Gebühren** - Für den ZCHF → CHF Verkauf fallen DFX-Gebühren an.

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
*Aktualisiert: 2025-12-08 (Atomarer POST /realunit/sell Endpoint hinzugefügt)*
