import '../models/redeem.dart';
import '../repositories/redeem_repository.dart';

class RedeemController {
  final RedeemRepository _repo = RedeemRepository();

  // =====================
  // GET ALL DATA 🔥
  // =====================
  Future<List<Redeem>> fetchAllRedeem() async {
    int page = 1;
    const int limit = 50; // ambil banyak biar cepat
    List<Redeem> allData = [];

    while (true) {
      final data = await _repo.getRedeemList(page: page, limit: limit);

      if (data.isEmpty) break;

      allData.addAll(data);
      page++;
    }

    return allData;
  }

  // =====================
  // VERIFY SERIAL
  // =====================
  Future<Map<String, dynamic>> verifySerial(String serialNumber) {
    return _repo.verifySerial(serialNumber);
  }

  // =====================
  // DELETE REDEEM ✅
  // =====================
  Future<Map<String, dynamic>> deleteRedeem(String id) {
    return _repo.deleteRedeem(id);
  }

  // =====================
  // REDEEM
  // =====================
  Future<Map<String, dynamic>> redeem({
    required String serialNumber,
    required int redeemType,
  }) {
    return _repo.redeem(serialNumber: serialNumber, redeemType: redeemType);
  }
}
