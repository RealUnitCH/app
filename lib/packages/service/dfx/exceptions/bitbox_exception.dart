class BitboxNotConnectedException implements Exception {
  const BitboxNotConnectedException();

  @override
  String toString() => 'BitBox is not connected';
}
