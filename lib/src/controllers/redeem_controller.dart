import '../models/redeem.dart';
import '../repositories/redeem_repository.dart';

class RedeemController {
  final RedeemRepository _repo = RedeemRepository();

  // =====================
  // GET LIST
  // =====================
  Future<List<Redeem>> fetchRedeem() {
    return _repo.getRedeemList();
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
}
