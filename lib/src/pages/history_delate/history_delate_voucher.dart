import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/history_delete_controller.dart';

/// ===========================================================
/// HISTORY DELETE VOUCHER PAGE
/// Tampilan sama seperti HistoryDeletePage (FWC)
/// ===========================================================
class HistoryDeleteVoucherPage extends StatefulWidget {
  const HistoryDeleteVoucherPage({super.key});

  @override
  State<HistoryDeleteVoucherPage> createState() =>
      _HistoryDeleteVoucherPageState();
}

class _HistoryDeleteVoucherPageState extends State<HistoryDeleteVoucherPage> {
  // ================= CONTROLLER =================
  final controller = HistoryDeleteController();

  // ================= SEARCH =================
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // load data pertama kali
    controller.load().then((_) => setState(() {}));

    // listener search
    searchCtrl.addListener(() {
      controller.search(searchCtrl.text);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPage = controller.totalPage;

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        title: const Text('Riwayat Penghapusan Voucher'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===================================================
            // HEADER
            // ===================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Penghapusan Voucher',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Total Data : ${controller.filteredData.isNotEmpty ? controller.filteredData.length : controller.allData.length}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ===================================================
            // SEARCH
            // ===================================================
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari transaksi, voucher, operator, stasiun',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===================================================
            // TABLE
            // ===================================================
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.red.shade50,
                          ),
                          columns: const [
                            DataColumn(label: Text('Nomor Transaksi')),
                            DataColumn(label: Text('Serial Voucher')),
                            DataColumn(label: Text('Kategori')),
                            DataColumn(label: Text('Tipe Voucher')),
                            DataColumn(label: Text('Tipe Perjalanan')),
                            DataColumn(label: Text('Operator')),
                            DataColumn(label: Text('Stasiun')),
                            DataColumn(label: Text('Alasan')),
                          ],
                          rows: controller.tableData.map((e) {
                            final journey = e['redeemType'];

                            return DataRow(
                              cells: [
                                DataCell(Text(e['transactionNumber'] ?? '-')),
                                DataCell(
                                  Text(e['voucher']?['serialNumber'] ?? '-'),
                                ),
                                DataCell(
                                  _badge(e['voucher']?['category'] ?? '-'),
                                ),
                                DataCell(Text(e['voucher']?['type'] ?? '-')),

                                // ================= PERJALANAN =================
                                DataCell(_journeyBadge(journey)),

                                DataCell(
                                  Text(e['operator']?['fullName'] ?? '-'),
                                ),
                                DataCell(
                                  Text(e['station']?['stationName'] ?? '-'),
                                ),

                                // ================= ALASAN =================
                                DataCell(
                                  e['notes'] != null &&
                                          e['notes'].toString().isNotEmpty
                                      ? TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () => _showReasonDialog(
                                            context,
                                            e['notes'],
                                          ),
                                          child: const Text(
                                            'Lihat Alasan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Tanpa Alasan',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),

            // ===================================================
            // PAGINATION
            // ===================================================
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: controller.currentPage > 1
                      ? () {
                          controller.prevPage();
                          setState(() {});
                        }
                      : null,
                ),
                Text('${controller.currentPage} / $totalPage'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: controller.currentPage < totalPage
                      ? () {
                          controller.nextPage();
                          setState(() {});
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // BADGE KATEGORI
  // ===========================================================
  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }

  // ===========================================================
  // BADGE PERJALANAN (INI YANG PENTING)
  // ===========================================================
  Widget _journeyBadge(String type) {
    final isRound = type.toUpperCase() == 'ROUNDTRIP';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isRound ? Colors.purple.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isRound ? 'Round Trip' : 'Single Journey',
        style: TextStyle(
          color: isRound ? Colors.purple : Colors.orange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ===========================================================
  // DIALOG ALASAN
  // ===========================================================
  void _showReasonDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Alasan Penghapusan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Text(reason, style: const TextStyle(fontSize: 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
