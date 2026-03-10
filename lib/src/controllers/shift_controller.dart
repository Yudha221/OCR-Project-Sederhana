import 'package:ocr_project/src/presentation/api.dart';
import '../repositories/shift_repository.dart';

class ShiftController {
  late final ShiftRepository _repo;

  ShiftController() {
    _repo = ShiftRepository(Api().dio);
  }

  Future<Map<String, dynamic>> openShift(String shiftId) async {
    try {
      final res = await _repo.openShift(shiftId);

      if (res['success'] == true) {
        return {'success': true};
      }

      return {
        'success': false,
        'message': res['message'] ?? 'Gagal membuka shift',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi'};
    }
  }

  Future<Map<String, dynamic>> closeShift(String notes) async {
    try {
      final res = await _repo.closeShift(notes);

      if (res['success'] == true) {
        return {
          'success': true,
          'message': res['data']?['message'] ?? 'Shift closed',
        };
      }

      return {
        'success': false,
        'message': res['message'] ?? 'Gagal menutup shift',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi'};
    }
  }

  Future<bool> getShiftStatus() async {
    try {
      final res = await _repo.getShiftStatus();

      if (res['success'] == true) {
        return res['data']?['status'] == 'OPEN';
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getAvailableShifts() async {
    try {
      final res = await _repo.getAvailableShift();
      return res;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> exportShiftReport() async {
    try {
      final res = await _repo.exportShiftReport();

      // Jika ada wrapper 'data', ambil data-nya
      if (res.containsKey('data') && res['data'] != null) {
        return res['data'];
      }
      
      // Jika tidak ada wrapper 'data' tapi ada key report langsung
      if (res.containsKey('voucherReport') || res.containsKey('voucher_report')) {
        return res;
      }

      // Default jika success true tapi tidak tahu strukturnya
      if (res['success'] == true) {
        return res['data'] ?? res;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
