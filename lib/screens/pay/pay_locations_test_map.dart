import 'package:flutter/material.dart';
import 'package:realunit_wallet/screens/pay/pay_locations.dart';
import 'package:realunit_wallet/screens/pay/pay_locations_lakes.dart';
import 'package:realunit_wallet/screens/pay/pay_locations_outline.dart';
import 'package:realunit_wallet/styles/colors.dart';

/// Painted country view for widget tests. A platform view cannot host the street map.
class PayLocationsTestMap extends StatelessWidget {
  const PayLocationsTestMap({super.key, required this.pins, required this.selected});

  final List<PayLocationPin> pins;
  final PayLocationPin? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final townStyle = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: RealUnitColors.neutral900,
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 1,
    );
    final countStyle = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: RealUnitColors.basic.white,
      fontWeight: FontWeight.w700,
      fontSize: 13,
      height: 1,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
          return const ColoredBox(color: RealUnitColors.brand200);
        }
        final view = payLocationCountryView(width: width, height: height);
        final markers = payLocationMarkers(visible: pins, selected: selected, zoom: view.zoom);
        return CustomPaint(
          size: Size(width, height),
          painter: _PayLocationsTestMapPainter(
            view: view,
            width: width,
            height: height,
            markers: markers,
            townStyle: townStyle,
            countStyle: countStyle,
          ),
        );
      },
    );
  }
}

class _PayLocationsTestMapPainter extends CustomPainter {
  _PayLocationsTestMapPainter({
    required this.view,
    required this.width,
    required this.height,
    required this.markers,
    required this.townStyle,
    required this.countStyle,
  });

  final PayLocationCountryView view;
  final double width;
  final double height;
  final List<PayLocationMarker> markers;
  final TextStyle townStyle;
  final TextStyle countStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = RealUnitColors.brand200);
    final land = Paint()..color = RealUnitColors.basic.white;
    final landEdge = Paint()
      ..color = RealUnitColors.neutral600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final ring in payLocationCountryRings) {
      final path = _ring(ring);
      canvas.drawPath(path, land);
      canvas.drawPath(path, landEdge);
    }
    final water = Paint()..color = RealUnitColors.brand200;
    final waterEdge = Paint()
      ..color = RealUnitColors.realUnitBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final ring in payLocationLakeRings) {
      final path = _ring(ring);
      canvas.drawPath(path, water);
      canvas.drawPath(path, waterEdge);
    }

    for (final marker in markers) {
      _paintMarker(canvas, marker);
    }
    for (final marker in markers) {
      if (marker.count != null) {
        _paintCount(canvas, marker);
      }
    }
    for (final marker in markers) {
      final town = marker.town;
      if (town != null) {
        _paintTown(canvas, marker, town);
      }
    }
  }

  Path _ring(List<PayLocationRingPoint> ring) {
    final path = Path();
    for (var index = 0; index < ring.length; index++) {
      final point = _at(ring[index].lat, ring[index].lon);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  void _paintMarker(Canvas canvas, PayLocationMarker marker) {
    final center = _at(marker.lat, marker.lon);
    final fillRadius = marker.diameter / 2 - marker.strokeWidth;
    canvas.drawCircle(center, fillRadius, Paint()..color = _hex(marker.color));
    canvas.drawCircle(
      center,
      fillRadius + marker.strokeWidth / 2,
      Paint()
        ..color = RealUnitColors.basic.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = marker.strokeWidth,
    );
  }

  void _paintCount(Canvas canvas, PayLocationMarker marker) {
    final center = _at(marker.lat, marker.lon);
    final text = TextPainter(
      text: TextSpan(text: '${marker.count}', style: countStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  void _paintTown(Canvas canvas, PayLocationMarker marker, String town) {
    final center = _at(marker.lat, marker.lon);
    final text = TextPainter(
      text: TextSpan(text: town, style: townStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 140);
    const padH = 8.0;
    const padV = 3.0;
    final plateWidth = text.width + padH * 2;
    final plateHeight = text.height + padV * 2;
    final top = center.dy - marker.diameter / 2 - 4 - plateHeight;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - plateWidth / 2, top, plateWidth, plateHeight),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = RealUnitColors.basic.white);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = RealUnitColors.neutral200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    text.paint(canvas, Offset(rect.left + padH, rect.top + padV));
  }

  Offset _at(double lat, double lon) {
    final point = payLocationMapPoint(
      lat: lat,
      lon: lon,
      zoom: view.zoom,
      centerLat: view.centerLat,
      centerLon: view.centerLon,
      width: width,
      height: height,
    );
    return Offset(point.x, point.y);
  }

  Color _hex(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));

  @override
  bool shouldRepaint(covariant _PayLocationsTestMapPainter oldDelegate) {
    return oldDelegate.view.zoom != view.zoom ||
        oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.markers.length != markers.length;
  }
}
