import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_state.dart';

void main() {
  group('RealUnitRegistrationState.fromJson', () {
    test('parses all known server values', () {
      expect(
        RealUnitRegistrationState.fromJson('AlreadyRegistered'),
        RealUnitRegistrationState.alreadyRegistered,
      );
      expect(
        RealUnitRegistrationState.fromJson('AddWallet'),
        RealUnitRegistrationState.addWallet,
      );
      expect(
        RealUnitRegistrationState.fromJson('NewRegistration'),
        RealUnitRegistrationState.newRegistration,
      );
      expect(
        RealUnitRegistrationState.fromJson('MergeProcessing'),
        RealUnitRegistrationState.mergeProcessing,
      );
    });

    test('falls back to mergeProcessing for an unknown (additively introduced) value', () {
      // A future backend state must not crash the client — it degrades to a
      // benign waiting state the user can re-check.
      expect(
        RealUnitRegistrationState.fromJson('SomethingNewFromBackend'),
        RealUnitRegistrationState.mergeProcessing,
      );
    });
  });
}
