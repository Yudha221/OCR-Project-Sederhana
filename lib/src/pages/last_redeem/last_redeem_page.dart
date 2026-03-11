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
  late LastRedeem lastRedeem;

  final LastRedeemController controller = LastRedeemController();
  final ImagePicker _picker = ImagePicker();

  File? selectedImage;
  bool isUploading = false;

  // 🔥 TAMBAHAN: simpan URL foto hasil upload
  String? uploadedPhotoUrl;

  Future<void> _loadLatestRedeem() async {
    final updated = await controller.fetchLastRedeem(lastRedeem.id);

    if (updated != null) {
      setState(() {
        lastRedeem = updated;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    lastRedeem = widget.data;

    // 🔥 ambil data terbaru dari server
    _loadLatestRedeem();
  }

  // ================= PICK IMAGE =================
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70);

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
    if (selectedImage == null) return;

    setState(() => isUploading = true);

    try {
      final photoUrl = await controller.uploadPhoto(
        lastRedeem.id,
        selectedImage!,
      );

      setState(() {
        selectedImage = null;
        lastRedeem = lastRedeem.copyWith(photoUrl: photoUrl);
      });

      _showSuccessDialog(); // popup berhasil
    } catch (e) {
      _showErrorDialog(); // popup gagal
    } finally {
      setState(() => isUploading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Upload Berhasil"),
          content: const Text("Foto berhasil diupload."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Upload Gagal"),
          content: const Text("Foto gagal diupload."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Last Redeem'),
        backgroundColor: Colors.white,
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
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: selectedImage != null
                      ? Image.file(selectedImage!, fit: BoxFit.contain)
                      : (lastRedeem.photoUrl != null &&
                            lastRedeem.photoUrl!.isNotEmpty)
                      ? Image.network(
                          "${lastRedeem.photoUrl}?t=${DateTime.now().millisecondsSinceEpoch}",
                          key: ValueKey(lastRedeem.photoUrl), // 🔥 penting
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, size: 40),
                            );
                          },
                        )
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
            _infoRow('Customer Name', d.name),
            _infoRow('NIK', d.nik),
            _infoRow('Card Category', d.cardCategory),
            _infoRow('Card Type', d.cardType),
            _infoRow('Serial Number', d.serialNumber),
            _infoRow('Kuota Awal', d.initialQuota),
            _infoRow('Kuota Terpakai', d.quotaUsed),
            _infoRow('Sisa Kuota', d.remainingQuota),
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
