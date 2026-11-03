enum Role {
  parent,
  teen;

  String get wire => name.toUpperCase();

  static Role fromWire(String value) =>
      Role.values.firstWhere((r) => r.wire == value);
}
