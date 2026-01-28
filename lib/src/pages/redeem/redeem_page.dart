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
  bool _isRedeeming = false; // ✅ TAMBAHAN

  // DATA DARI API
  String ownerName = '';
  String ownerNik = '';
  int remainingQuota = 0;
  String cardCategory = '';
  String cardType = '';

  // ✅ TAMBAHAN
  int get _requiredQuota {
    return _redeemType == 1 ? 1 : 2;
  }

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
      cardCategory = '';
      cardType = '';
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
        cardCategory = data['cardCategory']?.toString() ?? '-';
        cardType = data['cardType']?.toString() ?? '-';
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

  // ================= REDEEM (POST API) ✅ TAMBAHAN
  Future<void> _redeem() async {
    if (!_isVerified) return;

    if (remainingQuota < _requiredQuota) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kuota tidak cukup. Butuh $_requiredQuota, sisa $remainingQuota',
          ),
        ),
      );
      return;
    }

    try {
      setState(() => _isRedeeming = true);

      final response = await _redeemController.redeem(
        serialNumber: _serialController.text.trim(),
        redeemType: _redeemType,
      );

      if (response['success'] != true) {
        throw Exception(response['message']);
      }

      final data = response['data'];

      setState(() {
        remainingQuota = int.tryParse(data['quotaRemaining'].toString()) ?? 0;
      });

      _showRedeemSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Redeem gagal: $e')));
    } finally {
      setState(() => _isRedeeming = false);
    }
  }

  void _showRedeemSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // wajib klik OK
      builder: (context) {
        return AlertDialog(
          title: const Text('Berhasil'),
          content: const Text('Redeem berhasil'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // tutup dialog
                Navigator.pop(context); // balik ke HomePage
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // warna tombol
                foregroundColor: Colors.white, // warna teks
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan dari Camera'),
                onPressed: _isScanning ? null : _openScanner,
              ),
            ),

            const SizedBox(height: 12),

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

            if (_isVerified) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, // 👈 FULL LEBAR
                child: Card(
                  elevation: 4, // 👈 agak naik
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // 👈 lebih smooth
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20), // 👈 CARD JADI BESAR
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Kartu',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),

                        Text('Nama: $ownerName'),
                        const SizedBox(height: 6),
                        Text('NIK: $ownerNik'),
                        const SizedBox(height: 6),
                        Text('Serial: ${_serialController.text}'),
                        const SizedBox(height: 6),
                        Text('Card Category: $cardCategory'),
                        const SizedBox(height: 6),
                        Text('Card Type: $cardType'),

                        const SizedBox(height: 12),

                        Text(
                          'Sisa Kuota: $remainingQuota',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isVerified ? Colors.red : Colors.grey,
                ),
                onPressed: (_isVerified && !_isRedeeming) ? _redeem : null,
                child: _isRedeeming
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
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
