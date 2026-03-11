import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ocr_project/src/controllers/auth_controller.dart';
import 'package:ocr_project/src/controllers/redeem_controller.dart'
    hide ProductType;
import 'package:ocr_project/src/controllers/shift_controller.dart';
import 'package:ocr_project/src/models/last_redeem.dart';
import 'package:ocr_project/src/models/redeem.dart';
import 'package:ocr_project/src/pages/last_redeem/last_redeem_page.dart';
import 'package:ocr_project/src/pages/redeem/redeem_page.dart';
import 'package:ocr_project/src/utils/date_helper.dart';
import 'package:ocr_project/src/utils/status_awal_colors.dart';
import 'package:ocr_project/src/widgets/filter_button.dart';
import 'package:ocr_project/src/widgets/my_drawer.dart';
import 'package:ocr_project/src/models/user.dart';
import 'package:ocr_project/src/services/voucher_pdf_service.dart';
import 'package:ocr_project/src/models/card_type.dart';
import 'dart:convert';
import 'package:ocr_project/src/utils/role_access.dart';
import 'package:intl/intl.dart';
import 'package:ocr_project/src/managers/shift_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = AuthController();
  final RedeemController _redeemController = RedeemController();
  final ShiftManager _shiftManager = ShiftManager();

  // user
  String userName = '';
  String roleName = '-';
  RoleAccess? roleAccess;
  String roleCode = '';
  String? userStation;
  String username = '';

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

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 2, // pakai 2 kalau mau ,00
  );

  @override
  void initState() {
    super.initState();

    startDate = DateTime.now();
    endDate = DateTime.now();

    _shiftManager.init();
    _shiftManager.addListener(_refreshPage);

    _loadUserProfile();
    _loadRedeem();
    _loadCategories();
    _loadCardTypes();
    _loadStations();
  }

  void _refreshPage() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _shiftManager.removeListener(_refreshPage);
    super.dispose();
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
      final raw = jsonDecode(userJson);

      roleCode = raw['role']['roleCode'];
      userStation = raw['station']?['stationName'];
      username = raw['username'] ?? '-';

      roleAccess = RoleAccess(roleCode);

      setState(() {
        userName = raw['fullName'];
        roleName = raw['role']['roleName'];

        // 🔒 kalau role terkunci → auto station
        if (roleAccess!.lockStation && userStation != null) {
          selectedStations = [userStation!];
        }
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

    // hanya petugas yang bisa open shift
    if (!roleAccess!.canOpenShift) return false;

    // kalau petugas tapi belum open shift → kunci
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
              roleAccess: roleAccess!,
            ),
      // 🔥 TAMBAHAN REFRESH (SATU-SATUNYA PERUBAHAN)
      body: SafeArea(
        child: _shouldLockPage()
            ? _buildShiftLockedView()
            : RefreshIndicator(
                onRefresh: _loadRedeem,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).padding.bottom + 16,
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
            'Validasi Kuota FWC',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        if (roleAccess?.canRedeem == true)
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
                borderRadius: BorderRadius.circular(8),
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

  // ================= FILTER =================
  Widget _filterSection() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildFilterButton()),

        if (roleAccess?.canExportReport == true) ...[
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _buildExportButton()),
        ],
      ],
    );
  }

  Widget _buildFilterButton() {
    return FilterButton(
      categoryItems: categoryItems,
      cardTypeItems: cardTypeItems,
      stationItems: roleAccess?.lockStation == true ? [] : stationItems,
      selectedCategories: selectedCategories,
      selectedCardTypes: selectedCardTypes,
      selectedStations: selectedStations,
      startDate: startDate,
      endDate: endDate,
      onCategoryChanged: (v) => setState(() => selectedCategories = v),
      onCardTypeChanged: (v) => setState(() => selectedCardTypes = v),
      onStationChanged: roleAccess?.lockStation == true
          ? (_) {}
          : (v) => setState(() => selectedStations = v),
      onStartDateChanged: (d) => setState(() => startDate = d),
      onEndDateChanged: (d) => setState(() => endDate = d),
      onReset: _resetFilter,
      onApply: () {
        currentPage = 1;
        setState(_applyFilterAndPagination);
      },
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      height: 45,
      child: ElevatedButton.icon(
        onPressed: filteredData.isEmpty
            ? null
            : () async {
                setState(() => isLoading = true);
                try {
                  await VoucherReportService.generateReport(
                    data: filteredData,
                    station: userStation ?? '-',
                    operatorName: userName,
                    shiftDate: startDate ?? DateTime.now(),
                    userCode: username,
                    type: ProductType.fwc,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Export gagal: $e")));
                } finally {
                  setState(() => isLoading = false);
                }
              },
        icon: const Icon(Icons.download_rounded),
        label: const Text(
          "Export",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
            columns: [
              const DataColumn(label: Text('Tanggal Redeem')),
              const DataColumn(label: Text('Nama Pelanggan')),
              const DataColumn(label: Text('NIK')),
              const DataColumn(label: Text('Nomor Redeem')),
              const DataColumn(label: Text('Nomor Transaksi')),
              const DataColumn(label: Text('Status Asal')),
              const DataColumn(label: Text('Serial Kartu')),
              const DataColumn(label: Text('Kategori Kartu')),
              const DataColumn(label: Text('Tipe Kartu')),
              const DataColumn(label: Text('Tipe Perjalanan')),
              const DataColumn(label: Text('Sisa Kuota')),
              const DataColumn(label: Text('Operator Utama')),
              const DataColumn(label: Text('Operator Pengganti')),
              const DataColumn(label: Text('Stasiun')),
              const DataColumn(label: Text('NIP KAI')),
              const DataColumn(label: Text('Price Redeem')),
              const DataColumn(label: Text('Seat Class Program')),
              const DataColumn(label: Text('Quota Ticket')),
              const DataColumn(label: Text('Purchase Date')),
              const DataColumn(label: Text('Expired Date	')),
              const DataColumn(label: Text('Masa Aktif')),
              const DataColumn(label: Text('Ticketing Channel	')),
              const DataColumn(label: Text('Last Redeem')),
              if (roleAccess?.canDelete == true)
                const DataColumn(label: Text('Aksi')),
            ],
            rows: tableData.map((e) {
              return DataRow(
                cells: [
                  DataCell(Text(formatRedeemDate(e.redeemDate))),
                  DataCell(Text(e.customerName)),
                  DataCell(Text(e.identityNumber)),
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
                  DataCell(Text(e.secondaryOperatorName)),
                  DataCell(Text(e.station)),
                  DataCell(Text(e.nipKai)),
                  DataCell(Text(currencyFormatter.format(e.price))),
                  DataCell(Text('Premium Economy Class')),
                  DataCell(Text(e.quotaTicket.toString())),
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
                                      quotaTicket: e.quotaTicket,
                                      initialQuota: e.totalQuota,
                                      station: e.station,
                                      operatorName: e.operatorName,
                                      status: e.status,
                                      photoUrl:
                                          'https://rewards-dev.kcic.co.id/api/storage/lastredeem/${e.memberId}/${e.id}.jpg',
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
    final TextEditingController trainNumberController = TextEditingController();
    final TextEditingController ticketNumberController =
        TextEditingController();

    DateTime? departureDate;
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Yakin ingin menghapus data ini? Aksi ini memerlukan alasan penghapusan.',
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

                          /// reset semua field
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

                    /// ==============================
                    /// PEMBATALAN KERETA
                    /// ==============================
                    if (selectedReason == 'Pembatalan Kereta') ...[
                      const SizedBox(height: 12),

                      /// KODE BOOKING
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// NOMOR KA
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// NOMOR TIKET
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// TANGGAL KEBERANGKATAN
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                      ),
                    ],

                    /// ==============================
                    /// ALASAN LAINNYA
                    /// ==============================
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

        /// ==============================
        /// BUTTONS
        /// ==============================
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

              String notes = '';
              String? trainBookCode;
              String? trainNumber;
              String? ticketNumber;
              String? departureDateString;

              /// ===============================
              /// PEMBATALAN KERETA
              /// ===============================
              if (selectedReason == 'Pembatalan Kereta') {
                trainBookCode = bookingController.text.trim();
                trainNumber = trainNumberController.text.trim();
                ticketNumber = ticketNumberController.text.trim();

                departureDateString = DateFormat(
                  'yyyy-MM-dd',
                ).format(departureDate!);

                notes = 'Pembatalan Kereta';
              }
              /// ===============================
              /// SALAH INPUT
              /// ===============================
              else if (selectedReason == 'Salah input nomor seri kartu') {
                notes = 'Salah input nomor seri kartu';
              }
              /// ===============================
              /// LAINNYA
              /// ===============================
              else if (selectedReason == 'Lainnya') {
                notes = noteController.text.trim();
              }

              FocusScope.of(context).unfocus();
              Navigator.pop(context);

              setState(() => isLoading = true);

              try {
                final result = await _redeemController.deleteRedeem(
                  id: id,
                  reason: selectedReason!,
                  notes: notes,

                  trainBookCode: trainBookCode,
                  trainNumber: trainNumber,
                  ticketNumber: ticketNumber,
                  departureDate: departureDateString,
                );

                await _loadRedeem();

                if (!mounted) return;

                _showInfoDialog(
                  title: result["success"] ? "Berhasil" : "Gagal",
                  message: result["message"],
                  icon: result["success"]
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  color: result["success"] ? Colors.green : Colors.red,
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
