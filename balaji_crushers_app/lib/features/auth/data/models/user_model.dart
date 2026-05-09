/// Represents the authenticated user.
///
/// Aligns with what the backend actually returns:
/// - Login  : { id, name, username, role, token }
/// - /auth/me: { id, username, role, iat, exp }   ← JWT payload
class User {
  final int id;
  final String username;   // PRIMARY identifier — always present
  final String? name;      // Display name (nullable — may not be set)
  final String? email;     // Optional — not always returned by backend
  final String? phone;     // Optional extended field
  final String? department;// Optional extended field
  final String? designation;// Job title / position
  final String? role;
  final String? token;     // Only present right after login

  const User({
    required this.id,
    required this.username,
    this.name,
    this.email,
    this.phone,
    this.department,
    this.designation,
    this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      department: json['department']?.toString(),
      designation: json['designation']?.toString(),
      role: json['role']?.toString(),
      token: json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (designation != null) 'designation': designation,
      if (role != null) 'role': role,
      if (token != null) 'token': token,
    };
  }

  /// Convenience getter — prefers [name], falls back to [username].
  String get displayName => (name?.isNotEmpty == true) ? name! : username;

  @override
  String toString() => 'User(id: $id, username: $username, role: $role)';
}
