import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/utils/asset_logo.dart';
import 'package:flutter/material.dart';

class ChainAssetIcon extends StatelessWidget {
  final Asset asset;

  const ChainAssetIcon({super.key, required this.asset});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Image.asset(getAssetImagePath(asset)),
            Positioned(
              bottom: 0,
              right: 0,
              width: 13,
              child: Image.asset(getChainImagePath(asset.chainId)),
            ),
          ],
        ),
      );
}
