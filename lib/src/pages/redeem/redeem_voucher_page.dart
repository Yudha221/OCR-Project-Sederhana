import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ocr_project/src/controllers/voucher_controller.dart';
import 'package:ocr_project/src/utils/date_helper.dart';
import 'package:ocr_project/src/utils/ui_popup_vou.dart';
import 'package:flutter/services.dart';

class RedeemVoucherPage extends StatefulWidget {
  const RedeemVoucherPage({super.key});

  @override
  State<RedeemVoucherPage> createState() => _RedeemVoucherPageState();
}

class _RedeemVoucherPageState extends State<RedeemVoucherPage> {
  final VoucherRedeemController _controller = VoucherRedeemController();

  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identityController = TextEditingController();

  MobileScannerController? _scannerController;

  bool _isScanning = false;
  bool _isSerialVerified = false;
  bool _isVerifying = false;
  bool _isRedeeming = false;

  Map<String, dynamic>? _cardData;

  String _selectedIdType = "NIK";

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _identityController.text.trim().isNotEmpty;

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
    _identityController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _isSerialVerified = false;
      _cardData = null;
      _nameController.clear();
      _identityController.clear();
    });
  }

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

  Future<void> _verifySerial() async {
    final serial = _serialController.text.trim();
    if (serial.isEmpty) {
      PopupUtils.show(
        context: context,
        title: 'Validasi Gagal',
        message: 'Serial voucher wajib diisi',
        isError: true,
      );
      return;
    }

    try {
      setState(() => _isVerifying = true);

      final res = await _controller.verifySerial(serial);

      if (res['success'] != true) {
        throw Exception(res['message'] ?? 'Voucher tidak ditemukan');
      }

      final data = res['data'];
      final productType = _controller.detectProductType(data);
      final int quotaRemaining = data['quotaRemaining'] ?? 0;

      if (quotaRemaining <= 0) {
        PopupUtils.show(
          context: context,
          title: 'Kuota Habis',
          message: 'Voucher ini sudah tidak memiliki kuota.',
          isError: true,
        );
        return;
      }

      if (productType == ProductType.fwc) {
        PopupUtils.show(
          context: context,
          title: 'Serial Tidak Sesuai',
          message: 'Serial ini adalah FWC.',
          isError: true,
        );
        return;
      }

      setState(() {
        _isSerialVerified = true;
        _cardData = data;
      });

      PopupUtils.show(
        context: context,
        title: 'Voucher Valid',
        message: 'Voucher valid, silakan isi Nama & Tipe Identitas',
      );
    } catch (e) {
      PopupUtils.show(
        context: context,
        title: 'Proses Gagal',
        message: e.toString(),
        isError: true,
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _redeemVoucher() async {
    if (!_isSerialVerified || !_isFormValid) return;

    try {
      setState(() => _isRedeeming = true);

      final res = await _controller.redeemVoucher(
        serial: _serialController.text.trim(),
        name: _nameController.text.trim(),
        identityNumber: _identityController.text.trim(),
        passengerIdType: _selectedIdType,
      );

      if (res['success'] != true) {
        throw Exception(res['message'] ?? 'Redeem gagal');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
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
        ),
      );
    } catch (e) {
      PopupUtils.show(
        context: context,
        title: 'Redeem Gagal',
        message: e.toString(),
        isError: true,
      );
    } finally {
      setState(() => _isRedeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redeem Voucher')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 768;
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 1000 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 32 : 16),
                child: isTablet && isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildMainSection()),
                          const SizedBox(width: 32),
                          if (_cardData != null)
                            Expanded(child: _buildCardSection()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainSection(),
                          if (_cardData != null) ...[
                            const SizedBox(height: 24),
                            _buildCardSection(),
                          ],
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Redeem Voucher',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _serialController,
          decoration: InputDecoration(
            labelText: 'Serial Voucher',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _openScanner,
            ),
          ),
          onChanged: (_) => _reset(),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isVerifying || _isSerialVerified ? null : _verifySerial,
            child: _isVerifying
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Verify Voucher'),
          ),
        ),

        const SizedBox(height: 20),

        if (_cardData != null &&
            !(_isSerialVerified &&
                MediaQuery.of(context).size.width > 768 &&
                MediaQuery.of(context).orientation == Orientation.landscape))
          _buildCardSection(),

        const SizedBox(height: 20),

        TextField(
          controller: _nameController,
          enabled: _isSerialVerified,
          decoration: InputDecoration(
            labelText: 'Nama Penumpang',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        const SizedBox(height: 16),

        // 🔥 IDENTITAS ORIGINAL (TIDAK DIUBAH)
        const Text(
          "Tipe Identitas",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _isSerialVerified
                      ? () => setState(() => _selectedIdType = "NIK")
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedIdType == "NIK"
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "NIK",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedIdType == "NIK"
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _isSerialVerified
                      ? () => setState(() => _selectedIdType = "PASSPORT")
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedIdType == "PASSPORT"
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Passport",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedIdType == "PASSPORT"
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: _identityController,
          enabled: _isSerialVerified,
          keyboardType: _selectedIdType == "NIK"
              ? TextInputType.number
              : TextInputType.text,
          inputFormatters: _selectedIdType == "NIK"
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ]
              : [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(20),
                ],
          decoration: InputDecoration(
            labelText: _selectedIdType == "NIK"
                ? "Nomor NIK (16 Digit)"
                : "Nomor Passport",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        const SizedBox(height: 24),

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
            ),
            child: _isRedeeming
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  )
                : const Text('Redeem Voucher', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildCardSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Voucher',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _infoRow('Nama Perusahaan', _cardData?['companyName'] ?? '-'),
            _infoRow('Nama PIC', _cardData?['customerName'] ?? '-'),
            _infoRow('NIK/Passport PIC', _cardData?['nik'] ?? '-'),
            _infoRow('No. Seri', _cardData?['serialNumber'] ?? '-'),
            _infoRow('Kategori', _cardData?['cardCategory'] ?? '-'),
            _infoRow('Kelas', _cardData?['cardType'] ?? '-'),
            _infoRow('Masa Berlaku', formatDateIndo(_cardData?['expiredDate'])),
            _infoRow(
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
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? weight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
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
}
