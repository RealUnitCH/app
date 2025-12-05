import 'localization/arb_file_utils.dart';

void main(List<String> args) => alphabetizeLocalization();

void alphabetizeLocalization() {
  for (final lang in ['de', 'en']) {
    final fileName = getArbFileName(lang);
    alphabetizeArbFile(fileName);
  }
}
