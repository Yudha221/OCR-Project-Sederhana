import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/auth_controller.dart';
import 'package:ocr_project/src/controllers/voucher_controller.dart';
import 'package:ocr_project/src/models/redeem.dart';
import 'package:ocr_project/src/pages/redeem/redeem_voucher_page.dart';
import 'package:ocr_project/src/widgets/my_drawer.dart';

class HomePageVoucher extends StatefulWidget {
  const HomePageVoucher({super.key});

  @override
  State<HomePageVoucher> createState() => _HomePageVoucherState();
}

class _HomePageVoucherState extends State<HomePageVoucher> {
  final AuthController _authController = AuthController();
  final VoucherRedeemController _redeemController =
      VoucherRedeemController(); // 🔥 GANTI CONTROLLER

  // user
  String userName = '';

  // loading
  bool isLoading = false;

  // search & filter
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String? selectedCategory;
  String? selectedCardType;
  DateTime? startDate;
  DateTime? endDate;

  // data
  List<Redeem> allData = [];
  List<Redeem> filteredData = [];
  List<Redeem> tableData = [];

  // pagination
  int currentPage = 1;
  int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadVoucher();
  }

  Future<void> _loadUserName() async {
    final name = await _authController.getUserName();
    setState(() => userName = name);
  }

  Future<void> _loadVoucher() async {
    setState(() => isLoading = true);

    final data = await _redeemController.fetchAllVoucher(); // 🔥 VOUCHER

    allData = data;
    currentPage = 1;
    _applyFilterAndPagination();

    setState(() => isLoading = false);
  }

  // ================= FILTER + PAGINATION =================
  void _applyFilterAndPagination() {
    filteredData = allData.where((e) {
      final matchSearch =
          searchQuery.isEmpty ||
          e.customerName.toLowerCase().contains(searchQuery) ||
          e.identityNumber.contains(searchQuery) ||
          e.serialNumber.contains(searchQuery);

      final matchCategory =
          selectedCategory == null || e.cardCategory == selectedCategory;

      final matchType =
          selectedCardType == null || e.cardType == selectedCardType;

      bool matchDate = true;
      final redeemDate = DateTime.tryParse(e.redeemDate);

      if (startDate != null && redeemDate != null) {
        matchDate = redeemDate.isAfter(
          startDate!.subtract(const Duration(days: 1)),
        );
      }
      if (endDate != null && redeemDate != null && matchDate) {
        matchDate = redeemDate.isBefore(endDate!.add(const Duration(days: 1)));
      }

      return matchSearch && matchCategory && matchType && matchDate;
    }).toList();

    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    tableData = filteredData.sublist(
      start,
      end > filteredData.length ? filteredData.length : end,
    );
  }

  // ================= RESET =================
  void _resetFilter() {
    setState(() {
      _searchController.clear();
      searchQuery = '';
      selectedCategory = null;
      selectedCardType = null;
      startDate = null;
      endDate = null;
      currentPage = 1;
      _applyFilterAndPagination();
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      drawer: MyDrawer(userName: userName),

      body: RefreshIndicator(
        onRefresh: _loadVoucher, // 🔥
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleSection(),
              const SizedBox(height: 16),
              _searchSection(),
              const SizedBox(height: 16),
              _filterSection(),
              const SizedBox(height: 20),
              _tableSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ================= APP BAR =================
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF7A1E2D),
      title: const Text('Voucher', style: TextStyle(color: Colors.white)),
    );
  }

  // ================= TITLE =================
  Widget _titleSection() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Redeem Voucher Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RedeemVoucherPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Redeem'),
        ),
      ],
    );
  }

  // ================= SEARCH =================
  Widget _searchSection() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Cari nama / NIK / serial',
        border: OutlineInputBorder(),
      ),
      onChanged: (v) {
        searchQuery = v.toLowerCase();
        currentPage = 1;
        setState(_applyFilterAndPagination);
      },
    );
  }

  // ================= FILTER =================
  Widget _filterSection() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3.2,
              ),
              children: [
                _dropdown(
                  label: 'Category',
                  value: selectedCategory,
                  items: const ['Paid', 'Unpaid'],
                  onChanged: (v) {
                    selectedCategory = v;
                    currentPage = 1;
                    setState(_applyFilterAndPagination);
                  },
                ),
                _dropdown(
                  label: 'Type',
                  value: selectedCardType,
                  items: const ['Ekonomi Premium'],
                  onChanged: (v) {
                    selectedCardType = v;
                    currentPage = 1;
                    setState(_applyFilterAndPagination);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _resetFilter,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Filter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableSection() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tableData.isEmpty) {
      return const Center(child: Text('Data tidak tersedia'));
    }

    final totalPage = (filteredData.length / rowsPerPage).ceil().clamp(1, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= TOTAL DATA =================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Redeem Voucher',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Data : ${filteredData.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ================= TABLE =================
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Tanggal Redeem')),
              DataColumn(label: Text('Nama Pelanggan')),
              DataColumn(label: Text('NIK')),
              DataColumn(label: Text('Nomor Transaksi')),
              DataColumn(label: Text('Serial Voucher')),
              DataColumn(label: Text('Kategori Voucher')),
              DataColumn(label: Text('Tipe Voucher')),
              DataColumn(label: Text('Tipe Perjalanan')),
              DataColumn(label: Text('Sisa Kuota')),
              DataColumn(label: Text('Operator')),
              DataColumn(label: Text('Stasiun')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: tableData.map((e) {
              return DataRow(
                cells: [
                  DataCell(Text(e.redeemDate)),
                  DataCell(Text(e.customerName)),
                  DataCell(Text(e.identityNumber)),
                  DataCell(Text(e.transactionNumber)),
                  DataCell(Text(e.serialNumber)),

                  // ===== KATEGORI BADGE =====
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.cardCategory,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  // ===== TIPE BADGE =====
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.cardType,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: e.journeyType == 'ROUNDTRIP'
                            ? const Color(0xFFDCD0F3)
                            : const Color(0xFFE6D5B8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        formatJourney(e.journeyType), // 👈 INI KUNCINYA
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: e.journeyType == 'ROUNDTRIP'
                              ? const Color(0xFF5E35B1)
                              : const Color(0xFF8B4513),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: SizedBox(
                        height: 32, // 👈 PAKSA TINGGI BADGE
                        width: 36, // 👈 BIKIN RAPI & SERAGAM
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: e.remainingQuota <= 0
                                ? Colors.red.withOpacity(0.15)
                                : e.remainingQuota <= 2
                                ? Colors.orange.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            e.remainingQuota.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: e.remainingQuota <= 0
                                  ? Colors.red
                                  : e.remainingQuota <= 2
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(e.operatorName)),
                  DataCell(Text(e.station)),

                  // ===== AKSI =====
                  DataCell(
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(e.id),
                      icon: const Icon(
                        Icons.delete,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // ================= PAGINATION =================
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: currentPage > 1
                  ? () {
                      currentPage--;
                      setState(_applyFilterAndPagination);
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('$currentPage / $totalPage'),
            IconButton(
              onPressed: currentPage < totalPage
                  ? () {
                      currentPage++;
                      setState(_applyFilterAndPagination);
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  // ================= UTIL =================
  Widget _dropdown({
    required String label,
    required List<String> items,
    String? value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }

  void _confirmDelete(String id) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Voucher'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Alasan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _redeemController.deleteVoucher(
                id: id,
                note: ctrl.text,
                deletedBy: userName,
              );
              await _loadVoucher();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String formatJourney(String value) {
    if (value == 'ROUNDTRIP') return 'Round Trip';
    return 'Single Journey';
  }
}
