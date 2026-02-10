class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
  });

  /// Verifica se o utilizador é staff (admin ou supporter)
  bool get isSupporter => role == 'admin' || role == 'support' || role == 'supporter';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper para garantir que o ID é sempre int, mesmo que venha string
    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return UserModel(
      id: parseId(json['id']),
      name: json['name']?.toString() ?? 'Sem Nome',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      role: json['role']?.toString() ?? 'customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role,
    };
  }
}