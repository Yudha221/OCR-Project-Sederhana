import 'package:flutter/material.dart';
import 'package:ocr_project/src/services/voucher_pdf_service.dart';
import 'package:ocr_project/src/utils/role_access.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:ocr_project/src/controllers/auth_controller.dart';
import 'package:ocr_project/src/controllers/voucher_controller.dart'
    hide ProductType;
import 'package:ocr_project/src/models/redeem.dart';
import 'package:ocr_project/src/pages/redeem/redeem_voucher_page.dart';
import 'package:ocr_project/src/utils/date_helper.dart';
import 'package:ocr_project/src/utils/dialog_utils.dart';
import 'package:ocr_project/src/utils/status_awal_colors.dart';
import 'package:ocr_project/src/widgets/filter_button.dart';
import 'package:ocr_project/src/widgets/my_drawer.dart';
import 'package:intl/intl.dart';
import 'package:ocr_project/src/managers/shift_manager.dart';

class HomePageVoucher extends StatefulWidget {
  const HomePageVoucher({super.key});

  @override
  State<HomePageVoucher> createState() => _HomePageVoucherState();
}

class _HomePageVoucherState extends State<HomePageVoucher> {
  final AuthController _authController = AuthController();
  final VoucherRedeemController _redeemController = VoucherRedeemController();
  final ShiftManager _shiftManager = ShiftManager();

  // user
  String userName = '';
  String roleName = '-';
  RoleAccess? roleAccess;
  String roleCode = '';
  String username = '';
  String? userStation;

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

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _shiftManager.init();
    _loadUserProfile();
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

  Future<void> _loadUserProfile() async {
    const storage = FlutterSecureStorage();
    final userJson = await storage.read(key: 'userProfile');
    if (userJson == null) return;

    final raw = jsonDecode(userJson);

    roleCode = raw['role']['roleCode']; // petugas / admin / dll
    userStation = raw['station']?['stationName'];
    username = raw['username'] ?? '-';

    roleAccess = RoleAccess(roleCode);

    setState(() {
      userName = raw['fullName'];
      roleName = raw['role']['roleName'];

      // 🔒 KUNCI STATION
      if (roleAccess!.lockStation && userStation != null) {
        selectedStations = [userStation!];
      }
    });
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
          e.customerName.toString().toLowerCase().contains(searchQuery) ||
          e.identityNumber.toString().toLowerCase().contains(searchQuery) ||
          e.serialNumber.toString().toLowerCase().contains(searchQuery) ||
          (e.passengers.isNotEmpty &&
              e.passengers.first.passengerName
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery));

      final matchCategory =
          selectedCategories.isEmpty ||
          selectedCategories.contains(e.cardCategory);

      final matchType =
          selectedCardTypes.isEmpty || selectedCardTypes.contains(e.cardType);

      final matchStation =
          selectedStations.isEmpty || selectedStations.contains(e.station);

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

      if (roleAccess?.lockStation == true && userStation != null) {
        selectedStations = [userStation!];
      } else {
        selectedStations.clear();
      }

