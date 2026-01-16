import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/screens/settings_tax_report/cubit/settings_tax_report_cubit.dart';

class SettingsTaxReportPage extends StatelessWidget {
  const SettingsTaxReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsTaxReportCubit(
        getIt<RealUnitPdfService>(),
      ),
      child: const SettingsTaxReportView(),
    );
  }
}

class SettingsTaxReportView extends StatelessWidget {
  const SettingsTaxReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Steuerbericht',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Row(),
    );
  }
}
