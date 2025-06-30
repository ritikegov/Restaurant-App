import '../core/constants.dart';

class BookingModel {
  final int? id;
  final int userId;
  final int tableId;
  final int bookingTimeEpoch;
  final String status;
  final int? expiresAtEpoch;
  final int? checkedInAtEpoch;

  const BookingModel({
    this.id,
    required this.userId,
    required this.tableId,
    required this.bookingTimeEpoch,
    required this.status,
    this.expiresAtEpoch,
    this.checkedInAtEpoch,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    try {
      return BookingModel(
        id: map['id'] as int?,
        userId: map['user_id'] as int? ?? 0,
        tableId: map['table_id'] as int? ?? 0,
        bookingTimeEpoch: map['booking_time_epoch'] as int? ?? 0,
        status: map['status'] as String? ?? AppConstants.bookingStatusActive,
        expiresAtEpoch: map['expires_at_epoch'] as int?,
        checkedInAtEpoch: map['checked_in_at_epoch'] as int?,
      );
    } catch (e) {
      throw Exception('Failed to create BookingModel from map: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      final map = <String, dynamic>{
        'user_id': userId,
        'table_id': tableId,
        'booking_time_epoch': bookingTimeEpoch,
        'status': status,
        'expires_at_epoch': expiresAtEpoch,
        'checked_in_at_epoch': checkedInAtEpoch,
      };

      if (id != null) {
        map['id'] = id;
      }

      return map;
    } catch (e) {
      throw Exception('Failed to convert BookingModel to map: $e');
    }
  }

  BookingModel copyWith({
    int? id,
    int? userId,
    int? tableId,
    int? bookingTimeEpoch,
    String? status,
    int? expiresAtEpoch,
    int? checkedInAtEpoch,
  }) {
    try {
      return BookingModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        tableId: tableId ?? this.tableId,
        bookingTimeEpoch: bookingTimeEpoch ?? this.bookingTimeEpoch,
        status: status ?? this.status,
        expiresAtEpoch: expiresAtEpoch ?? this.expiresAtEpoch,
        checkedInAtEpoch: checkedInAtEpoch ?? this.checkedInAtEpoch,
      );
    } catch (e) {
      throw Exception('Failed to copy BookingModel: $e');
    }
  }

  bool get isActive => status == AppConstants.bookingStatusActive;
  bool get isCheckedIn => status == AppConstants.bookingStatusCheckedIn;
  bool get isCompleted => status == AppConstants.bookingStatusCompleted;
  bool get isCancelled => status == AppConstants.bookingStatusCancelled;
  bool get isNoShow => status == AppConstants.bookingStatusNoShow;

  @override
  String toString() {
    return 'BookingModel(id: $id, userId: $userId, tableId: $tableId, bookingTimeEpoch: $bookingTimeEpoch, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingModel &&
        other.id == id &&
        other.userId == userId &&
        other.tableId == tableId &&
        other.bookingTimeEpoch == bookingTimeEpoch &&
        other.status == status &&
        other.expiresAtEpoch == expiresAtEpoch &&
        other.checkedInAtEpoch == checkedInAtEpoch;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        tableId.hashCode ^
        bookingTimeEpoch.hashCode ^
        status.hashCode ^
        expiresAtEpoch.hashCode ^
        checkedInAtEpoch.hashCode;
  }
}
