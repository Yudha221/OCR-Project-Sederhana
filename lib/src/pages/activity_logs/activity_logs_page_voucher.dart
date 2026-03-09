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

  List<ActivityLog> logs = [];

  bool loading = true;
  String selectedAction = "ALL";

  int currentPage = 1;
  int totalPages = 1;
  int totalData = 0;
  int apiTotal = 0;

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
    setState(() {
      loading = true;
    });

    final result = await controller.getLogs(
      page: currentPage,
      product: "VOUCHER",
      action: selectedAction,
      search: searchController.text,
    );

    setState(() {
      logs = result["logs"];

      currentPage = result["pagination"]["page"];
      totalPages = result["pagination"]["totalPages"];
      totalData = result["pagination"]["total"];

      loading = false;
    });
  }

  void resetFilter() {
    setState(() {
      selectedAction = "ALL";
      searchController.clear();
      currentPage = 1;
    });

    loadLogs();
  }

  Color getActionColor(String action) {
    if (action == "CREATE_REDEEM") return Colors.green;
    if (action == "DELETE_REDEEM") return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// SEARCH
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Cari Aktifitas...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) {
                  _debounce!.cancel();
                }

                _debounce = Timer(const Duration(milliseconds: 500), () {
                  currentPage = 1;
                  loadLogs();
                });
              },
            ),

            const SizedBox(height: 12),

            /// FILTER + RESET
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF7A1E2D)),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF7A1E2D),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedAction,
                      dropdownColor: const Color(0xFF7A1E2D),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                      style: const TextStyle(color: Colors.white),

                      items: const [
                        DropdownMenuItem(
                          value: "ALL",
                          child: Text(
                            "Semua Aksi",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: "CREATE_REDEEM",
                          child: Text(
                            "Create",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: "UPDATE_REDEEM",
                          child: Text(
                            "Update",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: "DELETE_REDEEM",
                          child: Text(
                            "Delete",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],

                      onChanged: (value) {
                        setState(() {
                          selectedAction = value!;
                          currentPage = 1;
                        });

                        loadLogs();
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                OutlinedButton.icon(
                  onPressed: resetFilter,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Reset"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// HEADER
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Riwayat Aktivitas",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Total Data : $totalData",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// TABLE
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 40,
                      headingRowHeight: 50,
                      headingRowColor: MaterialStateProperty.all(
                        const Color(0xFFF4F6F8),
                      ),
                      columns: const [
                        DataColumn(label: Text('WAKTU')),
                        DataColumn(label: Text('OPERATOR')),
                        DataColumn(label: Text('AKSI')),
                        DataColumn(label: Text('DESKRIPSI')),
                        DataColumn(label: Text('CATATAN')),
                      ],
                      rows: logs.map((log) {
                        return DataRow(
                          cells: [
                            /// WAKTU
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd MMM yyyy HH:mm',
                                ).format(log.createdAt),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            /// OPERATOR
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    log.roleName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// AKSI BADGE
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: getActionColor(
                                    log.action,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  log.action.replaceAll("_", " "),
                                  style: TextStyle(
                                    color: getActionColor(log.action),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),

                            /// DESKRIPSI
                            DataCell(
                              SizedBox(
                                width: 300,
                                child: Text(
                                  log.description,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),

                            /// CATATAN
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: Text(
                                  log.notes ?? "-",
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize:
                                        11, // 👈 ini yang mengecilkan isi catatan
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),

            /// PAGINATION
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 1
                      ? () {
                          setState(() {
                            currentPage--;
                            loading = true;
                          });
                          loadLogs();
                        }
                      : null,
                ),
                Text("$currentPage / $totalPages"),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < totalPages
                      ? () {
                          setState(() {
                            currentPage++;
                            loading = true;
                          });
                          loadLogs();
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
