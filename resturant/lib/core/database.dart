import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConstants.databaseName);

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      // Create Users table
      await db.execute('''
        CREATE TABLE ${AppConstants.usersTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          created_at_epoch INTEGER NOT NULL
        )
      ''');

      // Create Tables table
      await db.execute('''
        CREATE TABLE ${AppConstants.tablesTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          total_capacity INTEGER NOT NULL,
          available_seats INTEGER NOT NULL
        )
      ''');

      // Create Bookings table
      await db.execute('''
        CREATE TABLE ${AppConstants.bookingsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          table_id INTEGER NOT NULL,
          booking_time_epoch INTEGER NOT NULL,
          status TEXT NOT NULL,
          expires_at_epoch INTEGER,
          checked_in_at_epoch INTEGER,
          FOREIGN KEY (user_id) REFERENCES ${AppConstants.usersTable} (id),
          FOREIGN KEY (table_id) REFERENCES ${AppConstants.tablesTable} (id)
        )
      ''');

      // Create Menu Items table
      await db.execute('''
        CREATE TABLE ${AppConstants.menuItemsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price_in_paise INTEGER NOT NULL,
          description TEXT,
          category TEXT NOT NULL
        )
      ''');

      // Create Orders table
      await db.execute('''
        CREATE TABLE ${AppConstants.ordersTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          table_id INTEGER NOT NULL,
          total_amount_in_paise INTEGER NOT NULL,
          order_time_epoch INTEGER NOT NULL,
          status TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES ${AppConstants.usersTable} (id),
          FOREIGN KEY (table_id) REFERENCES ${AppConstants.tablesTable} (id)
        )
      ''');

      // Create Order Items table
      await db.execute('''
        CREATE TABLE ${AppConstants.orderItemsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          menu_item_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          price_in_paise INTEGER NOT NULL,
          FOREIGN KEY (order_id) REFERENCES ${AppConstants.ordersTable} (id),
          FOREIGN KEY (menu_item_id) REFERENCES ${AppConstants.menuItemsTable} (id)
        )
      ''');

      // Insert initial data
      await _insertInitialData(db);
    } catch (e) {
      throw Exception('Failed to create database tables: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      // Handle database upgrades here if needed in future
      if (oldVersion < 2) {
        // Example: ALTER TABLE statements for version 2
      }
    } catch (e) {
      throw Exception('Failed to upgrade database: $e');
    }
  }

  Future<void> _insertInitialData(Database db) async {
    try {
      // Insert Tables
      for (int i = 0; i < AppConstants.totalTables; i++) {
        await db.insert(AppConstants.tablesTable, {
          'name': AppConstants.tableNames[i],
          'total_capacity': AppConstants.seatsPerTable,
          'available_seats': AppConstants.seatsPerTable,
        });
      }

      // Insert Menu Items
      for (final item in AppConstants.sampleMenuItems) {
        await db.insert(AppConstants.menuItemsTable, item);
      }
    } catch (e) {
      throw Exception('Failed to insert initial data: $e');
    }
  }

  // Generic database operations
  Future<int> insert(String table, Map<String, dynamic> values) async {
    try {
      final db = await database;
      return await db.insert(table, values);
    } catch (e) {
      throw Exception('Failed to insert data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw Exception('Failed to query data: $e');
    }
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.update(table, values, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw Exception('Failed to update data: $e');
    }
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw Exception('Failed to delete data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<dynamic>? arguments]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      throw Exception('Failed to execute raw query: $e');
    }
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    try {
      final db = await database;
      return await db.rawInsert(sql, arguments);
    } catch (e) {
      throw Exception('Failed to execute raw insert: $e');
    }
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    try {
      final db = await database;
      return await db.rawUpdate(sql, arguments);
    } catch (e) {
      throw Exception('Failed to execute raw update: $e');
    }
  }

  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    try {
      final db = await database;
      return await db.rawDelete(sql, arguments);
    } catch (e) {
      throw Exception('Failed to execute raw delete: $e');
    }
  }

  Future<void> close() async {
    try {
      final db = await database;
      await db.close();
      _database = null;
    } catch (e) {
      throw Exception('Failed to close database: $e');
    }
  }

  // Helper method to reset database (for testing/development)
  Future<void> resetDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConstants.databaseName);

      // Close current database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Delete database file
      await deleteDatabase(path);

      // Reinitialize database
      _database = await _initDatabase();
    } catch (e) {
      throw Exception('Failed to reset database: $e');
    }
  }
}
