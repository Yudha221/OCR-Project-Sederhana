import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/auth_controller.dart';
import 'package:ocr_project/src/controllers/redeem_controller.dart';
import 'package:ocr_project/src/models/redeem.dart';
import 'package:ocr_project/src/pages/auth/login_page.dart';
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

    final data = await _redeemController.fetchRedeem();
    allData = data;

    currentPage = 1;
    _applyFilterAndPagination();

    setState(() => isLoading = false);
  }

  // ================= FILTER + PAGINATION =================
  void _applyFilterAndPagination() {
    filteredData = allData.where((e) {
      // SEARCH
      final matchSearch =
          searchQuery.isEmpty ||
          e.customerName.toLowerCase().contains(searchQuery) ||
          e.identityNumber.contains(searchQuery) ||
          e.serialNumber.contains(searchQuery);

      // CATEGORY
      final matchCategory =
          selectedCategory == null || e.cardCategory == selectedCategory;

      // CARD TYPE
      final matchType =
          selectedCardType == null || e.cardType == selectedCardType;

      // DATE RANGE
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
      body: SingleChildScrollView(
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('NIK')),
              DataColumn(label: Text('Transaksi')),
              DataColumn(label: Text('Serial')),
              DataColumn(label: Text('Kategori')),
              DataColumn(label: Text('Tipe')),
              DataColumn(label: Text('Perjalanan')),
              DataColumn(label: Text('Terpakai')),
              DataColumn(label: Text('Sisa')),
              DataColumn(label: Text('Operator')),
              DataColumn(label: Text('Stasiun')),
              DataColumn(label: Text('Last')),
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
                  DataCell(Text(e.cardCategory)),
                  DataCell(Text(e.cardType)),
                  DataCell(Text(e.journeyType)),
                  DataCell(Text(e.usedQuota.toString())),
                  DataCell(Text(e.remainingQuota.toString())),
                  DataCell(Text(e.operatorName)),
                  DataCell(Text(e.station)),
                  DataCell(
                    Chip(
                      label: Text(
                        e.lastRedeem ? 'Last' : '-',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: e.lastRedeem
                          ? Colors.green
                          : Colors.grey,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
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
} // ← SATU-SATUNYA PENUTUP CLASS
