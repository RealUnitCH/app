enum DfxUserType {
  human,
  corperation;

  @override
  String toString() {
    switch (this) {
      case DfxUserType.human:
        return 'HUMAN';
      case DfxUserType.corperation:
        return 'CORPORATION';
    }
  }
}
