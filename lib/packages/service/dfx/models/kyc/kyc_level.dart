enum KycLevel { level0, level10, level20, level30, level40, level50, terminated, rejected }

// Mirror of `KycProcessStatus` in the API
// (`src/subdomains/generic/kyc/dto/output/kyc-info.dto.ts`). The high-level
// KYC process state. Defaults to `inProgress` if absent on the wire so
// pre-PR backends degrade reasonably.
enum KycProcessStatus { inProgress, pendingReview, completed, failed }

extension KycProcessStatusExtension on KycProcessStatus {
  String get value {
    switch (this) {
      case KycProcessStatus.inProgress:
        return 'InProgress';
      case KycProcessStatus.pendingReview:
        return 'PendingReview';
      case KycProcessStatus.completed:
        return 'Completed';
      case KycProcessStatus.failed:
        return 'Failed';
    }
  }

  // Unknown values must throw, not silently degrade to `inProgress`. Silent
  // default would re-introduce the exact "local default decision" that the
  // API-as-Decision-Authority rule (foundation PR #491) forbids: if the API
  // later adds e.g. `OnHold` or `Suspended` the app must fail loud so we
  // notice instead of routing the user through `_continueKyc` blindly.
  //
  // The pre-#3732 backwards-compat default applies only to an **absent**
  // field — the DTO parsers handle that on the JSON layer (see
  // `KycLevelDto.fromJson` / `KycSessionDto.fromJson`).
  static KycProcessStatus fromValue(String value) {
    switch (value) {
      case 'InProgress':
        return KycProcessStatus.inProgress;
      case 'PendingReview':
        return KycProcessStatus.pendingReview;
      case 'Completed':
        return KycProcessStatus.completed;
      case 'Failed':
        return KycProcessStatus.failed;
      default:
        throw ArgumentError('Unsupported KYC process status: $value');
    }
  }
}

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
  phoneChange,
  nameChange,
  addressChange,
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
      case KycStepName.phoneChange:
        return 'PhoneChange';
      case KycStepName.nameChange:
        return 'NameChange';
      case KycStepName.addressChange:
        return 'AddressChange';
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
      case 'PhoneChange':
        return KycStepName.phoneChange;
      case 'NameChange':
        return KycStepName.nameChange;
      case 'AddressChange':
        return KycStepName.addressChange;
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
