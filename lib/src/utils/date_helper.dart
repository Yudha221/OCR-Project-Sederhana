import 'package:intl/intl.dart';

String formatDeleteDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '-';

  final date = DateTime.parse(isoDate).toLocal();
  return DateFormat('d MMM yyyy, HH.mm').format(date);
}

/// ===============================
/// FORMAT RIWAYAT REDEEM
/// Contoh: 05-02-2026, 09:40:56
/// ===============================
String formatRedeemDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '-';

  try {
    final date = DateTime.parse(isoDate).toLocal(); // WIB
    return DateFormat('dd-MM-yyyy, HH:mm:ss').format(date);
  } catch (_) {
    return '-';
  }
}

/// ===============================
/// FORMAT TANGGAL SAJA
/// Contoh: 05-02-2026
/// ===============================
String formatDateOnly(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '-';

  try {
    final date = DateTime.parse(isoDate).toLocal();
    return DateFormat('dd-MM-yyyy').format(date);
  } catch (_) {
    return '-';
  }
}

/// ===============================
/// FORMAT TANGGAL INDONESIA
/// Contoh: 31 Mei 2026
/// ===============================
String formatDateIndo(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '-';

  try {
    final date = DateTime.parse(isoDate).toLocal();
    return DateFormat('dd MMMM yyyy').format(date);
  } catch (_) {
    return '-';
  }
}

/// ===============================
/// FORMAT Mata uang INDONESIA
/// Contoh: Rp.800,000,00
/// ===============================
String formatRupiah(dynamic price) {
  if (price == null) return '-';

  final number = int.tryParse(price.toString()) ?? 0;

  final format = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp.',
    decimalDigits: 2,
  );

  return format.format(number);
}
