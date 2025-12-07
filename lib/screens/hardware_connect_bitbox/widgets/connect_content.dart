import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:realunit_wallet/styles/styles.dart';

class ConnectContent extends StatelessWidget {
  final String imagePath;
  final String title;
  final String content;

  const ConnectContent({
    super.key,
    required this.imagePath,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 40, bottom: 20),
        child: SvgPicture.asset(imagePath),
      ),
      Text(
        title,
        textAlign: TextAlign.center,
        style: kBottonSheetTitleTextStyle,
      ),
      SizedBox(
        width: 330,
        child: Text(
          content,
          textAlign: TextAlign.center,
          style: kBottonSheetContentTextStyle,
        ),
      ),
    ],
  );
}
