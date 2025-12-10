part of 'buy_allowlist_cubit.dart';

class BuyAllowlistState extends Equatable {
  final bool canReceive;
  final bool isForbidden;
  final bool isPowerlisted;
  final bool loading;

  const BuyAllowlistState({
    this.canReceive = false,
    this.isForbidden = true,
    this.isPowerlisted = false,
    this.loading = false,
  });

  BuyAllowlistState copyWith({
    bool? canReceive,
    bool? isForbidden,
    bool? isPowerlisted,
    bool? loading,
  }) {
    return BuyAllowlistState(
      canReceive: canReceive ?? this.canReceive,
      isForbidden: isForbidden ?? this.isForbidden,
      isPowerlisted: isPowerlisted ?? this.isPowerlisted,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [canReceive, isForbidden, isPowerlisted, loading];
}
