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
