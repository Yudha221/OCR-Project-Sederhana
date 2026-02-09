import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ocr_project/src/controllers/auth_controller.dart';
import 'package:ocr_project/src/controllers/redeem_controller.dart';
import 'package:ocr_project/src/models/last_redeem.dart';
import 'package:ocr_project/src/models/redeem.dart';
import 'package:ocr_project/src/pages/last_redeem/last_redeem_page.dart';
import 'package:ocr_project/src/pages/redeem/redeem_page.dart';
import 'package:ocr_project/src/utils/date_helper.dart';
import 'package:ocr_project/src/widgets/filter_button.dart';
import 'package:ocr_project/src/widgets/my_drawer.dart';
import 'package:ocr_project/src/models/user.dart';
import 'dart:convert';

class HomePageKai extends StatefulWidget {
  const HomePageKai({super.key});

  @override
  State<HomePageKai> createState() => _HomePageState();
}

class _HomePageState extends State<HomePageKai> {
  final AuthController _authController = AuthController();
  final RedeemController _redeemController = RedeemController();

  // user
  String userName = '';
  String roleName = '-';

  // loading
  bool isLoading = false;
  List<String> categoryItems = [];
  bool isCategoryLoading = false;
  List<String> cardTypeItems = [];
  bool isCardTypeLoading = false;
  List<String> stationItems = [];
  bool isStationLoading = false;
  String? selectedStation;

  // search & filter
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  List<String> selectedCategories = [];
  List<String> selectedCardTypes = [];
  List<String> selectedStations = [];

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
    _loadUserProfile();
    _loadRedeem();
    _loadCategories();
    _loadCardTypes();
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

  Future<void> _loadCardTypes() async {
    setState(() => isCardTypeLoading = true);

    final items = await _redeemController.fetchFWCCardTypes();

    setState(() {
      cardTypeItems = items;
      isCardTypeLoading = false;
    });
  }

  Future<void> _loadCategories() async {
    setState(() => isCategoryLoading = true);

    final items = await _redeemController.fetchFWCCategoryNames();

    setState(() {
      categoryItems = items;
      isCategoryLoading = false;
    });
  }

