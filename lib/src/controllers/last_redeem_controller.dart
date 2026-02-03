import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:ocr_project/src/models/last_redeem.dart';
import 'package:ocr_project/src/repositories/last_redeem_repository.dart';

class LastRedeemController {
  final LastRedeemRepository _repository = LastRedeemRepository();

  Future<LastRedeem?> fetchLastRedeem() async {
    final response = await _repository.fetchLastRedeem();
    final items = response.data['data']['items'] as List;

    if (items.isEmpty) return null;
    return LastRedeem.fromJson(items.first);
  }

  /// ✅ upload foto & dapet URL
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
