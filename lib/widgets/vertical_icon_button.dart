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

