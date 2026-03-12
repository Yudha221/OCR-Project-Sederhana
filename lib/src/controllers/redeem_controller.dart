import 'package:ocr_project/src/models/station.dart';
import 'package:ocr_project/src/models/card_product.dart';
import '../models/redeem.dart';
import '../repositories/redeem_repository.dart';

enum ProductType { voucher, fwc }

class RedeemController {
  final RedeemRepository _repo = RedeemRepository();

  // =====================
  // GET ALL DATA 🔥
  // =====================
  Future<List<Redeem>> fetchAllRedeem({String? stationId}) async {
    int page = 1;
    const int limit = 1000;
    List<Redeem> allData = [];

    while (true) {
      final data = await _repo.getRedeemList(
        page: page,
        limit: limit,
        stationId: stationId,
      );
      if (data.isEmpty) break;
      allData.addAll(data);
      page++;
    }

    final fwcData = allData.where((e) => e.programType == 'FWC').toList();

    final products = await _repo.getCardProductsFWC();

    // 🔥 CACHE STATION
    final Map<String, String> stationCache = {};

    final enriched = await Future.wait(
      fwcData.map((redeem) async {
        // ================= PRODUCT MATCH =================
        final match = products.firstWhere(
          (p) =>
              p.categoryName == redeem.cardCategory &&
              p.typeName == redeem.cardType,
          orElse: () => CardProduct(
            categoryName: '',
            typeName: '',
            price: 0,
            totalQuota: 0,
            masaBerlaku: 0,
          ),
        );

        final pricePerQuota = match.totalQuota == 0
            ? 0
            : (match.price / match.totalQuota);

        final redeemPrice = (pricePerQuota * redeem.usedQuota).round();

        // ================= EXPIRED DATE =================
        String expired = '';
        if (redeem.cardId.isNotEmpty) {
          final card = await _repo.getCardById(redeem.cardId);
          expired = card['expiredDate']?.toString() ?? '';
        }

        // ================= CHANNEL CODE =================
        String channel = '';

        if (redeem.stationId.isNotEmpty) {
          if (stationCache.containsKey(redeem.stationId)) {
            channel = stationCache[redeem.stationId]!;
          } else {
            final station = await _repo.getStationById(redeem.stationId);

            channel = station['channelName'] ?? '';
            stationCache[redeem.stationId] = channel;
          }
        }

        return redeem.copyWith(
          price: redeemPrice,
          quotaTicket: match.totalQuota,
          masaAktif: match.masaBerlaku,
          seatClassProgram: match.typeName,
          expiredDate: expired,
          channelName: channel,
        );
      }),
    );

    return enriched;
  }

  // =====================
  // VERIFY SERIAL
  // =====================
  Future<Map<String, dynamic>> verifySerial(String serialNumber) {
    return _repo.verifySerial(serialNumber);
  }

  ProductType detectProductType(Map<String, dynamic> data) {
    final totalQuota = data['cardProduct']?['totalQuota'];

    if (totalQuota == 1) return ProductType.voucher;
    if (totalQuota > 1) return ProductType.fwc;

    throw Exception('Invalid product data');
  }

  // =====================
  // DELETE REDEEM ✅
  // =====================
  Future<Map<String, dynamic>> deleteRedeem({
    required String id,
    required String reason,
    required String notes,
    String? trainBookCode,
    String? trainNumber,
    String? ticketNumber,
    String? departureDate,
  }) {
    return _repo.deleteRedeem(
      id: id,
      reason: reason,
      notes: notes,
      trainBookCode: trainBookCode,
      trainNumber: trainNumber,
      ticketNumber: ticketNumber,
      departureDate: departureDate,
    );
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

  Future<Map<String, dynamic>> verifySerialFWC(String serialNumber) async {
    final res = await _repo.verifySerial(serialNumber);

    if (res['success'] != true) {
      return res;
    }

    final data = res['data'];
    final programType = data['programType'];

    // 🚨 BLOK JIKA BUKAN FWC
    if (programType != 'FWC') {
      return {
        'success': false,
        'errorType': 'WRONG_PROGRAM',
        'message': 'Serial ini adalah voucher, silakan redeem di menu Voucher',
      };
    }

    return res;
  }

  Future<List<String>> fetchFWCCategoryNames() async {
    final categories = await _repo.getCardCategories();

    // 🔥 ambil categoryName saja
    return categories.map((e) => e.categoryName).toList();
  }

  Future<List<String>> fetchFWCCardTypes() async {
    final types = await _repo.getCardTypes();

    // 🔥 ambil typeName saja
    return types.map((e) => e.typeName).toList();
  }

  // =====================
  // GET STATION NAMES
  // =====================
  Future<List<String>> fetchStationNames() async {
    final List<Station> stations = await _repo.getStations();

    return stations
        .map((e) => e.stationName)
        .toSet() // 🚨 hindari duplikat
        .toList();
  }

  int calculateUsedQuotaBySerial({
    required List<Redeem> allData,
    required String serialNumber,
  }) {
    return allData
        .where((e) => e.serialNumber == serialNumber && !e.isDeleted)
        .fold(0, (sum, e) => sum + e.usedQuota);
  }
}
