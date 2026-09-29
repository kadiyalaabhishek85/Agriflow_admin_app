import '../../../../core/models/user_role.dart';

/// User identity entity matching FastAPI UserPublic schema.
class AuthUser {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final UserRole role;
  final String status;
  final bool firstLogin;
  final DateTime? createdAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.status = 'active',
    this.firstLogin = false,
    this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      status: json['status'] as String? ?? 'active',
      firstLogin: json['first_login'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role.name,
      'status': status,
      'first_login': firstLogin,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  AuthUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    String? status,
    bool? firstLogin,
    DateTime? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      firstLogin: firstLogin ?? this.firstLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          phone == other.phone &&
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ phone.hashCode ^ role.hashCode;
}
