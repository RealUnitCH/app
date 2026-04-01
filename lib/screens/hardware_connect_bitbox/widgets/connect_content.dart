import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';

class ConnectContent extends StatelessWidget {
  final String imagePath;
  final String title;
  final Widget child;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConnectContent({
    super.key,
    required this.imagePath,
    required this.title,
    required this.child,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: .infinity,
    padding: const .symmetric(vertical: 20),
    child: Column(
      spacing: 10,
      children: [
        Padding(
          padding: const .only(top: 40, bottom: 20),
          child: SvgPicture.asset(imagePath),
        ),
        Text(
          title,
          textAlign: .center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        child,
        const Spacer(),
        Column(
          spacing: 12,
          children: [
            if (onConfirm != null)
              FilledButton(
                onPressed: onConfirm,
                child: Text(S.of(context).confirm),
              ),
            if (onCancel != null)
              FilledButton(
                style: Theme.of(context).filledButtonTheme.style?.copyWith(
                  backgroundColor: .all(RealUnitColors.neutral100),
                  foregroundColor: .all(RealUnitColors.realUnitBlack),
                ),
                onPressed: onCancel,
                child: Text(S.of(context).cancel),
              ),
          ],
        ),
      ],
    ),
  );
}
