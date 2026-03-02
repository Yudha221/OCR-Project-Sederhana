import 'passenger.dart';

class Redeem {
  final String id;
  final String redeemDate;
  final String updatedAt;
  final String customerName;
  final String identityNumber;
  final String transactionNumber;
  final String serialNumber;
  final String cardCategory;
  final String cardType;
  final String journeyType;
  final String programType;
  final int usedQuota;
  final int remainingQuota;
  final int quotaTicket;
  final int masaAktif;
  final int price;
  final bool isDeleted;
  final String note;
  final String operatorName;
  final String nipKai;
  final String station;
  final String seatClassProgram;
  final bool lastRedeem;

  final List<Passenger> passengers;

  Redeem({
    required this.id,
    required this.redeemDate,
    required this.updatedAt,
    required this.customerName,
    required this.identityNumber,
    required this.transactionNumber,
    required this.serialNumber,
    required this.cardCategory,
    required this.cardType,
    required this.journeyType,
    required this.programType,
    required this.usedQuota,
    required this.remainingQuota,
    required this.quotaTicket,
    required this.masaAktif,
    required this.price,
    required this.isDeleted,
    required this.note,
    required this.operatorName,
    required this.nipKai,
    required this.station,
    required this.lastRedeem,
    required this.seatClassProgram,
    required this.passengers,
  });

  factory Redeem.fromJson(Map<String, dynamic> json) {
    final card = json['card'] ?? {};
    final member = card['member'] ?? {};
    final product = card['cardProduct'] ?? {};
    final category = product['category'] ?? {};
    final type = product['type'] ?? {};
    final station = json['station'] ?? {};
    final operator = json['operator'] ?? {};

    final int remainingQuota =
        int.tryParse(json['remainingQuota']?.toString() ?? '0') ?? 0;

    final int quotaUsed =
        int.tryParse(json['quotaUsed']?.toString() ?? '0') ?? 0;

    final int quotaTicket =
        int.tryParse(card['quotaTicket']?.toString() ?? '0') ?? 0;

    final int masaAktif =
        int.tryParse(product['masaBerlaku']?.toString() ?? '0') ?? 0;

    final int price = int.tryParse(product['price']?.toString() ?? '0') ?? 0;

    final passengersJson = json['passengers'] as List<dynamic>? ?? [];
    final passengers = passengersJson
        .map((e) => Passenger.fromJson(e))
        .toList();

    return Redeem(
      id: json['id']?.toString() ?? '',
      redeemDate: json['createdAt']?.toString() ?? '-',
      updatedAt: json['updatedAt']?.toString() ?? '-',

      customerName: member['name'] ?? '-',
      identityNumber: member['identityNumber'] ?? '-',

      transactionNumber: json['transactionNumber'] ?? '-',
      serialNumber: card['serialNumber'] ?? '-',

      cardCategory: category['categoryName'] ?? '-',
      cardType: type['typeName'] ?? '-',

      journeyType: json['redeemType'] ?? '-',
      programType: card['programType'] ?? '-',

      usedQuota: quotaUsed,
      remainingQuota: remainingQuota,
      seatClassProgram: '',
      quotaTicket: quotaTicket,
      masaAktif: masaAktif,
      price: price,

      isDeleted: json['isDeleted'] == true,
      note: json['notes']?.toString() ?? '-',

      operatorName: operator['fullName'] ?? '-',
      nipKai: operator['nip'] ?? '-',
      station: station['stationName'] ?? '-',

      lastRedeem: remainingQuota <= 0,
      passengers: passengers,
    );
  }

  Redeem copyWith({
    int? price,
    int? quotaTicket,
    int? remainingQuota,
    int? masaAktif,
    String? seatClassProgram,
  }) {
    return Redeem(
      id: id,
      redeemDate: redeemDate,
      updatedAt: updatedAt,
      customerName: customerName,
      identityNumber: identityNumber,
      transactionNumber: transactionNumber,
      serialNumber: serialNumber,
      cardCategory: cardCategory,
      cardType: cardType,
      journeyType: journeyType,
      programType: programType,

      seatClassProgram: seatClassProgram ?? this.seatClassProgram,

      usedQuota: usedQuota,
      remainingQuota: remainingQuota ?? this.remainingQuota,
      quotaTicket: quotaTicket ?? this.quotaTicket,
      masaAktif: masaAktif ?? this.masaAktif,
      price: price ?? this.price,
      isDeleted: isDeleted,
      note: note,
      operatorName: operatorName,
      nipKai: nipKai,
      station: station,
      lastRedeem: (remainingQuota ?? this.remainingQuota) <= 0,
      passengers: passengers,
    );
  }
}
