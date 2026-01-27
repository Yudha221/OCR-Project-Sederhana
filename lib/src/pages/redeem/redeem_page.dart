import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ocr_project/src/controllers/redeem_controller.dart';

class RedeemPage extends StatefulWidget {
  const RedeemPage({super.key});

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  final TextEditingController _serialController = TextEditingController();
  final RedeemController _redeemController = RedeemController();

  MobileScannerController? _scannerController;

  int _redeemType = 1;
  bool _isScanning = false;
  bool _isVerified = false;
  bool _isVerifying = false;

  // DATA DARI API
  String ownerName = '';
  String ownerNik = '';
  int remainingQuota = 0;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.qrCode,
      ],
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _serialController.dispose();
    super.dispose();
  }

  // ================= RESET VERIFY
  void _resetVerification() {
    setState(() {
      _isVerified = false;
      ownerName = '';
      ownerNik = '';
      remainingQuota = 0;
    });
  }

  // ================= SCANNER
  void _openScanner() {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController!,
                onDetect: (capture) {
                  if (capture.barcodes.isEmpty) return;
                  final value = capture.barcodes.first.rawValue;
                  if (value == null || value.isEmpty) return;

                  Navigator.pop(context);
                  setState(() {
                    _serialController.text = value;
                    _isScanning = false;
                  });

                  if (_isVerified) _resetVerification();
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isScanning = false);
                  },
                ),
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton(
                  backgroundColor: Colors.black54,
                  onPressed: () => _scannerController?.toggleTorch(),
                  child: const Icon(Icons.flash_on),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      setState(() => _isScanning = false);
    });
  }

  // ================= VERIFY SERIAL (GET API)
  Future<void> _verifySerial() async {
    final serial = _serialController.text.trim();

    if (serial.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Serial number kosong')));
      return;
    }

    try {
      setState(() => _isVerifying = true);

      final response = await _redeemController.verifySerial(serial);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Gagal verifikasi');
      }

      final data = response['data'];

      setState(() {
        _isVerified = true;
        ownerName = data['customerName']?.toString() ?? '-';
        ownerNik = data['nik']?.toString() ?? '-';
        remainingQuota =
            int.tryParse(data['quotaRemaining']?.toString() ?? '0') ?? 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serial berhasil diverifikasi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Verifikasi gagal: $e')));
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  // ================= UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redeem Kuota')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Redeem Kuota',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            /// SERIAL
            const Text('Serial Number'),
            const SizedBox(height: 6),
            TextField(
              controller: _serialController,
              decoration: InputDecoration(
                hintText: 'Input serial number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _isScanning ? null : _openScanner,
                ),
              ),
              onChanged: (_) {
                if (_isVerified) _resetVerification();
              },
            ),

            const SizedBox(height: 12),

            /// SCAN BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan dari Camera'),
                onPressed: _isScanning ? null : _openScanner,
              ),
            ),

            const SizedBox(height: 12),

            /// VERIFY BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isVerifying ? null : _verifySerial,
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify Serial Number'),
              ),
            ),

            const SizedBox(height: 20),

            /// REDEEM TYPE
            const Text('Redeem Type'),
            RadioListTile<int>(
              value: 1,
              groupValue: _redeemType,
              title: const Text('Single Journey (1 Kuota)'),
              onChanged: _isVerified
                  ? (v) => setState(() => _redeemType = v!)
                  : null,
            ),
            RadioListTile<int>(
              value: 2,
              groupValue: _redeemType,
              title: const Text('PP / Round Trip (2 Kuota)'),
              onChanged: _isVerified
                  ? (v) => setState(() => _redeemType = v!)
                  : null,
            ),

            /// OWNER INFO
            if (_isVerified) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nama: $ownerName'),
                      Text('NIK: $ownerNik'),
                      Text('Serial: ${_serialController.text}'),
                      const SizedBox(height: 6),
                      Text(
                        'Sisa Kuota: $remainingQuota',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            /// REDEEM BUTTON (POST NANTI)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isVerified ? Colors.red : Colors.grey,
                ),
                onPressed: _isVerified ? () {} : null,
                child: const Text(
                  'Redeem',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