      startDate = null;
      endDate = null;
      currentPage = 1;
      _applyFilterAndPagination();
    });
  }

  DateTime _onlyDate(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  // ================= SHIFT LOCK =================
  bool _shouldLockPage() {
    if (roleAccess == null) return false;

    // hanya role yang bisa open shift
    if (!roleAccess!.canOpenShift) return false;

    // kalau shift belum open → lock
    return !_shiftManager.isOpen;
  }

  Widget _buildShiftLockedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 110, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            "Shift Belum Dibuka",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            "Silakan Open Shift di menu drawer",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      drawer: roleAccess == null
          ? null
          : MyDrawer(
              userName: userName,
              roleName: roleName,
              roleAccess: roleAccess!, // 🔥 INI KUNCI
            ),

      body: _shouldLockPage()
          ? _buildShiftLockedView()
          : RefreshIndicator(
              onRefresh: _loadVoucher,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).padding.bottom +
                      16, //  🔥 SAFE AREA BAWAH
                ),
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
      title: const Text(
        'Frequent Whoosher Card - Voucher',
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
            'Validasi Kuota Voucher',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (roleAccess?.canRedeem == true)
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RedeemVoucherPage()),
              );

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
            child: const Text('Validasi Voucher'),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== FILTER AREA =====
        SizedBox(
          width: 180, // 👈 atur lebar di sini (150–220 bebas)
          child: FilterButton(
            categoryItems: voucherCategoryItems,
            cardTypeItems: voucherTypeItems,
            stationItems: roleAccess?.lockStation == true ? [] : stationItems,

            selectedCategories: selectedCategories,
            selectedCardTypes: selectedCardTypes,
            selectedStations: selectedStations,

            startDate: startDate,
            endDate: endDate,

            onCategoryChanged: (v) => selectedCategories = v,
            onCardTypeChanged: (v) => selectedCardTypes = v,
            onStationChanged: roleAccess?.lockStation == true
                ? (_) {}
                : (v) => selectedStations = v,

            onStartDateChanged: (v) => startDate = v,
            onEndDateChanged: (v) => endDate = v,

            onApply: () {
              currentPage = 1;
              setState(_applyFilterAndPagination);
            },

            onReset: _resetFilter,
          ),
        ),

        const SizedBox(width: 16),

        // ===== PRINT BUTTON =====
        Expanded(
          child: SizedBox(
            height: 45,
            child: ElevatedButton(
              onPressed: filteredData.isEmpty
                  ? null
                  : () async {
                      print("Export ditekan");

                      await VoucherReportService.generateReport(
                        data: filteredData,
                        station: userStation ?? '-',
                        operatorName: userName,
                        shiftDate: DateTime.now(),
                        userCode: username,
                        type: ProductType.voucher,
                      );

                      print("Export selesai");
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Export",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
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
            columns: [
              const DataColumn(label: Text('Tanggal Redeem')),
              const DataColumn(label: Text('Nama PIC')),
              const DataColumn(label: Text('NIK PIC')),
              const DataColumn(label: Text('Nama Pelanggan')),
              const DataColumn(label: Text('NIK Pelanggan')),
              const DataColumn(label: Text('Nomor Redeem')),
              const DataColumn(label: Text('Nomor Transaksi')),
              const DataColumn(label: Text('Status Asal')),
              const DataColumn(label: Text('Serial Kartu')),
              const DataColumn(label: Text('Kategori Kartu')),
              const DataColumn(label: Text('kelas')),
              const DataColumn(label: Text('Operator Utama')),
              const DataColumn(label: Text('Operator Pengganti')),
              const DataColumn(label: Text('Stasiun')),
              const DataColumn(label: Text('NIP KAI')),
              const DataColumn(label: Text('Price Redeem')),
              const DataColumn(label: Text('Seat Class Program')),
              const DataColumn(label: Text('Quota Ticket')),
              const DataColumn(label: Text('Purchase Date')),
              const DataColumn(label: Text('Expired Date')),
              const DataColumn(label: Text('Masa Aktif')),
              const DataColumn(label: Text('Ticketing Channel')),

              if (roleAccess?.canDelete == true)
                const DataColumn(label: Text('Aksi')),
            ],
            rows: tableData.map((e) {
              return DataRow(
                cells: [
                  DataCell(Text(formatRedeemDate(e.redeemDate))),
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
                  DataCell(Text(e.redeemNumber)),
                  DataCell(Text(e.transactionNumber)),
                  DataCell(
                    Builder(
                      builder: (_) {
                        final origin = e.ticketOrigin.trim();
                        final color = StatusColors.getTicketOriginColor(origin);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            origin.isEmpty ? '-' : origin,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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

                      child: Text(
                        e.cardType,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(e.operatorName)),
                  DataCell(Text(e.secondaryOperatorName)),
                  DataCell(Text(e.station)),
                  DataCell(Text(e.nipKai)),
                  DataCell(Text(currencyFormatter.format(e.price))),
                  DataCell(Text(e.cardType)),
                  DataCell(Text(e.totalQuota.toString())),
                  DataCell(Text(formatDateOnly(e.redeemDate))),
                  DataCell(
                    Text(
                      e.expiredDate.isEmpty
                          ? '-'
                          : formatDateOnly(e.expiredDate),
                    ),
                  ),
                  DataCell(Text('${e.masaAktif} Hari')),
                  DataCell(Text(e.channelName.isEmpty ? '-' : e.channelName)),
                  // ===== AKSI =====
                  if (roleAccess?.canDelete == true)
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
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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

  void _confirmDelete(String id) {
    final TextEditingController noteController = TextEditingController();
    final TextEditingController bookingController = TextEditingController();
    final TextEditingController trainNumberController = TextEditingController();
    final TextEditingController ticketNumberController =
        TextEditingController();

    DateTime? departureDate;
    final formKey = GlobalKey<FormState>();
    String? selectedReason;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Voucher'),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Yakin ingin menghapus voucher ini?\nAksi ini membutuhkan alasan penghapusan.',
                    ),

                    const SizedBox(height: 16),

                    /// DROPDOWN ALASAN
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
                          trainNumberController.clear();
                          ticketNumberController.clear();
                          departureDate = null;
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Alasan wajib dipilih' : null,
                    ),

                    /// ============================
                    /// PEMBATALAN KERETA
                    /// ============================
                    if (selectedReason == 'Pembatalan Kereta') ...[
                      const SizedBox(height: 12),

                      /// KODE BOOKING
                      const Text(
                        "Kode Booking Kereta",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: bookingController,
                        decoration: const InputDecoration(
                          hintText: "Masukkan kode booking",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Kode booking wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      /// NOMOR KA
                      const Text(
                        "Nomor KA",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: trainNumberController,
                        decoration: const InputDecoration(
                          hintText: "Contoh: G1234",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nomor KA wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      /// NOMOR TIKET
                      const Text(
                        "Nomor Tiket",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: ticketNumberController,
                        decoration: const InputDecoration(
                          hintText: "Masukkan nomor tiket",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nomor tiket wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      /// TANGGAL KEBERANGKATAN
                      const Text(
                        "Tanggal Keberangkatan",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setModalState(() {
                              departureDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            hintText: "Pilih tanggal keberangkatan",
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            departureDate == null
                                ? "Pilih tanggal keberangkatan"
                                : DateFormat(
                                    'dd MMM yyyy',
                                  ).format(departureDate!),
                          ),
                        ),
                      ),
                    ],

                    /// ============================
                    /// ALASAN LAINNYA
                    /// ============================
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

              if (selectedReason == 'Pembatalan Kereta' &&
                  departureDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Tanggal keberangkatan wajib dipilih"),
                  ),
                );
                return;
              }

              late final String note;

              if (selectedReason == 'Pembatalan Kereta') {
                note =
                    'Alasan : Pembatalan Kereta\n'
                    'Kode Booking : ${bookingController.text.trim()}\n'
                    'Nomor KA : ${trainNumberController.text.trim()}\n'
                    'Nomor Tiket : ${ticketNumberController.text.trim()}\n'
                    'Tanggal Keberangkatan : ${DateFormat('dd-MM-yyyy').format(departureDate!)}';
              } else if (selectedReason == 'Lainnya') {
                note =
                    'Alasan : Lainnya\n'
                    'Keterangan : ${noteController.text.trim()}';
              } else {
                note = 'Alasan : $selectedReason';
              }

              FocusScope.of(context).unfocus();
              Navigator.pop(context);

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
