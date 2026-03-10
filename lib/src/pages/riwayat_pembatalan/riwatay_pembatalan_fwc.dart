import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/history_delete_controller.dart';
import 'package:ocr_project/src/utils/date_helper.dart';
import 'package:ocr_project/src/utils/role_access.dart';
import 'package:ocr_project/src/widgets/my_drawer.dart';

class PembatalanKeretaPagefwc extends StatefulWidget {
  final String userName;
  final String roleName;
  final RoleAccess roleAccess;

  const PembatalanKeretaPagefwc({
    super.key,
    required this.userName,
    required this.roleName,
    required this.roleAccess,
  });

  @override
  State<PembatalanKeretaPagefwc> createState() => _HistoryDeletePageState();
}

class _HistoryDeletePageState extends State<PembatalanKeretaPagefwc> {
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

  /// 🔥 FUNCTION REFRESH
  Future<void> _refreshData() async {
    await controller.load();
    setState(() {});
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
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'Riwayat Pembatalan Kereta FWC',
          style: TextStyle(color: Colors.white),
        ),
      ),

      /// SAFE AREA SUPAYA TIDAK KETUTUP NAVBAR
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Pembatalan Kereta FWC',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

              /// SEARCH
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari transaksi, kartu, operator, stasiun',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF7A1E2D)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF7A1E2D),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// TABLE + REFRESH
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                Colors.red.shade50,
                              ),
                              columns: const [
                                DataColumn(label: Text('Tanggal Pembatalan')),
                                DataColumn(label: Text('Nama Pelanggan')),
                                DataColumn(label: Text('NIK')),
                                DataColumn(
                                  label: Text('Nomor Orisinal Redeem'),
                                ),
                                DataColumn(
                                  label: Text('Nomor Pembatalan Redeem'),
                                ),
                                DataColumn(label: Text('Nomor Transaksi')),
                                DataColumn(label: Text('Status Pembatalan')),
                                DataColumn(label: Text('Status Asal')),
                                DataColumn(label: Text('Serial Kartu')),
                                DataColumn(label: Text('Kategori Kartu')),
                                DataColumn(label: Text('Tipe Kartu')),
                                DataColumn(label: Text('Tipe Perjalanan')),
                                DataColumn(label: Text('Sisa Kuota')),
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
                              rows: controller.tableData.map((e) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(formatDeleteDate(e.deletedAt)),
                                    ),
                                    DataCell(Text(e.customerName)),
                                    DataCell(Text(e.identityNumber)),
                                    DataCell(Text(e.redeemNumber)),
                                    DataCell(
                                      Text(e.redeemCancelledNumber ?? '-'),
                                    ),
                                    DataCell(Text(e.transactionNumber)),
                                    DataCell(
                                      Text(
                                        e.cancelReason ?? '-',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(e.ticketOrigin ?? '-')),
                                    DataCell(Text(e.serialNumber)),
                                    DataCell(_badge(e.cardCategory)),
                                    DataCell(Text(e.cardType)),
                                    DataCell(_journeyBadge(e.redeemType)),
                                    DataCell(Text('${e.quotaTicket}')),
                                    DataCell(Text(e.operatorName)),
                                    DataCell(
                                      Text(e.secondaryOperatorName ?? '-'),
                                    ),
                                    DataCell(Text(e.stationName)),
                                    DataCell(Text(e.operatorNip)),
                                    DataCell(Text(formatRupiah(e.price))),
                                    DataCell(Text(e.cardType)),
                                    DataCell(Text('${e.quotaTicket}')),
                                    DataCell(
                                      Text(formatDateOnly(e.purchaseDate)),
                                    ),
                                    DataCell(
                                      Text(formatDateOnly(e.expiredDate)),
                                    ),
                                    DataCell(Text('${e.masaBerlaku} Hari')),
                                    DataCell(Text(e.paymentChannel)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              /// PAGINATION
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
}
