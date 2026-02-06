class CardType {
  final String id;
  final String typeCode;
  final String typeName;
  final String? routeDescription;
  final String programType;

  CardType({
    required this.id,
    required this.typeCode,
    required this.typeName,
    this.routeDescription,
    required this.programType,
  });

  factory CardType.fromJson(Map<String, dynamic> json) {
    return CardType(
      id: json['id'],
      typeCode: json['typeCode'],
      typeName: json['typeName'],
      routeDescription: json['routeDescription'],
      programType: json['programType'],
    );
  }
}
