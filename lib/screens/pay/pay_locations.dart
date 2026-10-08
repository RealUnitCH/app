const String payLocationsBlockchain = 'Ethereum';
const String payLocationsAsset = 'ZCHF';

const String payLocationsPlacesUrl =
    'https://api.opencryptopay.io/map/places?blockchain=Ethereum&asset=ZCHF';

class PayLocationPin {
  final String name;
  final String? category;
  final double lat;
  final double lon;

  const PayLocationPin({
    required this.name,
    required this.category,
    required this.lat,
    required this.lon,
  });
}

bool payLocationsPlacesBodyIsList(Object? body) {
  return body is Map && body['places'] is List;
}

List<PayLocationPin> keepPayLocationPins(Object? body) {
  if (body is! Map) {
    return const [];
  }

  final places = body['places'];
  if (places is! List) {
    return const [];
  }

  final pins = <PayLocationPin>[];
  for (final place in places) {
    if (place is! Map) {
      continue;
    }

    final lat = _finiteDouble(place['lat']);
    final lon = _finiteDouble(place['lon']);
    if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      continue;
    }

    // The published list omits supports. Keep those places. A present
    // supports list must include ZCHF on Ethereum.
    final supports = place['supports'];
    if (supports != null &&
        (supports is! List ||
            !supports.any(
              (support) =>
                  support is Map &&
                  support['blockchain'] == payLocationsBlockchain &&
                  support['asset'] == payLocationsAsset,
            ))) {
      continue;
    }

    final name = place['name'];
    final category = place['category'];
    pins.add(
      PayLocationPin(
        name: name is String ? name : '',
        category: category is String ? category : null,
        lat: lat,
        lon: lon,
      ),
    );
  }

  return pins;
}

double? _finiteDouble(Object? value) {
  if (value is! num) {
    return null;
  }

  final number = value.toDouble();
  return number.isFinite ? number : null;
}
