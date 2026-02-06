import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/auth_controller.dart';
import 'package:ocr_project/src/controllers/voucher_controller.dart';
import 'package:ocr_project/src/models/redeem.dart';
import 'package:ocr_project/src/pages/redeem/redeem_voucher_page.dart';
import 'package:ocr_project/src/utils/dialog_utils.dart';
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
  List<String> voucherCategoryItems = [];
  bool isVoucherCategoryLoading = false;
  List<String> voucherTypeItems = [];
  bool isVoucherTypeLoading = false;
  List<String> stationItems = [];
  bool isStationLoading = false;

  // search & filter
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String? selectedCategory;
  String? selectedCardType;
  String? selectedStation;
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
    _loadVoucherCategories();
    _loadVoucherTypes();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => isStationLoading = true);

    final items = await _redeemController.fetchStationNames();

    setState(() {
      stationItems = items;
      isStationLoading = false;
    });
  }

  Future<void> _loadVoucherTypes() async {
    setState(() => isVoucherTypeLoading = true);

    final items = await _redeemController.fetchVoucherTypeNames();

    setState(() {
      voucherTypeItems = items;
      isVoucherTypeLoading = false;
    });
  }

  Future<void> _loadVoucherCategories() async {
    setState(() => isVoucherCategoryLoading = true);

    final items = await _redeemController.fetchVoucherCategoryNames();

    setState(() {
      voucherCategoryItems = items;
      isVoucherCategoryLoading = false;
    });
  }

  Future<void> _loadUserName() async {
    final name = await _authController.getUserName();
    setState(() => userName = name);
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
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

      final matchStation =
          selectedStation == null || e.station == selectedStation;

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

      return matchSearch &&
          matchCategory &&
          matchType &&
          matchStation &&
          matchDate;
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
          onPressed: () async {
            // 🔥 BUKA HALAMAN REDEEM & TUNGGU HASIL
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RedeemVoucherPage()),
            );

            // 🔥 TERIMA SINYAL & RELOAD TABEL
            if (result == true) {
              await _loadVoucher();
            }
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
    return SizedBox(
      height: 42,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari nama / NIK / serial',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        onChanged: (v) {
          searchQuery = v.toLowerCase();
          currentPage = 1;
          setState(_applyFilterAndPagination);
        },
      ),
    );
  }

  // ================= FILTER =================
  Widget _filterSection() {
    final isFilterActive =
        selectedCategory != null ||
        selectedCardType != null ||
        startDate != null ||
        endDate != null;

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER =====
            Row(
              children: [
                const Icon(Icons.filter_alt_outlined, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Filter Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (isFilterActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Filter Aktif',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            // ===== DATE RANGE =====
            Row(
              children: [
                Expanded(
                  child: _datePicker(
                    label: 'Tanggal Mulai',
                    value: startDate,
                    onTap: () async {
                      final date = await _pickDate(startDate);
                      if (date != null) {
                        startDate = date;
                        currentPage = 1;
                        setState(_applyFilterAndPagination);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datePicker(
                    label: 'Tanggal Akhir',
                    value: endDate,
                    onTap: () async {
                      final date = await _pickDate(endDate);
                      if (date != null) {
                        endDate = date;
                        currentPage = 1;
                        setState(_applyFilterAndPagination);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ===== DROPDOWN =====
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3.4,
              ),
              children: [
                _dropdown(
                  label: 'Kategori Voucher',
                  value: selectedCategory,
                  items: voucherCategoryItems,
                  onChanged: (v) {
                    selectedCategory = v;
                    currentPage = 1;
                    setState(_applyFilterAndPagination);
                  },
                ),
                _dropdown(
                  label: 'Tipe Voucher',
                  value: selectedCardType,
                  items: voucherTypeItems,
                  onChanged: (v) {
                    selectedCardType = v;
                    currentPage = 1;
                    setState(_applyFilterAndPagination);
                  },
                ),
                _dropdown(
                  label: 'Stasiun',
                  value: selectedStation,
                  items: stationItems,
                  onChanged: (v) {
                    selectedStation = v;
                    currentPage = 1;
                    setState(_applyFilterAndPagination);
                  },
                ),
              ],
            ),

            // ===== ACTION BUTTON =====
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _resetFilter,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
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
              DataColumn(label: Text('Nama PIC')),
              DataColumn(label: Text('NIK PIC')),
              DataColumn(label: Text('Nama Pelangan')),
              DataColumn(label: Text('NIK Pelangan')),
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
                  DataCell(
                    Text(
                      e.passengers.isNotEmpty &&
                              e.passengers.first.passengerName.trim().isNotEmpty
                          ? e.passengers.first.passengerName
                          : '-',
                    ),
                  ),

                  DataCell(
                    Text(
                      e.passengers.isNotEmpty &&
                              e.passengers.first.nik.trim().isNotEmpty
                          ? e.passengers.first.nik
                          : '-',
                    ),
                  ),
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
                        side: const BorderSide(
                          color: Colors.red, // 👈 warna border
                          width: 1.5, // 👈 tebal border
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // 👈 radius
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
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
      hint: Text('Semua $label'),
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        suffixIcon: value != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => onChanged(null),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _confirmDelete(String id) {
    DialogUtils.confirmDeleteFancy(
      context,
      title: 'Hapus Voucher',
      description:
          'Yakin ingin menghapus voucher ini?\nAksi ini membutuhkan alasan penghapusan.',
      onConfirm: (note) async {
        setState(() => isLoading = true);

        final res = await _redeemController.deleteVoucher(
          id: id,
          note: note,
          deletedBy: userName,
        );

        await _loadVoucher();

        if (!mounted) return;

        DialogUtils.showInfo(
          context,
          title: res['success'] == true ? 'Berhasil' : 'Gagal',
          message: res['message'],
          icon: res['success'] == true
              ? Icons.check_circle_outline
              : Icons.error_outline,
          color: res['success'] == true ? Colors.green : Colors.red,
        );

        setState(() => isLoading = false);
      },
    );
  }

  String formatJourney(String value) {
    if (value == 'ROUNDTRIP') return 'Round Trip';
    return 'Single Journey';
  }

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
        child: Text(
          value == null
              ? 'mm/dd/yyy'
              : '${value.day}/${value.month}/${value.year}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
