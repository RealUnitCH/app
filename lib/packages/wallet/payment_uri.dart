import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/packages/utils/parse_fixed.dart';

abstract class PaymentURI {
  PaymentURI({required this.amount, required this.address});

  final String amount;
  final String address;
}

class EthereumURI extends PaymentURI {
  EthereumURI({required super.amount, required super.address});

  factory EthereumURI.fromString(String uriString) {
    final uri = Uri.parse(uriString);

    if (uri.scheme.toLowerCase() != "ethereum") {
      throw PaymentURIParseException();
    }

    final address = uri.path;
    final amount = uri.queryParameters["amount"] ?? "";
    return EthereumURI(address: address, amount: amount);
  }

  @override
  String toString() {
    var base = 'ethereum:$address';

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class PaymentURIParseException extends FormatException {}

class ERC681URI extends PaymentURI {
  final int chainId;
  final String? contractAddress;

  ERC681URI({
    required this.chainId,
    required super.address,
    required super.amount,
    required this.contractAddress,
  });

  factory ERC681URI.fromString(String uriString) {
    final uri = Uri.parse(uriString);

    if (uri.scheme.toLowerCase() != "ethereum") {
      throw PaymentURIParseException();
    }

    final (isContract, targetAddress) = _getTargetAddress(uri.path);
    final chainId = _getChainID(uri.path);

    final address = isContract ? uri.queryParameters["address"] : targetAddress;
    final amount = isContract
        ? uri.queryParameters["uint256"]
        : uri.queryParameters["value"];

    var formatedAmount = "";

    if (amount != null) {
      formatedAmount = formatFixed(BigInt.parse(amount), 18);
    } else {
      formatedAmount = uri.queryParameters["amount"] ?? "";
    }

    if (address == null) throw PaymentURIParseException();

    return ERC681URI(
      chainId: chainId,
      address: address,
      amount: formatedAmount,
      contractAddress: isContract ? targetAddress : null,
    );
  }

  static int _getChainID(String path) {
    return int.parse(RegExp(
          r'@\d*',
        ).firstMatch(path)?.group(0)?.replaceAll("@", "") ??
        "1");
  }

  static (bool, String) _getTargetAddress(String path) {
    final targetAddress = RegExp(r'^(0x)?[0-9a-f]{40}', caseSensitive: false)
        .firstMatch(path)!
        .group(0)!;
    return (path.contains("/"), targetAddress);
  }

  @override
  String toString() {
    final pathSegments = <String>['${contractAddress ?? address}@$chainId'];
    final queryParameters = <String, dynamic>{};

    if (contractAddress != null) {
      pathSegments.add('/transfer');
      queryParameters["address"] = address;
    }

    if (amount.isNotEmpty) {
      final rawAmount = parseFixed(amount, 18);
      queryParameters[contractAddress != null ? "uint256" : "value"] =
          rawAmount.toString();
    }

    return Uri(
      scheme: "ethereum",
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    ).toString();
  }
}
