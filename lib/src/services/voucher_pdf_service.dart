import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/redeem.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum ProductType { voucher, fwc }

class VoucherReportService {
  static Future<void> generateReport({
    required List<Redeem> data,
    required String station,
    required String operatorName,
    required DateTime shiftDate,
    required String userCode,
    required ProductType type,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final formatter = DateFormat('dd-MM-yyyy, HH:mm:ss');

    final hari = DateFormat('EEEE', 'id_ID').format(now);
    final tanggalIndo = DateFormat('dd MMMM yyyy', 'id_ID').format(now);

    final hariEn = DateFormat('EEEE', 'en_US').format(now);
    final tanggalEn = DateFormat('MMMM d, yyyy', 'en_US').format(now);
    final docDate = DateFormat('dd.MM.yyyy').format(now);
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // ===== PRODUCT CONFIG =====
    final productName = type == ProductType.voucher ? "VOUCHER" : "FWC";
    final reportCode = type == ProductType.voucher ? "RDM" : "FWC";

    final prefs = await SharedPreferences.getInstance();

    // 🔥 BUAT KEY PER HARI
    final todayKey = DateFormat('yyyyMMdd').format(now);

    // key unik: user + tanggal
    final counterKey = "doc_counter_${userCode}_$todayKey";

    // ambil counter hari ini
    int counter = prefs.getInt(counterKey) ?? 0;

    // nomor berikutnya
    final nextNumber = counter + 1;

    // format 4 digit
    final docNumberFormatted = nextNumber.toString().padLeft(4, '0');

    // final document number
    final docNumber =
        "$docNumberFormatted/$userCode/$reportCode/$station/$docDate";

    // ================= LOAD LOGO =================
    final ByteData logoBytes = await rootBundle.load(
      'assets/images/PT_KCIC_logo.png',
    );
    final Uint8List logoUint8List = logoBytes.buffer.asUint8List();
    final logo = pw.MemoryImage(logoUint8List);

    // ================= GROUPING =================
    final Map<String, List<Redeem>> grouped = {};
    for (var e in data) {
      final key = "${e.cardCategory} ${e.cardType}";
      grouped.putIfAbsent(key, () => []).add(e);
    }

    int totalCount = 0;
    int totalAmount = 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // ================= HEADER CORPORATE =================
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 🔴 Garis merah kiri
              pw.Container(
                width: 8,
                height: 80,
                color: PdfColor.fromInt(0xFF7A1E2D),
              ),

              pw.SizedBox(width: 15),

              // 🖼 Logo
              pw.Image(logo, height: 60),

              pw.Spacer(),

              // 📍 Info kantor kanan
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "KCIC Halim Office",
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "Jalan Tol Jakarta - Cikampek KM 0+800,",
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    "Halim Perdanakusuma, Kec. Makasar,",
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    "Jakarta Timur 13610",
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text("62 21 50995123", style: pw.TextStyle(fontSize: 10)),
                  pw.Text("62 21 50932324", style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 10),

          pw.SizedBox(height: 20),

          // ================= JUDUL =================
          pw.Center(
            child: pw.Text(
              "LAPORAN PENCATATAN REDEEM $productName / $productName REDEEM RECORDING REPORT",
              textAlign: pw.TextAlign.justify,
              style: pw.TextStyle(
                fontSize: 12.2,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Text("NO DOCUMENT : $docNumber"),
          pw.SizedBox(height: 20),

          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(130),
              1: const pw.FixedColumnWidth(10),
              2: const pw.FlexColumnWidth(),
            },
            children: [
              _infoRow("Ticketing Station", station),
              _infoRow("Generated At", formatter.format(now)),
              _infoRow("Operator Name", operatorName),
              _infoRow(
                "Shift Date",
                DateFormat('dd-MM-yyyy').format(shiftDate),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ================= PARAGRAF BILINGUAL (2 KOLOM) =================
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  "Pada hari ini, $hari, tanggal $tanggalIndo, telah dilaksanakan kegiatan pencatatan dan pelaporan Redeem $productName.",
                  textAlign: pw.TextAlign.justify,
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),

              pw.SizedBox(width: 20),

              pw.Expanded(
                child: pw.Text(
                  "On this day, $hariEn, dated $tanggalEn, the recording and reporting activities for $productName Redeem were carried out.",
                  textAlign: pw.TextAlign.justify,
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ================= TABLE =================
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF7A1E2D),
                ),
                children: [
                  _cellHeader("No"),
                  _cellHeader("Kategori"),
                  _cellHeader("Class"),
                  _cellHeader("Count Of Redeem"),
                  _cellHeader("Total Redemption (Rp)"),
                ],
              ),

              ...grouped.entries.toList().asMap().entries.map((entry) {
                final index = entry.key + 1;
                final items = entry.value.value;

                final count = items.length;
                final amount = items.fold<int>(0, (sum, e) => sum + e.price);

                totalCount += count;
                totalAmount += amount;

                return pw.TableRow(
                  children: [
                    _cell(index.toString()),
                    _cell(items.first.cardCategory),
                    _cell(items.first.cardType), // 👈 INI CLASS
                    _cell(count.toString()),
                    _cell(rupiah.format(amount)),
                  ],
                );
              }),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell(""),
                  _cell(""),
                  _cellCenterBold("Total $productName"),
                  _cell(totalCount.toString()),
                  _cell(rupiah.format(totalAmount)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  "Rincian pencatatan dan pelaporan Redeem $productName telah terdokumentasi secara lengkap dalam sistem.",
                  textAlign: pw.TextAlign.justify,
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),

              pw.SizedBox(width: 20),

              pw.Expanded(
                child: pw.Text(
                  "The details of the recording and reporting of $productName Redeem have been fully documented in the system.",
                  textAlign: pw.TextAlign.justify,
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),

          // ================= SIGNATURE =================
          pw.SizedBox(height: 30),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ===== Acknowledged =====
              pw.Column(
                children: [
                  pw.Text(
                    "Acknowledged By",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text("[HPRS]"),
                  pw.SizedBox(height: 40),
                  pw.Text("(........................................)"),
                  pw.SizedBox(height: 5),
                  pw.Text("NIP."),
                ],
              ),

              // ===== Approval =====
              pw.Column(
                children: [
                  pw.Text(
                    "Approval By",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text("[OA]"),
                  pw.SizedBox(height: 40),
                  pw.Text("(........................................)"),
                  pw.SizedBox(height: 5),
                  pw.Text("NIP."),
                ],
              ),

              // ===== Created =====
              pw.Column(
                children: [
                  pw.Text(
                    "Created By [$userCode]",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 70),
                  pw.Text("($operatorName)"),
                  pw.SizedBox(height: 5),
                  pw.Text("NIP. $userCode"),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 25),

          pw.Text(
            "Version 1 - 01.2026  Last updated on: ${formatter.format(now)}",
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
          ),

          pw.SizedBox(height: 5),

          pw.Text(
            "Created by: SISTEM INFORMASI PENJUALAN (VOUCHER)",
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    final directory = await getApplicationDocumentsDirectory();

    final fileDate = DateFormat('yyyyMMdd').format(now);
    final cleanName = operatorName.replaceAll(" ", "_");

    final fileName = "Report_${productName}_Redeem_${cleanName}_$fileDate.pdf";

    final file = File("${directory.path}/$fileName");

    // simpan file
    await file.writeAsBytes(bytes);

    // buka file otomatis
    await OpenFilex.open(file.path);

    // baru setelah sukses → naikkan counter
    await prefs.setInt(counterKey, nextNumber);
  } // ⬅️ INI WAJIB! Tutup generateReport()

  static pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  static pw.Widget _cellCenterBold(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.TableRow _infoRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 11)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(":"),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(value, style: pw.TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  static Future<void> generateShiftReport(
    Map<String, dynamic> report,
    String operatorName,
  ) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final formatter = DateFormat('dd-MM-yyyy, HH:mm:ss');

    final docNumber = report['docNumber'] ?? '-';
    final station = report['stationName'] ?? '-';
    final shiftDate = report['shiftDate'] ?? '-';
    final deviceId = report['deviceId'] ?? '-';
    final shiftType = report['shiftType'] ?? '-';

    final voucher = report['voucherReport'];
    final fwc = report['fwcReport'];

    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // logo
    final ByteData logoBytes = await rootBundle.load(
      'assets/images/PT_KCIC_logo.png',
    );

    final Uint8List logoUint8List = logoBytes.buffer.asUint8List();
    final logo = pw.MemoryImage(logoUint8List);

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          /// HEADER
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 8,
                height: 80,
                color: PdfColor.fromInt(0xFF7A1E2D),
              ),

              pw.SizedBox(width: 15),

              pw.Image(logo, height: 60),

              pw.Spacer(),

              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("KCIC Halim Office"),
                  pw.Text("Jakarta Timur 13610"),
                  pw.Text("62 21 50995123"),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          /// TITLE
          pw.Center(
            child: pw.Text(
              "LAPORAN AKHIR SHIFT / END OF SHIFT REPORT",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Text("NO: $docNumber"),

          pw.SizedBox(height: 20),

          /// MAIN SHIFT INFO
          pw.Text(
            "Penanggung Jawab Utama Shift / Main Person In Charge Of Shift",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(150),
              1: const pw.FixedColumnWidth(10),
              2: const pw.FlexColumnWidth(),
            },
            children: [
              _infoRow("Operator Name", operatorName),
              _infoRow("Ticketing Station", station),
              _infoRow("Generated At", formatter.format(now)),
              _infoRow("Shift Date", shiftDate),
              _infoRow("Device ID", deviceId),
              _infoRow("Shift Type", shiftType),
            ],
          ),

          pw.SizedBox(height: 20),

          /// ================= VOUCHER TABLE =================
          pw.Text(
            "LAPORAN VOUCHER / VOUCHER REPORT",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF7A1E2D),
                ),
                children: [
                  _cellHeader("Type"),
                  _cellHeader("TRX"),
                  _cellHeader("TRX AMOUNT"),
                  _cellHeader("REDEEM"),
                  _cellHeader("REDEEM AMOUNT"),
                ],
              ),

              _shiftRow("Non Delegation", voucher['nonDelegation'], rupiah),
              _shiftRow("Delegation Shift", voucher['delegation'], rupiah),

              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cellCenterBold("Grand Total"),
                  _cell(voucher['grandTotal']['trxCount'].toString()),
                  _cell(rupiah.format(voucher['grandTotal']['trxAmount'])),
                  _cell(voucher['grandTotal']['redeemCount'].toString()),
                  _cell(rupiah.format(voucher['grandTotal']['redeemAmount'])),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 25),

          /// ================= FWC TABLE =================
          pw.Text(
            "LAPORAN FWC / FWC REPORT",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF7A1E2D),
                ),
                children: [
                  _cellHeader("Type"),
                  _cellHeader("TRX"),
                  _cellHeader("TRX AMOUNT"),
                  _cellHeader("REDEEM"),
                  _cellHeader("REDEEM AMOUNT"),
                ],
              ),

              _shiftRow("Non Delegation", fwc['nonDelegation'], rupiah),
              _shiftRow("Delegation Shift", fwc['delegation'], rupiah),

              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cellCenterBold("Grand Total"),
                  _cell(fwc['grandTotal']['trxCount'].toString()),
                  _cell(rupiah.format(fwc['grandTotal']['trxAmount'])),
                  _cell(fwc['grandTotal']['redeemCount'].toString()),
                  _cell(rupiah.format(fwc['grandTotal']['redeemAmount'])),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 40),

          /// SIGNATURE
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text("Acknowledged By"),
                  pw.Text("[HPRS]"),
                  pw.SizedBox(height: 60),
                  pw.Text("(....................)"),
                  pw.Text("NIP"),
                ],
              ),

              pw.Column(
                children: [
                  pw.Text("Approval By"),
                  pw.Text("[OA]"),
                  pw.SizedBox(height: 60),
                  pw.Text("(....................)"),
                  pw.Text("NIP"),
                ],
              ),

              pw.Column(
                children: [
                  pw.Text("Created By"),
                  pw.Text("[PSAC]"),
                  pw.SizedBox(height: 60),
                  pw.Text("($operatorName)"),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    final directory = await getApplicationDocumentsDirectory();

    final file = File("${directory.path}/shift_report.pdf");

    await file.writeAsBytes(bytes);

    await OpenFilex.open(file.path);
  }

  static pw.TableRow _shiftRow(
    String title,
    dynamic data,
    NumberFormat rupiah,
  ) {
    return pw.TableRow(
      children: [
        _cell(title),
        _cell(data['subtotalTrxCount'].toString()),
        _cell(rupiah.format(data['subtotalTrxAmount'])),
        _cell(data['subtotalRedeemCount'].toString()),
        _cell(rupiah.format(data['subtotalRedeemAmount'])),
      ],
    );
  }
}
