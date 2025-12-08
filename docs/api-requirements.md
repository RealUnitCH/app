# DFX API Anforderungen für REALU Verkauf

Dieses Dokument beschreibt die fehlenden API-Endpoints, die für die native Integration des REALU Token Verkaufs in der RealUnit App benötigt werden.

---

## Inhaltsverzeichnis

1. [Übersicht](#übersicht)
2. [Aktuelle Situation](#aktuelle-situation)
3. [Fehlende Endpoints](#fehlende-endpoints)
   - [3.1 GET /brokerbot/sellPrice](#31-get-brokerbotSellPrice)
   - [3.2 POST /brokerbot/sell](#32-post-brokerbotSell)
   - [3.3 GET /brokerbot/approval](#33-get-brokerbotApproval)
   - [3.4 POST /brokerbot/approve](#34-post-brokerbotApprove)
   - [3.5 GET /balance/:address](#35-get-balanceaddress)
   - [3.6 POST /transaction/send](#36-post-transactionSend)
4. [Architektur-Entscheidung: Client-signierte Transaktionen](#architektur-entscheidung)
5. [Prioritäten](#prioritäten)
6. [Zusammenfassung](#zusammenfassung)

---

## 1. Übersicht

Die RealUnit App soll den Verkauf von REALU Tokens **nativ** integrieren - ohne Umweg über externe WebViews oder das Aktionariat Widget.

Der Verkaufs-Flow besteht aus vier Schritten:

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Schritt 1: KYC prüfen                                                    │
│  ✅ GET /kyc existiert                                                    │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  Schritt 2: ETH für Gas beschaffen                                        │
│  ✅ POST /faucet existiert                                                │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  Schritt 3: REALU → ZCHF tauschen (Brokerbot)                             │
│  ❌ Mehrere Endpoints fehlen                                              │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  Schritt 4: ZCHF → CHF (DFX Sell)                                         │
│  ✅ POST /sell existiert                                                  │
│  ❌ Transfer-Endpoint fehlt                                               │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Aktuelle Situation

### Existierende Endpoints (RealUnit-spezifisch)

| Endpoint | Methode | Beschreibung | Smart Contract Call |
|----------|---------|--------------|---------------------|
| `/realunit/brokerbot/info` | GET | Brokerbot-Konfiguration | `settings()` |
| `/realunit/brokerbot/price` | GET | Aktueller Preis | `getPrice()` |
| `/realunit/brokerbot/buyPrice` | GET | Kaufpreis berechnen | `getBuyPrice(shares)` |
| `/realunit/brokerbot/shares` | GET | Shares für CHF berechnen | `getShares(amount)` |
| `/realunit/allowlist/:address` | GET | Allowlist-Status | `canReceiveFromAnyone()` |
| `/realunit/bank` | GET | Bankverbindung | - (Config) |

### Existierende Endpoints (DFX Core)

| Endpoint | Methode | Beschreibung |
|----------|---------|--------------|
| `/kyc` | GET | KYC-Status abrufen |
| `/faucet` | POST | ETH für Gas anfordern |
| `/sell` | POST | Sell-Route erstellen |
| `/sell/:routeId` | GET | Deposit-Adresse abrufen |

### Was fehlt

Der Brokerbot Smart Contract hat eine `sell()` Funktion und eine `getSellPrice()` Funktion, die aktuell **nicht über die DFX API exponiert** sind:

```solidity
// Existiert auf dem Smart Contract, aber NICHT in der API
function getSellPrice(uint256 shares) public view returns (uint256)
function sell(address token, uint256 amount, bytes calldata ref) external
```

Ausserdem fehlen Endpoints für:
- ERC-20 Token Approvals prüfen/vorbereiten
- Token-Balances abfragen
- Transaktionen vorbereiten (für Client-Signatur)

---

## 3. Fehlende Endpoints

### 3.1 GET /brokerbot/sellPrice

#### Warum wird dieser Endpoint benötigt?

Der Brokerbot verwendet ein **dynamisches Preismodell**. Der Preis sinkt mit jedem Verkauf:

```
Erlös = Summe(Preis_i) für i = 1 bis n
      = n × Aktueller_Preis - Decrement × n × (n-1) / 2
```

**Ohne diesen Endpoint:**
- Die App kann dem Benutzer nicht anzeigen, wie viel ZCHF er für seine REALU erhält
- Jede App müsste diese Berechnung selbst implementieren (Fehlerquelle)
- Direkter Alchemy/RPC-Zugriff wäre nötig (widerspricht der Architektur)

**Mit diesem Endpoint:**
- Konsistente Preisberechnung
- Keine direkte Blockchain-Kommunikation vom Client
- DFX kann Caching/Rate-Limiting implementieren

#### Spezifikation

```
GET /realunit/brokerbot/sellPrice?shares={number}
```

**Query Parameter:**
| Parameter | Typ | Required | Beschreibung |
|-----------|-----|----------|--------------|
| shares | number | Ja | Anzahl der zu verkaufenden REALU Shares |

**Response:**
```typescript
interface BrokerbotSellPriceDto {
  shares: number;           // Anzahl Shares (Echo)
  totalPrice: string;       // Erlös in ZCHF (z.B. "132.50")
  totalPriceRaw: string;    // Erlös in Wei (z.B. "132500000000000000000")
  pricePerShare: string;    // Aktueller Preis pro Share
  priceImpact: string;      // Preisänderung durch diesen Verkauf in %
}
```

**Beispiel:**
```bash
GET /realunit/brokerbot/sellPrice?shares=100

{
  "shares": 100,
  "totalPrice": "132.50",
  "totalPriceRaw": "132500000000000000000",
  "pricePerShare": "1.33",
  "priceImpact": "-0.075"
}
```

#### Implementation (Backend)

```typescript
// Erweiterung für realunit-blockchain.service.ts

const BROKERBOT_ABI_EXTENDED = [
  ...BROKERBOT_ABI,
  'function getSellPrice(uint256 shares) public view returns (uint256)',
];

async getBrokerbotSellPrice(shares: number): Promise<BrokerbotSellPriceDto> {
  const contract = this.getBrokerbotContract();
  const [totalPriceRaw, pricePerShareRaw] = await Promise.all([
    contract.getSellPrice(shares),
    contract.getPrice(),
  ]);

  const totalPrice = EvmUtil.fromWeiAmount(totalPriceRaw);
  const pricePerShare = EvmUtil.fromWeiAmount(pricePerShareRaw);

  // Preisänderung berechnen (Decrement × shares / aktueller Preis)
  const priceAfterSale = totalPrice / shares;
  const priceImpact = ((priceAfterSale - pricePerShare) / pricePerShare * 100);

  return {
    shares,
    totalPrice: totalPrice.toString(),
    totalPriceRaw: totalPriceRaw.toString(),
    pricePerShare: pricePerShare.toString(),
    priceImpact: priceImpact.toFixed(3),
  };
}
```

---

### 3.2 POST /brokerbot/sell

#### Warum wird dieser Endpoint benötigt?

Der Client muss eine Transaktion an den Brokerbot Smart Contract senden, um REALU gegen ZCHF zu tauschen.

**Architektur-Entscheidung:** Der Client signiert die Transaktion selbst. Die DFX API bereitet nur die Transaktionsdaten vor.

**Warum diese Architektur?**
1. **Sicherheit:** DFX speichert keine Private Keys der Benutzer
2. **Self-Custody:** Benutzer behalten volle Kontrolle über ihre Wallets
3. **Compliance:** Keine Verwahrung von Kundengeldern durch DFX
4. **Transparenz:** Benutzer sehen und bestätigen jede Transaktion

**Ohne diesen Endpoint:**
- Die App müsste den ABI kennen und den Function Call selbst encodieren
- Fehleranfällig (falsche Parameter, veralteter ABI)
- Kein zentrales Gas-Estimation
- Kein Logging/Monitoring auf DFX-Seite

**Mit diesem Endpoint:**
- DFX kontrolliert den ABI und die Encoding-Logik
- Zentrale Gas-Estimation (kann optimiert werden)
- Validierung der Parameter vor dem Senden
- Logging für Support-Fälle

#### Spezifikation

```
POST /realunit/brokerbot/sell
Content-Type: application/json
```

**Request Body:**
```typescript
interface BrokerbotSellRequest {
  shares: number;           // Anzahl zu verkaufender Shares
  walletAddress: string;    // Wallet-Adresse des Verkäufers
  minPrice?: string;        // Optional: Minimaler akzeptierter Preis (Slippage-Schutz)
}
```

**Response:**
```typescript
interface BrokerbotSellTxDto {
  // Transaktionsdaten (für wallet.sendTransaction)
  to: string;               // Brokerbot Contract Adresse
  data: string;             // Encoded Function Call (hex)
  value: string;            // "0" (kein ETH wird gesendet)

  // Gas-Estimation
  gasLimit: string;         // Geschätztes Gas-Limit
  gasPrice?: string;        // Optional: Aktueller Gas-Preis
  maxFeePerGas?: string;    // Optional: EIP-1559 max fee
  maxPriorityFeePerGas?: string; // Optional: EIP-1559 priority fee

  // Metadaten
  chainId: number;          // 1 (Ethereum Mainnet)
  nonce?: number;           // Optional: Nonce für die Transaktion

  // Validierung
  expectedShares: number;   // Zur Validierung auf Client-Seite
  expectedPrice: string;    // Erwarteter Erlös in ZCHF
  expiresAt: string;        // ISO Timestamp - TX-Daten sind nur begrenzt gültig
}
```

**Beispiel:**
```bash
POST /realunit/brokerbot/sell
{
  "shares": 100,
  "walletAddress": "0x1234567890abcdef1234567890abcdef12345678"
}

Response:
{
  "to": "0xCFF32C60B87296B8c0c12980De685bEd6Cb9dD6d",
  "data": "0x...",
  "value": "0",
  "gasLimit": "150000",
  "maxFeePerGas": "30000000000",
  "maxPriorityFeePerGas": "1000000000",
  "chainId": 1,
  "expectedShares": 100,
  "expectedPrice": "132.50",
  "expiresAt": "2025-12-06T15:30:00Z"
}
```

#### Fehlerbehandlung

| HTTP Status | Error Code | Beschreibung |
|-------------|------------|--------------|
| 400 | INVALID_SHARES | shares muss > 0 sein |
| 400 | INVALID_ADDRESS | Ungültige Wallet-Adresse |
| 400 | SELLING_DISABLED | Verkauf ist im Brokerbot deaktiviert |
| 400 | INSUFFICIENT_LIQUIDITY | Nicht genug ZCHF im Brokerbot |
| 503 | RPC_ERROR | Blockchain nicht erreichbar |

#### Implementation (Backend)

```typescript
// Controller
@Post('brokerbot/sell')
@ApiOperation({ summary: 'Prepare sell transaction' })
async prepareSellTransaction(
  @Body() dto: BrokerbotSellRequest
): Promise<BrokerbotSellTxDto> {
  return this.realunitService.prepareSellTransaction(dto);
}

// Service
async prepareSellTransaction(dto: BrokerbotSellRequest): Promise<BrokerbotSellTxDto> {
  // 1. Validierung
  if (dto.shares <= 0) throw new BadRequestException('INVALID_SHARES');
  if (!ethers.isAddress(dto.walletAddress)) throw new BadRequestException('INVALID_ADDRESS');

  // 2. Brokerbot-Status prüfen
  const info = await this.blockchainService.getBrokerbotInfo();
  if (!info.sellingEnabled) throw new BadRequestException('SELLING_DISABLED');

  // 3. Liquidität prüfen
  const sellPrice = await this.blockchainService.getBrokerbotSellPrice(dto.shares);
  const zchfBalance = await this.blockchainService.getBrokerbotZchfBalance();
  if (BigInt(sellPrice.totalPriceRaw) > BigInt(zchfBalance)) {
    throw new BadRequestException('INSUFFICIENT_LIQUIDITY');
  }

  // 4. Transaction Data encodieren
  const iface = new ethers.Interface(BROKERBOT_ABI);
  const data = iface.encodeFunctionData('sell', [
    REALU_TOKEN_ADDRESS,
    dto.shares,
    '0x01' // Direct sale reference
  ]);

  // 5. Gas estimieren
  const gasEstimate = await this.evmClient.estimateGas({
    to: BROKERBOT_ADDRESS,
    data,
    from: dto.walletAddress,
  });

  // 6. Gas-Preise abrufen
  const feeData = await this.evmClient.getFeeData();

  return {
    to: BROKERBOT_ADDRESS,
    data,
    value: '0',
    gasLimit: (gasEstimate * 120n / 100n).toString(), // 20% Buffer
    maxFeePerGas: feeData.maxFeePerGas?.toString(),
    maxPriorityFeePerGas: feeData.maxPriorityFeePerGas?.toString(),
    chainId: 1,
    expectedShares: dto.shares,
    expectedPrice: sellPrice.totalPrice,
    expiresAt: new Date(Date.now() + 5 * 60 * 1000).toISOString(), // 5 Minuten gültig
  };
}
```

---

### 3.3 GET /brokerbot/approval

#### Warum wird dieser Endpoint benötigt?

Bevor REALU über den Brokerbot verkauft werden können, muss der Benutzer dem Brokerbot die Erlaubnis geben, seine Tokens zu transferieren. Dies ist ein **ERC-20 Approval**.

**Ohne diesen Endpoint:**
- Die App muss selbst den REALU Token Contract abfragen
- Direkter RPC-Zugriff nötig
- Inkonsistente Implementierungen möglich

**Mit diesem Endpoint:**
- Einfache Prüfung: "Ist Approval vorhanden?"
- DFX kann Caching implementieren
- Einheitliche Fehlerbehandlung

#### Spezifikation

```
GET /realunit/brokerbot/approval/:address
```

**Path Parameter:**
| Parameter | Typ | Beschreibung |
|-----------|-----|--------------|
| address | string | Wallet-Adresse des Benutzers |

**Response:**
```typescript
interface BrokerbotApprovalDto {
  address: string;          // Wallet-Adresse (Echo)
  spender: string;          // Brokerbot-Adresse
  allowance: string;        // Aktuelles Approval (Anzahl Shares)
  allowanceRaw: string;     // Aktuelles Approval (Wei/Raw)
  isApproved: boolean;      // true wenn allowance > 0
  isUnlimited: boolean;     // true wenn allowance = MaxUint256
}
```

**Beispiel:**
```bash
GET /realunit/brokerbot/approval/0x1234...

{
  "address": "0x1234...",
  "spender": "0xCFF32C60B87296B8c0c12980De685bEd6Cb9dD6d",
  "allowance": "1000",
  "allowanceRaw": "1000",
  "isApproved": true,
  "isUnlimited": false
}
```

#### Implementation (Backend)

```typescript
const REALU_TOKEN_ABI_EXTENDED = [
  ...REALU_TOKEN_ABI,
  'function allowance(address owner, address spender) public view returns (uint256)',
];

async getBrokerbotApproval(address: string): Promise<BrokerbotApprovalDto> {
  const contract = this.getRealuTokenContract();
  const allowanceRaw = await contract.allowance(address, BROKERBOT_ADDRESS);

  const MAX_UINT256 = BigInt('0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff');

  return {
    address,
    spender: BROKERBOT_ADDRESS,
    allowance: allowanceRaw.toString(),
    allowanceRaw: allowanceRaw.toString(),
    isApproved: allowanceRaw > 0n,
    isUnlimited: allowanceRaw === MAX_UINT256,
  };
}
```

---

### 3.4 POST /brokerbot/approve

#### Warum wird dieser Endpoint benötigt?

Wenn kein Approval vorhanden ist, muss der Benutzer eine Approval-Transaktion senden. Analog zu `/brokerbot/sell` bereitet dieser Endpoint die Transaktionsdaten vor.

**Warum nicht einfach im Client implementieren?**
1. **Konsistenz:** Alle Transaktions-Vorbereitungen laufen über DFX
2. **Wartbarkeit:** Bei ABI-Änderungen muss nur das Backend aktualisiert werden
3. **Gas-Optimierung:** DFX kann die optimale Approval-Menge berechnen
4. **Sicherheit:** Validierung auf Server-Seite (z.B. keine Unlimited-Approvals für unbekannte Contracts)

#### Spezifikation

```
POST /realunit/brokerbot/approve
Content-Type: application/json
```

**Request Body:**
```typescript
interface BrokerbotApproveRequest {
  walletAddress: string;    // Wallet-Adresse des Benutzers
  amount?: string;          // Optional: Spezifische Menge (Default: unlimited)
  unlimited?: boolean;      // Optional: Unlimited Approval (MaxUint256)
}
```

**Response:**
```typescript
interface BrokerbotApproveTxDto {
  to: string;               // REALU Token Contract Adresse
  data: string;             // Encoded approve() Call
  value: string;            // "0"
  gasLimit: string;
  chainId: number;
  approvalAmount: string;   // Approval-Menge (zur Anzeige)
}
```

**Beispiel:**
```bash
POST /realunit/brokerbot/approve
{
  "walletAddress": "0x1234...",
  "unlimited": true
}

Response:
{
  "to": "0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B",
  "data": "0x095ea7b3...",
  "value": "0",
  "gasLimit": "50000",
  "chainId": 1,
  "approvalAmount": "unlimited"
}
```

#### Implementation (Backend)

```typescript
async prepareApprovalTransaction(dto: BrokerbotApproveRequest): Promise<BrokerbotApproveTxDto> {
  const MAX_UINT256 = '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

  const amount = dto.unlimited ? MAX_UINT256 : (dto.amount || MAX_UINT256);

  const iface = new ethers.Interface(['function approve(address spender, uint256 amount)']);
  const data = iface.encodeFunctionData('approve', [BROKERBOT_ADDRESS, amount]);

  const gasEstimate = await this.evmClient.estimateGas({
    to: REALU_TOKEN_ADDRESS,
    data,
    from: dto.walletAddress,
  });

  return {
    to: REALU_TOKEN_ADDRESS,
    data,
    value: '0',
    gasLimit: (gasEstimate * 120n / 100n).toString(),
    chainId: 1,
    approvalAmount: dto.unlimited ? 'unlimited' : amount,
  };
}
```

---

### 3.5 GET /balance/:address

#### Warum wird dieser Endpoint benötigt?

Die App muss verschiedene Balances anzeigen:
- ETH-Balance (für Gas-Gebühren)
- REALU-Balance (für Verkauf)
- ZCHF-Balance (nach dem Swap)

**Ohne diesen Endpoint:**
- Mehrere separate RPC-Calls vom Client
- Direkte Alchemy-Abhängigkeit
- Rate-Limiting-Probleme

**Mit diesem Endpoint:**
- Ein API-Call für alle relevanten Balances
- DFX kann Caching implementieren
- Einheitliche Formatierung

#### Spezifikation

```
GET /realunit/balance/:address
```

**Response:**
```typescript
interface WalletBalanceDto {
  address: string;
  balances: {
    eth: {
      balance: string;        // z.B. "0.05"
      balanceRaw: string;     // in Wei
      sufficientForGas: boolean;  // true wenn > 0.001 ETH
    };
    realu: {
      balance: string;        // z.B. "150" (ganze Zahlen, decimals=0)
      balanceRaw: string;
    };
    zchf: {
      balance: string;        // z.B. "199.50"
      balanceRaw: string;     // in Wei (18 decimals)
    };
  };
}
```

#### Implementation (Backend)

```typescript
async getWalletBalance(address: string): Promise<WalletBalanceDto> {
  const [ethBalance, realuBalance, zchfBalance] = await Promise.all([
    this.evmClient.getBalance(address),
    this.getRealuTokenContract().balanceOf(address),
    this.getZchfContract().balanceOf(address),
  ]);

  return {
    address,
    balances: {
      eth: {
        balance: EvmUtil.fromWeiAmount(ethBalance).toString(),
        balanceRaw: ethBalance.toString(),
        sufficientForGas: ethBalance >= parseEther('0.001'),
      },
      realu: {
        balance: realuBalance.toString(), // decimals = 0
        balanceRaw: realuBalance.toString(),
      },
      zchf: {
        balance: EvmUtil.fromWeiAmount(zchfBalance).toString(),
        balanceRaw: zchfBalance.toString(),
      },
    },
  };
}
```

---

### 3.6 POST /transaction/send

#### Warum wird dieser Endpoint benötigt?

Nach dem REALU → ZCHF Swap muss der Benutzer die erhaltenen ZCHF an die DFX Deposit-Adresse senden. Auch hierfür braucht der Client vorbereitete Transaktionsdaten.

**Dieser Endpoint ist generischer** und kann für beliebige ERC-20 Transfers verwendet werden.

#### Spezifikation

```
POST /realunit/transaction/send
Content-Type: application/json
```

**Request Body:**
```typescript
interface SendTransactionRequest {
  walletAddress: string;    // Absender
  tokenAddress: string;     // ERC-20 Token (z.B. ZCHF)
  recipient: string;        // Empfänger (z.B. DFX Deposit-Adresse)
  amount: string;           // Betrag in Token-Einheiten (nicht Wei)
}
```

**Response:**
```typescript
interface SendTransactionTxDto {
  to: string;               // Token Contract Adresse
  data: string;             // Encoded transfer() Call
  value: string;            // "0"
  gasLimit: string;
  chainId: number;

  // Validierung
  tokenSymbol: string;      // z.B. "ZCHF"
  amount: string;           // Echo
  recipient: string;        // Echo
}
```

**Beispiel:**
```bash
POST /realunit/transaction/send
{
  "walletAddress": "0x1234...",
  "tokenAddress": "0xb58e61c3098d85632df34eecfb899a1ed80921cb",
  "recipient": "0xDFX_DEPOSIT_ADDRESS...",
  "amount": "132.50"
}

Response:
{
  "to": "0xb58e61c3098d85632df34eecfb899a1ed80921cb",
  "data": "0xa9059cbb...",
  "value": "0",
  "gasLimit": "65000",
  "chainId": 1,
  "tokenSymbol": "ZCHF",
  "amount": "132.50",
  "recipient": "0xDFX_DEPOSIT_ADDRESS..."
}
```

#### Sicherheitsüberlegungen

Dieser Endpoint sollte **nur für bekannte Tokens** funktionieren:
- ZCHF: `0xb58e61c3098d85632df34eecfb899a1ed80921cb`
- REALU: `0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B`

```typescript
const ALLOWED_TOKENS = {
  '0xb58e61c3098d85632df34eecfb899a1ed80921cb': 'ZCHF',
  '0x553c7f9c780316fc1d34b8e14ac2465ab22a090b': 'REALU',
};

async prepareSendTransaction(dto: SendTransactionRequest): Promise<SendTransactionTxDto> {
  const tokenSymbol = ALLOWED_TOKENS[dto.tokenAddress.toLowerCase()];
  if (!tokenSymbol) {
    throw new BadRequestException('TOKEN_NOT_ALLOWED');
  }

  // ... Implementation
}
```

---

## 4. Architektur-Entscheidung: Client-signierte Transaktionen

### Das Problem

Für den REALU-Verkauf müssen mehrere Blockchain-Transaktionen durchgeführt werden:
1. Approval für Brokerbot
2. Sell-Transaktion an Brokerbot
3. ZCHF-Transfer an DFX

### Mögliche Ansätze

#### Option A: Server führt Transaktionen aus (❌ Abgelehnt)

```
Client → DFX API → DFX Wallet → Blockchain
```

**Nachteile:**
- DFX müsste Private Keys der User speichern
- Custody-Problematik (regulatorisch kritisch)
- Single Point of Failure
- Vertrauensproblem

#### Option B: Client signiert, Server broadcastet (⚠️ Möglich)

```
Client signiert TX → DFX API broadcastet → Blockchain
```

**Vorteile:**
- Keine Private Keys auf Server
- DFX kann TX-Hash loggen

**Nachteile:**
- Zusätzliche Latenz
- DFX-Abhängigkeit für Broadcast

#### Option C: Client signiert und sendet (✅ Gewählt)

```
Client signiert TX → Client sendet direkt → Blockchain
         ↑
    DFX API bereitet TX-Daten vor
```

**Vorteile:**
- Maximale Dezentralisierung
- Keine Custody
- Client hat volle Kontrolle
- Standard-Wallet-Integration (WalletConnect, MetaMask, etc.)

**Nachteile:**
- Client braucht RPC-Zugang für Broadcast

### Empfehlung für RPC-Routing

Auch der TX-Broadcast sollte über DFX geroutet werden:

```
POST /realunit/transaction/broadcast
{
  "signedTransaction": "0x..."
}
```

**Vorteile:**
- Kein direkter Alchemy-Zugang vom Client
- DFX kann TX-Status tracken
- Einheitliche Fehlerbehandlung

---

## 5. Prioritäten

### Priorität 1: Must-Have (Blocker)

| Endpoint | Begründung |
|----------|------------|
| `GET /brokerbot/sellPrice` | Ohne diesen Endpoint kann kein Verkaufspreis angezeigt werden |
| `POST /brokerbot/sell` | Kernfunktion: Bereitet Sell-TX vor |
| `GET /brokerbot/approval` | Muss vor jedem Verkauf geprüft werden |
| `POST /brokerbot/approve` | Ohne Approval funktioniert der Verkauf nicht |

### Priorität 2: Should-Have (UX-Verbesserung)

| Endpoint | Begründung |
|----------|------------|
| `GET /balance/:address` | Zeigt alle Balances auf einen Blick |
| `POST /transaction/send` | Für ZCHF → DFX Transfer |

### Priorität 3: Nice-to-Have (Optimierung)

| Endpoint | Begründung |
|----------|------------|
| `POST /transaction/broadcast` | TX-Broadcast über DFX statt direkt |
| `GET /transaction/:txHash` | TX-Status abfragen |
| `GET /gas/estimate` | Aktuelle Gas-Preise |

---

## 6. Zusammenfassung

### Übersicht aller Endpoints

| Endpoint | Status | Priorität |
|----------|--------|-----------|
| `GET /kyc` | ✅ Existiert | - |
| `POST /faucet` | ✅ Existiert | - |
| `GET /brokerbot/info` | ✅ Existiert | - |
| `GET /brokerbot/price` | ✅ Existiert | - |
| `GET /brokerbot/buyPrice` | ✅ Existiert | - |
| `GET /brokerbot/shares` | ✅ Existiert | - |
| `GET /allowlist/:address` | ✅ Existiert | - |
| `GET /bank` | ✅ Existiert | - |
| `POST /sell` | ✅ Existiert | - |
| `GET /sell/:routeId` | ✅ Existiert | - |
| **`GET /brokerbot/sellPrice`** | ❌ Fehlt | P1 |
| **`POST /brokerbot/sell`** | ❌ Fehlt | P1 |
| **`GET /brokerbot/approval`** | ❌ Fehlt | P1 |
| **`POST /brokerbot/approve`** | ❌ Fehlt | P1 |
| **`GET /balance/:address`** | ❌ Fehlt | P2 |
| **`POST /transaction/send`** | ❌ Fehlt | P2 |

### Nächste Schritte

1. **Backend-Team:** Implementierung der P1-Endpoints
2. **API-Review:** OpenAPI/Swagger-Dokumentation erstellen
3. **Testing:** Integration Tests mit Testnet
4. **Frontend-Integration:** Client-Code implementieren

---

*Dokumentation erstellt am: 2025-12-06*
