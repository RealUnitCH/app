part of 'settings_seed_cubit.dart';

class SettingsSeedState extends Equatable {
  final String seed;
  final bool showSeed;

  const SettingsSeedState(this.seed, {this.showSeed = false});

  SettingsSeedState copyWith({String? seed, bool? showSeed}) {
    return SettingsSeedState(
      seed ?? this.seed,
      showSeed: showSeed ?? this.showSeed,
    );
  }

  @override
  List<Object?> get props => [seed, showSeed];
}
