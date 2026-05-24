part of 'verify_seed_cubit.dart';

final class VerifySeedState extends Equatable {
  const VerifySeedState({
    this.wordIndices = const [],
    this.enteredWords = const [],
    this.hasError = false,
    this.isVerifying = false,
    this.isVerified = false,
    this.commitFailed = false,
    this.aborted = false,
    this.committedWallet,
  });

  final List<int> wordIndices;
  final List<String> enteredWords;

  /// The four entered words don't match the requested seed words.
  final bool hasError;

  /// The commit (`commitGeneratedWallet` + `setCurrentWallet`) is in flight.
  final bool isVerifying;

  /// The wallet was committed and marked current — onboarding may advance.
  final bool isVerified;

  /// The words matched, but persisting the wallet threw. Distinct from
  /// [hasError]: the user typed the right words, the disk write failed.
  /// Surfaced as a retry affordance so [verify] is never left in a state
  /// that is neither success nor a visible error.
  final bool commitFailed;

  /// The cubit's [SeedDraft] was disposed mid-verify — either because
  /// the user backgrounded the app (BL-023) or because the draft was
  /// already gone when the cubit was constructed. The view should
  /// route back to the create-wallet entry point; re-attempting verify
  /// from this state is impossible because the mnemonic is no longer
  /// in memory.
  final bool aborted;

  /// The wallet returned by `commitGeneratedWallet` — the persisted row
  /// with its real id. Only ever set together with [isVerified] `== true`;
  /// `null` until then. Passed to `LoadWalletEvent` so `HomeBloc` flips
  /// `hasWallet` true and onboarding advances instead of looping.
  final SoftwareWallet? committedWallet;

  bool get canVerify => enteredWords.length == 4 && enteredWords.every((w) => w.isNotEmpty);

  VerifySeedState copyWith({
    List<int>? wordIndices,
    List<String>? enteredWords,
    bool? hasError,
    bool? isVerifying,
    bool? isVerified,
    bool? commitFailed,
    bool? aborted,
    SoftwareWallet? committedWallet,
  }) => VerifySeedState(
    wordIndices: wordIndices ?? this.wordIndices,
    enteredWords: enteredWords ?? this.enteredWords,
    hasError: hasError ?? this.hasError,
    isVerifying: isVerifying ?? this.isVerifying,
    isVerified: isVerified ?? this.isVerified,
    commitFailed: commitFailed ?? this.commitFailed,
    aborted: aborted ?? this.aborted,
    committedWallet: committedWallet ?? this.committedWallet,
  );

  @override
  List<Object?> get props => [
    wordIndices,
    enteredWords,
    hasError,
    isVerifying,
    isVerified,
    commitFailed,
    aborted,
    committedWallet,
  ];
}
