import '../core/database.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/booking_model.dart';
import 'table_repository.dart';

class BookingRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TableRepository _tableRepository = TableRepository();

  Future<BookingModel?> createBooking(int userId, int tableId) async {
    try {
      final existingBooking = await getActiveBookingByUserId(userId);
      if (existingBooking != null) {
        throw Exception(AppConstants.errorUserAlreadyHasBooking);
      }
      final hasSeats = await _tableRepository.hasAvailableSeats(tableId);
      if (!hasSeats) {
        throw Exception(AppConstants.errorTableNotAvailable);
      }

      final currentTime = AppUtils.getCurrentEpochTime();
      final expiryTime =
          currentTime + (AppConstants.checkinTimeoutMinutes * 60 * 1000);

      final booking = BookingModel(
        userId: userId,
        tableId: tableId,
        bookingTimeEpoch: currentTime,
        status: AppConstants.bookingStatusActive,
        expiresAtEpoch: expiryTime,
      );

      final id = await _databaseHelper.insert(
        AppConstants.bookingsTable,
        booking.toMap(),
      );

      await _tableRepository.bookTableSeat(tableId);

      return booking.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<BookingModel?> getBookingById(int id) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.bookingsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return BookingModel.fromMap(result.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get booking by ID: $e');
    }
  }

  Future<BookingModel?> getActiveBookingByUserId(int userId) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.bookingsTable,
        where: 'user_id = ? AND status IN (?, ?)',
        whereArgs: [
          userId,
          AppConstants.bookingStatusActive,
          AppConstants.bookingStatusCheckedIn
        ],
        orderBy: 'booking_time_epoch DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        return BookingModel.fromMap(result.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get active booking: $e');
    }
  }

  Future<bool> cancelBooking(int bookingId, int userId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception(AppConstants.errorBookingNotFound);
      }

      if (booking.userId != userId) {
        throw Exception('Unauthorized to cancel this booking');
      }

      if (booking.isCancelled || booking.isCompleted || booking.isNoShow) {
        throw Exception('Booking cannot be cancelled');
      }

      final result = await _databaseHelper.update(
        AppConstants.bookingsTable,
        {'status': AppConstants.bookingStatusCancelled},
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      if (result > 0) {
        await _tableRepository.cancelTableSeat(booking.tableId);
        return true;
      }

      return false;
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  Future<bool> checkinBooking(int bookingId, int userId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception(AppConstants.errorBookingNotFound);
      }

      if (booking.userId != userId) {
        throw Exception('Unauthorized to check-in this booking');
      }

      if (!booking.isActive) {
        throw Exception('Only active bookings can be checked in');
      }

      if (AppUtils.hasBookingExpired(booking.bookingTimeEpoch)) {
        await _markAsNoShow(bookingId, booking.tableId);
        throw Exception('Booking has expired');
      }

      final result = await _databaseHelper.update(
        AppConstants.bookingsTable,
        {
          'status': AppConstants.bookingStatusCheckedIn,
          'checked_in_at_epoch': AppUtils.getCurrentEpochTime(),
        },
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to check-in booking: $e');
    }
  }

  Future<bool> modifyBooking(int bookingId, int userId, int newTableId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception(AppConstants.errorBookingNotFound);
      }

      if (booking.userId != userId) {
        throw Exception('Unauthorized to modify this booking');
      }

      if (!booking.isActive) {
        throw Exception('Only active bookings can be modified');
      }

      final hasSeats = await _tableRepository.hasAvailableSeats(newTableId);
      if (!hasSeats) {
        throw Exception(AppConstants.errorTableNotAvailable);
      }

      if (booking.tableId == newTableId) {
        return true;
      }

      await _tableRepository.cancelTableSeat(booking.tableId);

      await _tableRepository.bookTableSeat(newTableId);

      final result = await _databaseHelper.update(
        AppConstants.bookingsTable,
        {'table_id': newTableId},
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      if (result == 0) {
        await _tableRepository.bookTableSeat(booking.tableId);
        await _tableRepository.cancelTableSeat(newTableId);
        throw Exception('Failed to update booking');
      }

      return true;
    } catch (e) {
      throw Exception('Failed to modify booking: $e');
    }
  }

  Future<bool> checkoutBooking(int bookingId, int userId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception(AppConstants.errorBookingNotFound);
      }

      if (booking.userId != userId) {
        throw Exception('Unauthorized to checkout this booking');
      }

      if (!booking.isCheckedIn) {
        throw Exception('Booking must be checked in to checkout');
      }

      final result = await _databaseHelper.update(
        AppConstants.bookingsTable,
        {'status': AppConstants.bookingStatusCompleted},
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      if (result > 0) {
        await _tableRepository.cancelTableSeat(booking.tableId);
        return true;
      }

      return false;
    } catch (e) {
      throw Exception('Failed to checkout booking: $e');
    }
  }

  Future<bool> _markAsNoShow(int bookingId, int tableId) async {
    try {
      final result = await _databaseHelper.update(
        AppConstants.bookingsTable,
        {'status': AppConstants.bookingStatusNoShow},
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      if (result > 0) {
        await _tableRepository.cancelTableSeat(tableId);
        return true;
      }

      return false;
    } catch (e) {
      throw Exception('Failed to mark as no-show: $e');
    }
  }

  Future<List<BookingModel>> getBookingsByUserId(int userId) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.bookingsTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'booking_time_epoch DESC',
      );

      return result.map((map) => BookingModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get bookings by user ID: $e');
    }
  }

  Future<void> handleExpiredBookings() async {
    try {
      final activeBookings = await _databaseHelper.query(
        AppConstants.bookingsTable,
        where: 'status = ?',
        whereArgs: [AppConstants.bookingStatusActive],
      );

      for (final bookingMap in activeBookings) {
        final booking = BookingModel.fromMap(bookingMap);

        if (AppUtils.isNoShow(booking.bookingTimeEpoch)) {
          await _markAsNoShow(booking.id!, booking.tableId);
        }
      }
    } catch (e) {
      throw Exception('Failed to handle expired bookings: $e');
    }
  }

  Future<Map<String, dynamic>?> getBookingWithDetails(int bookingId) async {
    try {
      final result = await _databaseHelper.rawQuery('''
        SELECT b.*, t.name as table_name, u.username
        FROM ${AppConstants.bookingsTable} b
        JOIN ${AppConstants.tablesTable} t ON b.table_id = t.id
        JOIN ${AppConstants.usersTable} u ON b.user_id = u.id
        WHERE b.id = ?
      ''', [bookingId]);

      if (result.isNotEmpty) {
        return result.first;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get booking with details: $e');
    }
  }
}
