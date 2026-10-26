import 'dart:math' as math;

const String payLocationsBlockchain = 'Ethereum';
const String payLocationsAsset = 'ZCHF';

const String payLocationsPlacesUrl =
    'https://api.opencryptopay.io/map/places?blockchain=Ethereum&asset=ZCHF';
const String payLocationsStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';
const String payLocationClusterColor = '#034C81';

const double payLocationCountrySouth = 45.83003;
const double payLocationCountryNorth = 47.77564;
const double payLocationCountryWest = 5.97002;
const double payLocationCountryEast = 10.45459;

class PayLocationPin {
  final String name;
  final String? category;
  final double lat;
  final double lon;
  final String? id;
  final String description;
  final String techProvider;
  final String shopType;
  final String street;
  final String houseNumber;
  final String postalCode;
  final String city;
  final String country;
  final String activity;
  final String? coverUrl;

  const PayLocationPin({
    required this.name,
    required this.category,
    required this.lat,
    required this.lon,
    this.id,
    this.description = '',
    this.techProvider = '',
    this.shopType = '',
    this.street = '',
    this.houseNumber = '',
    this.postalCode = '',
    this.city = '',
    this.country = '',
    this.activity = 'none',
    this.coverUrl,
  });
}

class PayLocationPhoto {
  final String url;
  final String? caption;
  final double? width;
  final double? height;

  const PayLocationPhoto({
    required this.url,
    this.caption,
    this.width,
    this.height,
  });
}

