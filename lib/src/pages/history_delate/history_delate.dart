import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/history_delete_controller.dart';

class HistoryDeletePage extends StatefulWidget {
  const HistoryDeletePage({super.key});

  @override
  State<HistoryDeletePage> createState() => _HistoryDeletePageState();
}

class _HistoryDeletePageState extends State<HistoryDeletePage> {
  final controller = HistoryDeleteController();
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.load().then((_) => setState(() {}));

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
      appBar: AppBar(title: const Text('Riwayat Penghapusan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Penghapusan',
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
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SEARCH
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari transaksi, kartu, operator, stasiun',
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

            // TABLE
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
                            DataColumn(label: Text('Serial Kartu')),
                            DataColumn(label: Text('Kategori')),
                            DataColumn(label: Text('Tipe Kartu')),
                            DataColumn(label: Text('Perjalanan')),
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
                                  Text(e['card']?['serialNumber'] ?? '-'),
                                ),
                                DataCell(
                                  _badge(
                                    e['card']?['cardProduct']?['category']?['categoryName'] ??
                                        '-',
                                  ),
                                ),
                                DataCell(
                                  Text(e['card']?['programType'] ?? '-'),
                                ),
                                DataCell(_journeyBadge(journey)),
                                DataCell(
                                  Text(e['operator']?['fullName'] ?? '-'),
                                ),
                                DataCell(
                                  Text(e['station']?['stationName'] ?? '-'),
                                ),
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
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Text(
                                                'Lihat Alasan',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
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

            // PAGINATION
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

  Widget _journeyBadge(String type) {
    final isRound = type == 'ROUNDTRIP';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isRound ? Colors.purple.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isRound ? 'Roundtrip' : 'Single Journey',
        style: TextStyle(color: isRound ? Colors.purple : Colors.orange),
      ),
    );
  }

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
