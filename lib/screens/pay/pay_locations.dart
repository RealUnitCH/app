import 'dart:math' as math;

const String payLocationsBlockchain = 'Ethereum';
const String payLocationsAsset = 'ZCHF';

const String payLocationsPlacesUrl =
    'https://api.opencryptopay.io/map/places?blockchain=Ethereum&asset=ZCHF';

class PayLocationPin {
  final String name;
  final String? category;
  final double lat;
  final double lon;
  final String? street;
  final String? houseNumber;
  final String? postalCode;
  final String? city;

  const PayLocationPin({
    required this.name,
    required this.category,
    required this.lat,
    required this.lon,
    this.street,
    this.houseNumber,
    this.postalCode,
    this.city,
  });

  String get addressLine {
    final streetValue = street;
    final houseNumberValue = houseNumber;
    final postalCodeValue = postalCode;
    final cityValue = city;
    final streetLine = [
      if (streetValue != null && streetValue.isNotEmpty) streetValue,
      if (houseNumberValue != null && houseNumberValue.isNotEmpty) houseNumberValue,
    ].join(' ');
    final cityLine = [
      if (postalCodeValue != null && postalCodeValue.isNotEmpty) postalCodeValue,
      if (cityValue != null && cityValue.isNotEmpty) cityValue,
    ].join(' ');
    return [
      if (streetLine.isNotEmpty) streetLine,
      if (cityLine.isNotEmpty) cityLine,
    ].join(', ');
  }
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

    // Absent supports, and [] for "not stated", keep the place: the API
    // already filtered the request by blockchain/asset. A non-empty list
    // must include ZCHF on Ethereum. Any other supports value is dropped.
    final supports = place['supports'];
    if (supports != null) {
      if (supports is! List) {
        continue;
      }
      if (supports.isNotEmpty &&
          !supports.any(
            (support) =>
                support is Map &&
                support['blockchain'] == payLocationsBlockchain &&
                support['asset'] == payLocationsAsset,
          )) {
        continue;
      }
    }

    final name = place['name'];
    if (name is! String || name.trim().isEmpty) {
      continue;
    }
    final category = place['category'];
    pins.add(
      PayLocationPin(
        name: name.trim(),
        category: category is String ? category : null,
        lat: lat,
        lon: lon,
        street: _optionalString(place['street']),
        houseNumber: _optionalString(place['houseNumber']),
        postalCode: _optionalString(place['postalCode']),
        city: _optionalString(place['city']),
      ),
    );
  }

  return pins;
}

class PayLocationCluster {
  final double lat;
  final double lon;
  final List<PayLocationPin> pins;

  const PayLocationCluster({required this.lat, required this.lon, required this.pins});

  bool get isSingle => pins.length == 1;
}

/// Cell size for a cluster spacing of about 64 pixels at [zoom].
double payLocationClusterCellDegrees(double zoom) {
  final worldPixels = 256 * math.pow(2, zoom);
  return 360 / worldPixels * 64;
}

List<PayLocationCluster> clusterPayLocationPins(
  List<PayLocationPin> pins, {
  required double cellDegrees,
}) {
  if (pins.isEmpty) {
    return const [];
  }
  if (cellDegrees <= 0) {
    return [
      for (final pin in pins) PayLocationCluster(lat: pin.lat, lon: pin.lon, pins: [pin]),
    ];
  }

  final groups = <String, List<PayLocationPin>>{};
  for (final pin in pins) {
    final key = '${(pin.lat / cellDegrees).floor()}:${(pin.lon / cellDegrees).floor()}';
    groups.putIfAbsent(key, () => []).add(pin);
  }

  return [
    for (final group in groups.values)
      PayLocationCluster(
        lat: group.fold<double>(0, (sum, pin) => sum + pin.lat) / group.length,
        lon: group.fold<double>(0, (sum, pin) => sum + pin.lon) / group.length,
        pins: group,
      ),
  ];
}

List<PayLocationPin> filterPayLocationPins(List<PayLocationPin> pins, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return pins;
  }
  return [
    for (final pin in pins)
      if (pin.name.toLowerCase().contains(needle) ||
          (pin.city?.toLowerCase().contains(needle) ?? false) ||
          (pin.street?.toLowerCase().contains(needle) ?? false) ||
          (pin.postalCode?.toLowerCase().contains(needle) ?? false) ||
          pin.addressLine.toLowerCase().contains(needle))
        pin,
  ];
}

class PayLocationLabel {
  final String place;
  final String? street;

  const PayLocationLabel(this.place, this.street);

  /// Town without a leading Swiss or Liechtenstein postal code.
  String get town {
    final match = _postalTown.firstMatch(place);
    final town = match?.group(1);
    if (town == null || town.isEmpty) {
      return place;
    }
    return town;
  }
}

