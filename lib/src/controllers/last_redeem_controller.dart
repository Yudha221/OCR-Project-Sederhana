import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:ocr_project/src/models/last_redeem.dart';
import 'package:ocr_project/src/repositories/last_redeem_repository.dart';

class LastRedeemController {
  final LastRedeemRepository _repository = LastRedeemRepository();

  Future<LastRedeem?> fetchLastRedeem(String redeemId) async {
    final response = await _repository.fetchLastRedeem();
    final items = response.data['data']['items'] as List;

    final match = items.firstWhere(
      (e) => e['id'] == redeemId,
      orElse: () => null,
    );

    if (match == null) return null;

    final redeem = LastRedeem.fromJson(match);

    // 🔥 hitung kuota terpakai dari backend data
    int usedQuota = redeem.initialQuota - redeem.remainingQuota;

    return LastRedeem(
      id: redeem.id,
      name: redeem.name,
      nik: redeem.nik,
      serialNumber: redeem.serialNumber,
      programType: redeem.programType,
      cardCategory: redeem.cardCategory,
      cardType: redeem.cardType,
      redeemDate: redeem.redeemDate,
      redeemType: redeem.redeemType,
      quotaUsed: usedQuota, // 🔥 ini yang dipakai
      remainingQuota: redeem.remainingQuota,
      quotaTicket: redeem.quotaTicket,
      initialQuota: redeem.initialQuota,
      station: redeem.station,
      operatorName: redeem.operatorName,
      status: redeem.status,
      photoUrl: redeem.photoUrl,
    );
  }

  /// upload foto & dapat URL
  Future<String> uploadPhoto(String id, File file) async {
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';

    return await _repository.uploadLastDoc(id, {
      'imageBase64': base64Image,
      'mimeType': mimeType,
    });
  }
}
