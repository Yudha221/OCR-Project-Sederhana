import 'package:flutter/material.dart';
import 'package:ocr_project/src/controllers/auth_controller.dart';
import 'package:ocr_project/src/pages/auth/login_page.dart';
import 'package:ocr_project/src/pages/history_delate/history_delate.dart';
import 'package:ocr_project/src/pages/history_delate/history_delate_voucher.dart';
import 'package:ocr_project/src/pages/home/home_page.dart';
import 'package:ocr_project/src/pages/home/home_page_kai.dart';
import 'package:ocr_project/src/pages/home/home_page_voucher.dart';
import 'my_drawer_tile.dart';

class MyDrawer extends StatelessWidget {
  final String userName;
  final String roleName;

  const MyDrawer({super.key, required this.userName, required this.roleName});

  static const _bgColor = Color(0xFF7A1E2D);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _bgColor,
      child: Column(
        children: [
          _buildHeader(),
          _buildMenu(context),
          const Spacer(),
          const Divider(color: Colors.white54),
          _buildLogout(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(color: _bgColor),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [_UserAvatar(), SizedBox(height: 8), _LoginLabel()],
          ),
        ),
      ),
    );
  }

  // ================= MENU =================
  Widget _buildMenu(BuildContext context) {
    return Column(
      children: [
        MyDrawerTile(
          text: 'Redeem FWC',
          icon: Icons.credit_card,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
        MyDrawerTile(
          text: 'Redeem FWCKAI',
          icon: Icons.train,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomePageKai()),
            );
          },
        ),
        MyDrawerTile(
          text: 'Redeem Voucher',
          icon: Icons.confirmation_num,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomePageVoucher()),
            );
          },
        ),
        MyDrawerTile(
          text: 'History Delete FWC',
          icon: Icons.delete_forever,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryDeletePage()),
            );
          },
        ),
        MyDrawerTile(
          text: 'History Delete Voucher',
          icon: Icons.credit_card_off,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HistoryDeleteVoucherPage(),
              ),
            );
          },
        ),
        MyDrawerTile(
          text: 'History Delete FWCKAI',
          icon: Icons.delete_sweep,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryDeletePage()),
            );
          },
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Sign Out'),
          ],
        ),
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
                MaterialPageRoute(builder: (_) => LoginPage()),
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

// ================= SUB WIDGET =================

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 28, // 🔥 sedikit diperkecil agar aman
      backgroundColor: Colors.white,
      child: Icon(Icons.person, color: Colors.black, size: 28),
    );
  }
}

class _LoginLabel extends StatelessWidget {
  const _LoginLabel();

  @override
  Widget build(BuildContext context) {
    final drawer = context.findAncestorWidgetOfExactType<MyDrawer>();

    final userName = drawer?.userName.isNotEmpty == true
        ? drawer!.userName
        : '-';
    final roleName = drawer?.roleName.isNotEmpty == true
        ? drawer!.roleName
        : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Login sebagai',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          roleName,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
