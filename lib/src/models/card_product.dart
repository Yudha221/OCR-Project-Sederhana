class CardProduct {
  final String categoryName;
  final String typeName;
  final int price;
  final int totalQuota;
  final int masaBerlaku;

  CardProduct({
    required this.categoryName,
    required this.typeName,
    required this.price,
    required this.totalQuota,
    required this.masaBerlaku,
  });

  factory CardProduct.fromJson(Map<String, dynamic> json) {
    return CardProduct(
      categoryName: json['category']?['categoryName'] ?? '',
      typeName: json['type']?['typeName'] ?? '',
      price: int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      totalQuota: int.tryParse(json['totalQuota']?.toString() ?? '0') ?? 0,
      masaBerlaku: int.tryParse(json['masaBerlaku']?.toString() ?? '0') ?? 0,
    );
  }
}