String payLocationActivityColor(String activity) {
  return switch (activity) {
    'daily' => '#FF4D00',
    'within7Days' => '#FF7A29',
    'within30Days' => '#FFA05C',
    'olderThan30Days' => '#FFC48F',
    _ => '#FFE3CC',
  };
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
    if (name is! String || name.trim().isEmpty) {
      continue;
    }
    final category = place['category'];
    final id = _nonEmptyString(place['id']);
    final activity = _payLocationActivity(place['activity']);
    final coverPhoto = place['coverPhoto'];
    final coverUrl = coverPhoto is Map ? _httpsUrl(coverPhoto['url']) : null;
    pins.add(
      PayLocationPin(
        name: name.trim(),
        category: category is String ? category.trim() : null,
        lat: lat,
        lon: lon,
        id: id,
        description: _trimmedString(place['description']),
        techProvider: _trimmedString(place['techProvider']),
        shopType: _trimmedString(place['shopType']),
        street: _trimmedString(place['street']),
        houseNumber: _trimmedString(place['houseNumber']),
        postalCode: _trimmedString(place['postalCode']),
        city: _trimmedString(place['city']),
        country: _trimmedString(place['country']),
        activity: activity,
        coverUrl: coverUrl,
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

enum PayLocationMarkerKind { pin, cluster }

class PayLocationMarker {
  final PayLocationMarkerKind kind;
  final double lat;
  final double lon;
  final double diameter;
  final double strokeWidth;
  final String color;
  final int? count;
  final String? town;
  final List<PayLocationPin> pins;

  const PayLocationMarker({
    required this.kind,
    required this.lat,
    required this.lon,
    required this.diameter,
    required this.strokeWidth,
    required this.color,
    required this.pins,
    this.count,
    this.town,
  });
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

List<PayLocationMarker> payLocationMarkers({
  required List<PayLocationPin> visible,
  required PayLocationPin? selected,
  required double zoom,
}) {
  PayLocationPin? selectedPin;
  if (selected != null && visible.any((pin) => samePayLocationPin(pin, selected))) {
    selectedPin = selected;
  }
  final clustered = [
    for (final pin in visible)
      if (selectedPin == null || !samePayLocationPin(pin, selectedPin)) pin,
  ];
  final clusters = clusterPayLocationPins(
    clustered,
    cellDegrees: payLocationClusterCellDegrees(zoom),
  );
  final markers = <PayLocationMarker>[
    for (final cluster in clusters)
      if (cluster.isSingle)
        PayLocationMarker(
          kind: PayLocationMarkerKind.pin,
          lat: cluster.lat,
          lon: cluster.lon,
          diameter: 16,
          strokeWidth: 2,
          color: payLocationActivityColor(cluster.pins.single.activity),
          pins: cluster.pins,
          town: _payLocationMarkerTown(cluster.pins.single, zoom <= 7.5),
        )
      else
        PayLocationMarker(
          kind: PayLocationMarkerKind.cluster,
          lat: cluster.lat,
          lon: cluster.lon,
          diameter: 34,
          strokeWidth: 2,
          color: payLocationClusterColor,
          pins: cluster.pins,
          count: cluster.pins.length,
        ),
  ];
  if (selectedPin != null) {
    markers.add(
      PayLocationMarker(
        kind: PayLocationMarkerKind.pin,
        lat: selectedPin.lat,
        lon: selectedPin.lon,
        diameter: 18,
        strokeWidth: 3,
        color: payLocationActivityColor(selectedPin.activity),
        pins: [selectedPin],
        town: _payLocationMarkerTown(selectedPin, true),
      ),
    );
  }
  return markers;
}

String? _payLocationMarkerTown(PayLocationPin pin, bool show) {
  if (!show) {
    return null;
  }
  final town = payLocationLabel(pin.name).town;
  return town.isEmpty ? null : town;
}

List<String> payLocationAddressLines(PayLocationPin pin) {
  return [
    _joinNonEmpty([pin.street, pin.houseNumber], ' '),
    _joinNonEmpty([pin.postalCode, pin.city], ' '),
    pin.country,
  ].where((line) => line.isNotEmpty).toList(growable: false);
}

String? payLocationDetailUrl(String? id) {
  if (id == null || !id.startsWith('npub1')) {
    return null;
  }
  return 'https://api.opencryptopay.io/map/places/$id';
}

List<PayLocationPhoto> payLocationPhotos(Object? body) {
  if (body is! Map) {
    return const [];
  }
  final place = body['place'];
  if (place is! Map) {
    return const [];
  }
  final photos = place['photos'];
  if (photos is! List) {
    return const [];
  }

  final result = <PayLocationPhoto>[];
  for (final photo in photos) {
    if (photo is! Map) {
      continue;
    }
    final url = _httpsUrl(photo['url']);
    if (url == null) {
      continue;
    }
    result.add(
      PayLocationPhoto(
        url: url,
        caption: _nonEmptyString(photo['caption']),
        width: _positiveFiniteDouble(photo['width']),
        height: _positiveFiniteDouble(photo['height']),
      ),
    );
  }
  return result;
}

double payLocationZoomForSpan({
  required double south,
  required double north,
  required double west,
  required double east,
  required double width,
  required double height,
  required double padding,
  required double maxZoom,
}) {
  final lonSpan = math.max((east - west).abs(), 1e-9);
  double mercatorY(double lat) {
    final latRad = lat * math.pi / 180;
    return math.log(math.tan(math.pi / 4 + latRad / 2));
  }

  final ySpan = math.max((mercatorY(north) - mercatorY(south)).abs(), 1e-9);
  final usableW = math.max(width - 2 * padding, 1);
  final usableH = math.max(height - 2 * padding, 1);
  final zLon = math.log(usableW / 256 * 360 / lonSpan) / math.log(2);
  final zLat = math.log(usableH / 256 / (ySpan / (2 * math.pi))) / math.log(2);
  return math.min(zLon, zLat).clamp(5, maxZoom).toDouble();
}

List<PayLocationPin> filterPayLocationPins(List<PayLocationPin> pins, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return pins;
  }
  return [for (final pin in pins) if (pin.name.toLowerCase().contains(needle)) pin];
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

PayLocationLabel payLocationLabel(String name) {
  final trimmed = name.trim();
  final comma = trimmed.lastIndexOf(',');
  if (comma <= 0 || comma >= trimmed.length - 1) {
    return PayLocationLabel(trimmed, null);
  }

  final street = trimmed.substring(0, comma).trim();
  final place = trimmed.substring(comma + 1).trim();
  if (street.isEmpty || place.isEmpty) {
    return PayLocationLabel(trimmed, null);
  }
  return PayLocationLabel(place, street);
}

List<PayLocationPin> sortPayLocationPins(List<PayLocationPin> pins) {
  final sorted = [...pins]..sort((a, b) {
    final left = payLocationLabel(a.name);
    final right = payLocationLabel(b.name);
    final byTown = left.town.compareTo(right.town);
    if (byTown != 0) {
      return byTown;
    }
    final byPlace = left.place.compareTo(right.place);
    if (byPlace != 0) {
      return byPlace;
    }
    return (left.street ?? '').compareTo(right.street ?? '');
  });
  return sorted;
}

bool samePayLocationPin(PayLocationPin a, PayLocationPin b) {
  return a.name == b.name && a.lat == b.lat && a.lon == b.lon;
}

double? _finiteDouble(Object? value) {
  if (value is! num) {
    return null;
  }

  final number = value.toDouble();
  return number.isFinite ? number : null;
}

double? _positiveFiniteDouble(Object? value) {
  final number = _finiteDouble(value);
  return number != null && number > 0 ? number : null;
}

String _trimmedString(Object? value) {
  return value is String ? value.trim() : '';
}

String? _nonEmptyString(Object? value) {
  final text = _trimmedString(value);
  return text.isEmpty ? null : text;
}

String _payLocationActivity(Object? value) {
  return switch (value) {
    'daily' => 'daily',
    'within7Days' => 'within7Days',
    'within30Days' => 'within30Days',
    'olderThan30Days' => 'olderThan30Days',
    'none' => 'none',
    _ => 'none',
  };
}

String? _httpsUrl(Object? value) {
  final url = _nonEmptyString(value);
  if (url == null || !url.startsWith('https://')) {
    return null;
  }
  final parsed = Uri.tryParse(url);
  return parsed != null && parsed.scheme == 'https' && parsed.host.isNotEmpty ? url : null;
}

String _joinNonEmpty(List<String> parts, String separator) {
  return parts.where((part) => part.isNotEmpty).join(separator);
}
