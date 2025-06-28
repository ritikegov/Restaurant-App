import '../core/database.dart';
import '../core/constants.dart';
import '../models/menu_item_model.dart';

class MenuRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Get all menu items
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

  // Get menu item by ID
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

  // Get menu items by category
  Future<List<MenuItemModel>> getMenuItemsByCategory(String category) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.menuItemsTable,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'name ASC',
      );

      return result.map((map) => MenuItemModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get menu items by category: $e');
    }
  }

  // Get all categories
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

  // Add menu item
  Future<MenuItemModel?> addMenuItem(MenuItemModel menuItem) async {
    try {
      final id = await _databaseHelper.insert(
        AppConstants.menuItemsTable,
        menuItem.toMap(),
      );

      return menuItem.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to add menu item: $e');
    }
  }

  // Update menu item
  Future<bool> updateMenuItem(MenuItemModel menuItem) async {
    try {
      if (menuItem.id == null) {
        throw Exception('Menu item ID is required for update');
      }

      final result = await _databaseHelper.update(
        AppConstants.menuItemsTable,
        menuItem.toMap(),
        where: 'id = ?',
        whereArgs: [menuItem.id],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to update menu item: $e');
    }
  }

  // Delete menu item
  Future<bool> deleteMenuItem(int id) async {
    try {
      final result = await _databaseHelper.delete(
        AppConstants.menuItemsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to delete menu item: $e');
    }
  }

  // Search menu items
  Future<List<MenuItemModel>> searchMenuItems(String query) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.menuItemsTable,
        where: 'name LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );

      return result.map((map) => MenuItemModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to search menu items: $e');
    }
  }

  // Get menu items by price range
  Future<List<MenuItemModel>> getMenuItemsByPriceRange(
      int minPriceInPaise, int maxPriceInPaise) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.menuItemsTable,
        where: 'price_in_paise BETWEEN ? AND ?',
        whereArgs: [minPriceInPaise, maxPriceInPaise],
        orderBy: 'price_in_paise ASC',
      );

      return result.map((map) => MenuItemModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get menu items by price range: $e');
    }
  }

  // Get popular menu items (placeholder for future implementation)
  Future<List<MenuItemModel>> getPopularMenuItems({int limit = 10}) async {
    try {
      // For now, just return the first few items
      // In a real app, this could be based on order frequency
      final result = await _databaseHelper.query(
        AppConstants.menuItemsTable,
        orderBy: 'name ASC',
        limit: limit,
      );

      return result.map((map) => MenuItemModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get popular menu items: $e');
    }
  }
}
