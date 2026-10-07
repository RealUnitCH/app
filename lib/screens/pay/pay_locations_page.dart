import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
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
  });

  final Widget Function(List<PayLocationPin> pins)? mapBuilder;
  final http.Client? httpClient;

  /// False keeps the initial loading frame and does not start a request.
  final bool loadOnStart;

  @override
  State<PayLocationsPage> createState() => _PayLocationsPageState();
}

class _PayLocationsPageState extends State<PayLocationsPage> {
  List<String> _blockchains = const ['Ethereum'];
  List<String> _assets = const ['ZCHF'];
  String _blockchain = 'Ethereum';
  String _asset = 'ZCHF';
  List<PayLocationPin> _pins = const [];
  PayLocationPin? _selectedPin;
  bool _filtersOk = false;
  bool _loading = true;
  bool _error = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.loadOnStart) {
      _loadFilters();
    }
  }

  Future<http.Response> _get(Uri url) {
    final client = widget.httpClient;
    if (client != null) {
      return client.get(url);
    }
    return getIt<AppStore>().httpClient.get(url);
  }

  Future<void> _loadFilters() async {
    final generation = ++_generation;
    try {
      final response = await _get(Uri.parse(payLocationsFiltersUrl));
      if (response.statusCode != 200) {
        _showError(generation);
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        _showError(generation);
        return;
      }

      final choices = parsePayLocationFilters(decoded);
      if (!mounted || generation != _generation) {
        return;
      }

      setState(() {
        _blockchains = choices.blockchains;
        _assets = choices.assets;
        _filtersOk = true;
      });
      await _loadPlaces(generation);
    } catch (_) {
      _showError(generation);
    }
  }

  Future<void> _loadPlaces(int generation) async {
    final url = placesUrlAfterFilters(
      filtersOk: _filtersOk,
      blockchain: _blockchain,
      asset: _asset,
    );
    if (url == null) {
      _showError(generation);
      return;
    }
    try {
      final response = await _get(Uri.parse(url));
      if (response.statusCode != 200) {
        _showError(generation);
        return;
      }

      final decoded = jsonDecode(response.body);
      if (!payLocationsPlacesBodyIsList(decoded)) {
        _showError(generation);
        return;
      }

      final pins = keepPayLocationPins(
        decoded,
        _blockchain,
        _asset,
      );
      if (!mounted || generation != _generation) {
        return;
      }

      setState(() {
        _pins = pins;
        _selectedPin = null;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      _showError(generation);
    }
  }

  void _showError(int generation) {
    if (!mounted || generation != _generation) {
      return;
    }

    setState(() {
      _loading = false;
      _error = true;
    });
  }

  void _selectBlockchain(String? value) {
    if (value == null || value == _blockchain) {
      return;
    }

    final generation = ++_generation;
    setState(() {
      _blockchain = value;
      _selectedPin = null;
      _loading = true;
      _error = false;
    });
    _loadPlaces(generation);
  }

  void _selectAsset(String? value) {
    if (value == null || value == _asset) {
      return;
    }

    final generation = ++_generation;
    setState(() {
      _asset = value;
      _selectedPin = null;
      _loading = true;
      _error = false;
    });
    _loadPlaces(generation);
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).payLocationsTitle)),
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        S.of(context).payLocationsBlockchain,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _blockchain,
                        items: _blockchains
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _selectBlockchain,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        S.of(context).payLocationsAsset,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _asset,
                        items: _assets
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _selectAsset,
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(child: _buildContent()),
              if (_selectedPin case final pin?)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(pin.name, style: Theme.of(context).textTheme.bodyMedium),
                    if (pin.category case final category? when category.isNotEmpty)
                      Text(category, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
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

    final map = widget.mapBuilder?.call(_pins) ?? _buildMap();
    return Stack(
      children: [
        Positioned.fill(child: map),
        if (_pins.isEmpty)
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

  Widget _buildMap() {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(46.8, 8.23),
        initialZoom: 7,
        backgroundColor: RealUnitColors.neutral100,
      ),
      children: [
        MarkerLayer(
          markers: _pins
              .map(
                (pin) => Marker(
                  width: 14,
                  height: 14,
                  point: LatLng(pin.lat, pin.lon),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPin = pin),
                    child: Container(
                      decoration: BoxDecoration(
                        color: RealUnitColors.status.red600,
                        shape: BoxShape.circle,
                        border: Border.all(color: RealUnitColors.basic.white, width: 2),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
