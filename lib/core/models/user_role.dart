/// Configurable, contract-friendly user role definition for the AgriFlow frontend.
/// Does not hardcode rigid backend schemas while providing clean role-checking capabilities.
enum UserRole {
  manager,
  admin,
  superAdmin,
  unsupported;

  /// Parse role string from backend authentication payloads.
  /// Handles variants like 'manager', 'admin', 'super_admin', 'superadmin', etc.
  /// Explicitly returns [unsupported] for unknown or unauthorized roles (e.g. farmer).
  static UserRole fromString(String? role) {
    if (role == null) return UserRole.unsupported;
    final normalized = role.trim().toLowerCase().replaceAll('-', '_');
    if (normalized == 'super_admin' || normalized == 'superadmin') {
      return UserRole.superAdmin;
    }
    if (normalized == 'admin' || normalized == 'administrator') {
      return UserRole.admin;
    }
    if (normalized == 'manager') {
      return UserRole.manager;
    }
    return UserRole.unsupported;
  }

  /// Whether the role is supported by the Admin & Manager console
  bool get isSupported =>
      this == UserRole.admin ||
      this == UserRole.superAdmin ||
      this == UserRole.manager;

  /// Whether the user has administrative privileges (Admin or SuperAdmin)
  bool get isAdmin => this == UserRole.admin || this == UserRole.superAdmin;

  /// Whether the user is a manager (field/operations focus)
  bool get isManager => this == UserRole.manager;

  /// Whether the user has top-level super admin authorization
  bool get isSuperAdmin => this == UserRole.superAdmin;

  /// Display title for header bar
  String get consoleTitle {
    switch (this) {
      case UserRole.superAdmin:
      case UserRole.admin:
        return 'Admin Console';
      case UserRole.manager:
        return 'Manager Console';
      case UserRole.unsupported:
        return 'Access Denied';
    }
  }

  /// Display label for badge
  String get displayLabel {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.unsupported:
        return 'Unauthorized';
    }
  }

  /// Permission helpers for frontend feature gating
  bool get canManageManagers => isSuperAdmin;
  bool get canAccessAuditLogs => isAdmin;
  bool get canAccessReports => isAdmin;
  bool get canManageCache => isAdmin;
  bool get canEditMarketRates => isAdmin;
  bool get canDeleteFarmer => isSuperAdmin;
  bool get canAccessCreditsAdmin => isAdmin;
}

