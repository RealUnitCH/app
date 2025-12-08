# Integration: REALU Token Kauf per Banküberweisung

Dieses Dokument beschreibt die Integration des REALU Token Kaufs per Banküberweisung in der RealUnit App.

> **Hinweis:** Technische Details zu Smart Contracts und API-Endpoints siehe [smart-contracts.md](./smart-contracts.md)

---

## Integrations-Ansatz

- Eigenes Frontend (kein Aktionariat Widget)
- DFX API für Blockchain-Anfragen (Preis, Allowlist, Bankverbindung)
- Aktionariat API für Order-Erstellung und Referenz-Generierung (API-Zugang erforderlich)
- RealUnit/Aktionariat übernimmt Zahlungsabwicklung und Token-Auslieferung

---

## Architektur-Übersicht

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  RealUnit   │     │   DFX API   │     │ Aktionariat │     │  Brokerbot  │
│    App      │     │             │     │  Backend    │     │  (On-Chain) │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                    │                    │                    │
      │  1. Preis/Allowlist│                    │                    │
      │───────────────────▶│                    │                    │
      │                    │  2. Blockchain     │                    │
      │                    │─────────────────────────────────────────▶│
      │                    │◀─────────────────────────────────────────│
      │◀───────────────────│                    │                    │
      │  3. Order erstellen│                    │                    │
      │──────────────────────────────────────▶│                    │
      │  4. Referenz zurück│                    │                    │
      │◀──────────────────────────────────────│                    │
      │                    │                    │                    │
      │  5. Kunde überweist mit Referenz       │                    │
      │──────────────────────────────────────▶│                    │
      │                    │                    │  6. Zahlungseingang│
      │                    │                    │  7. notifyTrade()──▶│
      │                    │                    │     8. REALU Transfer
      │◀─────────────────────────────────────────────────────────────│
      │  9. REALU in Wallet│                    │                    │
```

### Verantwortlichkeiten

| Komponente | Aufgaben |
|------------|----------|
| **RealUnit App** | Preis berechnen, Allowlist prüfen, Bankverbindung abrufen, Order erstellen, UI |
| **DFX API** | Alle Blockchain-Anfragen routen (kein direkter RPC vom Client) |
| **Aktionariat** | Order/Referenz-Generierung, Zahlungsabwicklung, On-Chain Settlement |

---

## Kauf-Flow

### Schritt 1: Allowlist prüfen

```typescript
const API_BASE = 'https://api.dfx.swiss/v1/realunit';

async function validateWallet(address: string): Promise<void> {
  const response = await fetch(`${API_BASE}/allowlist/${address}`);
  const status = await response.json();

  if (status.isForbidden) {
    throw new Error('Wallet-Adresse ist gesperrt');
  }

  if (!status.canReceive) {
    throw new Error('Wallet ist nicht allowlisted. Bitte kontaktieren Sie RealUnit.');
  }
}
```

### Schritt 2: Preis berechnen

```typescript
interface PurchaseQuote {
  shares: number;
  pricePerShare: string;
  totalPrice: string;
}

// Nach Anzahl Shares
async function getQuoteByShares(shares: number): Promise<PurchaseQuote> {
  const response = await fetch(`${API_BASE}/brokerbot/buyPrice?shares=${shares}`);
  const data = await response.json();
  return {
    shares: data.shares,
    pricePerShare: data.pricePerShare,
    totalPrice: data.totalPrice,
  };
}

// Nach CHF-Betrag
async function getQuoteByAmount(amountChf: string): Promise<PurchaseQuote> {
  const response = await fetch(`${API_BASE}/brokerbot/shares?amount=${amountChf}`);
  const data = await response.json();
  return {
    shares: data.shares,
    pricePerShare: data.pricePerShare,
    totalPrice: amountChf,
  };
}
```

### Schritt 3: Bankverbindung abrufen

```typescript
interface BankDetails {
  recipient: string;
  address: string;
  iban: string;
  bic: string;
  bankName: string;
  currency: string;  // immer "CHF"
}

