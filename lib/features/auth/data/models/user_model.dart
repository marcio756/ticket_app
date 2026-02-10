class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role;
  final int dailySupportSeconds;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.dailySupportSeconds = 0,
  });

  /// Verifica se o utilizador é staff (admin ou supporter)
  bool get isSupporter => role == 'admin' || role == 'support' || role == 'supporter';

  /// Helper para formatar o tempo restante
  String get formattedSupportTime {
    final duration = Duration(seconds: dailySupportSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds";
  }

  // [NOVO] Método copyWith para permitir atualizações imutáveis
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? role,
    int? dailySupportSeconds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      dailySupportSeconds: dailySupportSeconds ?? this.dailySupportSeconds,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    int parseInt(dynamic value) {
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
      dailySupportSeconds: parseInt(json['daily_support_seconds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role,
      'daily_support_seconds': dailySupportSeconds,
    };
  }
}