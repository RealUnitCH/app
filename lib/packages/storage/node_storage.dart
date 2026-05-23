import 'package:drift/drift.dart';

// The schema getters below are read by `drift_dev` at codegen time and the
// resulting column metadata is consumed via the generated mirror class —
// they are not invoked at runtime, so line-coverage instrumentation never
// marks them as executed. The same coverage gap exists on every Drift
// table in the repo. `// coverage:ignore-line` keeps the file at the
// surface the test suite can actually reach.
@DataClassName('NodeData')
class Nodes extends Table {
  IntColumn get chainId => integer().unique()(); // coverage:ignore-line

  TextColumn get name => text()(); // coverage:ignore-line

  TextColumn get httpsUrl => text()(); // coverage:ignore-line

  TextColumn get wssUrl => text().nullable()(); // coverage:ignore-line
}
