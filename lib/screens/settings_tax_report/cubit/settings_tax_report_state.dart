part of 'settings_tax_report_cubit.dart';

abstract class SettingsTaxReportState extends Equatable {
  const SettingsTaxReportState();

  @override
  List<Object?> get props => [];
}

class SettingsTaxReportInitial extends SettingsTaxReportState {
  const SettingsTaxReportInitial();
}

class SettingsTaxReportLoading extends SettingsTaxReportState {
  const SettingsTaxReportLoading();
}

class SettingsTaxReportSuccess extends SettingsTaxReportState {
  final String taxReportPath;

  const SettingsTaxReportSuccess(this.taxReportPath);

  @override
  List<Object?> get props => [taxReportPath];
}

class SettingsTaxReportFailure extends SettingsTaxReportState {
  const SettingsTaxReportFailure();
}