async function getBankDetails(): Promise<BankDetails> {
  const response = await fetch(`${API_BASE}/bank`);
  return response.json();
}
```

### Schritt 4: Order erstellen (Aktionariat API)

> **WICHTIG:** Für die Order-Erstellung wird Zugang zur Aktionariat Backend-API benötigt. Diese ist **nicht öffentlich dokumentiert**.

```typescript
// Pseudo-Code (API-Endpoint noch nicht bekannt)
interface CreateOrderRequest {
  ticker: string;           // "REALU"
  shares: number;           // Anzahl Shares
  walletAddress: string;    // Empfänger-Wallet
  email?: string;           // Für Bestätigungs-E-Mail
}

interface CreateOrderResponse {
  orderId: number;          // z.B. 752191
  reference: string;        // z.B. "REALU-752191"
  amount: string;           // CHF Betrag
  expiresAt: string;        // ISO Timestamp
}

async function createOrder(request: CreateOrderRequest): Promise<CreateOrderResponse> {
  const response = await fetch('https://api.aktionariat.com/orders', {  // URL unbekannt
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,  // API-Key erforderlich
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(request),
  });
  return response.json();
}
```

### Zahlungsreferenz-Format

```
REALU-752191
  │      │
  │      └── Order-ID (vom Backend vergeben)
  │
  └── Token-Symbol
```

---

## UI-Beispiel (React Native)

```tsx
function BankPurchaseScreen({ shares, walletAddress }: Props) {
  const [quote, setQuote] = useState<PurchaseQuote | null>(null);
  const [bankDetails, setBankDetails] = useState<BankDetails | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function init() {
      try {
        // 1. Allowlist prüfen
        await validateWallet(walletAddress);

        // 2. Preis berechnen
        const q = await getQuoteByShares(shares);
        setQuote(q);

        // 3. Bankverbindung abrufen
        const bank = await getBankDetails();
        setBankDetails(bank);
      } catch (e) {
        setError(e.message);
      }
    }
    init();
  }, [shares, walletAddress]);

  if (error) return <Error message={error} />;
  if (!quote || !bankDetails) return <Loading />;

  // TODO: Referenz von Aktionariat API holen
  const reference = 'REALU-XXXXXX';

  return (
    <View>
      <Text>Kauf: {quote.shares} REALU</Text>
      <Text>Preis pro Share: {quote.pricePerShare} CHF</Text>
      <Text>Gesamtbetrag: {quote.totalPrice} CHF</Text>

      <Divider />

      <Text>Banküberweisung an:</Text>
      <Text>Empfänger: {bankDetails.recipient}</Text>
      <Text>IBAN: {bankDetails.iban}</Text>
      <Text>Betrag: {quote.totalPrice} CHF</Text>
      <Text>Referenz: {reference}</Text>

      <Info>
        Nach Zahlungseingang werden die REALU Tokens
        automatisch an Ihre Wallet gesendet.
      </Info>
    </View>
  );
}
```

---

## Offene Punkte (mit Aktionariat/RealUnit klären)

### Erledigt
- [x] ~~Exakte Bankverbindung (IBAN, BIC, Bank)~~ → via DFX API `/bank`
- [x] ~~Format der Zahlungsreferenz~~ → `REALU-{orderId}`

### API-Zugang erforderlich
- [ ] API-Endpoint für Order-Erstellung (URL, Authentifizierung)
- [ ] API-Key oder OAuth-Credentials
- [ ] API-Dokumentation für Order-Endpoints
- [ ] Webhook für Order-Status-Updates (optional)

### Prozess-Fragen
- [ ] Bearbeitungszeit nach Zahlungseingang
- [ ] Gültigkeitsdauer einer Order/Referenz
- [ ] Testumgebung / Sandbox verfügbar?

---

## Alternative: Aktionariat Widget

Falls kein API-Zugang gewährt wird:

```html
<script src="https://hub.aktionariat.com/brokerbot-v3/brokerbot-v3.js" async></script>
<akt-brokerbot ticker="REALU" lang="de"></akt-brokerbot>
```

| Vorteile | Nachteile |
|----------|-----------|
| Funktioniert sofort | Kein eigenes UI-Design |
| Referenz automatisch | Keine Kontrolle über Flow |
| Aktionariat übernimmt alles | Widget in WebView |

---

*Dokumentation erstellt am: 2025-12-05*
*Aktualisiert: 2025-12-06*
