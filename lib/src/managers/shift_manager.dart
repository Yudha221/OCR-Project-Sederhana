import 'package:flutter/foundation.dart';
import '../controllers/shift_controller.dart';

class ShiftManager extends ChangeNotifier {
  static final ShiftManager _instance = ShiftManager._internal();
  factory ShiftManager() => _instance;
  ShiftManager._internal();

  final ShiftController _controller = ShiftController();

  bool _isOpen = false;
  bool _initialized = false;

  bool get isOpen => _isOpen;

  Future<void> init() async {
    if (_initialized) return;

    _initialized = true;

    _isOpen = await _controller.getShiftStatus();

    notifyListeners();
  }

  // 🔥 TAMBAHKAN INI
  Future<List<dynamic>> getAvailableShifts() async {
    return await _controller.getAvailableShifts();
  }

  Future<void> openShift(String shiftId) async {
    final res = await _controller.openShift(shiftId);

    if (res['success'] == true) {
      _isOpen = true;
      notifyListeners();
    }
  }

  Future<void> closeShift(String notes) async {
    final res = await _controller.closeShift(notes);

    if (res['success'] == true) {
      _isOpen = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> exportShiftReport() async {
    return await _controller.exportShiftReport();
  }
}
