import 'package:flutter/material.dart';
import 'constants.dart';

class AppUtils {
  // Convert epoch timestamp to formatted Indian time
  static String formatEpochToIST(int epochTime) {
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(epochTime);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Get current epoch time
  static int getCurrentEpochTime() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  // Convert paise to rupees string
  static String formatPriceFromPaise(int priceInPaise) {
    try {
      final rupees = priceInPaise / 100;
      return '${AppConstants.currencySymbol}${rupees.toStringAsFixed(2)}';
    } catch (e) {
      return '${AppConstants.currencySymbol}0.00';
    }
  }

  // Convert rupees to paise
  static int convertRupeesToPaise(double rupees) {
    try {
      return (rupees * 100).round();
    } catch (e) {
      return 0;
    }
  }

  // Check if booking is within 23 hours (only for completed bookings)
  static bool canBookTable(int? lastCompletedBookingEpoch) {
    if (lastCompletedBookingEpoch == null) return true;

    try {
      final now = getCurrentEpochTime();
      final difference = now - lastCompletedBookingEpoch;
      final hoursInMs = AppConstants.bookingDurationHours * 60 * 60 * 1000;
      return difference >= hoursInMs;
    } catch (e) {
      return true;
    }
  }

  // Check if booking has expired for check-in
  static bool hasBookingExpired(int bookingEpoch) {
    try {
      final now = getCurrentEpochTime();
      final difference = now - bookingEpoch;
      final timeoutInMs = AppConstants.checkinTimeoutMinutes * 60 * 1000;
      return difference > timeoutInMs;
    } catch (e) {
      return false;
    }
  }

  // Check if it's a no-show
  static bool isNoShow(int bookingEpoch) {
    try {
      final now = getCurrentEpochTime();
      final difference = now - bookingEpoch;
      final noShowTimeoutInMs = AppConstants.noShowTimeoutMinutes * 60 * 1000;
      return difference > noShowTimeoutInMs;
    } catch (e) {
      return false;
    }
  }

  // Show toast message
  static void showToast(BuildContext context, String message,
      {bool isError = false}) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('Error showing toast: $e');
    }
  }

  // Validate username
  static String? validateUsername(String? username) {
    if (username == null || username.trim().isEmpty) {
      return AppConstants.errorUsernameRequired;
    }

    final trimmedUsername = username.trim();
    if (trimmedUsername.length < AppConstants.minUsernameLength ||
        trimmedUsername.length > AppConstants.maxUsernameLength) {
      return AppConstants.errorUsernameLength;
    }

    return null;
  }

  // Validate password
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return AppConstants.errorPasswordRequired;
    }

    if (password.length < AppConstants.minPasswordLength) {
      return AppConstants.errorPasswordLength;
    }

    return null;
  }

  // Simple password hashing (for production, use proper hashing)
  static String hashPassword(String password) {
    try {
      return password.split('').map((char) => char.codeUnitAt(0)).join('');
    } catch (e) {
      return password;
    }
  }

  // Get time difference in hours
  static double getHoursDifference(int fromEpoch, int toEpoch) {
    try {
      final difference = toEpoch - fromEpoch;
      return difference / (1000 * 60 * 60);
    } catch (e) {
      return 0.0;
    }
  }

  // Get formatted time for booking
  static String getBookingTimeText(int epochTime) {
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(epochTime);
      final now = DateTime.now();

      if (dateTime.day == now.day &&
          dateTime.month == now.month &&
          dateTime.year == now.year) {
        return 'Today, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return formatEpochToIST(epochTime);
      }
    } catch (e) {
      return 'Invalid Time';
    }
  }

  // Generate unique order ID
  static String generateOrderId() {
    try {
      return 'ORD${getCurrentEpochTime()}';
    } catch (e) {
      return 'ORD${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Check if string is null or empty
  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  // Safe integer parsing
  static int safeParseInt(dynamic value, {int defaultValue = 0}) {
    try {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.parse(value);
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  // Safe double parsing
  static double safeParseDouble(dynamic value, {double defaultValue = 0.0}) {
    try {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.parse(value);
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
}
