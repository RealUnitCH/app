import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pay/pay_info_page.dart';
import 'package:realunit_wallet/screens/pay/pay_scan_page.dart';
import 'package:realunit_wallet/setup/di.dart';

/// The software-wallet disclosure stays up when pay is not allowed, even if
/// some other install already stored [alreadySeen]. The unavailable notice
/// is not that disclosure.
bool showPayIntro({required bool payAllowed, required bool alreadySeen}) {
  if (!payAllowed) return true;
  return !alreadySeen;
}

bool readPayIntroSeen() {
  if (!getIt.isRegistered<SharedPreferences>() || !getIt.isRegistered<SettingsRepository>()) {
    return false;
  }
  return getIt<SettingsRepository>().payIntroSeen;
}

void markPayIntroSeen() {
  if (!getIt.isRegistered<SharedPreferences>() || !getIt.isRegistered<SettingsRepository>()) {
    return;
  }
  getIt<SettingsRepository>().payIntroSeen = true;
}

/// Picks the pay screen from the live wallet. A wallet that cannot pay always
/// shows the unavailable notice and is not marked seen. The choice between
/// the disclosure and the scanner is fixed on the first payable frame of this
/// visit, so writing the flag does not open the scanner.
class PayIntroGate extends StatefulWidget {
  final String? initialPayload;

  const PayIntroGate({super.key, this.initialPayload});

  @override
  State<PayIntroGate> createState() => _PayIntroGateState();
}

class _PayIntroGateState extends State<PayIntroGate> {
  /// Null until this visit has a software wallet that can pay.
  bool? _showIntro;
  var _markScheduled = false;

  @override
  Widget build(BuildContext context) {
    final payAllowed =
        context.watch<HomeBloc>().state.openWallet?.walletType == WalletType.software;
    if (!payAllowed) {
      return PayInfoPage(initialPayload: widget.initialPayload);
    }
    final showIntro = _showIntro ??= showPayIntro(
      payAllowed: true,
      alreadySeen: readPayIntroSeen(),
    );
    if (showIntro && !_markScheduled) {
      _markScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final stillPayable =
            context.read<HomeBloc>().state.openWallet?.walletType == WalletType.software;
        if (!stillPayable) {
          _markScheduled = false;
          return;
        }
        markPayIntroSeen();
      });
    }
    if (showIntro) {
      return PayInfoPage(initialPayload: widget.initialPayload);
    }
    return PayScanPage(initialPayload: widget.initialPayload);
  }
}
