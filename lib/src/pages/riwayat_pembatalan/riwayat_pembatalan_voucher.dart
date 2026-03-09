import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/voucher_delete_controller.dart';
import 'package:ocr_project/src/models/pembatalan_kereta.dart';
import 'package:ocr_project/src/utils/date_helper.dart';
import 'package:ocr_project/src/widgets/my_drawer.dart';
import 'package:ocr_project/src/utils/role_access.dart';

class PembatalanKeretaPageVoucher extends StatefulWidget {
  final String userName;
  final String roleName;
  final RoleAccess roleAccess;

  const PembatalanKeretaPageVoucher({
    super.key,
    required this.userName,
    required this.roleName,
    required this.roleAccess,
  });

  @override
  State<PembatalanKeretaPageVoucher> createState() =>
      _HistoryDeleteVoucherPageState();
}

class _HistoryDeleteVoucherPageState
    extends State<PembatalanKeretaPageVoucher> {
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

      drawer: MyDrawer(
        userName: widget.userName,
        roleName: widget.roleName,
        roleAccess: widget.roleAccess,
      ),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF7A1E2D),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Riwayat Pembatalan Voucher',
          style: TextStyle(color: Colors.white),
        ),
      ),
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
                            DataColumn(label: Text('Tanggal Pembatalan')),
                            DataColumn(label: Text('Nama PIC')),
                            DataColumn(label: Text('NIK PIC')),
                            DataColumn(label: Text('Nama Pelanggan')),
                            DataColumn(label: Text('NIK Pelanggan')),
                            DataColumn(label: Text('Nomor Orisinal Redeem')),
                            DataColumn(label: Text('Nomor Pembatalan Redeem')),
                            DataColumn(label: Text('Nomor Transaksi')),
                            DataColumn(label: Text('Status Pembatalan')),
                            DataColumn(label: Text('Status Awal')),
                            DataColumn(label: Text('Serial Kartu')),
                            DataColumn(label: Text('Kategori Kartu')),
                            DataColumn(label: Text('Kelas')),
                            DataColumn(label: Text('Operator Utama')),
                            DataColumn(label: Text('Operator Pengganti')),
                            DataColumn(label: Text('Stasiun')),
                            DataColumn(label: Text('NIP KAI')),
                            DataColumn(label: Text('Price Redeem')),
                            DataColumn(label: Text('Seat Class Program')),
                            DataColumn(label: Text('Quota Ticket')),
                            DataColumn(label: Text('Purchase Date')),
                            DataColumn(label: Text('Expired Date')),
                            DataColumn(label: Text('Masa Aktif')),
                            DataColumn(label: Text('Ticketing Channel')),
                          ],
                          rows: controller.tableData.map<DataRow>((
                            PembatalanKereta e,
                          ) {
                            return DataRow(
                              cells: [
                                DataCell(Text(formatDeleteDate(e.deletedAt))),

                                DataCell(Text(e.operatorName)),

                                DataCell(Text(e.operatorNip)),

                                DataCell(Text(e.customerName)),

                                DataCell(Text(e.identityNumber)),

                                DataCell(Text(e.redeemNumber)),

                                DataCell(Text(e.redeemCancelledNumber ?? '-')),

                                DataCell(Text(e.transactionNumber)),

                                DataCell(Text(e.cancelReason ?? '-')),

                                DataCell(Text(e.ticketOrigin ?? '-')),

                                DataCell(Text(e.serialNumber)),

                                DataCell(_categoryBadge(e.cardCategory)),

                                DataCell(Text(e.cardType)),

                                DataCell(Text(e.operatorName)),

                                DataCell(Text(e.secondaryOperatorName ?? '-')),

                                DataCell(Text(e.stationName)),

                                DataCell(Text(e.operatorNip)),

                                DataCell(Text(formatRupiah(e.price))),

                                DataCell(Text(e.cardType)),

                                DataCell(Text('${e.quotaTicket}')),

                                DataCell(Text(formatDateOnly(e.purchaseDate))),

                                DataCell(Text(formatDateOnly(e.expiredDate))),

                                DataCell(Text('${e.masaBerlaku} Hari')),

                                DataCell(Text(e.paymentChannel)),
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
