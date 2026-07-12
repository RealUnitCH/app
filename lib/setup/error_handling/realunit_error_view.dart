import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

/// Minimal on-brand replacement for the default grey [ErrorWidget]. Wired into
/// [ErrorWidget.builder] in `main` and rendered for any uncaught build/paint
/// exception, so it lives outside the [MaterialApp] localization scope — the
/// copy is deliberately hardcoded (no `S.of(context)`) because this is a
/// last-resort surface that must render even when localization is unavailable.
/// It brings its own [Directionality] so it can paint as a bare root widget.
/// In debug it also shows the exception text to keep diagnosis fast; release
/// shows only the friendly line.
///
/// Kept in its own file (rather than inline in `main.dart`) so it can be
/// widget-tested without importing `main.dart`, whose transitive imports would
/// otherwise pull untested bootstrap code into the coverage report.
class RealUnitErrorView extends StatelessWidget {
  const RealUnitErrorView({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Container(
      color: RealUnitColors.neutral50,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Icon(Icons.error_outline, color: RealUnitColors.status.red600, size: 48),
          const Text(
            'Something went wrong. Please restart the app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RealUnitColors.neutral900,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (kDebugMode)
            Text(
              details.exceptionAsString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: RealUnitColors.neutral500),
            ),
        ],
      ),
    ),
  );
}
