import '../core/database.dart';
import '../core/constants.dart';
import '../models/table_model.dart';

class TableRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Get all tables
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

  // Get table by ID
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

  // Update table availability
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

  // Book a seat at table (decrease available seats)
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

  // Cancel booking (increase available seats)
  Future<bool> cancelTableSeat(int tableId) async {
    try {
      final table = await getTableById(tableId);
      if (table == null) {
        throw Exception('Table not found');
      }

      if (table.availableSeats >= table.totalCapacity) {
        return true; // Already at full capacity
      }

      final newAvailableSeats = table.availableSeats + 1;
      return await updateTableAvailability(tableId, newAvailableSeats);
    } catch (e) {
      throw Exception('Failed to cancel table seat: $e');
    }
  }

  // Get available tables (tables with at least one available seat)
  Future<List<TableModel>> getAvailableTables() async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.tablesTable,
        where: 'available_seats > 0',
        orderBy: 'id ASC',
      );

      return result.map((map) => TableModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get available tables: $e');
    }
  }

  // Get tables by availability status
  Future<List<TableModel>> getTablesByAvailability({
    bool? isFullyAvailable,
    bool? isPartiallyAvailable,
    bool? isFullyBooked,
  }) async {
    try {
      String? whereClause;

      if (isFullyAvailable == true) {
        whereClause = 'available_seats = total_capacity';
      } else if (isPartiallyAvailable == true) {
        whereClause =
            'available_seats > 0 AND available_seats < total_capacity';
      } else if (isFullyBooked == true) {
        whereClause = 'available_seats = 0';
      }

      final result = await _databaseHelper.query(
        AppConstants.tablesTable,
        where: whereClause,
        orderBy: 'id ASC',
      );

      return result.map((map) => TableModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get tables by availability: $e');
    }
  }

  // Reset all tables to full availability (for testing/admin purposes)
  Future<bool> resetAllTables() async {
    try {
      final result = await _databaseHelper.update(
        AppConstants.tablesTable,
        {'available_seats': AppConstants.seatsPerTable},
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to reset all tables: $e');
    }
  }

  // Get table statistics
  Future<Map<String, int>> getTableStatistics() async {
    try {
      final tables = await getAllTables();

      int totalTables = tables.length;
      int fullyAvailable = 0;
      int partiallyBooked = 0;
      int fullyBooked = 0;
      int totalAvailableSeats = 0;
      int totalBookedSeats = 0;

      for (final table in tables) {
        totalAvailableSeats += table.availableSeats;
        totalBookedSeats += table.bookedSeats;

        if (table.availableSeats == table.totalCapacity) {
          fullyAvailable++;
        } else if (table.availableSeats > 0) {
          partiallyBooked++;
        } else {
          fullyBooked++;
        }
      }

      return {
        'totalTables': totalTables,
        'fullyAvailable': fullyAvailable,
        'partiallyBooked': partiallyBooked,
        'fullyBooked': fullyBooked,
        'totalAvailableSeats': totalAvailableSeats,
        'totalBookedSeats': totalBookedSeats,
      };
    } catch (e) {
      throw Exception('Failed to get table statistics: $e');
    }
  }

  // Check if table has available seats
  Future<bool> hasAvailableSeats(int tableId) async {
    try {
      final table = await getTableById(tableId);
      return table?.availableSeats != null && table!.availableSeats > 0;
    } catch (e) {
      throw Exception('Failed to check table availability: $e');
    }
  }

  // Get table with booking info
  Future<Map<String, dynamic>?> getTableWithBookingInfo(int tableId) async {
    try {
      final result = await _databaseHelper.rawQuery('''
        SELECT t.*, 
               COUNT(b.id) as active_bookings,
               GROUP_CONCAT(u.username) as booked_by_users
        FROM ${AppConstants.tablesTable} t
        LEFT JOIN ${AppConstants.bookingsTable} b ON t.id = b.table_id 
                  AND b.status IN ('${AppConstants.bookingStatusActive}', '${AppConstants.bookingStatusCheckedIn}')
        LEFT JOIN ${AppConstants.usersTable} u ON b.user_id = u.id
        WHERE t.id = ?
        GROUP BY t.id
      ''', [tableId]);

      if (result.isNotEmpty) {
        return result.first;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get table with booking info: $e');
    }
  }
}
