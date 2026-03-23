part of 'verify_seed_cubit.dart';

final class VerifySeedState extends Equatable {
  const VerifySeedState({
    this.wordIndices = const [],
    this.enteredWords = const [],
    this.hasError = false,
    this.isVerified = false,
  });

  final List<int> wordIndices;
  final List<String> enteredWords;
  final bool hasError;
  final bool isVerified;

  bool get canVerify => enteredWords.length == 4 && enteredWords.every((w) => w.isNotEmpty);

  VerifySeedState copyWith({
    List<int>? wordIndices,
    List<String>? enteredWords,
    bool? hasError,
    bool? isVerified,
  }) => VerifySeedState(
    wordIndices: wordIndices ?? this.wordIndices,
    enteredWords: enteredWords ?? this.enteredWords,
    hasError: hasError ?? this.hasError,
    isVerified: isVerified ?? this.isVerified,
  );

  @override
  List<Object?> get props => [wordIndices, enteredWords, hasError, isVerified];
}
