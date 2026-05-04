import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

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
              AppFilledButton(
                onPressed: onConfirm,
                label: S.of(context).confirm,
              ),
            if (onCancel != null)
              AppFilledButton(
                variant: .secondary,
                fullWidth: false,
                onPressed: onCancel,
                label: S.of(context).cancel,
              ),
          ],
        ),
      ],
    ),
  );
}
