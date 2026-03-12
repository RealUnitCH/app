import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';

enum KycLevel { level0, level10, level20, level30, level40, level50, terminated, rejected }

enum KycStepName {
  contactData,
  personalData,
  nationalityData,
  recommendation,
  ownerDirectory,
  commercialRegister,
  legalEntity,
  soleProprietorshipConfirmation,
  signatoryPower,
  authority,
  beneficialOwner,
  operationalActivity,
  ident,
  financialData,
  additionalDocuments,
  residencePermit,
  statutes,
  dfxApproval,
  paymentAgreement,
  recallAgreement,
  realUnitRegistration,
}

extension KycStepNameExtension on KycStepName {
  String get value {
    switch (this) {
      case KycStepName.contactData:
        return 'ContactData';
      case KycStepName.personalData:
        return 'PersonalData';
      case KycStepName.nationalityData:
        return 'NationalityData';
      case KycStepName.recommendation:
        return 'Recommendation';
      case KycStepName.ownerDirectory:
        return 'OwnerDirectory';
      case KycStepName.commercialRegister:
        return 'CommercialRegister';
      case KycStepName.legalEntity:
        return 'LegalEntity';
      case KycStepName.soleProprietorshipConfirmation:
        return 'SoleProprietorshipConfirmation';
      case KycStepName.signatoryPower:
        return 'SignatoryPower';
      case KycStepName.authority:
        return 'Authority';
      case KycStepName.beneficialOwner:
        return 'BeneficialOwner';
      case KycStepName.operationalActivity:
        return 'OperationalActivity';
      case KycStepName.ident:
        return 'Ident';
      case KycStepName.financialData:
        return 'FinancialData';
      case KycStepName.additionalDocuments:
        return 'AdditionalDocuments';
      case KycStepName.residencePermit:
        return 'ResidencePermit';
      case KycStepName.statutes:
        return 'Statutes';
      case KycStepName.dfxApproval:
        return 'DfxApproval';
      case KycStepName.paymentAgreement:
        return 'PaymentAgreement';
      case KycStepName.recallAgreement:
        return 'RecallAgreement';
      case KycStepName.realUnitRegistration:
        return 'RealUnitRegistration';
    }
  }

  static KycStepName fromValue(String value) {
    switch (value) {
      case 'ContactData':
        return KycStepName.contactData;
      case 'PersonalData':
        return KycStepName.personalData;
      case 'NationalityData':
        return KycStepName.nationalityData;
      case 'Recommendation':
        return KycStepName.recommendation;
      case 'OwnerDirectory':
        return KycStepName.ownerDirectory;
      case 'CommercialRegister':
        return KycStepName.commercialRegister;
      case 'LegalEntity':
        return KycStepName.legalEntity;
      case 'SoleProprietorshipConfirmation':
        return KycStepName.soleProprietorshipConfirmation;
      case 'SignatoryPower':
        return KycStepName.signatoryPower;
      case 'Authority':
        return KycStepName.authority;
      case 'BeneficialOwner':
        return KycStepName.beneficialOwner;
      case 'OperationalActivity':
        return KycStepName.operationalActivity;
      case 'Ident':
        return KycStepName.ident;
      case 'FinancialData':
        return KycStepName.financialData;
      case 'AdditionalDocuments':
        return KycStepName.additionalDocuments;
      case 'ResidencePermit':
        return KycStepName.residencePermit;
      case 'Statutes':
        return KycStepName.statutes;
      case 'DfxApproval':
        return KycStepName.dfxApproval;
      case 'PaymentAgreement':
        return KycStepName.paymentAgreement;
      case 'RecallAgreement':
        return KycStepName.recallAgreement;
      case 'RealUnitRegistration':
        return KycStepName.realUnitRegistration;
      default:
        throw ArgumentError('Unknown KycStepName value: $value');
    }
  }
}

enum KycStepType {
  auto,
  video,
  manual,
  sumsubAuto,
  sumsubVideo,
}

extension KycStepTypeExtension on KycStepType {
  String get value {
    switch (this) {
      case KycStepType.auto:
        return 'Auto';
      case KycStepType.video:
        return 'Video';
      case KycStepType.manual:
        return 'Manual';
      case KycStepType.sumsubAuto:
        return 'SumsubAuto';
      case KycStepType.sumsubVideo:
        return 'SumsubVideo';
    }
  }

