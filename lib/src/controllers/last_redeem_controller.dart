import 'package:ocr_project/src/models/last_redeem.dart';
import 'package:ocr_project/src/repositories/last_redeem_repository.dart';

class LastRedeemController {
  final LastRedeemRepository _repository = LastRedeemRepository();

  Future<LastRedeem?> fetchLastRedeem() async {
    final response = await _repository.fetchLastRedeem();

    final items = response.data['data']['items'] as List;

    if (items.isEmpty) return null;

    // 🔥 AMBIL TRANSAKSI TERAKHIR
    return LastRedeem.fromJson(items.first);
  }
}
