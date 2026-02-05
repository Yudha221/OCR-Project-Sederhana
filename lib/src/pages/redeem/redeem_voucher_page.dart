import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ocr_project/src/controllers/voucher_controller.dart';

class RedeemVoucherPage extends StatefulWidget {
  const RedeemVoucherPage({super.key});

  @override
  State<RedeemVoucherPage> createState() => _RedeemVoucherPageState();
}

class _RedeemVoucherPageState extends State<RedeemVoucherPage> {
  final VoucherRedeemController _controller = VoucherRedeemController();

  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();

  MobileScannerController? _scannerController;

  bool _isScanning = false;
  bool _isSerialVerified = false;
  bool _isVerifying = false;
  bool _isRedeeming = false;

  Map<String, dynamic>? _cardData;

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _nikController.text.trim().length == 16;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _serialController.dispose();
    _nameController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  // ================= RESET
  void _reset() {
    setState(() {
      _isSerialVerified = false;
      _cardData = null;
      _nameController.clear();
      _nikController.clear();
    });
  }

  // ================= SCAN SERIAL
  void _openScanner() {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
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
                    _reset();
                  });
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
            ],
          ),
        );
      },
    ).whenComplete(() => setState(() => _isScanning = false));
  }

  // ================= VERIFY SERIAL (API)
  Future<void> _verifySerial() async {
    final serial = _serialController.text.trim();
    if (serial.isEmpty) {
      _snack('Serial voucher wajib diisi', isError: true);
      return;
    }

    try {
      setState(() => _isVerifying = true);

      final res = await _controller.verifySerial(serial);

      if (res['success'] != true) {
        throw Exception(res['message'] ?? 'Voucher tidak ditemukan');
      }

      setState(() {
        _isSerialVerified = true;
        _cardData = res['data']; // 🔥 SIMPAN DATA CARD
      });

      _snack('Voucher valid, silakan isi Nama & NIK');
    } catch (e) {
      _snack(e.toString(), isError: true);
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  // ================= REDEEM
  Future<void> _redeemVoucher() async {
    if (!_isSerialVerified || !_isFormValid) return;

    try {
      setState(() => _isRedeeming = true);

      final res = await _controller.redeemVoucher(
        serial: _serialController.text.trim(),
        name: _nameController.text.trim(),
        nik: _nikController.text.trim(),
      );

      if (res['success'] != true) {
        throw Exception(res['message'] ?? 'Redeem gagal');
      }

      _showSuccess();
    } catch (e) {
      _snack(e.toString(), isError: true);
    } finally {
      setState(() => _isRedeeming = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Berhasil'),
          content: const Text('Voucher berhasil diredeem'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
                Navigator.pop(context, true);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget infoRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? weight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: weight),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redeem Voucher')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Redeem Voucher',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // SERIAL
            TextField(
              controller: _serialController,
              decoration: InputDecoration(
                labelText: 'Serial Voucher',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _openScanner,
                ),
              ),
              onChanged: (_) => _reset(),
            ),

            const SizedBox(height: 12),

            // VERIFY BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying || _isSerialVerified
                    ? null
                    : _verifySerial,
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify Voucher'),
              ),
            ),

            // ================= CARD DATA
            if (_cardData != null) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Voucher',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),

                      infoRow(
                        'Nama Perusahaan',
                        _cardData?['customerName'] ?? '-',
                      ),
                      infoRow('NIK PIC', _cardData?['nik'] ?? '-'),
                      infoRow(
                        'Serial Voucher',
                        _cardData?['serialNumber'] ?? '-',
                      ),
                      infoRow('Kategori', _cardData?['cardCategory'] ?? '-'),
                      infoRow('Tipe Kartu', _cardData?['cardType'] ?? '-'),
                      infoRow(
                        'Status',
                        _cardData?['statusActive'] ?? '-',
                        valueColor: _cardData?['statusActive'] == 'ACTIVE'
                            ? Colors.green
                            : Colors.red,
                        weight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // NAMA
            TextField(
              controller: _nameController,
              enabled: _isSerialVerified,
              decoration: InputDecoration(
                labelText: 'Nama Penumpang',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // NIK
            TextField(
              controller: _nikController,
              enabled: _isSerialVerified,
              keyboardType: TextInputType.number,
              maxLength: 16,
              decoration: InputDecoration(
                labelText: 'NIK Penumpang',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // REDEEM
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isSerialVerified && _isFormValid && !_isRedeeming)
                    ? _redeemVoucher
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isSerialVerified && _isFormValid)
                      ? Colors.green
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isRedeeming
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Redeem Voucher',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
