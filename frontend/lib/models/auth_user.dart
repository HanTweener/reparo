class AuthUser {
  final String id;
  final String name;
  final String email;
  final String roleCode;
  final bool isActive;
  final String? emailVerifiedAt;
  final int completedTasksCount;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roleCode,
    this.isActive = true,
    this.emailVerifiedAt,
    this.completedTasksCount = 0,
  });

  bool get isCustomer => roleCode == 'CUSTOMER';
  bool get isTechnician => roleCode == 'TECHNICIAN';
  bool get isAdmin => roleCode == 'ADMIN';
  bool get isCashier => roleCode == 'CASHIER';
  bool get isAdminOrCashier => isAdmin || isCashier;

  String get roleLabel {
    switch (roleCode) {
      case 'ADMIN':
        return 'Administrator';
      case 'CASHIER':
        return 'Kasir';
      case 'TECHNICIAN':
        return 'Teknisi';
      case 'CUSTOMER':
      default:
        return 'Pelanggan';
    }
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roleCode: json['role_code'] as String? ?? 'CUSTOMER',
      isActive: json['is_active'] as bool? ?? true,
      emailVerifiedAt: json['email_verified_at'] as String?,
      completedTasksCount: (json['completed_tasks_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role_code': roleCode,
      'is_active': isActive,
      'email_verified_at': emailVerifiedAt,
      'completed_tasks_count': completedTasksCount,
    };
  }
}

