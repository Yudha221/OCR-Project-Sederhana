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

enum ProductType { voucher, fwc, fwckai }

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
    final String pName = type == ProductType.voucher
        ? "VOUCHER"
        : type == ProductType.fwckai
            ? "FWCKAI"
            : "FWC";

    final String p = type == ProductType.voucher
        ? "VOUCHER"
        : "FREQUENT WHOOSHER CARD";
    final formatter = DateFormat('dd-MM-yyyy, HH:mm:ss');
    final docDate = DateFormat('dd-MM-yyyy').format(now);
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 2,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a3.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // ================= TITLE =================
          pw.Center(
            child: pw.Text(
              "LAPORAN REDEEM $p",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          // ================= INFO SECTION =================
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Operator : $operatorName", style: const pw.TextStyle(fontSize: 12)),
              pw.Text("Shift : ${DateFormat('dd-MM-yyyy').format(shiftDate)}, ${DateFormat('HH:mm:ss').format(now)}", style: const pw.TextStyle(fontSize: 12)),
              pw.Text("Jumlah transaksi redeem : ${data.length}", style: const pw.TextStyle(fontSize: 12)),
            ],
          ),

          pw.SizedBox(height: 20),

          // ================= TABLE =================
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.3),
            columnWidths: {
              0: const pw.FixedColumnWidth(15), // No
              1: const pw.FixedColumnWidth(55), // Tanggal Redeem
              2: const pw.FixedColumnWidth(65), // Nama Pelanggan
              3: const pw.FixedColumnWidth(60), // NIK
              4: const pw.FixedColumnWidth(95), // Nomor Redeem
              5: const pw.FixedColumnWidth(95), // Nomor Transaksi
              6: const pw.FixedColumnWidth(35), // Status Asal
              7: const pw.FixedColumnWidth(65), // Serial Kartu
              8: const pw.FixedColumnWidth(35), // Kategori Kartu
              9: const pw.FixedColumnWidth(35), // Tipe Kartu
              10: const pw.FixedColumnWidth(45), // Perjalanan
              11: const pw.FixedColumnWidth(25), // Sisa
              12: const pw.FixedColumnWidth(65), // Op Utama
              13: const pw.FixedColumnWidth(65), // Op Pengganti
              14: const pw.FixedColumnWidth(40), // Stasiun
              15: const pw.FixedColumnWidth(40), // NIP KAI
              16: const pw.FixedColumnWidth(65), // Price
              17: const pw.FixedColumnWidth(50), // Seat Class
              18: const pw.FixedColumnWidth(25), // Quota
              19: const pw.FixedColumnWidth(45), // Purchase Date
              20: const pw.FixedColumnWidth(45), // Expired Date
              21: const pw.FixedColumnWidth(30), // Masa Aktif
              22: const pw.FixedColumnWidth(50), // Channel
            },
            children: [
              // HEADER
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF7A1E2D)),
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  _cellHeader("No"),
                  _cellHeader("Tanggal Redeem"),
                  _cellHeader("Nama Pelanggan"),
                  _cellHeader("NIK"),
                  _cellHeader("Nomor Redeem"),
                  _cellHeader("Nomor Transaksi"),
                  _cellHeader("Status Asal"),
                  _cellHeader("Serial Kartu"),
                  _cellHeader("Kategori Kartu"),
                  _cellHeader("Tipe Kartu"),
                  _cellHeader("Tipe Perjalanan"),
                  _cellHeader("Sisa\nKuota"),
                  _cellHeader("Operator Utama"),
                  _cellHeader("Operator Pengganti"),
                  _cellHeader("Stasiun"),
                  _cellHeader("NIP KAI"),
                  _cellHeader("Price Redeem"),
                  _cellHeader("Seat Class Program"),
                  _cellHeader("Quota Ticket"),
                  _cellHeader("Purchase Date"),
                  _cellHeader("Expired Date"),
                  _cellHeader("Masa Aktif"),
                  _cellHeader("Ticketing Channel"),
                ],
              ),

              // DATA ROWS
              ...data.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final e = entry.value;
                return pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    _cell(index.toString()),
                    _cell(_formatDate(e.redeemDate)),
                    _cell(e.customerName),
                    _cell(e.identityNumber),
                    _cell(e.redeemNumber),
                    _cell(e.transactionNumber),
                    _cell(e.ticketOrigin),
                    _cell(e.serialNumber),
                    _cell(e.cardCategory),
                    _cell(e.cardType),
                    _cell(e.journeyType),
                    _cell(e.remainingQuota.toString()),
                    _cell(e.operatorName),
                    _cell(e.secondaryOperatorName),
                    _cell(e.station),
                    _cell(e.nipKai),
                    _cell(rupiah.format(e.price)),
                    _cell(e.seatClassProgram),
                    _cell(e.quotaTicket.toString()),
                    _cell(_formatDate(e.redeemDate)), 
                    _cell(_formatDate(e.expiredDate)),
                    _cell("${e.masaAktif} Hari"),
                    _cell(e.channelName),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final fileDate = DateFormat('yyyyMMdd').format(now);
    final fileName = "Redeem_Report_${pName}_$fileDate.pdf";
    final file = File("${directory.path}/$fileName");

    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
  }

  static pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 6.5),
        textAlign: pw.TextAlign.center,
        softWrap: true, // ✅ ALLOW WRAPPING
      ),
    );
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == '-') return '-';
    try {
      // Attempt to parse ISO8601 or yyyy-MM-dd
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (e) {
      // Return as is if parsing fails
      return dateStr;
    }
  }

  static pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 6.5,
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
        softWrap: true, // ✅ ALLOW WRAPPING
      ),
    );
  }

  static pw.Widget _cellCenterBold(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _buildSignatureBlock(String title, String role, String name, String? nip) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.Text(role, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 50),
        // Use a Row to center the left-aligned inner column
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(name, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 2),
                pw.Text("NIP. ${nip ?? ""}", style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _infoRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(":"),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
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
    final formatter = DateFormat('d-M-yyyy, HH.mm.ss');
    final station = report['stationName'] ?? report['station_name'] ?? '-';

    final prefs = await SharedPreferences.getInstance();
    
    // Generate Document Number
    final currentMonth = DateFormat('MM.yyyy').format(now);
    final lastMonth = prefs.getString('last_doc_month') ?? '';
    int currentCounter = 1;

    if (lastMonth != currentMonth) {
      prefs.setInt('doc_counter', 1);
      prefs.setString('last_doc_month', currentMonth);
    } else {
      currentCounter = (prefs.getInt('doc_counter') ?? 0) + 1;
      prefs.setInt('doc_counter', currentCounter);
    }

    String stationCode = 'HLM';
    final stnName = station.toUpperCase();
    if (stnName.contains('HALIM')) {
      stationCode = 'HLM';
    } else if (stnName.contains('KARAWANG')) {
      stationCode = 'KRW';
    } else if (stnName.contains('PADALARANG')) {
      stationCode = 'PDL';
    } else if (stnName.contains('TEGALLUAR')) {
      stationCode = 'TGL';
    } else if (stnName.contains('MARKETING')) {
      stationCode = 'MKT';
    } else if (station != '-' && station.length >= 3) {
      stationCode = station.substring(0, 3).toUpperCase();
    }

    final String docCounterStr = currentCounter.toString().padLeft(4, '0');
    final String docNumber = "$docCounterStr/SIP/LAS/$stationCode/$currentMonth";

    // Shift Type Mapping
    final shiftType = (report['shiftType'] ?? report['shift_type'])?.toString().toUpperCase() ?? '-';
    
    final shiftDate = report['shiftDate'] ?? report['shift_date'] ?? '-';
    final deviceId = report['deviceId'] ?? report['device_id'] ?? '-';

    final String nip = report['userCode'] ?? report['operatorNip'] ?? report['nip'] ?? report['operator_nip'] ?? '-';
    final String tempOperatorName = report['replacementOperatorName'] ?? report['replacement_operator_name'] ?? report['temporaryOperatorName'] ?? report['temporary_operator_name'] ?? '-';
    final String delegasiTime = report['delegationTime'] ?? report['delegation_time'] ?? '-';

    final voucher = report['voucherReport'] ?? report['voucher_report'] ?? {};
    final fwc = report['fwcReport'] ?? report['fwc_report'] ?? {};

    final formatterNum = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    // header letterhead
    final ByteData headerBytes = await rootBundle.load(
      'assets/images/kcic-letterhead.jpeg',
    );

    final Uint8List headerUint8List = headerBytes.buffer.asUint8List();
    final headerImage = pw.MemoryImage(headerUint8List);

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          /// HEADER (Letterhead)
          pw.Image(headerImage),

          pw.SizedBox(height: 20),

          /// TITLE
          pw.Text(
            "LAPORAN AKHIR SHIFT / END OF SHIFT REPORT",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          pw.Text("NO: $docNumber", style: const pw.TextStyle(fontSize: 10)),

          pw.SizedBox(height: 20),

          /// MAIN SHIFT INFO
          pw.Text(
            "Penanggung Jawab Utama Shift / Main Person In Charge Of Shift",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(80),
              1: const pw.FixedColumnWidth(10),
              2: const pw.FlexColumnWidth(),
              3: const pw.FixedColumnWidth(80),
              4: const pw.FixedColumnWidth(10),
              5: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(children: [
                _infoText("Operator Name"), _infoText(":"), _infoText(operatorName),
                _infoText("Generated At"), _infoText(":"), _infoText(formatter.format(now)),
              ]),
              pw.TableRow(children: [
                _infoText("Ticketing Station"), _infoText(":"), _infoText(station),
                _infoText("Shift Date"), _infoText(":"), _infoText(shiftDate),
              ]),
              pw.TableRow(children: [
                _infoText("Device ID"), _infoText(":"), pw.Text(deviceId, style: const pw.TextStyle(fontSize: 10)),
                _infoText("Shift Type"), _infoText(":"), _infoText(shiftType),
              ]),
            ],
          ),

          pw.SizedBox(height: 12),

          /// TEMPORARY SHIFT INFO
          pw.Text(
            "Penanggung Jawab Pengganti Shift Sementara / Person In Charge Of Temporary Shift Replacement",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(80),
              1: const pw.FixedColumnWidth(10),
              2: const pw.FlexColumnWidth(),
              3: const pw.FixedColumnWidth(80),
              4: const pw.FixedColumnWidth(10),
              5: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(children: [
                _infoText("Operator Name"), _infoText(":"), _infoText(tempOperatorName),
                _infoText("Delegasi Time"), _infoText(":"), _infoText(delegasiTime),
              ]),
            ]
          ),

          pw.SizedBox(height: 20),

          /// ================= VOUCHER TABLE =================
          pw.Text(
            "LAPORAN VOUCHER / VOUCHER REPORT",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          _buildShiftTable(voucher, formatterNum),

          pw.SizedBox(height: 20),

          /// ================= FWC TABLE =================
          pw.Text(
            "LAPORAN FWC / FWC REPORT",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          _buildShiftTable(fwc, formatterNum),


          pw.SizedBox(height: 40),

          /// SIGNATURE
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: _buildSignatureBlock("Acknowledged By", "[HPRS]", "(........................................)", null),
              ),
              pw.Expanded(
                child: _buildSignatureBlock("Approval By", "[OA]", "(........................................)", null),
              ),
              pw.Expanded(
                child: _buildSignatureBlock("Created By", "[PSAC]", "($operatorName)", nip),
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    final directory = await getApplicationDocumentsDirectory();

    final cleanName = operatorName.replaceAll(" ", "_");
    final fileName = "End_Of_Shift_Report_${cleanName}_${now.millisecondsSinceEpoch}.pdf";
final file = File("${directory.path}/$fileName");

    await file.writeAsBytes(bytes);

    await OpenFilex.open(file.path);
  }

  static pw.Widget _infoText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
    );
  }

  static pw.Widget _buildShiftTable(Map<String, dynamic> data, NumberFormat f) {
    final nonDel = data['nonDelegation'] ?? data['non_delegation'] ?? {};
    final del = data['delegation'] ?? data['delegation_shift'] ?? {};
    final gt = data['grandTotal'] ?? data['grand_total'] ?? {};

    final nonDelItems = nonDel['items'] as List? ?? nonDel['item_details'] as List? ?? nonDel['details'] as List? ?? [];
    final delItems = del['items'] as List? ?? del['item_details'] as List? ?? del['details'] as List? ?? [];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FixedColumnWidth(60), // Lebarin sedikit untuk Type
        2: const pw.FlexColumnWidth(),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(40),
        6: const pw.FixedColumnWidth(60),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cellHeaderBlack("No"),
            _cellHeaderBlack("Type"),
            _cellHeaderBlack("Category"),
            _cellHeaderBlack("TRX"),
            _cellHeaderBlack("TRX AMOUNT"),
            _cellHeaderBlack("REDEEM"),
            _cellHeaderBlack("REDEEM AMOUNT"),
          ],
        ),
        // A. Non Delegation
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            _cell(""),
            _cellLeft("A. Non Delegation"),
            _cell(""), _cell(""), _cell(""), _cell(""), _cell(""),
          ]
        ),
        
        // Items for A
        ...nonDelItems.asMap().entries.map((entry) {
          final i = entry.key + 1;
          final item = entry.value as Map<String, dynamic>;
          return pw.TableRow(
            children: [
              _cell(i.toString()),
              _cell(item['type']?.toString() ?? item['cardType']?.toString() ?? '-'),
              _cell(item['category']?.toString() ?? item['cardCategory']?.toString() ?? '-'),
              _cellCenter(_count(item, ['trxCount', 'trx_count'])),
              _cellCenter(_val(item, 'trxAmount', 'trx_amount', f)),
              _cellCenter(_count(item, ['redeemCount', 'redeem_count'])),
              _cellCenter(_val(item, 'redeemAmount', 'redeem_amount', f)),
            ]
          );
        }),

        pw.TableRow(
          children: [
            _cell(""),
            _cell(""),
            _cellRight("Subtotal A"),
            _cellCenter(_count(nonDel, ['subtotalTrxCount', 'subtotal_trx_count'])),
            _cellCenter(_val(nonDel, 'subtotalTrxAmount', 'subtotal_trx_amount', f)),
            _cellCenter(_count(nonDel, ['subtotalRedeemCount', 'subtotal_redeem_count'])),
            _cellCenter(_val(nonDel, 'subtotalRedeemAmount', 'subtotal_redeem_amount', f)),
          ]
        ),

        // B. Delegation Shift
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            _cell(""),
            _cellLeft("B. Delegation Shift"),
            _cell(""), _cell(""), _cell(""), _cell(""), _cell(""),
          ]
        ),

        // Items for B
        ...delItems.asMap().entries.map((entry) {
          final i = entry.key + 1;
          final item = entry.value as Map<String, dynamic>;
          return pw.TableRow(
            children: [
              _cell(i.toString()),
              _cell(item['type']?.toString() ?? item['cardType']?.toString() ?? '-'),
              _cell(item['category']?.toString() ?? item['cardCategory']?.toString() ?? '-'),
              _cellCenter(_count(item, ['trxCount', 'trx_count'])),
              _cellCenter(_val(item, 'trxAmount', 'trx_amount', f)),
              _cellCenter(_count(item, ['redeemCount', 'redeem_count'])),
              _cellCenter(_val(item, 'redeemAmount', 'redeem_amount', f)),
            ]
          );
        }),

        pw.TableRow(
          children: [
            _cell(""),
            _cell(""),
            _cellRight("Subtotal B"),
            _cellCenter(del['subtotalTrxCount']?.toString() ?? del['subtotal_trx_count']?.toString() ?? "0"),
            _cellCenter(_val(del, 'subtotalTrxAmount', 'subtotal_trx_amount', f)),
            _cellCenter(del['subtotalRedeemCount']?.toString() ?? del['subtotal_redeem_count']?.toString() ?? "0"),
            _cellCenter(_val(del, 'subtotalRedeemAmount', 'subtotal_redeem_amount', f)),
          ]
        ),

        // Grand Total
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell(""),
            _cell(""),
            _cellRightBold("Grand Total"),
            _shiftCellCenterBold(_count(gt, ['trxCount', 'totalTrxCount', 'total_trx_count', 'grandTotalTrxCount'])),
            _shiftCellCenterBold(_val(gt, 'trxAmount', 'total_trx_amount', f)),
            _shiftCellCenterBold(_count(gt, ['redeemCount', 'totalRedeemCount', 'total_redeem_count', 'grandTotalRedeemCount'])),
            _shiftCellCenterBold(_val(gt, 'redeemAmount', 'total_redeem_amount', f)),
          ]
        ),
      ],
    );
  }

  static String _val(Map<String, dynamic> m, String k1, String k2, NumberFormat f) {
    final v = m[k1] ?? m[k2] ?? m['total_$k1'] ?? m['total_$k2'] ?? m['subtotal_$k1'] ?? m['subtotal_$k2'];
    if (v == null) return "0";
    
    // robust parsing
    final numVal = num.tryParse(v.toString()) ?? 0;
    return f.format(numVal);
  }

  static String _count(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m[k] != null) return m[k].toString();
    }
    return "0";
  }

  static pw.Widget _cellHeaderBlack(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _cellLeft(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
      ),
    );
  }

  static pw.Widget _cellRight(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
      ),
    );
  }

  static pw.Widget _cellRightBold(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
      ),
    );
  }

  static pw.Widget _cellCenter(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Center(
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
      ),
    );
  }

  static pw.Widget _shiftCellCenterBold(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Center(
        child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
      ),
    );
  }
}
