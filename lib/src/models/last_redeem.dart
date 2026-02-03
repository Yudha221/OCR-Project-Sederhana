class LastRedeem {
  final String id;
  final String name;
  final String nik;
  final String serialNumber;
  final String programType;
  final String cardCategory;
  final String cardType;
  final String redeemDate;
  final String redeemType;
  final int quotaUsed;
  final int remainingQuota;
  final String station;
  final String operatorName;
  final String status;
  final String? photoUrl;

  LastRedeem({
    required this.id,
    required this.name,
    required this.nik,
    required this.serialNumber,
    required this.programType,
    required this.cardCategory,
    required this.cardType,
    required this.redeemDate,
    required this.redeemType,
    required this.quotaUsed,
    required this.remainingQuota,
    required this.station,
    required this.operatorName,
    required this.status,
    this.photoUrl,
  });

  factory LastRedeem.fromJson(Map<String, dynamic> json) {
    return LastRedeem(
      id: json['id'].toString(),
      name: json['card']['member']['name'],
      nik: json['card']['member']['identityNumber'],
      serialNumber: json['card']['serialNumber'],
      programType: json['card']['programType'],
      cardCategory: json['card']['cardProduct']['category']['categoryName'],
      cardType: json['card']['cardProduct']['type']['typeName'],
      redeemDate: json['shiftDate'],
      redeemType: json['redeemType'],
      quotaUsed: json['quotaUsed'],
      remainingQuota: json['remainingQuota'],
      station: json['station']['stationName'],
      operatorName: json['operator']['fullName'],
      status: json['status'],
      photoUrl: json['photoUrl'], // ⬅️ dari backend
    );
  }

  LastRedeem copyWith({String? photoUrl}) {
    return LastRedeem(
      id: id,
      name: name,
      nik: nik,
      serialNumber: serialNumber,
      programType: programType,
      cardCategory: cardCategory,
      cardType: cardType,
      redeemDate: redeemDate,
      redeemType: redeemType,
      quotaUsed: quotaUsed,
      remainingQuota: remainingQuota,
      station: station,
      operatorName: operatorName,
      status: status,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
