import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_project/src/models/last_redeem.dart';
import 'package:ocr_project/src/controllers/last_redeem_controller.dart';

class LastRedeemPage extends StatefulWidget {
  final LastRedeem data;

  const LastRedeemPage({super.key, required this.data});

  @override
  State<LastRedeemPage> createState() => _LastRedeemPageState();
}

class _LastRedeemPageState extends State<LastRedeemPage> {
  late final LastRedeem lastRedeem;

  final LastRedeemController controller = LastRedeemController();

  final ImagePicker _picker = ImagePicker();

  File? selectedImage;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    lastRedeem = widget.data;
  }

  // ================= PICK IMAGE (KAMERA + GALERI) =================
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70, // 🔥 compress biar upload cepat
    );

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  // ================= PILIH SUMBER FOTO =================
  void _showImageSource() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Kamera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Galeri"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= UPLOAD IMAGE =================
  Future<void> _uploadImage() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pilih foto dulu")));
      return;
    }

    setState(() => isUploading = true);

    try {
      await controller.uploadPhoto(lastRedeem.id, selectedImage!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload berhasil')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Last Redeem'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _uploadPhotoSection(),
            const SizedBox(height: 24),
            _lastRedeemCard(),
          ],
        ),
      ),
    );
  }

  // ================= UPLOAD FOTO =================
  Widget _uploadPhotoSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Upload Foto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showImageSource,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12), // 🔥 sudut kotak
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: selectedImage != null
                      ? Image.file(selectedImage!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt, size: 40),
                            SizedBox(height: 8),
                            Text("Tap untuk upload foto"),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUploading ? null : _uploadImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.blueGrey,
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Upload Foto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LAST REDEEM CARD =================
  Widget _lastRedeemCard() {
    final d = lastRedeem;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(d.nik, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('Serial Card', d.serialNumber),
            _infoRow('Program', d.programType),
            _infoRow('Category', d.cardCategory),
            _infoRow('Type', d.cardType),
            const Divider(height: 24),
            const Text(
              'Last Redeem',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _infoRow('Tanggal', d.redeemDate),
            _infoRow('Perjalanan', d.redeemType),
            _infoRow('Kuota Terpakai', d.quotaUsed),
            _infoRow('Sisa Kuota', d.remainingQuota),
            _infoRow('Stasiun', d.station),
            _infoRow('Operator', d.operatorName),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
