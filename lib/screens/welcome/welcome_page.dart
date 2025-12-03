import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
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
                      SizedBox(height: 8),
                      Text(
                        'RealUnit Wallet',
                        style: const TextStyle(
                          color: RealUnitColors.realUnitBlack,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 30 / 26,
                          letterSpacing: 26 * -0.02,
                        ),
                      ),
                      Text(
                        'Investiere in reale Werte und behalte die volle Kontrolle — rund um die Uhr.',
                        style: const TextStyle(
                          color: RealUnitColors.neutral500,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 22 / 16,
                          letterSpacing: 0.0,
                        ),
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
                            Text(
                              'Software Wallet',
                              style: const TextStyle(
                                color: RealUnitColors.realUnitBlack,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 24 / 20,
                                letterSpacing: 20 * -0.01,
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/images/icons/software_wallet.svg',
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.push('/wallet/create'),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              RealUnitColors.brand600,
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.all(8),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          child: Text('Neue Wallet erstellen'),
                        ),
                        FilledButton(
                          onPressed: () => context.push('/wallet/restore'),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              RealUnitColors.neutral100,
                            ),
                            foregroundColor: WidgetStateProperty.all(
                              RealUnitColors.realUnitBlack,
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.all(8),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          child: Text('Wallet wiederherstellen'),
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
                            Text(
                              'BitBox \nHardware Wallet',
                              style: const TextStyle(
                                color: RealUnitColors.realUnitBlack,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 24 / 20,
                                letterSpacing: 20 * -0.01,
                              ),
                            ),
                            SvgPicture.asset('assets/images/icons/bitbox.svg'),
                          ],
                        ),
                        SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {},
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              RealUnitColors.brand600,
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.all(8),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
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
