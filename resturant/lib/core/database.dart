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
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE ${AppConstants.usersTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          created_at_epoch INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE ${AppConstants.tablesTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          total_capacity INTEGER NOT NULL,
          available_seats INTEGER NOT NULL
        )
      ''');

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

      await db.execute('''
        CREATE TABLE ${AppConstants.menuItemsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price_in_paise INTEGER NOT NULL,
          description TEXT,
          category TEXT NOT NULL
        )
      ''');

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

      await _insertInitialData(db);
    } catch (e) {
      throw Exception('Failed to create database tables: $e');
    }
  }

  Future<void> _insertInitialData(Database db) async {
    try {
      for (int i = 0; i < AppConstants.totalTables; i++) {
        await db.insert(AppConstants.tablesTable, {
          'name': AppConstants.tableNames[i],
          'total_capacity': AppConstants.seatsPerTable,
          'available_seats': AppConstants.seatsPerTable,
        });
      }

      for (final item in AppConstants.sampleMenuItems) {
        await db.insert(AppConstants.menuItemsTable, item);
      }
    } catch (e) {
      throw Exception('Failed to insert initial data: $e');
    }
  }

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

  Future<void> close() async {
    try {
      final db = await database;
      await db.close();
      _database = null;
    } catch (e) {
      throw Exception('Failed to close database: $e');
    }
  }
}
