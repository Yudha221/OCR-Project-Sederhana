import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ocr_project/src/controllers/auth_controller.dart';
import 'package:ocr_project/src/controllers/voucher_controller.dart';

class RedeemVoucherPage extends StatefulWidget {
  const RedeemVoucherPage({super.key});

  @override
  State<RedeemVoucherPage> createState() => _RedeemVoucherPageState();
}

class _RedeemVoucherPageState extends State<RedeemVoucherPage> {
  final AuthController _authController = AuthController();
  final VoucherRedeemController _controller = VoucherRedeemController();

  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();

  final MobileScannerController _scannerController = MobileScannerController();

  bool isLoading = false;
  bool isScanning = false;
  bool hasScanned = false;
  bool isVerified = false;

  String userName = '';

  // ================= FORM VALIDATION =================
  bool get isFormFilled {
    return _serialController.text.trim().isNotEmpty &&
        _nameController.text.trim().isNotEmpty &&
        _nikController.text.trim().length == 16;
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _serialController.dispose();
    _nameController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    userName = await _authController.getUserName();
    if (mounted) setState(() {});
  }

  // ================= STOP SCAN =================
  void _stopScan() {
    _scannerController.stop();
    setState(() {
      isScanning = false;
      hasScanned = false;
    });
  }

  // ================= VERIFY =================
  void _verifyData() {
    if (!isFormFilled) {
      _showSnack(
        'Serial, Nama, dan NIK wajib diisi sebelum verify',
        isError: true,
      );
      return;
    }

    setState(() => isVerified = true);
    _showSnack('Data valid, silakan redeem');
  }

  // ================= REDEEM =================
  Future<void> _redeemVoucher() async {
    setState(() => isLoading = true);

    try {
      final result = await _controller.redeemVoucher(
        serial: _serialController.text.trim(),
        name: _nameController.text.trim(),
        nik: _nikController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnack(result['message'] ?? 'Voucher berhasil diredeem');

        // RESET STATE (1x REDEEM)
        _serialController.clear();
        _nameController.clear();
        _nikController.clear();

        setState(() {
          isVerified = false;
          hasScanned = false;
        });
      } else {
        _showSnack(result['message'] ?? 'Gagal redeem voucher', isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Terjadi kesalahan saat redeem', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A1E2D),
        title: const Text(
          'Redeem Voucher',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ================= SCANNER =================
            if (isScanning)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) {
                            if (hasScanned) return;

                            final barcode = capture.barcodes.first.rawValue;

                            if (barcode != null && barcode.isNotEmpty) {
                              hasScanned = true;
                              _serialController.text = barcode;

                              _scannerController.stop();
                              setState(() {
                                isScanning = false;
                                isVerified = false;
                              });

                              _showSnack(
                                'Serial terisi, isi Nama & NIK lalu verify',
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: _stopScan,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ================= FORM =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.confirmation_number_outlined,
                              color: Colors.red,
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Redeem Voucher',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Petugas: $userName',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // SERIAL
                        TextField(
                          controller: _serialController,
                          enabled: !isVerified,
                          onChanged: (_) => setState(() => isVerified = false),
                          decoration: InputDecoration(
                            labelText: 'Serial Voucher',
                            hintText: 'Scan / masukkan serial voucher',
                            helperText: 'Klik icon QR untuk scan',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isScanning
                                    ? Icons.close
                                    : Icons.qr_code_scanner,
                                color: Colors.red,
                              ),
                              onPressed: isVerified
                                  ? null
                                  : () {
                                      if (isScanning) {
                                        _stopScan();
                                      } else {
                                        setState(() {
                                          isScanning = true;
                                          hasScanned = false;
                                          isVerified = false;
                                        });
                                      }
                                    },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // NAMA
                        TextField(
                          controller: _nameController,
                          enabled: !isVerified,
                          onChanged: (_) => setState(() => isVerified = false),
                          decoration: InputDecoration(
                            labelText: 'Nama',
                            hintText: 'Masukkan nama penerima',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // NIK
                        TextField(
                          controller: _nikController,
                          enabled: !isVerified,
                          keyboardType: TextInputType.number,
                          maxLength: 16,
                          onChanged: (_) => setState(() => isVerified = false),
                          decoration: InputDecoration(
                            labelText: 'NIK',
                            hintText: 'Masukkan NIK',
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // VERIFY
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed:
                                (!isFormFilled || isLoading || isVerified)
                                ? null
                                : _verifyData,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Verify Data',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // REDEEM
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (isVerified && !isLoading)
                                ? _redeemVoucher
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isLoading
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
