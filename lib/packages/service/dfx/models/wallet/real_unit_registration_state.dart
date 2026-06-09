/// Mirror of the server-side `RealUnitRegistrationState` returned on
/// `GET /v1/realunit/registration`. The API decides the full registration
/// routing for a wallet; the app renders it 1:1 — see CONTRIBUTING.md
/// "API as Decision Authority".
enum RealUnitRegistrationState {
  /// This wallet (`jwt.address`) is already in the Aktionariat share
  /// register. The app must skip the registration step entirely.
  alreadyRegistered(jsonName: 'AlreadyRegistered'),

  /// Another wallet of the same account is registered; this one isn't.
  /// The app shows a streamlined one-tap "Add this wallet" page.
  addWallet(jsonName: 'AddWallet'),

  /// No prior Aktionariat registration on this account. The app shows
  /// the full registration form, pre-filled from `userData` when present.
  newRegistration(jsonName: 'NewRegistration'),

  /// An account merge for this user is still propagating on the backend, so
  /// `userData` is not yet available. The app renders a waiting state and
  /// re-checks instead of treating the absent `userData` as a failure.
  mergeProcessing(jsonName: 'MergeProcessing');

  final String jsonName;
  const RealUnitRegistrationState({required this.jsonName});

  /// Unknown values fall back to [mergeProcessing] (a benign waiting state the
  /// user can re-check) so an additively-introduced backend state never crashes
  /// the client — mirrors the tolerant parsing of other server-mirror enums.
  factory RealUnitRegistrationState.fromJson(String value) {
    return RealUnitRegistrationState.values.firstWhere(
      (e) => e.jsonName == value,
      orElse: () => RealUnitRegistrationState.mergeProcessing,
    );
  }
}
