const String payLocationsFiltersUrl = 'https://api.opencryptopay.io/map/filters';

String payLocationsPlacesUrl(String blockchain, String asset) {
  return 'https://api.opencryptopay.io/map/places?blockchain='
      '${Uri.encodeQueryComponent(blockchain)}&asset='
      '${Uri.encodeQueryComponent(asset)}';
}

String? placesUrlAfterFilters({
  required bool filtersOk,
  required String blockchain,
  required String asset,
}) {
  if (!filtersOk) {
    return null;
  }

  return payLocationsPlacesUrl(blockchain, asset);
}

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

List<PayLocationPin> keepPayLocationPins(
  Object? body,
  String blockchain,
  String asset,
) {
  if (body is! Map<Object?, Object?>) {
    return const [];
  }

  final places = body['places'];
  if (places is! List) {
    return const [];
  }

  final pins = <PayLocationPin>[];
  for (final place in places) {
    if (place is! Map<Object?, Object?>) {
      continue;
    }

    final lat = _finiteDouble(place['lat']);
    final lon = _finiteDouble(place['lon']);
    if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      continue;
    }

    final supports = place['supports'];
    if (supports is! List ||
        !supports.any(
          (support) =>
              support is Map<Object?, Object?> &&
              support['blockchain'] == blockchain &&
              support['asset'] == asset,
        )) {
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

class PayLocationChoices {
  final List<String> blockchains;
  final List<String> assets;

  const PayLocationChoices({
    required this.blockchains,
    required this.assets,
  });
}

PayLocationChoices parsePayLocationFilters(Object? body) {
  final blockchains = <String>[];
  final assets = <String>[];

  if (body is Map<Object?, Object?>) {
    final rawBlockchains = body['blockchains'];
    if (rawBlockchains is List) {
      blockchains.addAll(rawBlockchains.whereType<String>());
    }

    final rawAssets = body['assets'];
    if (rawAssets is List) {
      assets.addAll(rawAssets.whereType<String>());
    }
  }

  if (!blockchains.contains('Ethereum')) {
    blockchains.insert(0, 'Ethereum');
  }
  if (!assets.contains('ZCHF')) {
    assets.insert(0, 'ZCHF');
  }

  return PayLocationChoices(blockchains: blockchains, assets: assets);
}

double? _finiteDouble(Object? value) {
  if (value is! num) {
    return null;
  }

  final number = value.toDouble();
  return number.isFinite ? number : null;
}
