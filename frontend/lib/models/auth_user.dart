class AuthUser {
  final String id;
  final String name;
  final String email;
  final String roleCode;
  final bool isActive;
  final String? emailVerifiedAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roleCode,
    this.isActive = true,
    this.emailVerifiedAt,
  });

  bool get isCustomer => roleCode == 'CUSTOMER';
  bool get isTechnician => roleCode == 'TECHNICIAN';
  bool get isAdmin => roleCode == 'ADMIN';

  String get roleLabel {
    switch (roleCode) {
      case 'ADMIN':
        return 'Administrator';
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
    };
  }
}

