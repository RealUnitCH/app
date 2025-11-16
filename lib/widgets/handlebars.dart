import 'package:realunit_wallet/styles/colors.dart';
import 'package:flutter/material.dart';

class Handlebars {
  static Widget horizontal(
    BuildContext context, {
    EdgeInsetsGeometry margin = const EdgeInsets.only(top: 10),
    double? width,
  }) =>
      Container(
        margin: margin,
        height: 5,
        width: width ??= MediaQuery.of(context).size.width * 0.25,
        decoration: BoxDecoration(
          color: DEuroColors.anthracite,
          borderRadius: BorderRadius.circular(5.0),
        ),
      );
}
