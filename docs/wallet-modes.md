# Wallet Modes

The realunit-app supports three wallet modes. Two are real user-facing options
(software and BitBox); the third (`debug`) is a developer-only address +
signature mode used to inspect a known wallet without holding its key
material. Each mode has a different signing capability, and any feature that
needs an EIP-712 signature must be gated on that capability before the user
is sent into the flow.

The enum lives at `lib/packages/wallet/wallet.dart`:

```dart
enum WalletType { software, bitbox, debug }
```

## Modes at a glance

| Mode | Holds key material? | EIP-712 signing | Typical user flow |
|---|---|---|---|
| `software` | yes (12-word seed, encrypted at rest) | signs in the background, near-zero user friction | full app — register, link wallet, trade |
| `bitbox` | yes (on the hardware device) | requires confirmation on the connected unlocked BitBox | full app — register, link wallet, trade |
| `debug` | no (address only, plus a stored signature attestation) | **cannot sign** — `DebugWalletAccount.signMessage` throws `UnsupportedError` | read-only browsing of a known address, plus any flow that the API accepts without a fresh signature (`AlreadyRegistered`, `KycRequired`) |

## Features that require signing

The RealUnit registration flow signs an EIP-712 envelope so the backend can
prove the user owns the wallet. Two API-driven sub-flows reach the signer:

- `RealUnitRegistrationState.newRegistration` — one-tap "Sign and register"
  page, `KycRegisterPage`. The page consumes the same DFX-KYC-prefilled
  `RealUnitUserDataDto` the API supplies and forwards it to
  `completeRegistration` unchanged (there is no editable form — the server
  enforces a byte-for-byte match anyway).
- `RealUnitRegistrationState.addWallet` — one-tap "Add this wallet" page,
  `KycLinkWalletPage`

Both are gated in `KycCubit._runCheckKyc` directly after the
`RealUnitRegistrationService.getRegistrationInfo()` round-trip. When the
current wallet is `WalletType.debug` and the API has routed to either of the
above states, the cubit emits `KycSignatureUnsupportedFailure` instead of
`KycSuccess`, and `KycPageManager` renders `KycSignatureUnsupportedPage`.

`AlreadyRegistered` and `KycRequired` do not invoke the signer, so debug-mode
users flow through them unchanged.

## Why this gate is local

Signing capability is a physical property of the wallet implementation —
nothing the server returns can change whether the user's device can produce
an EIP-712 signature. This is the same exception class as the PIN / wallet
lock / BitBox connection gates listed in CONTRIBUTING.md's
*"API as Decision Authority"* rule under "physical security boundary". The
gate is intentionally local; it does not duplicate any API decision.

## Future: feature gating

Any future feature that needs an EIP-712 signature (or any wallet-side
cryptographic operation the debug mode cannot service) should follow the
same pattern:

1. Read `getIt<AppStore>().wallet.walletType` at the routing decision point
   (a cubit, never a widget).
2. Emit a dedicated terminal failure state (parallel to
   `KycSignatureUnsupportedFailure`).
3. Render a tailored page in the feature's page-manager switch.

Do not let the sign call blow up deep inside the flow with a raw
`UnsupportedError` — the UX must be deterministic and explain to the user
which modes are supported.
