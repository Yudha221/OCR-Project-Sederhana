import 'package:flutter/material.dart';

class DialogUtils {
  /// =====================
  /// CONFIRM DELETE (FANCY)
  /// =====================
  static Future<void> confirmDeleteFancy(
    BuildContext context, {
    required String title,
    required String description,
    required Future<void> Function(String note) onConfirm,
  }) {
    final noteController = TextEditingController();
    final bookingController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedReason;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Hapus Data', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description),
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
                      });
                    },
                    validator: (v) => v == null ? 'Alasan wajib dipilih' : null,
                  ),

                  /// INPUT PEMBATALAN KERETA
                  if (selectedReason == 'Pembatalan Kereta') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bookingController,
                      decoration: const InputDecoration(
                        labelText: 'Kode Booking Kereta',
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

                  /// INPUT LAINNYA
                  if (selectedReason == 'Lainnya') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Alasan Lainnya',
                        border: OutlineInputBorder(),
                      ),
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
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                late final String note;

                if (selectedReason == 'Pembatalan Kereta') {
                  note =
                      'Alasan : Pembatalan Kereta\n'
                      'Kode Booking : ${bookingController.text.trim()}';
                } else if (selectedReason == 'Lainnya') {
                  note =
                      'Alasan : Lainnya\n'
                      'Keterangan : ${noteController.text.trim()}';
                } else {
                  note = 'Alasan : $selectedReason';
                }

                Navigator.pop(context);
                await onConfirm(note);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  /// =====================
  /// INFO POPUP
  /// =====================
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    Color color = Colors.blue,
  }) {
    return showDialog(
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
