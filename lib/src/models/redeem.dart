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
  final String stationId;
  final String channelName;
  final int totalQuota;
  final int usedQuota;
  final int remainingQuota;
  final int quotaTicket;
  final int masaAktif;
  final int price;
  final bool isDeleted;
  final String note;
  final String redeemNumber;
  final String status;
  final String operatorName;
  final String secondaryOperatorName;
  final String nipKai;
  final String station;
  final String seatClassProgram;
  final String cardId;
  final String expiredDate;
  final String ticketOrigin;
  final bool lastRedeem;
  final String memberId;

  final List<Passenger> passengers;

  Redeem({
    required this.id,
    required this.redeemNumber,
    required this.status,
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
    required this.totalQuota,
    required this.remainingQuota,
    required this.quotaTicket,
    required this.masaAktif,
    required this.price,
    required this.isDeleted,
    required this.note,
    required this.operatorName,
    required this.secondaryOperatorName,
    required this.nipKai,
    required this.station,
    required this.lastRedeem,
    required this.memberId,
    required this.seatClassProgram,
    required this.cardId,
    required this.expiredDate,
    required this.stationId,
    required this.ticketOrigin,
    required this.channelName,
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
    final secondaryOperator = json['secondaryOperator'] ?? {};
    final stationId = json['stationId'] ?? json['station']?['id'] ?? '';

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
      redeemNumber: json['redeemNumber'] ?? '-',
      status: json['status'] ?? '-',
      redeemDate: json['createdAt']?.toString() ?? '-',
      updatedAt: json['updatedAt']?.toString() ?? '-',
      ticketOrigin: json['ticketOrigin'] ?? '-',
      customerName: member['name'] ?? '-',
      identityNumber: member['identityNumber'] ?? '-',

      transactionNumber: json['transactionNumber'] ?? '-',
      serialNumber: card['serialNumber'] ?? '-',

      cardCategory: category['categoryName'] ?? '-',
      cardType: type['typeName'] ?? '-',

      journeyType: json['redeemType'] ?? '-',
      programType: card['programType'] ?? '-',
      memberId: member['id'] ?? '',

      usedQuota: quotaUsed,
      remainingQuota: remainingQuota,
      seatClassProgram: '',
      quotaTicket: quotaTicket,
      masaAktif: masaAktif,
      price: price,

      isDeleted: json['isDeleted'] == true,
      note: json['notes']?.toString() ?? '-',

      operatorName: operator['fullName'] ?? '-',
      secondaryOperatorName: secondaryOperator['fullName'] ?? '-',
      nipKai: operator['nip'] ?? '-',
      station: station['stationName'] ?? '-',

      lastRedeem: remainingQuota <= 0,
      totalQuota: 0,
      passengers: passengers,
      cardId: json['cardId'] ?? '',
      stationId: stationId,
      channelName: '',
      expiredDate: '', // kosong dulu, nanti diisi dari API card
    );
  }

  Redeem copyWith({
    int? price,
    int? quotaTicket,
    int? remainingQuota,
    int? masaAktif,
    String? seatClassProgram,
    String? expiredDate,
    String? channelName,
    int? totalQuota,
    String? redeemNumber,
    String? status,
    String? ticketOrigin,
  }) {
    return Redeem(
      id: id,
      redeemDate: redeemDate,
      updatedAt: updatedAt,
      customerName: customerName,
      memberId: memberId,
      identityNumber: identityNumber,
      transactionNumber: transactionNumber,
      serialNumber: serialNumber,
      cardCategory: cardCategory,
      cardType: cardType,
      journeyType: journeyType,
      programType: programType,
      expiredDate: expiredDate ?? this.expiredDate,
      seatClassProgram: seatClassProgram ?? this.seatClassProgram,
      cardId: cardId,
      usedQuota: usedQuota,
      remainingQuota: remainingQuota ?? this.remainingQuota,
      quotaTicket: quotaTicket ?? this.quotaTicket,
      totalQuota: totalQuota ?? this.totalQuota,
      masaAktif: masaAktif ?? this.masaAktif,
      price: price ?? this.price,
      isDeleted: isDeleted,
      note: note,
      operatorName: operatorName,
      secondaryOperatorName: secondaryOperatorName,
      nipKai: nipKai,
      station: station,
      stationId: stationId,
      channelName: channelName ?? this.channelName, // 🔥 FIX
      lastRedeem: (remainingQuota ?? this.remainingQuota) <= 0,
      passengers: passengers,
      redeemNumber: redeemNumber ?? this.redeemNumber,
      status: status ?? this.status,
      ticketOrigin: ticketOrigin ?? this.ticketOrigin,
    );
  }
}
