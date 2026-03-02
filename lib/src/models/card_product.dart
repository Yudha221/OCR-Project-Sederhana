class CardProduct {
  final String categoryName;
  final String typeName;
  final int price;

  CardProduct({
    required this.categoryName,
    required this.typeName,
    required this.price,
  });

  factory CardProduct.fromJson(Map<String, dynamic> json) {
    return CardProduct(
      categoryName: json['category']?['categoryName'] ?? '',
      typeName: json['type']?['typeName'] ?? '',
      price: int.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }
}