  Future<void> _loadUserProfile() async {
    const storage = FlutterSecureStorage();
    final userJson = await storage.read(key: 'userProfile');

    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));

      debugPrint('USERNAME : ${user.fullName}');
      debugPrint('ROLE     : ${user.roleName}');

      setState(() {
        userName = user.fullName;
        roleName = user.roleName;
      });
    }
  }

  Future<void> _loadRedeem() async {
    setState(() => isLoading = true);

    final data = await _redeemController.fetchAllRedeem();

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
          selectedCategories.isEmpty ||
          selectedCategories.contains(e.cardCategory);

      final matchType =
          selectedCardTypes.isEmpty || selectedCardTypes.contains(e.cardType);

      final matchStation =
          selectedStations.isEmpty || selectedStations.contains(e.station);
      ;

      bool matchDate = true;
      final redeemRaw = DateTime.tryParse(e.redeemDate);

      if (redeemRaw != null) {
        final redeemDate = _onlyDate(redeemRaw);

        if (startDate != null) {
          final s = _onlyDate(startDate!);
          matchDate = redeemDate.isAtSameMomentAs(s) || redeemDate.isAfter(s);
        }

        if (endDate != null && matchDate) {
          final eDate = _onlyDate(endDate!);
          matchDate =
              redeemDate.isAtSameMomentAs(eDate) || redeemDate.isBefore(eDate);
        }
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
      selectedCategories.clear();
      selectedCardTypes.clear();
      selectedStations.clear();
      startDate = null;
      endDate = null;
      currentPage = 1;
      _applyFilterAndPagination();
    });
  }

  DateTime _onlyDate(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      drawer: MyDrawer(userName: userName, roleName: roleName),

      // 🔥 TAMBAHAN REFRESH (SATU-SATUNYA PERUBAHAN)
      body: RefreshIndicator(
        onRefresh: _loadRedeem,
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
              FilterButton(
                categoryItems: categoryItems,
                cardTypeItems: cardTypeItems,
                stationItems: stationItems,

                selectedCategories: selectedCategories,
                selectedCardTypes: selectedCardTypes,
                selectedStations: selectedStations,

                startDate: startDate,
                endDate: endDate,

                onCategoryChanged: (v) {
                  setState(() => selectedCategories = v);
                },
                onCardTypeChanged: (v) {
                  setState(() => selectedCardTypes = v);
                },
                onStationChanged: (v) {
                  setState(() => selectedStations = v);
                },

                onStartDateChanged: (d) {
                  setState(() => startDate = d);
                },
                onEndDateChanged: (d) {
                  setState(() => endDate = d);
                },

                onReset: _resetFilter,
                onApply: () {
                  currentPage = 1;
                  setState(_applyFilterAndPagination);
                },
              ),

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
      title: const Text(
        'Frequent Whoosher Card',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  // ================= TITLE =================
  Widget _titleSection() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Redeem Kuota FWC',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RedeemPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // 👈 BORDER RADIUS
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            borderRadius: BorderRadius.circular(24), // 👈 ROUNDED
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

  // ================= TABLE =================
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA), // abu modern
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ///  JUDUL
              const Text(
                "Riwayat Redeem",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),

              ///  TOTAL DATA (punya kamu — cuma dipindah)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.10),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Tanggal Redeem')),
              DataColumn(label: Text('Nama Pelanggan')),
              DataColumn(label: Text('NIK')),
              DataColumn(label: Text('Nomor Transaksi')),
              DataColumn(label: Text('Serial Kartu')),
              DataColumn(label: Text('Kategori Kartu')),
              DataColumn(label: Text('Tipe Kartu')),
              DataColumn(label: Text('Tipe Perjalanan')),
              DataColumn(label: Text('Sisa Kuota')),
              DataColumn(label: Text('Operator')),
              DataColumn(label: Text('Stasiun')),
              DataColumn(label: Text('Last Redeem')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: tableData.map((e) {
              return DataRow(
                cells: [
                  DataCell(Text(formatRedeemDate(e.redeemDate))),
                  DataCell(Text(e.customerName)),
                  DataCell(Text(e.identityNumber)),
                  DataCell(Text(e.transactionNumber)),
                  DataCell(Text(e.serialNumber)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6E4FF), // bg soft blue
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e.cardCategory,
                        style: const TextStyle(
                          color: Color(0xFF1565C0), // text blue
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(e.cardType)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: e.journeyType.toLowerCase().contains('round')
                            ? const Color(0xFFDCD0F3)
                            : const Color(0xFFE6D5B8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e.journeyType,
                        style: TextStyle(
                          color: e.journeyType.toLowerCase().contains('round')
                              ? const Color(0xFF5E35B1)
                              : const Color(0xFF8B4513),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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
                          color: e.remainingQuota <= 0
                              ? Colors.red
                              : e.remainingQuota <= 2
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(e.operatorName)),
                  DataCell(Text(e.station)),
                  DataCell(
                    ElevatedButton(
                      onPressed: e.lastRedeem
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LastRedeemPage(
                                    data: LastRedeem(
                                      id: e.id,
                                      name: e.customerName,
                                      nik: e.identityNumber,
                                      serialNumber: e.serialNumber,
                                      programType: e.journeyType,
                                      cardCategory: e.cardCategory,
                                      cardType: e.cardType,
                                      redeemDate: e.redeemDate,
                                      redeemType: e.journeyType,
                                      quotaUsed: e.usedQuota,
                                      remainingQuota: e.remainingQuota,
                                      station: e.station,
                                      operatorName: e.operatorName,
                                      status: e.lastRedeem ? 'Success' : '-',
                                    ),
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: e.lastRedeem
                            ? Colors.green
                            : Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // 👈 BORDER RADIUS
                        ),
                      ),
                      child: const Text(
                        'Last Redeem',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
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

  void _confirmDelete(String id) {
    final TextEditingController noteController = TextEditingController();
    final TextEditingController bookingController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedReason;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Data'),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Yakin ingin menghapus data ini? Aksi ini memerlukan alasan penghapusan.',
                  ),
                  const SizedBox(height: 16),

                  /// 🔽 DROPDOWN ALASAN
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: const InputDecoration(
                      labelText: 'Alasan Penghapusan',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Salah input nomor seri kartu',
                        child: Text('Salah input nomor seri kartu'),
                      ),
                      DropdownMenuItem(
                        value: 'Pembatalan Kereta',
                        child: Text('Pembatalan Kereta'),
                      ),
                      DropdownMenuItem(
                        value: 'Lainnya',
                        child: Text('Lainnya'),
                      ),
                    ],
                    onChanged: (v) {
                      setModalState(() {
                        selectedReason = v;
                        noteController.clear();
                        bookingController.clear();
                      });
                    },
                    validator: (v) => v == null ? 'Alasan wajib dipilih' : null,
                  ),

                  /// ✍️ INPUT UNTUK PEMBATALAN KERETA
                  if (selectedReason == 'Pembatalan Kereta') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bookingController,
                      decoration: const InputDecoration(
                        labelText: 'Kode Booking Kereta',
                        hintText: 'Masukkan kode booking',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Kode booking wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],

                  /// ✍️ INPUT UNTUK LAINNYA
                  if (selectedReason == 'Lainnya') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Alasan Lainnya',
                        hintText: 'Masukkan alasan penghapusan',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Alasan wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              late final String note;

              if (selectedReason == 'Pembatalan Kereta') {
                note = bookingController.text.trim();
              } else if (selectedReason == 'Lainnya') {
                note = noteController.text.trim();
              } else {
                note = selectedReason!;
              }

              Navigator.pop(context);
              setState(() => isLoading = true);

              try {
                final result = await _redeemController.deleteRedeem(
                  id: id,
                  note: note,
                  deletedBy: userName,
                );

                await _loadRedeem();

                if (!mounted) return;
                _showInfoDialog(
                  title: result['success'] == true ? 'Berhasil' : 'Gagal',
                  message: result['message'] ?? '',
                  icon: result['success'] == true
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  color: result['success'] == true ? Colors.green : Colors.red,
                );
              } finally {
                if (mounted) {
                  setState(() => isLoading = false);
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ================= DIALOG HELPER (HOME PAGE)
  void _showInfoDialog({
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    Color color = Colors.blue,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
