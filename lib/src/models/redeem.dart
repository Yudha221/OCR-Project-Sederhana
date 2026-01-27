class Redeem {
  final String id; // ✅ STRING UUID
  final String redeemDate;
  final String customerName;
  final String identityNumber;
  final String transactionNumber;
  final String serialNumber;
  final String cardCategory;
  final String cardType;
  final String journeyType;
  final int usedQuota;
  final int remainingQuota;
  final String operatorName;
  final String station;
  final bool lastRedeem;

  Redeem({
    required this.id,
    required this.redeemDate,
    required this.customerName,
    required this.identityNumber,
    required this.transactionNumber,
    required this.serialNumber,
    required this.cardCategory,
    required this.cardType,
    required this.journeyType,
    required this.usedQuota,
    required this.remainingQuota,
    required this.operatorName,
    required this.station,
    required this.lastRedeem,
  });

  factory Redeem.fromJson(Map<String, dynamic> json) {
    final card = json['card'] ?? {};
    final member = card['member'] ?? {};
    final product = card['cardProduct'] ?? {};
    final category = product['category'] ?? {};
    final type = product['type'] ?? {};
    final station = json['station'] ?? {};
    final operator = json['operator'] ?? {};

    final int quotaTicket =
        int.tryParse(card['quotaTicket']?.toString() ?? '0') ?? 0;
    final int quotaUsed =
        int.tryParse(json['quotaUsed']?.toString() ?? '0') ?? 0;

    return Redeem(
      id: json['id']?.toString() ?? '', // ✅ UUID STRING
      redeemDate: json['createdAt']?.toString() ?? '-',
      customerName: member['name'] ?? '-',
      identityNumber: member['identityNumber'] ?? '-',
      transactionNumber: json['transactionNumber'] ?? '-',
      serialNumber: card['serialNumber'] ?? '-',
      cardCategory: category['categoryName'] ?? '-',
      cardType: type['typeName'] ?? '-',
      journeyType: json['redeemType'] ?? '-',
      usedQuota: quotaUsed,
      remainingQuota: quotaTicket - quotaUsed,
      operatorName: operator['fullName'] ?? '-',
      station: station['stationName'] ?? '-',
      lastRedeem: (quotaTicket - quotaUsed) <= 0,
    );
  }
}
