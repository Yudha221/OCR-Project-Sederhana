import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/voucher_delete_controller.dart';
import 'package:ocr_project/src/models/redeem.dart';

class HistoryDeleteVoucherPage extends StatefulWidget {
  const HistoryDeleteVoucherPage({super.key});

  @override
  State<HistoryDeleteVoucherPage> createState() =>
      _HistoryDeleteVoucherPageState();
}

class _HistoryDeleteVoucherPageState extends State<HistoryDeleteVoucherPage> {
  final controller = VoucherDeleteController();
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller.load().then((_) {
      if (mounted) setState(() {});
    });

    searchCtrl.addListener(() {
      controller.search(searchCtrl.text);
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPage = controller.totalPage;

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(title: const Text('Riwayat Penghapusan Voucher')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= HEADER =================
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
                    'Total Data : ${controller.filteredData.isNotEmpty ? controller.filteredData.length : controller.tableData.length}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ================= SEARCH =================
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari transaksi, pelanggan, operator, stasiun',
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

            // ================= TABLE =================
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : controller.tableData.isEmpty
                  ? const Center(child: Text('Data tidak tersedia'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.red.shade50,
                          ),
                          columns: const [
                            DataColumn(label: Text('Tanggal Dihapus')),
                            DataColumn(label: Text('Nama Pelanggan')),
                            DataColumn(label: Text('NIK')),
                            DataColumn(label: Text('Nomor Transaksi')),
                            DataColumn(label: Text('Serial Voucher')),
                            DataColumn(label: Text('Kategori')),
                            DataColumn(label: Text('Tipe Voucher')),
                            DataColumn(label: Text('Sisa Kuota')),
                            DataColumn(label: Text('Perjalanan')),
                            DataColumn(label: Text('Operator')),
                            DataColumn(label: Text('Stasiun')),
                            DataColumn(label: Text('Alasan Hapus')),
                          ],
                          rows: controller.tableData.map<DataRow>((Redeem e) {
                            return DataRow(
                              cells: [
                                // Tanggal Dihapus
                                DataCell(
                                  Text(
                                    e.redeemDate != '-'
                                        ? e.redeemDate.substring(0, 10)
                                        : '-',
                                  ),
                                ),

                                // Nama Pelanggan
                                DataCell(Text(e.customerName)),

                                // NIK
                                DataCell(Text(e.identityNumber)),

                                // Nomor Transaksi
                                DataCell(Text(e.transactionNumber)),

                                // Serial Voucher
                                DataCell(Text(e.serialNumber)),

                                // Kategori
                                DataCell(_categoryBadge(e.cardCategory)),

                                // Tipe Voucher
                                DataCell(Text(e.cardType)),

                                DataCell(_quotaBadge(e.remainingQuota)),

                                // Perjalanan
                                DataCell(_journeyBadge(e.journeyType)),

                                // Operator
                                DataCell(Text(e.operatorName)),

                                // Stasiun
                                DataCell(Text(e.station)),

                                // Alasan Hapus
                                DataCell(
                                  e.note.isNotEmpty && e.note != '-'
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
                                            e.note,
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

            const SizedBox(height: 8),

            // ================= PAGINATION =================
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

  // ================= JOURNEY BADGE =================
  Widget _journeyBadge(String type) {
    final isSingle = type.toUpperCase() == 'SINGLE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSingle ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isSingle ? 'Single Journey' : 'Multi Journey',
        style: TextStyle(
          color: isSingle ? Colors.orange : Colors.blue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ================= DIALOG ALASAN =================
  void _showReasonDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alasan Penghapusan'),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // ================= CATEGORY BADGE =================
  Widget _categoryBadge(String category) {
    final value = category.toLowerCase();
    final isPaid = value == 'paid';
    final isUnpaid = value == 'unpaid';

    Color borderColor;
    Color bgColor;
    Color textColor;

    if (isPaid) {
      borderColor = Colors.blue;
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue;
    } else if (isUnpaid) {
      borderColor = Colors.red;
      bgColor = Colors.red.shade50;
      textColor = Colors.red;
    } else {
      borderColor = Colors.grey;
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _quotaBadge(int remainingQuota) {
    final isEmpty = remainingQuota <= 0;

    return Center(
      child: Text(
        isEmpty ? '0' : '$remainingQuota',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isEmpty ? Colors.red : Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
