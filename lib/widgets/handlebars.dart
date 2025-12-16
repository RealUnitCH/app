import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class Handlebars {
  static Widget horizontal(
    BuildContext context, {
    EdgeInsetsGeometry margin = const EdgeInsets.only(top: 10),
    double? width,
    double borderRadius = 5,
  }) =>
      Container(
        margin: margin,
        height: 5,
        width: width ?? MediaQuery.of(context).size.width * 0.25,
        decoration: BoxDecoration(
          color: RealUnitColors.realUnitBlack,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      );
}
