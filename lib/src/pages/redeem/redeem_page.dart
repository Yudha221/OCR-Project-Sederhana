import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class RedeemPage extends StatefulWidget {
  const RedeemPage({super.key});

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  final TextEditingController _serialController = TextEditingController();

  MobileScannerController? _scannerController;

  int _redeemType = 1;
  bool _isScanning = false;

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

  /// =====================
  /// OPEN SCANNER
  /// =====================
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

                  debugPrint('DETECTED BARCODE: $value');

                  Navigator.pop(context);
                  setState(() {
                    _serialController.text = value;
                    _isScanning = false;
                  });
                },
              ),

              /// CLOSE BUTTON
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

              /// FLASH BUTTON
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

  /// =====================
  /// VERIFY
  /// =====================
  void _verifySerial() {
    final serial = _serialController.text.trim();

    if (serial.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Serial number kosong')));
      return;
    }

    debugPrint('Serial: $serial');
    debugPrint('Redeem Type: $_redeemType');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Serial siap diverifikasi')));
  }

  /// =====================
  /// UI
  /// =====================
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

            /// SERIAL NUMBER
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
            ),

            const SizedBox(height: 12),

            /// CAMERA BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan dari Camera'),
                onPressed: _isScanning ? null : _openScanner,
              ),
            ),

            const SizedBox(height: 20),

            /// REDEEM TYPE
            const Text('Redeem Type'),
            RadioListTile<int>(
              value: 1,
              groupValue: _redeemType,
              title: const Text('Single Journey (1 Kuota)'),
              onChanged: (v) => setState(() => _redeemType = v!),
            ),
            RadioListTile<int>(
              value: 2,
              groupValue: _redeemType,
              title: const Text('PP / Round Trip (2 Kuota)'),
              onChanged: (v) => setState(() => _redeemType = v!),
            ),

            const SizedBox(height: 20),

            /// ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: _verifySerial,
                    child: const Text(
                      'Verify Serial Number',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
