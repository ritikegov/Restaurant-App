import '../core/database.dart';
import '../core/constants.dart';
import '../models/table_model.dart';

class TableRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<List<TableModel>> getAllTables() async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.tablesTable,
        orderBy: 'id ASC',
      );

      return result.map((map) => TableModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all tables: $e');
    }
  }

  Future<TableModel?> getTableById(int id) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.tablesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return TableModel.fromMap(result.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get table by ID: $e');
    }
  }

  Future<bool> updateTableAvailability(int tableId, int availableSeats) async {
    try {
      final result = await _databaseHelper.update(
        AppConstants.tablesTable,
        {'available_seats': availableSeats},
        where: 'id = ?',
        whereArgs: [tableId],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to update table availability: $e');
    }
  }

  Future<bool> bookTableSeat(int tableId) async {
    try {
      final table = await getTableById(tableId);
      if (table == null) {
        throw Exception('Table not found');
      }

      if (table.availableSeats <= 0) {
        throw Exception(AppConstants.errorTableNotAvailable);
      }

      final newAvailableSeats = table.availableSeats - 1;
      return await updateTableAvailability(tableId, newAvailableSeats);
    } catch (e) {
      throw Exception('Failed to book table seat: $e');
    }
  }

  Future<bool> cancelTableSeat(int tableId) async {
    try {
      final table = await getTableById(tableId);
      if (table == null) {
        throw Exception('Table not found');
      }

      if (table.availableSeats >= table.totalCapacity) {
        return true;
      }

      final newAvailableSeats = table.availableSeats + 1;
      return await updateTableAvailability(tableId, newAvailableSeats);
    } catch (e) {
      throw Exception('Failed to cancel table seat: $e');
    }
  }

  Future<bool> hasAvailableSeats(int tableId) async {
    try {
      final table = await getTableById(tableId);
      return table?.availableSeats != null && table!.availableSeats > 0;
    } catch (e) {
      throw Exception('Failed to check table availability: $e');
    }
  }
}
