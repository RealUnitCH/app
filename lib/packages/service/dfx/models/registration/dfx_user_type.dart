enum DfxUserType {
  human(name: 'human', jsonName: 'HUMAN'),
  corporation(name: 'corporation', jsonName: 'CORPORATION');

  final String name;
  final String jsonName;

  const DfxUserType({required this.name, required this.jsonName});
}
