import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:drift/drift.dart';

extension NodeStorage on AppDatabase {
  Future<int> insertNode(
          int chainId, String name, String httpsUrl, String? wssUrl) =>
      into(nodes).insert(NodesCompanion.insert(
        chainId: chainId,
        name: name,
        httpsUrl: httpsUrl,
        wssUrl: Value(wssUrl),
      ));

  Future<int> updateNode(int chainId, {String? httpsUrl, String? wssUrl}) =>
      (update(nodes)..where((row) => row.chainId.equals(chainId)))
          .write(NodesCompanion(
        httpsUrl: Value.absentIfNull(httpsUrl),
        wssUrl: Value.absentIfNull(wssUrl),
      ));

  Future<NodeData?> getNode(int chainId) =>
      (select(nodes)..where((row) => row.chainId.equals(chainId)))
          .getSingleOrNull();

  Future<List<NodeData>> get allNodes => nodes.all().get();
}

@DataClassName("NodeData")
class Nodes extends Table {
  IntColumn get chainId => integer().unique()();

  TextColumn get name => text()();

  TextColumn get httpsUrl => text()();

  TextColumn get wssUrl => text().nullable()();
}
