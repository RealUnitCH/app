import 'dart:developer' as developer;

import 'package:realunit_wallet/packages/service/dfx/dfx_fiat_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

/// Translates the backend's per-user fiat list into the local [Currency]
/// type for type-safe wiring of the existing payment flows. The picker
/// renders only fiats the API reports as buyable / sellable.
///
/// API call site: [DfxFiatService] → `GET /v1/fiat`.
///
/// Currencies the API returns that the current app build does not yet have
/// an enum value for are logged and skipped — they will appear in the
/// picker as soon as the enum is extended in a subsequent app release.
class SupportedFiatRepository {
  final DfxFiatService _fiatService;

  SupportedFiatRepository(DfxFiatService fiatService) : _fiatService = fiatService;

  Future<List<Currency>> getBuyable() => _resolve((dto) => dto.buyable);

  Future<List<Currency>> getSellable() => _resolve((dto) => dto.sellable);

  Future<List<Currency>> getAll() => _resolve((_) => true);

  Future<List<Currency>> _resolve(bool Function(dynamic) filter) async {
    final fiats = await _fiatService.getAllFiats();
    final result = <Currency>[];
    for (final fiat in fiats) {
      if (!filter(fiat)) continue;
      final currency = _tryParse(fiat.name);
      if (currency != null) {
        result.add(currency);
      } else {
        developer.log(
          'SupportedFiatRepository: backend offers currency "${fiat.name}" '
          'but this app build has no Currency enum value for it; skipping.',
        );
      }
    }
    return result;
  }

  Currency? _tryParse(String code) {
    try {
      return Currency.fromCode(code);
    } catch (_) {
      return null;
    }
  }
}
