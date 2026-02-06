import 'passenger.dart';

class Redeem {
  final String id; // ✅ STRING UUID
  final String redeemDate;
  final String updatedAt;
  final String customerName;
  final String identityNumber;
  final String transactionNumber;
  final String serialNumber;
  final String cardCategory;
  final String cardType;
  final String journeyType;
  final String programType; // ✅ NEW FIELD
  final int usedQuota;
  final int remainingQuota;
  final bool isDeleted;
  final String note;
  final String operatorName;
  final String station;
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
    required this.isDeleted,
    required this.note,
    required this.operatorName,
    required this.station,
    required this.lastRedeem,
    required this.passengers,
  });

  factory Redeem.fromJson(Map<String, dynamic> json) {
    // 🔥 DEBUG: Cek apakah notes masuk
    if (json['notes'] != null) {
      print('DEBUG JSON NOTES (ID: ${json['id']}): ${json['notes']}');
    }

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
    final passengersJson = json['passengers'] as List<dynamic>? ?? [];
    final passengers = passengersJson
        .map((e) => Passenger.fromJson(e))
        .toList();

    return Redeem(
      id: json['id']?.toString() ?? '', // ✅ UUID STRING
      redeemDate: json['createdAt']?.toString() ?? '-',
      updatedAt: json['updatedAt']?.toString() ?? '-',
      customerName: member['name'] ?? '-',
      identityNumber: member['identityNumber'] ?? '-',
      transactionNumber: json['transactionNumber'] ?? '-',
      serialNumber: card['serialNumber'] ?? '-',
      cardCategory: category['categoryName'] ?? '-',
      cardType: type['typeName'] ?? '-',
      journeyType: json['redeemType'] ?? '-',
      programType: card['programType'] ?? '-', // ✅ Map from JSON
      note: json['notes']?.toString() ?? '-',
      usedQuota: quotaUsed,
      remainingQuota: remainingQuota,
      isDeleted: json['isDeleted'] == true,
      operatorName: operator['fullName'] ?? '-',
      station: station['stationName'] ?? '-',
      lastRedeem: remainingQuota <= 0,
      passengers: passengers,
    );
  }
}
