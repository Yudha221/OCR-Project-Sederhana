import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/auth_controller.dart';
import 'package:ocr_project/src/pages/auth/login_page.dart';
import 'package:ocr_project/src/pages/redeem/redeem_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = AuthController();

  String userName = '';
  String searchQuery = '';
  String? selectedCategory;
  String? selectedCardType;
  DateTime? startDate;
  DateTime? endDate;

  final List<Map<String, dynamic>> tableData = [];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await _authController.getUserName();
    setState(() {
      userName = name;
    });
  }

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
          offset: const Offset(0, 40),
          onSelected: (value) {
            if (value == 'logout') {
              _showLogoutDialog();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.black),
                const SizedBox(width: 6),
                Text(
                  userName.isEmpty ? '-' : userName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7A1E2D),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RedeemPage()),
            );
          },
          child: const Text('Redeem', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // ================= SEARCH =================
  Widget _searchSection() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search members',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (v) => setState(() => searchQuery = v),
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
                  onChanged: (v) => setState(() => selectedCategory = v),
                ),
                _dropdown(
                  label: 'Card Type',
                  value: selectedCardType,
                  items: const ['JaBan', 'KaBan', 'JaKa'],
                  onChanged: (v) => setState(() => selectedCardType = v),
                ),
                _datePicker(
                  label: 'Start Date',
                  date: startDate,
                  onPicked: (d) => setState(() => startDate = d),
                ),
                _datePicker(
                  label: 'End Date',
                  date: endDate,
                  onPicked: (d) => setState(() => endDate = d),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= TABLE =================
  Widget _tableSection() {
    return Card(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Redeem Date')),
            DataColumn(label: Text('Customer Name')),
            DataColumn(label: Text('Identity Number')),
            DataColumn(label: Text('Card Category')),
            DataColumn(label: Text('Card Type')),
            DataColumn(label: Text('Serial Number')),
            DataColumn(label: Text('Jumlah Kuota')),
            DataColumn(label: Text('Sisa Kuota')),
            DataColumn(label: Text('Shift Date')),
            DataColumn(label: Text('Stasiun')),
            DataColumn(label: Text('Last Redeem')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: const [],
        ),
      ),
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
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
