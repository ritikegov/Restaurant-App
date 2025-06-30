import '../core/database.dart';
import '../core/constants.dart';
import '../models/menu_item_model.dart';

class MenuRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<List<MenuItemModel>> getAllMenuItems() async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.menuItemsTable,
        orderBy: 'category ASC, name ASC',
      );

      return result.map((map) => MenuItemModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all menu items: $e');
    }
  }

  Future<MenuItemModel?> getMenuItemById(int id) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.menuItemsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return MenuItemModel.fromMap(result.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get menu item by ID: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final result = await _databaseHelper.rawQuery('''
        SELECT DISTINCT category 
        FROM ${AppConstants.menuItemsTable} 
        ORDER BY category ASC
      ''');

      return result.map((row) => row['category'] as String).toList();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }
}
