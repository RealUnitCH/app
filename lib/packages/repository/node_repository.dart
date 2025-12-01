import 'dart:async';
import 'dart:developer' as developer;

import 'package:realunit_wallet/models/node.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/node_storage.dart';

class NodeRepository {
  final AppDatabase _appDatabase;

  const NodeRepository(this._appDatabase);

  Future<void> saveNode(Node node) async {
    final exists = await existsNode(node);
    developer.log('Node for ${node.name} exists: $exists',
        name: 'NodeRepository.saveNode');
    if (!exists) await insertNode(node);
  }

  Future<int> insertNode(Node node) => _appDatabase.insertNode(
        node.chainId,
        node.name,
        node.httpsUrl,
        node.wssUrl,
      );

  Future<void> updateNode(Node node) => _appDatabase.updateNode(node.chainId,
      httpsUrl: node.httpsUrl, wssUrl: node.wssUrl);

  Future<Node?> getNode(int chainId) =>
      _appDatabase.getNode(chainId).then((node) => node != null
          ? Node(
              chainId: node.chainId,
              name: node.name,
              httpsUrl: node.httpsUrl,
              wssUrl: node.wssUrl,
            )
          : null);

  Future<List<Node>> get allNodes => _appDatabase.allNodes.then((nodes) => nodes
      .map((node) => Node(
            chainId: node.chainId,
            name: node.name,
            httpsUrl: node.httpsUrl,
            wssUrl: node.wssUrl,
          ))
      .toList());

  Future<bool> existsNode(Node node) =>
      getNode(node.chainId).then((asset) => asset != null);
}
