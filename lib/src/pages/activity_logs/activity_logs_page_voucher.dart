import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocr_project/src/utils/role_access.dart';
import 'package:ocr_project/src/widgets/my_drawer.dart';
import '../../controllers/activity_log_controller.dart';
import '../../models/activity_log.dart';

class ActivityLogsPage extends StatefulWidget {
  final String userName;
  final String roleName;
  final RoleAccess roleAccess;

  const ActivityLogsPage({
    super.key,
    required this.userName,
    required this.roleName,
    required this.roleAccess,
  });

  @override
  State<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<ActivityLogsPage> {
  final controller = ActivityLogController();
  final searchController = TextEditingController();
  Timer? _debounce;

  String selectedAction = "ALL";

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadLogs() async {
    await controller.loadLogs(product: "VOUCHER");
    if (mounted) {
      setState(() {
        controller.filterLogs(searchController.text, selectedAction);
      });
    }
  }

  void resetFilter() {
    setState(() {
      selectedAction = "ALL";
      searchController.clear();
      controller.currentPage = 1;
    });

    loadLogs();
  }

  Color getActionColor(String action) {
    final act = action.toUpperCase();
    if (act.contains("CREATE")) return Colors.green;
    if (act.contains("DELETE")) return Colors.red;
    if (act.contains("UPDATE")) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
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
          "Activity Logs Voucher",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadLogs,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// SEARCH & FILTER ROW
                _buildFilterSection(),

                const SizedBox(height: 16),

                /// TOTAL DATA BADGE
                if (!controller.isLoading) _buildTotalBadge(),

                const SizedBox(height: 12),

                /// TABLE
                if (controller.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (controller.tableLogs.isEmpty)
                  _buildEmptyState()
                else
                  _buildLogsTable(),

                /// PAGINATION
                if (controller.tableLogs.isNotEmpty) _buildPagination(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "Cari Aktifitas...",
            prefixIcon: const Icon(Icons.search, color: Color(0xFF7A1E2D)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7A1E2D), width: 1.5),
            ),
          ),
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 800), () {
              setState(() {
                controller.filterLogs(v, selectedAction);
              });
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7A1E2D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedAction,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF7A1E2D),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: "ALL", child: Text("Semua Aksi")),
                      DropdownMenuItem(value: "CREATE_REDEEM", child: Text("Create")),
                      DropdownMenuItem(value: "UPDATE_REDEEM", child: Text("Update")),
                      DropdownMenuItem(value: "DELETE_REDEEM", child: Text("Delete")),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedAction = v;
                          controller.filterLogs(searchController.text, v);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: resetFilter,
              icon: const Icon(Icons.refresh),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7A1E2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daftar Aktivitas Log',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xff7A1E2D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Total: ${controller.filteredLogs.length}',
            style: const TextStyle(color: Color(0xff7A1E2D), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tidak ada data log ditemukan', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(label: Text('WAKTU')),
            DataColumn(label: Text('OPERATOR')),
            DataColumn(label: Text('AKSI')),
            DataColumn(label: Text('DESKRIPSI')),
            DataColumn(label: Text('CATATAN')),
          ],
          rows: controller.tableLogs.map((log) {
            return DataRow(
              cells: [
                DataCell(Text(DateFormat('dd MMM yyyy HH:mm').format(log.createdAt))),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(log.roleName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                DataCell(_actionBadge(log.action)),
                DataCell(SizedBox(width: 300, child: Text(log.description))),
                DataCell(SizedBox(width: 200, child: Text(log.notes ?? "-", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: controller.currentPage > 1
                ? () {
                    setState(() => controller.prevPage());
                  }
                : null,
          ),
          Text("${controller.currentPage} / ${controller.totalPages}"),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: controller.currentPage < controller.totalPages
                ? () {
                    setState(() => controller.nextPage());
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _actionBadge(String action) {
    Color color = getActionColor(action);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        action.replaceAll("_", " "),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
