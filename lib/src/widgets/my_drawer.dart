import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/auth_controller.dart';
import 'package:ocr_project/src/pages/activity_logs/activity_logs_page_fwckai.dart';
import 'package:ocr_project/src/pages/activity_logs/activity_logs_page_voucher.dart';
import 'package:ocr_project/src/pages/activity_logs/activity_logs_page_fwc.dart';
import 'package:ocr_project/src/pages/auth/login_page.dart';
import 'package:ocr_project/src/pages/riwayat_pembatalan/riwatay_pembatalan_fwc.dart';
import 'package:ocr_project/src/pages/riwayat_pembatalan/riwayat_pembatalan_fwckai.dart';
import 'package:ocr_project/src/pages/riwayat_pembatalan/riwayat_pembatalan_voucher.dart';
import 'package:ocr_project/src/pages/home/home_page.dart';
import 'package:ocr_project/src/pages/home/home_page_kai.dart';
import 'package:ocr_project/src/pages/home/home_page_voucher.dart';
import 'package:ocr_project/src/services/voucher_pdf_service.dart';
import 'package:ocr_project/src/utils/role_access.dart';
import 'my_drawer_tile.dart';
import 'package:ocr_project/src/managers/shift_manager.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class MyDrawer extends StatefulWidget {
  final String userName;
  final String roleName;
  final RoleAccess roleAccess;
  final String roleCode;
  final Function(bool)? onShiftChanged;

  const MyDrawer({
    super.key,
    required this.userName,
    required this.roleName,
    required this.roleAccess,
    required this.roleCode,
    this.onShiftChanged,
  });

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  static const _bgColor = Color(0xFF7A1E2D);

  bool _isProcessingShift = false;
  final ShiftManager _shiftManager = ShiftManager();

  @override
  void initState() {
    super.initState();

    _shiftManager.init();
    _shiftManager.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _shiftManager.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _bgColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 🔥 SHIFT TOGGLE HANYA UNTUK PETUGAS
                    if (widget.roleAccess.canOpenShift) _buildShiftToggle(),

                    // 🔥 MENU HANYA MUNCUL
                    // 1. Kalau bukan petugas
                    // 2. Atau petugas tapi sudah open shift
                    if (!widget.roleAccess.canOpenShift || _shiftManager.isOpen)
                      _buildMenu(context),
                  ],
                ),
              ),
            ),

            const Divider(color: Colors.white54),

            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: _buildLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SHIFT TOGGLE =================
  Widget _buildShiftToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SwitchListTile(
        value: _shiftManager.isOpen,
        activeColor: Colors.green,
        title: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              _shiftManager.isOpen ? 'Close Shift' : 'Open Shift',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        onChanged: _isProcessingShift
            ? null
            : (value) async {
                setState(() => _isProcessingShift = true);

                if (value) {
                  await _handleOpenShift(context);
                } else {
                  await _handleCloseShift(context);
                }

                setState(() => _isProcessingShift = false);
              },
      ),
    );
  }

  Future<void> _handleOpenShift(BuildContext context) async {
    try {
      final shifts = await _shiftManager.getAvailableShifts();

      if (shifts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak ada shift tersedia")),
        );
        return;
      }

      String? selectedShiftId;

      await showDialog(
        context: context,
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_open,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Open Shift",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Are you ready to start your shift? This will enable all features and start logging your activities.",
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 20),

                      /// LABEL
                      const Row(
                        children: [
                          Icon(Icons.access_time, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Pilih Shift Duty *",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// DROPDOWN
                      DropdownButtonFormField2<String>(
                        isExpanded: true,
                        value: selectedShiftId,

                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF8B1E2D),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),

                        iconStyleData: const IconStyleData(
                          icon: Icon(Icons.keyboard_arrow_down),
                          iconEnabledColor: Colors.white,
                        ),

                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        hint: const Text(
                          "Pilih Shift",
                          style: TextStyle(color: Colors.white70),
                        ),

                        items: shifts.map((shift) {
                          return DropdownMenuItem<String>(
                            value: shift['id'],
                            child: Text(
                              shift['name'],
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                              ),
                            ),
                          );
                        }).toList(),

                        onChanged: (value) {
                          setState(() {
                            selectedShiftId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      const SizedBox(height: 20),

                      /// BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () async {
                                if (selectedShiftId == null) return;

                                await _shiftManager.openShift(selectedShiftId!);

                                Navigator.pop(context);
                              },
                              child: const Text("Confirm Open"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _handleCloseShift(BuildContext context) async {
    final TextEditingController notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Close Shift",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// DESCRIPTION
                const Text(
                  "Are you sure you want to close your shift? "
                  "You can optionally add notes before closing.",
                  style: TextStyle(color: Colors.grey, height: 1.4),
                ),

                const SizedBox(height: 20),

                /// NOTES FIELD
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Notes (optional)",
                    hintText: "Tambahkan catatan jika diperlukan...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          await _shiftManager.closeShift(notesController.text);

                          // ambil report dari backend
                          final report = await _shiftManager
                              .exportShiftReport();

                          Navigator.pop(context);

                          if (report != null) {
                            try {
                              await VoucherReportService.generateShiftReport(
                                report,
                                widget.userName,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Gagal membuat PDF: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Gagal mengambil data report dari server",
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          "Close Shift",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(color: _bgColor),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black, size: 28),
          ),
          const SizedBox(height: 8),
          const Text(
            'Login sebagai',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            widget.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.roleName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ================= MENU =================
  Widget _buildMenu(BuildContext context) {
    return Column(
      children: [
        // ================= REDEEM =================
        ExpansionTile(
          leading: const Icon(Icons.redeem, color: Colors.white),
          title: const Text(
            "Redeem Validation",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: [
            if (widget.roleAccess.canFWC)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: MyDrawerTile(
                  text: 'Redeem Kuota FWC',
                  icon: Icons.credit_card,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                ),
              ),

            if (widget.roleAccess.canFWCKai)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: MyDrawerTile(
                  text: 'Redeem Kuota FWCKAI',
                  icon: Icons.train,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePageKai()),
                    );
                  },
                ),
              ),

            if (widget.roleAccess.canVoucher)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: MyDrawerTile(
                  text: 'Redeem Kuota Voucher',
                  icon: Icons.confirmation_num,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomePageVoucher(),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),

        // ================= Riwayat Pembatalan =================
        if (widget.roleAccess.canViewCancellationHistory)
          ExpansionTile(
            leading: const Icon(Icons.delete, color: Colors.white),
            title: const Text(
              "Riwayat Pembatalan",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            children: [
              if (widget.roleAccess.canViewCancellationHistory)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: MyDrawerTile(
                    text: 'Riwayat Pembatalan FWC',
                    icon: Icons.credit_card_off,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PembatalanKeretaPagefwc(
                            userName: widget.userName,
                            roleName: widget.roleName,
                            roleAccess: widget.roleAccess,
                            roleCode: widget.roleCode,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (widget.roleAccess.canViewCancellationHistory)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: MyDrawerTile(
                    text: 'Riwayat Pembatalan FWCKAI',
                    icon: Icons.delete_forever,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PembatalanKeretaPagefwcKai(
                            userName: widget.userName,
                            roleName: widget.roleName,
                            roleAccess: widget.roleAccess,
                            roleCode: widget.roleCode,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (widget.roleAccess.canViewCancellationHistory)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: MyDrawerTile(
                    text: 'Riwayat Pembatalan Voucher',
                    icon: Icons.delete_sweep,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PembatalanKeretaPageVoucher(
                            userName: widget.userName,
                            roleName: widget.roleName,
                            roleAccess: widget.roleAccess,
                            roleCode: widget.roleCode,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),

        // ================= ACTIVITY LOGS =================
        if (widget.roleAccess.canViewActivityLog)
          ExpansionTile(
            leading: const Icon(Icons.history, color: Colors.white),
            title: const Text(
              "Activity Logs",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            children: [
              if (widget.roleAccess.canViewActivityLog)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: MyDrawerTile(
                    text: 'Activity Logs FWC',
                    icon: Icons.credit_card,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityLogsPagefwc(
                            userName: widget.userName,
                            roleName: widget.roleName,
                            roleAccess: widget.roleAccess,
                            roleCode: widget.roleCode,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (widget.roleAccess.canViewActivityLog)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: MyDrawerTile(
                    text: 'Activity Logs FWCKAI',
                    icon: Icons.train,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityLogsPagefwckai(
                            userName: widget.userName,
                            roleName: widget.roleName,
                            roleAccess: widget.roleAccess,
                            roleCode: widget.roleCode,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (widget.roleAccess.canViewActivityLog)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: MyDrawerTile(
                    text: 'Activity Logs Voucher',
                    icon: Icons.confirmation_num,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityLogsPage(
                            userName: widget.userName,
                            roleName: widget.roleName,
                            roleAccess: widget.roleAccess,
                            roleCode: widget.roleCode,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }

  // ================= LOGOUT =================
  Widget _buildLogout(BuildContext context) {
    return MyDrawerTile(
      text: 'Sign Out',
      icon: Icons.logout,
      textColor: Colors.red,
      iconColor: Colors.red,
      onTap: () => _showLogoutDialog(context),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final authController = AuthController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Yakin ingin sign out dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await authController.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
