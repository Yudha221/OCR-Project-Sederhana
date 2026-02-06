import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ocr_project/src/controllers/redeem_controller.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_project/src/controllers/last_redeem_controller.dart';

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

  // ===== LAST REDEEM (TAMBAHAN TANPA UBAH LOGIC)
  final LastRedeemController _lastRedeemController = LastRedeemController();
  final ImagePicker _picker = ImagePicker();
  File? _lastRedeemImage;

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

  Color _quotaColor(int quota) {
    return quota <= 1 ? Colors.red : Colors.black;
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
      _showInfoDialog(
        title: 'Serial Kosong',
        message: 'Silakan masukkan atau scan serial number terlebih dahulu.',
        icon: Icons.warning_amber_rounded,
        color: Colors.orange,
      );
      return;
    }

    try {
      setState(() => _isVerifying = true);

      final response = await _redeemController.verifySerial(serial);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Gagal verifikasi');
      }

      final data = response['data'];
      final productType = _redeemController.detectProductType(data);

      // 🚨 JIKA DIA VOUCHER
      if (productType == ProductType.voucher) {
        _showWrongProgramDialog();
        return;
      }

      // ✅ HANYA FWC BOLEH LEWAT
      setState(() {
        _isVerified = true;
        ownerName = data['customerName']?.toString() ?? '-';
        ownerNik = data['nik']?.toString() ?? '-';
        cardCategory = data['cardCategory']?.toString() ?? '-';
        cardType = data['cardType']?.toString() ?? '-';
        remainingQuota =
            int.tryParse(data['quotaRemaining']?.toString() ?? '0') ?? 0;
      });

      _showInfoDialog(
        title: 'Verifikasi Berhasil',
        message: 'Serial FWC berhasil diverifikasi.',
        icon: Icons.check_circle_outline,
        color: Colors.green,
      );
    } catch (e) {
      _showInfoDialog(
        title: 'Verifikasi Gagal',
        message: e.toString(),
        icon: Icons.error_outline,
        color: Colors.red,
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  void _showWrongProgramDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          title: Row(
            children: const [
              Icon(
                Icons.confirmation_number_outlined,
                color: Colors.orange,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Serial Tidak Sesuai',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            'Serial yang Anda masukkan adalah Voucher.\n\n'
            'Jenis kartu ini tidak dapat diredeem melalui menu FWC. '
            'Silakan lakukan redeem melalui menu Voucher.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= REDEEM (POST API) ✅ TAMBAHAN
  Future<void> _redeem() async {
    if (!_isVerified) return;

    final beforeRedeemQuota = remainingQuota;

    if (remainingQuota < _requiredQuota) {
      _showInfoDialog(
        title: 'Kuota Tidak Cukup',
        message:
            'Kuota tidak mencukupi.\n'
            'Dibutuhkan: $_requiredQuota\n'
            'Sisa: $remainingQuota',
        icon: Icons.error_outline,
        color: Colors.red,
      );
      return;
    }

    try {
      setState(() => _isRedeeming = true);

      final response = await _redeemController.redeem(
        serialNumber: _serialController.text.trim(),
        redeemType: _redeemType,
      );

      // 🔥 SOFTKODE DITARO DI SINI (WAJIB)
      if (response['success'] != true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              title: Row(
                children: const [
                  Icon(
                    Icons.confirmation_number_outlined,
                    color: Colors.red,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Serial Voucher',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Text(
                response['message'] ??
                    'Voucher ini sudah digunakan atau sudah tidak berlaku.',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Mengerti',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
        return;
      }

      // ✅ LANJUT NORMAL (PASTI FWC)
      final afterRedeemQuota = beforeRedeemQuota - _requiredQuota;

      setState(() {
        remainingQuota = afterRedeemQuota;
      });

      if (afterRedeemQuota == 0) {
        final lastRedeemId = response['data']['transactionNumber'];
        await _openLastRedeemCamera(lastRedeemId);
        return;
      }

      _showRedeemSuccessDialog();
    } catch (e) {
      _showInfoDialog(
        title: 'Redeem Gagal',
        message: e.toString(),
        icon: Icons.error_outline,
        color: Colors.red,
      );
    } finally {
      setState(() => _isRedeeming = false);
    }
  }

  // ================= LAST REDEEM CAMERA
  Future<void> _openLastRedeemCamera(String lastRedeemId) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo != null) {
      _lastRedeemImage = File(photo.path);
    }

    _showLastRedeemDialog(lastRedeemId);
  }

  void _showLastRedeemDialog(String lastRedeemId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Redeem Terakhir'),
        content: const Text('Simpan bukti last redeem?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRedeemSuccessDialog();
            },
            child: const Text('Tanpa Bukti'),
          ),
          ElevatedButton(
            onPressed: _lastRedeemImage == null
                ? null
                : () async {
                    Navigator.pop(context);
                    await _lastRedeemController.uploadPhoto(
                      lastRedeemId,
                      _lastRedeemImage!,
                    );
                    _showRedeemSuccessDialog();
                  },
            child: const Text('Dengan Bukti'),
          ),
        ],
      ),
    );
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

                        Text('Nama Pelanggan: $ownerName'),
                        const SizedBox(height: 6),
                        Text('NIK: $ownerNik'),
                        const SizedBox(height: 6),
                        Text('No. Seri: ${_serialController.text}'),
                        const SizedBox(height: 6),
                        Text('Category: $cardCategory'),
                        const SizedBox(height: 6),
                        Text('Type: $cardType'),
                        const SizedBox(height: 6),
                        Text('Kuota Terpakai: $_requiredQuota'),

                        const SizedBox(height: 12),

                        Text(
                          'Sisa Kuota: $remainingQuota',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _quotaColor(remainingQuota),
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

  void _showInfoDialog({
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    Color color = Colors.blue,
  }) {
    showDialog(
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
