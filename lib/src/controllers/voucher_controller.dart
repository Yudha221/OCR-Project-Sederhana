import 'package:ocr_project/src/models/station.dart';
import '../models/redeem.dart';
import '../repositories/voucher_repository.dart';

enum ProductType { voucher, fwc }

class VoucherRedeemController {
  final VoucherRepository _repo = VoucherRepository();

  /// =====================
  /// GLOBAL CACHE (ANTI API SPAM)
  /// =====================
  final Map<String, Map<String, dynamic>> _cardCache = {};
  final Map<String, Map<String, dynamic>> _productCache = {};
  Map<String, String>? _stationCache;

  /// =====================
  /// GET ALL VOUCHER DATA
  /// =====================
  Future<List<Redeem>> fetchAllVoucher() async {
    int page = 1;
    const int limit = 50;

    final List<Redeem> allData = [];

    /// =====================
    /// PAGINATION FETCH
    /// =====================
    while (true) {
      final data = await _repo.getRedeemList(page: page, limit: limit);

      if (data.isEmpty) break;

      allData.addAll(data);
      page++;
    }

    final voucherData = allData
        .where((e) => e.programType == 'VOUCHER')
        .toList();

    /// =====================
    /// LOAD STATION CACHE SEKALI
    /// =====================
    if (_stationCache == null) {
      final stations = await _repo.getStations();

      _stationCache = {for (var s in stations) s.id: s.channelName};
    }

    /// =====================
    /// ENRICH DATA
    /// =====================
    final List<Redeem> enriched = [];

    for (final redeem in voucherData) {
      int totalQuota = 0;
      int price = 0;
      String expired = '';

      try {
        if (redeem.cardId.isNotEmpty) {
          final card = await _getCard(redeem.cardId);

          expired = card['expiredDate']?.toString() ?? '';

          final productId = card['cardProductId'];

          if (productId != null) {
            final product = await _getProduct(productId);

            totalQuota =
                int.tryParse(product['totalQuota']?.toString() ?? '0') ?? 0;

            price = int.tryParse(product['price']?.toString() ?? '0') ?? 0;
          }
        }
      } catch (_) {}

      final channel = _stationCache?[redeem.stationId] ?? '';

      enriched.add(
        redeem.copyWith(
          price: price,
          expiredDate: expired,
          channelName: channel,
          totalQuota: totalQuota,
          remainingQuota: redeem.quotaTicket,
        ),
      );
    }

    return enriched;
  }

  /// =====================
  /// CARD CACHE
  /// =====================
  Future<Map<String, dynamic>> _getCard(String cardId) async {
    if (_cardCache.containsKey(cardId)) {
      return _cardCache[cardId]!;
    }

    final card = await _repo.getCardById(cardId);

    _cardCache[cardId] = card;

    return card;
  }

  /// =====================
  /// PRODUCT CACHE
  /// =====================
  Future<Map<String, dynamic>> _getProduct(String productId) async {
    if (_productCache.containsKey(productId)) {
      return _productCache[productId]!;
    }

    final response = await _repo.dio.get('/card/product/$productId');

    final product = response.data['data'];

    _productCache[productId] = product;

    return product;
  }

  /// =====================
  /// VERIFY SERIAL
  /// =====================
  Future<Map<String, dynamic>> verifySerial(String serialNumber) {
    return _repo.verifySerial(serialNumber);
  }

  /// =====================
  /// PRODUCT TYPE DETECTION
  /// =====================
  ProductType detectProductType(Map<String, dynamic> data) {
    final totalQuota = data['cardProduct']?['totalQuota'];

    if (totalQuota == 1) return ProductType.voucher;

    if (totalQuota > 1) return ProductType.fwc;

    throw Exception('Invalid product data');
  }

  /// =====================
  /// REDEEM
  /// =====================
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

  /// =====================
  /// DELETE
  /// =====================
  Future<Map<String, dynamic>> deleteVoucher({
    required String id,
    required String note,
    required String deletedBy,
  }) {
    return _repo.deleteVoucher(id: id, note: note, deletedBy: deletedBy);
  }

  /// =====================
  /// GET CATEGORY NAMES
  /// =====================
  Future<List<String>> fetchVoucherCategoryNames() async {
    final categories = await _repo.getVoucherCategories();

    return categories.map((e) => e.categoryName).toList();
  }

  /// =====================
  /// GET TYPE NAMES
  /// =====================
  Future<List<String>> fetchVoucherTypeNames() async {
    final types = await _repo.getVoucherCardTypes();

    return types.map((e) => e.typeName).toList();
  }

  /// =====================
  /// GET STATION NAMES
  /// =====================
  Future<List<String>> fetchStationNames() async {
    final stations = await _repo.getStations();

    return stations.map((e) => e.stationName).toSet().toList();
  }
}
