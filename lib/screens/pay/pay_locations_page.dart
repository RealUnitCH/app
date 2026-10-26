import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/pay/pay_locations.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PayLocationsPage extends StatefulWidget {
  const PayLocationsPage({
    super.key,
    this.mapBuilder,
    this.httpClient,
    this.loadOnStart = true,
    this.initialQuery = '',
  });

  final Widget Function(List<PayLocationPin> pins)? mapBuilder;
  final http.Client? httpClient;

  /// False keeps the initial loading frame and does not start a request.
  final bool loadOnStart;

  /// Pre-fills the shop search. Tests use it to show the no-match state.
  final String initialQuery;

  @override
  State<PayLocationsPage> createState() => _PayLocationsPageState();
}

class _PayLocationsPageState extends State<PayLocationsPage> {
  static const String _pinColor = '#E02523';
  static const String _clusterColor = '#034C81';
  static const String _white = '#FFFFFF';
  static const String _townColor = '#0F172A';

  late final TextEditingController _searchController;

  maplibre.MapLibreMapController? _mapController;
  List<PayLocationPin> _pins = const [];
  List<PayLocationMarker> _addedMarkers = const [];
  PayLocationPin? _selectedPin;
  late String _query;
  bool _loading = true;
  bool _error = false;
  bool _styleLoaded = false;
  bool _countryFitDone = false;
  bool _countryFitScheduled = false;
  bool _drawingMarkers = false;
  double _zoom = 7;
  maplibre.LatLng _center = const maplibre.LatLng(46.8, 8.23);
  Size _mapSize = Size.zero;
  int _loadGeneration = 0;
  int _markerGeneration = 0;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController = TextEditingController(text: widget.initialQuery);
    if (widget.loadOnStart) {
      _loadPlaces();
    }
  }

  Future<http.Response> _get(Uri url) {
    final client = widget.httpClient;
    if (client != null) {
      return client.get(url);
    }
    return getIt<AppStore>().httpClient.get(url);
  }

  Future<void> _loadPlaces() async {
    final generation = ++_loadGeneration;
    try {
      final response = await _get(
        Uri.parse(payLocationsPlacesUrl),
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        _showError(generation);
        return;
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (!payLocationsPlacesBodyIsList(decoded)) {
        _showError(generation);
        return;
      }

      final pins = keepPayLocationPins(decoded);
      if (!mounted || generation != _loadGeneration) {
        return;
      }

      setState(() {
        _pins = pins;
        _selectedPin = pins.length == 1 ? pins.single : null;
        _loading = false;
        _error = false;
      });
      _redrawMarkers();
    } catch (_) {
      _showError(generation);
    }
  }

  void _showError(int generation) {
    if (!mounted || generation != _loadGeneration) {
      return;
    }

    setState(() {
      _loading = false;
      _error = true;
    });
  }

  @override
  void dispose() {
    _loadGeneration++;
    _markerGeneration++;
    _styleLoaded = false;
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(maplibre.MapLibreMapController controller) {
    if (identical(_mapController, controller)) {
      return;
    }
    _mapController = controller;
    controller.onCircleTapped.add((circle) => _handleAnnotationTap(circle.data));
    controller.onSymbolTapped.add((symbol) => _handleAnnotationTap(symbol.data));
  }

  void _onStyleLoaded() {
    _styleLoaded = true;
    if (!_fitCountryOnce()) {
      _scheduleCountryFit();
    }
    _redrawMarkers();
  }

  void _onCameraMove(maplibre.CameraPosition position) {
    if (!mounted) {
      return;
    }
    _center = position.target;
    final zoom = position.zoom;
    if ((zoom - _zoom).abs() <= 0.05) {
      return;
    }
    setState(() => _zoom = zoom);
    _redrawMarkers();
  }

  void _zoomBy(double delta) {
    final controller = _mapController;
    if (!_styleLoaded ||
        controller == null ||
        !_hasMapSize ||
        !_center.latitude.isFinite ||
        !_center.longitude.isFinite) {
      return;
    }
    final zoom = (_zoom + delta).clamp(5, 16).toDouble();
    unawaited(controller.animateCamera(maplibre.CameraUpdate.zoomTo(zoom)));
  }

  void _selectPin(PayLocationPin pin) {
    setState(() => _selectedPin = pin);
    _redrawMarkers();
    _moveTo(pin.lat, pin.lon, 13);
  }

  void _onQuery(String value) {
    final visible = filterPayLocationPins(_pins, value);
    setState(() {
      _query = value;
      if (visible.length == 1) {
        _selectedPin = visible.single;
        return;
      }
      final selected = _selectedPin;
      if (selected == null) {
        return;
      }
      final stillVisible = visible.any((pin) => samePayLocationPin(pin, selected));
      if (!stillVisible) {
        _selectedPin = null;
      }
    });
    _redrawMarkers();
    _frameQuery(visible, value);
  }

  void _frameQuery(List<PayLocationPin> visible, String value) {
    if (value.trim().isEmpty || visible.isEmpty) {
      _fitSpan(
        south: payLocationCountrySouth,
        north: payLocationCountryNorth,
        west: payLocationCountryWest,
        east: payLocationCountryEast,
        padding: 28,
        maxZoom: 16,
      );
      return;
    }
    if (visible.length == 1) {
      final pin = visible.single;
      _moveTo(pin.lat, pin.lon, 12);
      return;
    }
    _fitPins(visible, padding: 36, maxZoom: 12);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).payLocationsTitle)),
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 16, vertical: 12),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_error) {
      return Center(
        child: Text(
          S.of(context).payLocationsError,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: RealUnitColors.neutral500),
        ),
      );
    }
    if (_pins.isEmpty) {
      return _emptyCard(context);
    }

    final visible = sortPayLocationPins(filterPayLocationPins(_pins, _query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: _buildMapFrame(visible)),
        Padding(
          padding: const .only(top: 12, bottom: 8),
          child: _searchField(context),
        ),
        Padding(
          padding: const .only(bottom: 4),
          child: Text(
            _countLabel(context, visible.length),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(flex: 2, child: _shopList(context, visible)),
      ],
    );
  }

  Widget _emptyCard(BuildContext context) {
    final map = widget.mapBuilder?.call(const []) ?? _buildMap();
    return Stack(
      children: [
        Positioned.fill(child: map),
        Center(
          child: Card(
            child: Padding(
              padding: const .all(12),
              child: Text(
                S.of(context).payLocationsEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _countLabel(BuildContext context, int count) {
    if (count == 1) {
      return S.of(context).payLocationsCountOne;
    }
    return S.of(context).payLocationsCountMany('$count');
  }

  Widget _searchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: _onQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: S.of(context).payLocationsSearch,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: RealUnitColors.neutral50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _shopList(BuildContext context, List<PayLocationPin> visible) {
    if (visible.isEmpty) {
      return Center(
        child: Text(
          S.of(context).payLocationsNoMatch,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: RealUnitColors.neutral500),
        ),
      );
    }

    return ListView.separated(
      itemCount: visible.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: RealUnitColors.neutral200),
      itemBuilder: (context, index) {
        final pin = visible[index];
        final label = payLocationLabel(pin.name);
        final selected = _selectedPin != null && samePayLocationPin(pin, _selectedPin!);
        return Material(
          color: selected ? RealUnitColors.brand200 : RealUnitColors.basic.white,
          child: InkWell(
            onTap: () => _selectPin(pin),
            child: Padding(
              padding: const .symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.place,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (label.street != null)
                    Text(
                      label.street!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: RealUnitColors.neutral500,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapFrame(List<PayLocationPin> visible) {
    final map = widget.mapBuilder?.call(visible) ?? _buildMap();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(child: map),
          Positioned(top: 8, right: 8, child: _zoomControls()),
        ],
      ),
    );
  }

  Widget _zoomControls() {
    return Material(
      color: RealUnitColors.basic.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _zoomButton(Icons.add, S.of(context).payLocationsZoomIn, 1),
          _zoomButton(Icons.remove, S.of(context).payLocationsZoomOut, -1),
        ],
      ),
    );
  }

  Widget _zoomButton(IconData icon, String tooltip, double delta) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () => _zoomBy(delta),
      icon: Icon(icon, size: 20),
    );
  }

  Widget _buildMap() {
    if (WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding')) {
      // A platform view breaks widget tests.
      return const ColoredBox(color: RealUnitColors.brand200);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : 0,
          constraints.hasBoundedHeight ? constraints.maxHeight : 0,
        );
        if (size != _mapSize) {
          _mapSize = size;
          if (_styleLoaded && !_countryFitDone) {
            _scheduleCountryFit();
          }
        }
        return maplibre.MapLibreMap(
          styleString: payLocationsStyleUrl,
          initialCameraPosition: const maplibre.CameraPosition(
            target: maplibre.LatLng(46.8, 8.23),
            zoom: 7,
          ),
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          trackCameraPosition: true,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          myLocationEnabled: false,
          logoEnabled: false,
          minMaxZoomPreference: const maplibre.MinMaxZoomPreference(5, 16),
          annotationOrder: const [
            maplibre.AnnotationType.circle,
            maplibre.AnnotationType.symbol,
          ],
          annotationConsumeTapEvents: const [
            maplibre.AnnotationType.circle,
            maplibre.AnnotationType.symbol,
          ],
          foregroundLoadColor: RealUnitColors.brand200,
          onCameraMove: _onCameraMove,
        );
      },
    );
  }

  List<PayLocationPin> _visiblePins() {
    return sortPayLocationPins(filterPayLocationPins(_pins, _query));
  }

  void _redrawMarkers() {
    _markerGeneration++;
    if (!_styleLoaded || _mapController == null || _drawingMarkers) {
      return;
    }
    unawaited(_drawMarkers());
  }

  Future<void> _drawMarkers() async {
    _drawingMarkers = true;
    try {
      while (mounted && _styleLoaded) {
        final controller = _mapController;
        if (controller == null) {
          return;
        }
        final generation = _markerGeneration;
        final markers = payLocationMarkers(
          visible: _visiblePins(),
          selected: _selectedPin,
          zoom: _zoom,
        );
        await controller.clearCircles();
        await controller.clearSymbols();
        if (!_markerDrawIsCurrent(generation, controller)) {
          continue;
        }

        final circleOptions = <maplibre.CircleOptions>[];
        final circleData = <Map<String, dynamic>>[];
        for (var index = 0; index < markers.length; index++) {
          final marker = markers[index];
          circleOptions.add(
            maplibre.CircleOptions(
              geometry: maplibre.LatLng(marker.lat, marker.lon),
              circleRadius: marker.diameter / 2 - marker.strokeWidth, // Stroke is outside radius.
              circleColor: marker.kind == PayLocationMarkerKind.pin ? _pinColor : _clusterColor,
              circleStrokeWidth: marker.strokeWidth,
              circleStrokeColor: _white,
            ),
          );
          circleData.add(_markerData(marker, index));
        }
        if (circleOptions.isNotEmpty) {
          await controller.addCircles(circleOptions, circleData);
        }
        if (!_markerDrawIsCurrent(generation, controller)) {
          continue;
        }

        final symbolOptions = <maplibre.SymbolOptions>[];
        final symbolData = <Map<String, dynamic>>[];
        for (var index = 0; index < markers.length; index++) {
          final marker = markers[index];
          if (marker.count != null) {
            symbolOptions.add(
              maplibre.SymbolOptions(
                geometry: maplibre.LatLng(marker.lat, marker.lon),
                textField: '${marker.count}',
                textSize: 13,
                textColor: _white,
                fontNames: const ['Noto Sans Bold'],
              ),
            );
            symbolData.add(_markerData(marker, index));
          }
          if (marker.town != null) {
            symbolOptions.add(
              maplibre.SymbolOptions(
                geometry: maplibre.LatLng(marker.lat, marker.lon),
                textField: marker.town,
                textSize: 12,
                textColor: _townColor,
                textHaloColor: _white,
                textHaloWidth: 1.2,
                fontNames: const ['Noto Sans Regular'],
                textAnchor: 'bottom',
                textOffset: const Offset(0, -0.9),
                textMaxWidth: 10,
              ),
            );
            symbolData.add(_markerData(marker, index));
          }
        }
        if (symbolOptions.isNotEmpty) {
          await controller.addSymbols(symbolOptions, symbolData);
        }
        if (!_markerDrawIsCurrent(generation, controller)) {
          continue;
        }
        _addedMarkers = markers;
        return;
      }
    } finally {
      _drawingMarkers = false;
    }
  }

  bool _markerDrawIsCurrent(int generation, maplibre.MapLibreMapController controller) {
    return mounted &&
        _styleLoaded &&
        generation == _markerGeneration &&
        identical(controller, _mapController);
  }

  Map<String, dynamic> _markerData(PayLocationMarker marker, int index) {
    return {
      'kind': marker.kind == PayLocationMarkerKind.pin ? 'pin' : 'cluster',
      'index': index,
    };
  }

  void _handleAnnotationTap(Object? data) {
    if (data is! Map) {
      return;
    }
    final index = data['index'];
    if (index is! int || index < 0 || index >= _addedMarkers.length) {
      return;
    }
    final marker = _addedMarkers[index];
    final kind = marker.kind == PayLocationMarkerKind.pin ? 'pin' : 'cluster';
    if (data['kind'] != kind) {
      return;
    }
    if (marker.kind == PayLocationMarkerKind.pin) {
      _selectPin(marker.pins.single);
      return;
    }
    _openCluster(marker.pins);
  }

  bool get _hasMapSize => _mapSize.width > 0 && _mapSize.height > 0;

  bool _fitCountryOnce() {
    if (_countryFitDone) {
      return true;
    }
    final moved = _fitSpan(
      south: payLocationCountrySouth,
      north: payLocationCountryNorth,
      west: payLocationCountryWest,
      east: payLocationCountryEast,
      padding: 28,
      maxZoom: 16,
    );
    if (moved) {
      _countryFitDone = true;
    }
    return moved;
  }

  void _scheduleCountryFit() {
    if (_countryFitDone || _countryFitScheduled) {
      return;
    }
    _countryFitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _countryFitScheduled = false;
      if (mounted) {
        _fitCountryOnce();
      }
    });
  }

  bool _fitSpan({
    required double south,
    required double north,
    required double west,
    required double east,
    required double padding,
    required double maxZoom,
  }) {
    final controller = _mapController;
    if (!_styleLoaded || controller == null || !_hasMapSize) {
      return false;
    }
    final zoom = payLocationZoomForSpan(
      south: south,
      north: north,
      west: west,
      east: east,
      width: _mapSize.width,
      height: _mapSize.height,
      padding: padding,
      maxZoom: maxZoom,
    );
    final center = maplibre.LatLng((south + north) / 2, (west + east) / 2);
    unawaited(
      controller.animateCamera(maplibre.CameraUpdate.newLatLngZoom(center, zoom)),
    );
    return true;
  }

  void _fitPins(List<PayLocationPin> pins, {required double padding, required double maxZoom}) {
    var south = pins.first.lat;
    var north = pins.first.lat;
    var west = pins.first.lon;
    var east = pins.first.lon;
    for (final pin in pins.skip(1)) {
      if (pin.lat < south) {
        south = pin.lat;
      }
      if (pin.lat > north) {
        north = pin.lat;
      }
      if (pin.lon < west) {
        west = pin.lon;
      }
      if (pin.lon > east) {
        east = pin.lon;
      }
    }
    _fitSpan(
      south: south,
      north: north,
      west: west,
      east: east,
      padding: padding,
      maxZoom: maxZoom,
    );
  }

  void _moveTo(double lat, double lon, double zoom) {
    final controller = _mapController;
    if (!_styleLoaded || controller == null || !_hasMapSize) {
      return;
    }
    unawaited(
      controller.animateCamera(
        maplibre.CameraUpdate.newLatLngZoom(maplibre.LatLng(lat, lon), zoom),
      ),
    );
  }

  void _openCluster(List<PayLocationPin> pins) {
    _fitPins(pins, padding: 48, maxZoom: 14);
  }
}
