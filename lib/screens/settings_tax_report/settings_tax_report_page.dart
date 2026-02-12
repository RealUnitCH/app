import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings_tax_report/cubit/settings_tax_report_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/date_picker_field.dart';

class SettingsTaxReportPage extends StatelessWidget {
  const SettingsTaxReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsTaxReportCubit(
        getIt<RealUnitPdfService>(),
      ),
      child: SettingsTaxReportView(),
    );
  }
}

class SettingsTaxReportView extends StatelessWidget {
  SettingsTaxReportView({super.key});

  final _datePickerModel = _DatePickerModel();

  @override
  Widget build(BuildContext context) {
    final settingsState = context.read<SettingsBloc>().state;
    return BlocListener<SettingsTaxReportCubit, SettingsTaxReportState>(
      listener: (context, state) async {
        if (state is SettingsTaxReportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
        if (state is SettingsTaxReportSuccess) {
          await OpenFile.open(state.taxReportPath);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            S.of(context).taxReport,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            spacing: 20.0,
            children: [
              Text(
                S.of(context).taxReportDescription,
                textAlign: TextAlign.center,
              ),
              ValueListenableBuilder(
                  valueListenable: _datePickerModel,
                  builder: (context, value, child) {
                    return DatePickerField(
                      initialDate: _datePickerModel.value,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now(),
                      onDateSelected: (date) => _datePickerModel.setDate(date),
                    );
                  }),
              BlocBuilder<SettingsTaxReportCubit, SettingsTaxReportState>(
                  builder: (context, state) {
                if (state is SettingsTaxReportLoading) {
                  return FilledButton.icon(
                    onPressed: null,
                    icon: SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: RealUnitColors.basic.black.withValues(alpha: 0.5),
                      ),
                    ),
                    label: Text(S.of(context).pdf),
                  );
                }
                return FilledButton.icon(
                  onPressed: () => context.read<SettingsTaxReportCubit>().generateTaxReport(
                      date: _datePickerModel.value,
                      currency: settingsState.currency,
                      language: settingsState.language),
                  label: Text(S.of(context).pdf),
                  icon: const Icon(Icons.file_download_outlined),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerModel extends ValueNotifier<DateTime> {
  _DatePickerModel() : super(DateTime.now());

  void setDate(DateTime date) => value = date;
}
