import 'package:flutter/material.dart';

class ShiftLockedView extends StatelessWidget {
  const ShiftLockedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 90, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            "Shift Belum Dibuka",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            "Silakan Open Shift untuk memulai transaksi",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
