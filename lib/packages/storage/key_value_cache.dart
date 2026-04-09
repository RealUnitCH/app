import 'package:drift/drift.dart';

@DataClassName('CacheEntry')
class KeyValueCache extends Table {
  TextColumn get id => text().unique()();

  TextColumn get value => text()();
}
