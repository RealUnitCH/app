import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

void main() {
  group('$KycLevel', () {
    test('values has exactly 8 entries', () {
      // 6 numeric levels + terminated + rejected. Catches accidental
      // additions to the enum that would silently bypass every
      // switch-on-level call site.
      expect(KycLevel.values, hasLength(8));
    });

    group('value (extension getter)', () {
      test('level0..level50 map to 0/10/20/30/40/50', () {
        expect(KycLevel.level0.value, 0);
        expect(KycLevel.level10.value, 10);
        expect(KycLevel.level20.value, 20);
        expect(KycLevel.level30.value, 30);
        expect(KycLevel.level40.value, 40);
        expect(KycLevel.level50.value, 50);
      });

      test('terminated → -10, rejected → -20', () {
        // Negative sentinels for terminal states. Pinned because the
        // server distinguishes between user-aborted and rejected KYC.
        expect(KycLevel.terminated.value, -10);
        expect(KycLevel.rejected.value, -20);
      });
    });

    group('fromValue (static)', () {
      test('round-trips every enum value', () {
        for (final level in KycLevel.values) {
          expect(KycLevelExtension.fromValue(level.value), level);
        }
      });

      test('throws ArgumentError on unknown numeric input', () {
        expect(() => KycLevelExtension.fromValue(99), throwsArgumentError);
        expect(() => KycLevelExtension.fromValue(-1), throwsArgumentError);
      });
    });
  });

  group('$KycProcessStatus', () {
    test('value getter maps every enum to its expected wire string', () {
      // Pinned per-case so a rename in the API DTO is caught immediately
      // instead of through a downstream test.
      expect(KycProcessStatus.inProgress.value, 'InProgress');
      expect(KycProcessStatus.pendingReview.value, 'PendingReview');
      expect(KycProcessStatus.completed.value, 'Completed');
      expect(KycProcessStatus.failed.value, 'Failed');
      expect(KycProcessStatus.mergeProcessing.value, 'MergeProcessing');
    });

    test('round-trips every enum value through fromValue/value', () {
      for (final status in KycProcessStatus.values) {
        expect(KycProcessStatusExtension.fromValue(status.value), status);
      }
    });

    // Foundation rule (#491) forbids silent local defaults on unknown API
    // values. An unknown `processStatus` string would previously degrade
    // silently to `inProgress`, which then routes into `_continueKyc` —
    // the exact "local default decision" the rule eliminates.
    test('throws ArgumentError on unknown string input', () {
      expect(
        () => KycProcessStatusExtension.fromValue('OnHold'),
        throwsArgumentError,
      );
      expect(
        () => KycProcessStatusExtension.fromValue('Suspended'),
        throwsArgumentError,
      );
      expect(
        () => KycProcessStatusExtension.fromValue(''),
        throwsArgumentError,
      );
    });
  });

  group('$KycStepName', () {
    // The DTO surface lists 24 step names. A count assertion catches
    // accidental enum additions that would silently bypass every
    // switch-on-step call site (router fallthrough, missing UI label,
    // missing `_continueKyc` branch).
    test('values has exactly 24 entries', () {
      expect(KycStepName.values, hasLength(24));
    });

    test('value getter pins every enum to its API wire string', () {
      // Per-case pin instead of a generated map: a copy-paste typo in the
      // production switch ("PesonalData") would otherwise round-trip
      // through `fromValue(this.value)` without ever hitting the API
      // string we ship.
      expect(KycStepName.contactData.value, 'ContactData');
      expect(KycStepName.personalData.value, 'PersonalData');
      expect(KycStepName.nationalityData.value, 'NationalityData');
      expect(KycStepName.recommendation.value, 'Recommendation');
      expect(KycStepName.ownerDirectory.value, 'OwnerDirectory');
      expect(KycStepName.commercialRegister.value, 'CommercialRegister');
      expect(KycStepName.legalEntity.value, 'LegalEntity');
      expect(
        KycStepName.soleProprietorshipConfirmation.value,
        'SoleProprietorshipConfirmation',
      );
      expect(KycStepName.signatoryPower.value, 'SignatoryPower');
      expect(KycStepName.authority.value, 'Authority');
      expect(KycStepName.beneficialOwner.value, 'BeneficialOwner');
      expect(KycStepName.operationalActivity.value, 'OperationalActivity');
      expect(KycStepName.ident.value, 'Ident');
      expect(KycStepName.financialData.value, 'FinancialData');
      expect(KycStepName.additionalDocuments.value, 'AdditionalDocuments');
      expect(KycStepName.residencePermit.value, 'ResidencePermit');
      expect(KycStepName.statutes.value, 'Statutes');
      expect(KycStepName.dfxApproval.value, 'DfxApproval');
      expect(KycStepName.paymentAgreement.value, 'PaymentAgreement');
      expect(KycStepName.recallAgreement.value, 'RecallAgreement');
      expect(KycStepName.realUnitRegistration.value, 'RealUnitRegistration');
      expect(KycStepName.phoneChange.value, 'PhoneChange');
      expect(KycStepName.nameChange.value, 'NameChange');
      expect(KycStepName.addressChange.value, 'AddressChange');
    });

    test('fromValue round-trips every enum value', () {
      for (final step in KycStepName.values) {
        expect(KycStepNameExtension.fromValue(step.value), step);
      }
    });

    test('fromValue throws ArgumentError on unknown wire strings', () {
      // Symmetric to KycProcessStatus: no silent fallback. A new
      // step rolling out server-side must show up loud here so we add
      // the UI/router branch before users hit it.
      expect(
        () => KycStepNameExtension.fromValue('NewStepTBD'),
        throwsArgumentError,
      );
      expect(
        () => KycStepNameExtension.fromValue(''),
        throwsArgumentError,
      );
      // Case-sensitivity is part of the contract — the API ships
      // PascalCase, anything else is wrong.
      expect(
        () => KycStepNameExtension.fromValue('contactdata'),
        throwsArgumentError,
      );
    });
  });

  group('$KycStepType', () {
    test('values has exactly 5 entries', () {
      expect(KycStepType.values, hasLength(5));
    });

    test('value getter pins every enum to its API wire string', () {
      expect(KycStepType.auto.value, 'Auto');
      expect(KycStepType.video.value, 'Video');
      expect(KycStepType.manual.value, 'Manual');
      expect(KycStepType.sumsubAuto.value, 'SumsubAuto');
      expect(KycStepType.sumsubVideo.value, 'SumsubVideo');
    });

    test('fromValue round-trips every enum value', () {
      for (final t in KycStepType.values) {
        expect(KycStepTypeExtension.fromValue(t.value), t);
      }
    });

    test('fromValue throws ArgumentError on unknown wire strings', () {
      expect(
        () => KycStepTypeExtension.fromValue('Onsite'),
        throwsArgumentError,
      );
      expect(
        () => KycStepTypeExtension.fromValue(''),
        throwsArgumentError,
      );
    });
  });

  group('$KycStepStatus', () {
    test('values has exactly 8 entries', () {
      expect(KycStepStatus.values, hasLength(8));
    });

    test('value getter pins every enum to its API wire string', () {
      expect(KycStepStatus.notStarted.value, 'NotStarted');
      expect(KycStepStatus.inProgress.value, 'InProgress');
      expect(KycStepStatus.inReview.value, 'InReview');
      expect(KycStepStatus.failed.value, 'Failed');
      expect(KycStepStatus.completed.value, 'Completed');
      expect(KycStepStatus.outdated.value, 'Outdated');
      expect(KycStepStatus.dataRequested.value, 'DataRequested');
      expect(KycStepStatus.onHold.value, 'OnHold');
    });

    test('fromValue round-trips every enum value', () {
      for (final s in KycStepStatus.values) {
        expect(KycStepStatusExtension.fromValue(s.value), s);
      }
    });

    test('fromValue throws ArgumentError on unknown wire strings', () {
      expect(
        () => KycStepStatusExtension.fromValue('Suspended'),
        throwsArgumentError,
      );
      expect(
        () => KycStepStatusExtension.fromValue(''),
        throwsArgumentError,
      );
    });
  });

  group('$KycStepReason', () {
    test('values has exactly 2 entries', () {
      expect(KycStepReason.values, hasLength(2));
    });

    test('value getter pins every enum to its API wire string', () {
      expect(KycStepReason.accountExists.value, 'AccountExists');
      expect(
        KycStepReason.accountMergeRequested.value,
        'AccountMergeRequested',
      );
    });

    test('fromValue round-trips every enum value', () {
      for (final r in KycStepReason.values) {
        expect(KycStepReasonExtension.fromValue(r.value), r);
      }
    });

    test('fromValue throws ArgumentError on unknown wire strings', () {
      expect(
        () => KycStepReasonExtension.fromValue('AccountLocked'),
        throwsArgumentError,
      );
      expect(
        () => KycStepReasonExtension.fromValue(''),
        throwsArgumentError,
      );
    });
  });
}
