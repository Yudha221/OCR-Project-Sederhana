import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/auth_controller.dart';
import 'package:ocr_project/src/controllers/redeem_controller.dart';
import 'package:ocr_project/src/models/last_redeem.dart';
import 'package:ocr_project/src/models/redeem.dart';
import 'package:ocr_project/src/pages/auth/login_page.dart';
import 'package:ocr_project/src/pages/last_redeem/last_redeem_page.dart';
import 'package:ocr_project/src/pages/redeem/redeem_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = AuthController();
  final RedeemController _redeemController = RedeemController();

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
    _loadRedeem();
  }

  Future<void> _loadUserName() async {
    final name = await _authController.getUserName();
    setState(() => userName = name);
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
        'Frequent Whoosher Card',
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'logout') _showLogoutDialog();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  userName.isEmpty ? '-' : userName,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TITLE =================
  Widget _titleSection() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Redeem Kuota Management',
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
                  label: 'Card Category',
                  value: selectedCategory,
                  items: const ['Gold', 'Silver', 'KAI'],
                  onChanged: (v) {
                    selectedCategory = v;
                    currentPage = 1;
                    setState(_applyFilterAndPagination);
                  },
                ),
                _dropdown(
                  label: 'Card Type',
                  value: selectedCardType,
                  items: const ['JaBan', 'JaKa', 'Kaban'],
                  onChanged: (v) {
                    selectedCardType = v;
                    currentPage = 1;
                    setState(_applyFilterAndPagination);
                  },
                ),
                _datePicker(
                  label: 'Start Date',
                  date: startDate,
                  onPicked: (d) {
                    startDate = d;
                    currentPage = 1;
                    setState(_applyFilterAndPagination);
                  },
                ),
                _datePicker(
                  label: 'End Date',
                  date: endDate,
                  onPicked: (d) {
                    endDate = d;
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
              /// 🔥 JUDUL
              const Text(
                "Riwayat Redeem",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),

              /// 🔥 TOTAL DATA (punya kamu — cuma dipindah)
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
                  DataCell(Text(e.redeemDate)),
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

  // ================= COMPONENT =================
  Widget _dropdown({
    required String label,
    required List<String> items,
    String? value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime) onPicked,
  }) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(
        text: date == null ? '' : '${date.day}/${date.month}/${date.year}',
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  // ================= LOGOUT =================
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authController.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
                (_) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isLoading = true);

              try {
                final result = await _redeemController.deleteRedeem(id);

                if (result['success'] == true) {
                  await _loadRedeem();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Data berhasil dihapus',
                      ),
                    ),
                  );
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Gagal menghapus data',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terjadi kesalahan'),
                    backgroundColor: Colors.red,
                  ),
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
}
