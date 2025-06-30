import '../core/database.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/user_model.dart';

class UserRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<UserModel?> createUser(String username, String password) async {
    try {
      final existingUser = await getUserByUsername(username);
      if (existingUser != null) {
        throw Exception(AppConstants.errorUserExists);
      }

      final hashedPassword = AppUtils.hashPassword(password);

      final user = UserModel(
        username: username.trim(),
        password: hashedPassword,
        createdAtEpoch: AppUtils.getCurrentEpochTime(),
      );

      final id = await _databaseHelper.insert(
        AppConstants.usersTable,
        user.toMap(),
      );

      return user.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.usersTable,
        where: 'username = ?',
        whereArgs: [username.trim()],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return UserModel.fromMap(result.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get user by username: $e');
    }
  }

  Future<UserModel?> getUserById(int id) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.usersTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return UserModel.fromMap(result.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get user by ID: $e');
    }
  }

  Future<UserModel?> authenticateUser(String username, String password) async {
    try {
      final hashedPassword = AppUtils.hashPassword(password);

      final result = await _databaseHelper.query(
        AppConstants.usersTable,
        where: 'username = ? AND password = ?',
        whereArgs: [username.trim(), hashedPassword],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return UserModel.fromMap(result.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to authenticate user: $e');
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      if (user.id == null) {
        throw Exception('User ID is required for update');
      }

      final result = await _databaseHelper.update(
        AppConstants.usersTable,
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final result = await _databaseHelper.delete(
        AppConstants.usersTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.usersTable,
        orderBy: 'created_at_epoch DESC',
      );

      return result.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  Future<bool> usernameExists(String username) async {
    try {
      final user = await getUserByUsername(username);
      return user != null;
    } catch (e) {
      throw Exception('Failed to check username existence: $e');
    }
  }

  Future<bool> updatePassword(int userId, String newPassword) async {
    try {
      final hashedPassword = AppUtils.hashPassword(newPassword);

      final result = await _databaseHelper.update(
        AppConstants.usersTable,
        {'password': hashedPassword},
        where: 'id = ?',
        whereArgs: [userId],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }
}
