class RoleAccess {
  final String roleCode;

  RoleAccess(String role) : roleCode = role.toLowerCase();

  /// ================= VIEW (SEMUA YANG BOLEH LIHAT DATA) =================
  bool get canView {
    switch (roleCode) {
      case 'superadmin':
      case 'head_marketing':
      case 'spv_ticketing':
      case 'ticketing':
      case 'marketing':
      case 'supervisor':
      case 'petugas':
      case 'accounting':
      case 'contact_center':
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

  /// ================= Pembatalan =================
  bool get canDelete {
    switch (roleCode) {
      case 'superadmin':
      case 'petugas':
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

  /// ================= SHIFT =================
  bool get canOpenShift {
    switch (roleCode) {
      case 'petugas':
        return true;
      default:
        return false;
    }
  }

  /// ================= ACTIVITY LOG =================
  bool get canViewActivityLog {
    switch (roleCode) {
      case 'superadmin':
      case 'supervisor':
      case 'petugas':
      case 'spv_ticketing':
        return true;
      default:
        return false;
    }
  }

  /// ================= EXPORT REPORT =================
  bool get canExportReport {
    switch (roleCode) {
      case 'superadmin':
      case 'accounting':
        return true;
      default:
        return false;
    }
  }

  /// ================= CUSTOMER VIEW =================
  bool get canViewCustomer {
    switch (roleCode) {
      case 'contact_center':
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
