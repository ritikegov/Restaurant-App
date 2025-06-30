class UserModel {
  final int? id;
  final String username;
  final String password;
  final int createdAtEpoch;

  const UserModel({
    this.id,
    required this.username,
    required this.password,
    required this.createdAtEpoch,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      return UserModel(
        id: map['id'] as int?,
        username: map['username'] as String? ?? '',
        password: map['password'] as String? ?? '',
        createdAtEpoch: map['created_at_epoch'] as int? ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to create UserModel from map: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      final map = <String, dynamic>{
        'username': username,
        'password': password,
        'created_at_epoch': createdAtEpoch,
      };

      if (id != null) {
        map['id'] = id;
      }

      return map;
    } catch (e) {
      throw Exception('Failed to convert UserModel to map: $e');
    }
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? password,
    int? createdAtEpoch,
  }) {
    try {
      return UserModel(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password ?? this.password,
        createdAtEpoch: createdAtEpoch ?? this.createdAtEpoch,
      );
    } catch (e) {
      throw Exception('Failed to copy UserModel: $e');
    }
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, createdAtEpoch: $createdAtEpoch)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.username == username &&
        other.password == password &&
        other.createdAtEpoch == createdAtEpoch;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        password.hashCode ^
        createdAtEpoch.hashCode;
  }
}
