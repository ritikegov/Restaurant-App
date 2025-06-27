import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class SharedPreferencesService {
  static SharedPreferences? _preferences;

  static Future<void> init() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
    } catch (e) {
      throw Exception('Failed to initialize SharedPreferences: $e');
    }
  }

  // User login state
  static Future<bool> setLoggedInUser(Map<String, dynamic> user) async {
    try {
      await init();
      final success =
          await _preferences!.setInt(AppConstants.keyLoggedInUser, user['id']);
      if (success) {
        await _preferences!.setString('logged_in_username', user['username']);
      }
      return success;
    } catch (e) {
      throw Exception('Failed to set logged in user: $e');
    }
  }

  static Future<int?> getLoggedInUserId() async {
    try {
      await init();
      return _preferences!.getInt(AppConstants.keyLoggedInUser);
    } catch (e) {
      throw Exception('Failed to get logged in user ID: $e');
    }
  }

  static Future<String?> getLoggedInUsername() async {
    try {
      await init();
      return _preferences!.getString('logged_in_username');
    } catch (e) {
      throw Exception('Failed to get logged in username: $e');
    }
  }

  static Future<bool> isUserLoggedIn() async {
    try {
      await init();
      return _preferences!.containsKey(AppConstants.keyLoggedInUser);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> logout() async {
    try {
      await init();
      final success1 = await _preferences!.remove(AppConstants.keyLoggedInUser);
      final success2 = await _preferences!.remove('logged_in_username');
      final success3 =
          await _preferences!.remove(AppConstants.keyUserBookedTable);
      return success1 && success2 && success3;
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  // Table booking state
  static Future<bool> setUserBookedTable(int tableId) async {
    try {
      await init();
      return await _preferences!
          .setInt(AppConstants.keyUserBookedTable, tableId);
    } catch (e) {
      throw Exception('Failed to set user booked table: $e');
    }
  }

  static Future<int?> getUserBookedTable() async {
    try {
      await init();
      return _preferences!.getInt(AppConstants.keyUserBookedTable);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> hasUserBookedTable() async {
    try {
      await init();
      return _preferences!.containsKey(AppConstants.keyUserBookedTable);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeUserBookedTable() async {
    try {
      await init();
      return await _preferences!.remove(AppConstants.keyUserBookedTable);
    } catch (e) {
      throw Exception('Failed to remove user booked table: $e');
    }
  }

  // Clear all preferences
  static Future<bool> clearAll() async {
    try {
      await init();
      return await _preferences!.clear();
    } catch (e) {
      throw Exception('Failed to clear all preferences: $e');
    }
  }
}
