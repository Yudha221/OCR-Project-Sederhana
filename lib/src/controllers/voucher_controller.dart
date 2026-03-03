import 'package:ocr_project/src/models/card_product.dart';
import 'package:ocr_project/src/models/station.dart';

import '../models/redeem.dart';
import '../repositories/voucher_repository.dart';

enum ProductType { voucher, fwc }

class VoucherRedeemController {
  final VoucherRepository _repo = VoucherRepository();

  // =====================
  // GET ALL VOUCHER DATA
  // =====================
  Future<List<Redeem>> fetchAllVoucher() async {
    int page = 1;
    const int limit = 50;
    List<Redeem> allData = [];

    while (true) {
      final data = await _repo.getRedeemList(page: page, limit: limit);
      if (data.isEmpty) break;

      allData.addAll(data);
      page++;
    }

    final voucherData = allData
        .where((e) => e.programType == 'VOUCHER')
        .toList();

    final products = await _repo.getCardProducts('VOUCHER');

    // 🔥 Ambil semua station SEKALI SAJA
    final stations = await _repo.getStations();

    // 🔥 Buat map stationId -> channelCode
    final stationMap = {for (var s in stations) s.id: s.channelCode};

    final enriched = await Future.wait(
      voucherData.map((redeem) async {
        int totalQuota = 0;
        int price = 0;
        String expired = '';

        if (redeem.cardId.isNotEmpty) {
          try {
            // 1️⃣ Ambil card
            final card = await _repo.getCardById(redeem.cardId);

            expired = card['expiredDate']?.toString() ?? '';
            final productId = card['cardProductId'];

            // 2️⃣ Ambil card product detail
            if (productId != null) {
              final productRes = await _repo.dio.get(
                '/card/product/$productId',
              );

              final product = productRes.data['data'];

              totalQuota =
                  int.tryParse(product['totalQuota']?.toString() ?? '0') ?? 0;

              price = int.tryParse(product['price']?.toString() ?? '0') ?? 0;
            }
          } catch (_) {}
        }

        final channel = stationMap[redeem.stationId] ?? '';

        return redeem.copyWith(
          price: price,
          expiredDate: expired,
          channelCode: channel,
          totalQuota: totalQuota,
          remainingQuota: redeem.quotaTicket,
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
  // REDEEM
  // =====================
  Future<Map<String, dynamic>> redeemVoucher({
    required String serial,
    required String name,
    required String identityNumber,
    required String passengerIdType,
  }) {
    return _repo.redeemVoucher(
      serial: serial,
      name: name,
      identityNumber: identityNumber,
      passengerIdType: passengerIdType,
    );
  }

  // =====================
  // DELETE
  // =====================
  Future<Map<String, dynamic>> deleteVoucher({
    required String id,
    required String note,
    required String deletedBy,
  }) {
    return _repo.deleteVoucher(id: id, note: note, deletedBy: deletedBy);
  }

  // =====================
  // GET VOUCHER CATEGORY NAMES
  // =====================
  Future<List<String>> fetchVoucherCategoryNames() async {
    final categories = await _repo.getVoucherCategories();

    // 🔥 ambil categoryName saja
    return categories.map((e) => e.categoryName).toList();
  }

  // =====================
  // GET VOUCHER TYPE NAMES
  // =====================
  Future<List<String>> fetchVoucherTypeNames() async {
    final types = await _repo.getVoucherCardTypes();

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
}
