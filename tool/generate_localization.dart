import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'alphabetize_localization.dart';
import 'localization/localization_constants.dart';
import 'utils/utils.dart';

const inputPath = 'assets/languages/';
const outputPath = 'lib/generated/';
const localizationFileName = 'i18n.dart';
const localeListFileName = 'locales.dart';
const srcDir = 'srcDir';
const defaultLocale = 'en';

Future<void> main(List<String> args) async {
  alphabetizeLocalization();

  final extraInfo = args.isNotEmpty
      ? args.fold(<String, dynamic>{}, (Map<String, dynamic> acc, String arg) {
          final parts = arg.split('=');
          var key = normalizeKeyName(parts[0]);
          if (key.contains('--')) {
            key = key.substring(2);
          }
          acc[key] = parts.length > 1
              ? parts[1].isNotEmpty
                  ? parts[1]
                  : inputPath
              : inputPath;
          return acc;
        })
      : <String, dynamic>{srcDir: inputPath};

  final outputDir = Directory(outputPath);

  if (!outputDir.existsSync()) {
    await outputDir.create();
  }

  extraInfo.forEach((key, dynamic value) async {
    if (key != srcDir) {
      developer.log('Wrong key: $key');
      return;
    }

    final dirPath = value as String;
    final dir = Directory(dirPath);

    if (!await dir.exists()) {
      developer.log('Wrong directory path: $dirPath');
      return;
    }

    final localePath = <String, dynamic>{};
    await dir.list(recursive: false).forEach((element) {
      try {
        final shortLocale = element.path
            .split(
              '_',
            )[1]
            .split('.')[0];
        localePath[shortLocale] = element.path;
      } catch (e) {
        developer.log('Wrong file: ${element.path}');
      }
    });

    if (!localePath.keys.contains(defaultLocale)) {
      developer.log("Locale list doesn't contain $defaultLocale");
      return;
    }

    try {
      var output = '';
      var locales = 'const locales = [';

      output += part1;
      output += textDirectionDeclaration;

      var inputContent = File(localePath[defaultLocale].toString()).readAsStringSync();
      var config = json.decode(inputContent) as Map<String, dynamic>;

      output += localizedStrings(config: config, hasOverride: false);
      output += '}\n\n';

      localePath.forEach((key, dynamic value) {
        inputContent = File(localePath[key].toString()).readAsStringSync();
        config = json.decode(inputContent) as Map<String, dynamic>;

        locales += "'$key', ";

        output += 'class \$$key extends S {\n';
        output += '  const \$$key();\n';

        if (key != defaultLocale) {
          output += textDirectionDeclaration;
          output += localizedStrings(config: config, hasOverride: true);
        }

        output += '}\n\n';
      });

      output += classDeclaration;

      for (final key in localePath.keys) {
        output += "      Locale('$key', ''),\n";
      }

      output += part2;

      for (final key in localePath.keys) {
        output += "        case '$key':\n";
        output += '          S.current = const \$$key();\n';
        output += '          return SynchronousFuture<S>(S.current);\n';
      }

      output += part3;

      await File(outputPath + localizationFileName).writeAsString(output);

      locales += '];';

      await File(outputPath + localeListFileName).writeAsString(locales);
    } catch (e) {
      developer.log(e.toString());
    }
  });
}

String localizedStrings({required Map<String, dynamic> config, required bool hasOverride}) {
  var output = '';

  final pattern = RegExp('[\$]{(.*?)}');

  config.forEach((key, dynamic value) {
    final camelKey = _snakeToCamel(key);
    final matches = pattern.allMatches(value as String);

    if (hasOverride) {
      output += '  @override\n';
    }

    if (matches.isEmpty) {
      output += "  String get $camelKey => '''$value''';\n";
    } else {
      final set = matches.map((elem) => elem.group(1)).toSet().toList();

      output += '  String $camelKey(';

      for (var elem in set) {
        if (elem == set.last) {
          output += 'String $elem';
        } else {
          output += 'String $elem, ';
        }
      }

      output += ") => '''${_removeCurlyBraces(value)}''';\n";
    }
  });

  return output;
}

String _snakeToCamel(String input) {
  final parts = input.split('_');
  if (parts.isEmpty) return input;

  return parts.first +
      parts.skip(1).map((p) => p.isNotEmpty ? p[0].toUpperCase() + p.substring(1) : '').join();
}

String _removeCurlyBraces(String value) {
  return value.replaceAllMapped(
    RegExp(r'\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}'),
    (match) => '\$${match.group(1)}',
  );
}