final RegExp _postalTown = RegExp(r'^\d{4}\s+(.+)$');

PayLocationLabel payLocationLabel(
  String name, {
  String? city,
  String? street,
  String? houseNumber,
}) {
  final trimmedCity = city?.trim();
  if (trimmedCity != null && trimmedCity.isNotEmpty) {
    final streetLine = [
      if (street != null && street.trim().isNotEmpty) street.trim(),
      if (houseNumber != null && houseNumber.trim().isNotEmpty) houseNumber.trim(),
    ].join(' ');
    return PayLocationLabel(trimmedCity, streetLine.isEmpty ? null : streetLine);
  }

  final trimmed = name.trim();
  final comma = trimmed.lastIndexOf(',');
  if (comma <= 0 || comma >= trimmed.length - 1) {
    return PayLocationLabel(trimmed, null);
  }

  final parsedStreet = trimmed.substring(0, comma).trim();
  final place = trimmed.substring(comma + 1).trim();
  if (parsedStreet.isEmpty || place.isEmpty) {
    return PayLocationLabel(trimmed, null);
  }
  return PayLocationLabel(place, parsedStreet);
}

List<PayLocationPin> sortPayLocationPins(List<PayLocationPin> pins) {
  final sorted = [...pins]
    ..sort((a, b) {
      final left = payLocationLabel(
        a.name,
        city: a.city,
        street: a.street,
        houseNumber: a.houseNumber,
      );
      final right = payLocationLabel(
        b.name,
        city: b.city,
        street: b.street,
        houseNumber: b.houseNumber,
      );
      final byCity = left.town.compareTo(right.town);
      if (byCity != 0) {
        return byCity;
      }
      final byName = a.name.compareTo(b.name);
      if (byName != 0) {
        return byName;
      }
      final leftStreet = _streetSortKey(a, left);
      final rightStreet = _streetSortKey(b, right);
      final byStreet = leftStreet.compareTo(rightStreet);
      if (byStreet != 0) {
        return byStreet;
      }
      final leftNumber = _leadingInt(a.houseNumber);
      final rightNumber = _leadingInt(b.houseNumber);
      if (leftNumber != null && rightNumber != null) {
        final byNumber = leftNumber.compareTo(rightNumber);
        if (byNumber != 0) {
          return byNumber;
        }
      } else if (leftNumber != null) {
        return -1;
      } else if (rightNumber != null) {
        return 1;
      }
      final byHouse = (a.houseNumber ?? '').compareTo(b.houseNumber ?? '');
      if (byHouse != 0) {
        return byHouse;
      }
      final byPostal = (a.postalCode ?? '').compareTo(b.postalCode ?? '');
      if (byPostal != 0) {
        return byPostal;
      }
      final byLat = a.lat.compareTo(b.lat);
      if (byLat != 0) {
        return byLat;
      }
      return a.lon.compareTo(b.lon);
    });
  return sorted;
}

String _streetSortKey(PayLocationPin pin, PayLocationLabel label) {
  final street = pin.street;
  if (street != null && street.isNotEmpty) {
    return street;
  }
  return label.street ?? '';
}

int? _leadingInt(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final match = RegExp(r'^\d+').firstMatch(value);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(0)!);
}

bool samePayLocationPin(PayLocationPin a, PayLocationPin b) {
  return a.name == b.name && a.lat == b.lat && a.lon == b.lon;
}

/// True when a city label would run under a shop marker at [zoom].
bool payLocationCityCovered({
  required String cityName,
  required double cityLat,
  required double cityLon,
  required double zoom,
  required List<PayLocationCluster> clusters,
  PayLocationPin? selected,
}) {
  final cell = payLocationClusterCellDegrees(zoom);
  if (cell <= 0) {
    return false;
  }

  final cosLat = math.cos(cityLat * math.pi / 180);
  final textPx = math.max(28.0, cityName.length * 7.2);
  bool hits(double lat, double lon, double markerPx) {
    final dx = (cityLon - lon) / cell * 64;
    final dy = cosLat == 0 ? 0.0 : (cityLat - lat) / cell * 64 / cosLat;
    final gap = math.sqrt(dx * dx + dy * dy) - (textPx / 2 + markerPx / 2);
    return gap < 4;
  }

  for (final cluster in clusters) {
    if (hits(cluster.lat, cluster.lon, cluster.isSingle ? 18 : 34)) {
      return true;
    }
  }
  if (selected != null && hits(selected.lat, selected.lon, 168)) {
    return true;
  }
  return false;
}

double? _finiteDouble(Object? value) {
  if (value is! num) {
    return null;
  }

  final number = value.toDouble();
  return number.isFinite ? number : null;
}

String? _optionalString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
