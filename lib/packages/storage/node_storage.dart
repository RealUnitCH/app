import 'package:drift/drift.dart';

@DataClassName('NodeData')
class Nodes extends Table {
  IntColumn get chainId => integer().unique()();

  TextColumn get name => text()();

  TextColumn get httpsUrl => text()();

  TextColumn get wssUrl => text().nullable()();
}
