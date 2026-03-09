class PembatalanKereta {
  final String id;
  final String redeemNumber;
  final String? redeemCancelledNumber;
  final String transactionNumber;

  final String customerName;
  final String identityNumber;

  final String operatorName;
  final String operatorNip;
  final String? secondaryOperatorName;

  final String stationName;
  final String paymentChannel;

  final String serialNumber;
  final String cardCategory;
  final String cardType;

  final int quotaTicket;
  final int price;
  final int masaBerlaku;

  final String purchaseDate;
  final String expiredDate;

  final String? ticketOrigin;
  final String? cancelReason;

  final String deletedAt;
  final String programType;
  final String redeemType;

  PembatalanKereta({
    required this.id,
    required this.redeemNumber,
    this.redeemCancelledNumber,
    required this.transactionNumber,
    required this.customerName,
    required this.identityNumber,
    required this.operatorName,
    required this.operatorNip,
    this.secondaryOperatorName,
    required this.stationName,
    required this.paymentChannel,
    required this.serialNumber,
    required this.cardCategory,
    required this.cardType,
    required this.quotaTicket,
    required this.price,
    required this.masaBerlaku,
    required this.purchaseDate,
    required this.expiredDate,
    this.ticketOrigin,
    this.cancelReason,
    required this.deletedAt,
    required this.programType,
    required this.redeemType,
  });

  factory PembatalanKereta.fromJson(Map<String, dynamic> json) {
    final card = json['card'] ?? {};
    final product = card['cardProduct'] ?? {};
    final member = card['member'] ?? {};
    final operator = json['operator'] ?? {};
    final station = json['station'] ?? {};
    final paymentChannel = station['paymentChannel'] ?? {};

    /// 🔹 harga card
    final int cardPrice =
        int.tryParse(product['price']?.toString() ?? '0') ?? 0;

    /// 🔹 total quota card (INI YANG BENAR)
    final int totalQuota =
        int.tryParse(product['totalQuota']?.toString() ?? '0') ?? 0;

    /// 🔹 quota yang dipakai
    final int quotaUsed =
        int.tryParse(json['quotaUsed']?.toString() ?? '0') ?? 0;

    /// 🔹 harga per tiket
    final int pricePerTicket = totalQuota == 0
        ? 0
        : (cardPrice / totalQuota).round();

    /// 🔹 harga redeem
    final int redeemPrice = pricePerTicket * quotaUsed;

    return PembatalanKereta(
      id: json['id'] ?? '',
      redeemNumber: json['redeemNumber'] ?? '',
      redeemCancelledNumber: json['redeemCancelledNumber'],
      transactionNumber: json['transactionNumber'] ?? '',

      customerName: member['name'] ?? '',
      identityNumber: member['identityNumber'] ?? '',

      operatorName: operator['fullName'] ?? '',
      operatorNip: operator['nip'] ?? '',
      secondaryOperatorName: json['secondaryOperator']?['fullName'],

      stationName: station['stationName'] ?? '',
      paymentChannel: paymentChannel['name'] ?? '',

      serialNumber: card['serialNumber'] ?? '',

      cardCategory: product['category']?['categoryName'] ?? '',
      cardType: product['type']?['typeName'] ?? '',

      quotaTicket: totalQuota,
      price: redeemPrice,
      masaBerlaku: product['masaBerlaku'] ?? 0,

      purchaseDate: card['purchaseDate'] ?? '',
      expiredDate: card['expiredDate'] ?? '',

      ticketOrigin: json['ticketOrigin'],
      cancelReason: json['cancelReason'],

      deletedAt: json['deletedAt'] ?? '',
      programType: card['programType'] ?? '',
      redeemType: json['redeemType'] ?? '',
    );
  }
}