  static KycStepType fromValue(String value) {
    switch (value) {
      case 'Auto':
        return KycStepType.auto;
      case 'Video':
        return KycStepType.video;
      case 'Manual':
        return KycStepType.manual;
      case 'SumsubAuto':
        return KycStepType.sumsubAuto;
      case 'SumsubVideo':
        return KycStepType.sumsubVideo;
      default:
        throw ArgumentError('Unknown KycStepType value: $value');
    }
  }
}

enum KycStepStatus {
  notStarted,
  inProgress,
  inReview,
  failed,
  completed,
  outdated,
  dataRequested,
  onHold,
}

extension KycStepStatusExtension on KycStepStatus {
  String get value {
    switch (this) {
      case KycStepStatus.notStarted:
        return 'NotStarted';
      case KycStepStatus.inProgress:
        return 'InProgress';
      case KycStepStatus.inReview:
        return 'InReview';
      case KycStepStatus.failed:
        return 'Failed';
      case KycStepStatus.completed:
        return 'Completed';
      case KycStepStatus.outdated:
        return 'Outdated';
      case KycStepStatus.dataRequested:
        return 'DataRequested';
      case KycStepStatus.onHold:
        return 'OnHold';
    }
  }

  String localizedValue(BuildContext context) {
    switch (this) {
      case KycStepStatus.notStarted:
        return S.of(context).kycStepStatusNotStarted;
      case KycStepStatus.inProgress:
        return S.of(context).kycStepStatusInProgress;
      case KycStepStatus.inReview:
        return S.of(context).kycStepStatusInReview;
      case KycStepStatus.failed:
        return S.of(context).kycStepStatusFailed;
      case KycStepStatus.completed:
        return S.of(context).kycStepStatusCompleted;
      case KycStepStatus.outdated:
        return S.of(context).kycStepStatusOutdated;
      case KycStepStatus.dataRequested:
        return S.of(context).kycStepStatusDataRequested;
      case KycStepStatus.onHold:
        return S.of(context).kycStepStatusOnHold;
    }
  }

  static KycStepStatus fromValue(String value) {
    switch (value) {
      case 'NotStarted':
        return KycStepStatus.notStarted;
      case 'InProgress':
        return KycStepStatus.inProgress;
      case 'InReview':
        return KycStepStatus.inReview;
      case 'Failed':
        return KycStepStatus.failed;
      case 'Completed':
        return KycStepStatus.completed;
      case 'Outdated':
        return KycStepStatus.outdated;
      case 'DataRequested':
        return KycStepStatus.dataRequested;
      case 'OnHold':
        return KycStepStatus.onHold;
      default:
        throw ArgumentError('Unknown KycStepStatus value: $value');
    }
  }
}

enum KycStepReason {
  accountExists,
  accountMergeRequested,
}

extension KycStepReasonExtension on KycStepReason {
  String get value {
    switch (this) {
      case KycStepReason.accountExists:
        return 'AccountExists';
      case KycStepReason.accountMergeRequested:
        return 'AccountMergeRequested';
    }
  }

  static KycStepReason fromValue(String value) {
    switch (value) {
      case 'AccountExists':
        return KycStepReason.accountExists;
      case 'AccountMergeRequested':
        return KycStepReason.accountMergeRequested;
      default:
        throw ArgumentError('Unknown KycStepReason value: $value');
    }
  }
}

extension KycLevelExtension on KycLevel {
  int get value {
    switch (this) {
      case KycLevel.level0:
        return 0;
      case KycLevel.level10:
        return 10;
      case KycLevel.level20:
        return 20;
      case KycLevel.level30:
        return 30;
      case KycLevel.level40:
        return 40;
      case KycLevel.level50:
        return 50;
      case KycLevel.terminated:
        return -10;
      case KycLevel.rejected:
        return -20;
    }
  }

  static KycLevel fromValue(int value) {
    switch (value) {
      case 0:
        return KycLevel.level0;
      case 10:
        return KycLevel.level10;
      case 20:
        return KycLevel.level20;
      case 30:
        return KycLevel.level30;
      case 40:
        return KycLevel.level40;
      case 50:
        return KycLevel.level50;
      case -10:
        return KycLevel.terminated;
      case -20:
        return KycLevel.rejected;
      default:
        throw ArgumentError('Unknown KycLevel value: $value');
    }
  }
}
