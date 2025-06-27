import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.databaseName);

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _createDatabase,
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    try {
      // Create Users table
      await db.execute('''
        CREATE TABLE ${AppConstants.tableUsers} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      // Create Tables table
      await db.execute('''
        CREATE TABLE ${AppConstants.tableTables} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_number INTEGER UNIQUE NOT NULL,
          capacity INTEGER NOT NULL,
          available_seats INTEGER NOT NULL,
          status TEXT NOT NULL,
          booked_by_user_id INTEGER,
          FOREIGN KEY (booked_by_user_id) REFERENCES ${AppConstants.tableUsers} (id)
        )
      ''');

      // Create Menu table
      await db.execute('''
        CREATE TABLE ${AppConstants.tableMenu} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_name TEXT NOT NULL,
          price REAL NOT NULL,
          description TEXT,
          category TEXT NOT NULL
        )
      ''');

      // Create Orders table
      await db.execute('''
        CREATE TABLE ${AppConstants.tableOrders} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          table_id INTEGER NOT NULL,
          total_amount REAL NOT NULL,
          order_date TEXT NOT NULL,
          status TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES ${AppConstants.tableUsers} (id),
          FOREIGN KEY (table_id) REFERENCES ${AppConstants.tableTables} (id)
        )
      ''');

      // Create Order Items table
      await db.execute('''
        CREATE TABLE ${AppConstants.tableOrderItems} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          menu_item_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          price REAL NOT NULL,
          FOREIGN KEY (order_id) REFERENCES ${AppConstants.tableOrders} (id),
          FOREIGN KEY (menu_item_id) REFERENCES ${AppConstants.tableMenu} (id)
        )
      ''');

      // Insert default tables
      await _insertDefaultTables(db);

      // Insert default menu items
      await _insertDefaultMenuItems(db);
    } catch (e) {
      throw Exception('Failed to create database tables: $e');
    }
  }

  Future<void> _insertDefaultTables(Database db) async {
    try {
      for (int i = 1; i <= AppConstants.totalTables; i++) {
        await db.insert(AppConstants.tableTables, {
          'table_number': i,
          'capacity': AppConstants.seatsPerTable,
          'available_seats': AppConstants.seatsPerTable,
          'status': AppConstants.tableStatusAvailable,
          'booked_by_user_id': null,
        });
      }
    } catch (e) {
      throw Exception('Failed to insert default tables: $e');
    }
  }

  Future<void> _insertDefaultMenuItems(Database db) async {
    try {
      final menuItems = [
        // Appetizers
        {
          'item_name': 'Chicken Wings',
          'price': 12.99,
          'description': 'Crispy chicken wings with buffalo sauce',
          'category': AppConstants.menuCategoryAppetizer,
        },
        {
          'item_name': 'Mozzarella Sticks',
          'price': 8.99,
          'description': 'Golden fried mozzarella with marinara sauce',
          'category': AppConstants.menuCategoryAppetizer,
        },
        {
          'item_name': 'Caesar Salad',
          'price': 9.99,
          'description': 'Fresh romaine lettuce with caesar dressing',
          'category': AppConstants.menuCategoryAppetizer,
        },

        // Main Course
        {
          'item_name': 'Grilled Chicken',
          'price': 18.99,
          'description': 'Grilled chicken breast with vegetables',
          'category': AppConstants.menuCategoryMainCourse,
        },
        {
          'item_name': 'Beef Steak',
          'price': 24.99,
          'description': 'Premium beef steak cooked to perfection',
          'category': AppConstants.menuCategoryMainCourse,
        },
        {
          'item_name': 'Salmon Fillet',
          'price': 22.99,
          'description': 'Fresh salmon with lemon herb seasoning',
          'category': AppConstants.menuCategoryMainCourse,
        },
        {
          'item_name': 'Pasta Carbonara',
          'price': 16.99,
          'description': 'Creamy pasta with bacon and parmesan',
          'category': AppConstants.menuCategoryMainCourse,
        },

        // Desserts
        {
          'item_name': 'Chocolate Cake',
          'price': 6.99,
          'description': 'Rich chocolate cake with cream',
          'category': AppConstants.menuCategoryDessert,
        },
        {
          'item_name': 'Ice Cream',
          'price': 4.99,
          'description': 'Vanilla ice cream with chocolate chips',
          'category': AppConstants.menuCategoryDessert,
        },

        // Beverages
        {
          'item_name': 'Coca Cola',
          'price': 2.99,
          'description': 'Refreshing cola drink',
          'category': AppConstants.menuCategoryBeverage,
        },
        {
          'item_name': 'Fresh Orange Juice',
          'price': 4.99,
          'description': 'Freshly squeezed orange juice',
          'category': AppConstants.menuCategoryBeverage,
        },
        {
          'item_name': 'Coffee',
          'price': 3.99,
          'description': 'Premium roasted coffee',
          'category': AppConstants.menuCategoryBeverage,
        },
      ];

      for (final item in menuItems) {
        await db.insert(AppConstants.tableMenu, item);
      }
    } catch (e) {
      throw Exception('Failed to insert default menu items: $e');
    }
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    try {
      final db = await database;
      return await db.insert(AppConstants.tableUsers, user);
    } catch (e) {
      throw Exception('Failed to insert user: $e');
    }
  }

  Future<Map<String, dynamic>?> getUser(
      String username, String password) async {
    try {
      final db = await database;
      final result = await db.query(
        AppConstants.tableUsers,
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<bool> userExists(String username) async {
    try {
      final db = await database;
      final result = await db.query(
        AppConstants.tableUsers,
        where: 'username = ?',
        whereArgs: [username],
      );
      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if user exists: $e');
    }
  }

  // Table operations
  Future<List<Map<String, dynamic>>> getAllTables() async {
    try {
      final db = await database;
      return await db.query(AppConstants.tableTables);
    } catch (e) {
      throw Exception('Failed to get tables: $e');
    }
  }

  Future<int> bookTable(int tableId, int userId) async {
    try {
      final db = await database;
      return await db.update(
        AppConstants.tableTables,
        {
          'booked_by_user_id': userId,
          'available_seats': AppConstants.seatsPerTable - 1,
          'status': AppConstants.tableStatusPartiallyOccupied,
        },
        where: 'id = ?',
        whereArgs: [tableId],
      );
    } catch (e) {
      throw Exception('Failed to book table: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserBookedTable(int userId) async {
    try {
      final db = await database;
      final result = await db.query(
        AppConstants.tableTables,
        where: 'booked_by_user_id = ?',
        whereArgs: [userId],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      throw Exception('Failed to get user booked table: $e');
    }
  }

  // Menu operations
  Future<List<Map<String, dynamic>>> getAllMenuItems() async {
    try {
      final db = await database;
      return await db.query(AppConstants.tableMenu);
    } catch (e) {
      throw Exception('Failed to get menu items: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMenuByCategory(String category) async {
    try {
      final db = await database;
      return await db.query(
        AppConstants.tableMenu,
        where: 'category = ?',
        whereArgs: [category],
      );
    } catch (e) {
      throw Exception('Failed to get menu by category: $e');
    }
  }

  // Order operations
  Future<int> insertOrder(Map<String, dynamic> order) async {
    try {
      final db = await database;
      return await db.insert(AppConstants.tableOrders, order);
    } catch (e) {
      throw Exception('Failed to insert order: $e');
    }
  }

  Future<int> insertOrderItem(Map<String, dynamic> orderItem) async {
    try {
      final db = await database;
      return await db.insert(AppConstants.tableOrderItems, orderItem);
    } catch (e) {
      throw Exception('Failed to insert order item: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserOrders(int userId) async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT o.*, t.table_number 
        FROM ${AppConstants.tableOrders} o
        JOIN ${AppConstants.tableTables} t ON o.table_id = t.id
        WHERE o.user_id = ?
        ORDER BY o.order_date DESC
      ''', [userId]);
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT oi.*, m.item_name, m.description
        FROM ${AppConstants.tableOrderItems} oi
        JOIN ${AppConstants.tableMenu} m ON oi.menu_item_id = m.id
        WHERE oi.order_id = ?
      ''', [orderId]);
    } catch (e) {
      throw Exception('Failed to get order items: $e');
    }
  }

  // Close database
  Future<void> close() async {
    try {
      final db = await database;
      await db.close();
    } catch (e) {
      throw Exception('Failed to close database: $e');
    }
  }
}
