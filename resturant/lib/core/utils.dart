import 'package:flutter/material.dart';
import 'constants.dart';

class AppUtils {
  static String formatEpochToIST(int epochTime) {
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(epochTime);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  static int getCurrentEpochTime() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  static String formatPriceFromPaise(int priceInPaise) {
    try {
      final rupees = priceInPaise / 100;
      return '${AppConstants.currencySymbol}${rupees.toStringAsFixed(2)}';
    } catch (e) {
      return '${AppConstants.currencySymbol}0.00';
    }
  }

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

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return AppConstants.errorPasswordRequired;
    }

    if (password.length < AppConstants.minPasswordLength) {
      return AppConstants.errorPasswordLength;
    }

    return null;
  }

  static String hashPassword(String password) {
    try {
      return password.split('').map((char) => char.codeUnitAt(0)).join('');
    } catch (e) {
      return password;
    }
  }
}
