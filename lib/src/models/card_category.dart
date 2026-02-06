class CardCategory {
  final String id;
  final String categoryCode;
  final String categoryName;
  final String programType;

  CardCategory({
    required this.id,
    required this.categoryCode,
    required this.categoryName,
    required this.programType,
  });

  factory CardCategory.fromJson(Map<String, dynamic> json) {
    return CardCategory(
      id: json['id'],
      categoryCode: json['categoryCode'],
      categoryName: json['categoryName'],
      programType: json['programType'],
    );
  }
}
