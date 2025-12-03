import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RealUnitColors.brand700,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RealUnitIcon(
                        size: 48,
                      ),
                      Text(
                        'RealUnit Wallet',
                      ),
                      Text(
                        'Investiere in reale Werte und behalte die volle Kontrolle — rund um die Uhr.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Software Wallet'),
                            SvgPicture.asset('assets/images/icons/software_wallet.svg'),
                          ],
                        ),
                        SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.go('/wallet/create'),
                          child: Text('Neue Wallet erstellen'),
                        ),
                        FilledButton(
                          onPressed: () => context.go('/wallet/restore'),
                          child: Text(S.of(context).import_wallet),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('BitBox Hardware Wallet'),
                            SvgPicture.asset('assets/images/icons/bitbox.svg'),
                          ],
                        ),
                        SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {},
                          child: Text('Mit BitBox verbinden'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
