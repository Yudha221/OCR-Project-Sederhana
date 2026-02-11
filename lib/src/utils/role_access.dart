class RoleAccess {
  final String roleCode;

  RoleAccess(this.roleCode);

  /// ================= VIEW (SEMUA YANG BOLEH LIHAT DATA) =================
  bool get canView {
    switch (roleCode) {
      case 'superadmin':
      case 'admin':
      case 'supervisor':
      case 'petugas':
      case 'marketing':
        return true;
      default:
        return false;
    }
  }

  /// ================= REDEEM =================
  bool get canRedeem {
    switch (roleCode) {
      case 'superadmin':
      case 'supervisor':
      case 'petugas':
        return true;
      default:
        return false;
    }
  }

  /// ================= DELETE =================
  bool get canDelete {
    switch (roleCode) {
      case 'superadmin':
      case 'supervisor':
        return true;
      default:
        return false;
    }
  }

  /// ================= STATION LOCK =================
  bool get lockStation {
    switch (roleCode) {
      case 'supervisor':
      case 'petugas':
        return true;
      default:
        return false;
    }
  }

  /// ================= DRAWER PER MENU =================
  bool get canFWC => canView;
  bool get canFWCKai => canView;
  bool get canVoucher => canView;
}
