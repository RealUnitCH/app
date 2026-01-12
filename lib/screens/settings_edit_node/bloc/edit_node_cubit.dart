import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/models/node.dart';
import 'package:realunit_wallet/packages/repository/node_repository.dart';

part 'edit_node_state.dart';

class EditNodeCubit extends Cubit<EditNodeState> {
  EditNodeCubit(this._nodeRepository, this.blockchain) : super(const EditNodeState());

  final Blockchain blockchain;
  final NodeRepository _nodeRepository;

  void loadNode() async {
    final node = (await _nodeRepository.getNode(blockchain.chainId)) ??
        Node(chainId: blockchain.chainId, name: blockchain.name, httpsUrl: '');

    emit(state.copyWith(node: node));
  }

  Future<void> saveHttpRPCUrl(String url) async {
    if (state.node != null) {
      emit(state.copyWith(isSaving: true));

      final node = Node(
        chainId: blockchain.chainId,
        name: state.node!.name,
        httpsUrl: url,
        wssUrl: state.node!.wssUrl,
      );
      await _nodeRepository.updateNode(node);
      emit(state.copyWith(node: node, isSaving: false));
    }
  }
}
