part of 'create_wallet_cubit.dart';

final class CreateWalletState {
  const CreateWalletState({this.hideSeed = true, this.draft});

  final bool hideSeed;
  // Post-Initiative-IV the state carries a transient [SeedDraft]
  // instead of a `SoftwareWallet`. The draft is the only main-isolate
  // holder of the BIP39 plaintext during the onboarding window; the
  // committed `SoftwareWallet` handle is produced inside the verify
  // step via `WalletService.commitGeneratedWallet` and never lives on
  // this state.
  final SeedDraft? draft;

  CreateWalletState copyWith({
    bool? hideSeed,
    SeedDraft? draft,
  }) =>
      CreateWalletState(
        hideSeed: hideSeed ?? this.hideSeed,
        draft: draft ?? this.draft,
      );
}
