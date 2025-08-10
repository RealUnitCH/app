import 'package:flutter/material.dart';

class VerticalIconButton extends StatelessWidget {
  final void Function()? onPressed;
  final Widget icon;
  final String label;

  const VerticalIconButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
  });

  static Widget extended({
    void Function()? onPressed,
    required Widget icon,
    required String label,
  }) =>
      _WideVerticalIconButton(
        onPressed: onPressed,
        icon: icon,
        label: label,
      );

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onPressed,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: CircleAvatar(
                backgroundColor: Colors.white.withAlpha(50),
                child: icon,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            )
          ],
        ),
      );
}

class _WideVerticalIconButton extends StatelessWidget {
  final void Function()? onPressed;
  final Widget icon;
  final String label;

  const _WideVerticalIconButton({
    this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onPressed,
        child: Column(
          children: [
            Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withAlpha(50),
              ),
              margin: const EdgeInsets.only(bottom: 5),
              child: icon,
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            )
          ],
        ),
      );
}
