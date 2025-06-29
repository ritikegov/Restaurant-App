import 'package:flutter/material.dart';

class AppConstants {
  static const int totalTables = 8;
  static const int seatsPerTable = 4;

  static const int bookingDurationHours = 23;
  static const int checkinTimeoutMinutes = 30;
  static const int noShowTimeoutMinutes = 15;

  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  static const String timeZone = 'Asia/Kolkata';

  static const Color tableAvailableColor = Colors.green;
  static const Color tablePartiallyBookedColor = Colors.orange;
  static const Color tableMostlyBookedColor = Colors.yellow;
  static const Color tableFullyBookedColor = Colors.red;
  static const Color tableSingleSeatTakenColor = Colors.grey;

  static const String usersTable = 'users';
  static const String tablesTable = 'tables';
  static const String bookingsTable = 'bookings';
  static const String menuItemsTable = 'menu_items';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';

  static const int databaseVersion = 1;
  static const String databaseName = 'restaurant_app.db';

  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 20;
  static const int minUsernameLength = 3;

  static const String prefKeyUserId = 'user_id';
  static const String prefKeyUsername = 'username';
  static const String prefKeyIsLoggedIn = 'is_logged_in';

  static const String appName = 'Restaurant App';

  static const String errorUserExists = 'User already exists';
  static const String errorInvalidCredentials = 'Invalid username or password';
  static const String errorUsernameRequired = 'Username is required';
  static const String errorPasswordRequired = 'Password is required';
  static const String errorUsernameLength = 'Username must be 3-20 characters';
  static const String errorPasswordLength =
      'Password must be at least 6 characters';
  static const String errorTableNotAvailable = 'Table is not available';
  static const String errorUserAlreadyHasBooking =
      'You already have an active booking';
  static const String errorBookingNotFound = 'Booking not found';
  static const String errorNoActiveBooking = 'No active booking found';
  static const String errorCheckinRequired = 'Please check-in to place orders';
  static const String errorDatabaseOperation = 'Database operation failed';

  static const String successUserCreated = 'User created successfully';
  static const String successLoginSuccessful = 'Login successful';
  static const String successBookingCreated = 'Table booked successfully';
  static const String successBookingCancelled =
      'Booking cancelled successfully';
  static const String successBookingModified = 'Booking modified successfully';
  static const String successCheckedIn = 'Checked in successfully';
  static const String successCheckedOut = 'Checked out successfully';
  static const String successOrderPlaced = 'Order placed successfully';

  static const String bookingStatusActive = 'ACTIVE';
  static const String bookingStatusCheckedIn = 'CHECKED_IN';
  static const String bookingStatusCompleted = 'COMPLETED';
  static const String bookingStatusCancelled = 'CANCELLED';
  static const String bookingStatusNoShow = 'NO_SHOW';

  static const String orderStatusPending = 'PENDING';
  static const String orderStatusPreparing = 'PREPARING';
  static const String orderStatusReady = 'READY';
  static const String orderStatusServed = 'SERVED';
  static const String orderStatusCompleted = 'COMPLETED';

  static const String categoryAppetizers = 'Appetizers';
  static const String categoryMainCourse = 'Main Course';
  static const String categoryDesserts = 'Desserts';
  static const String categoryBeverages = 'Beverages';

  static const List<String> tableNames = [
    'Table 1',
    'Table 2',
    'Table 3',
    'Table 4',
    'Table 5',
    'Table 6',
    'Table 7',
    'Table 8',
  ];

  static const List<Map<String, dynamic>> sampleMenuItems = [
    {
      'name': 'Paneer Tikka',
      'price_in_paise': 25000,
      'description': 'Grilled cottage cheese with spices',
      'category': categoryAppetizers,
    },
    {
      'name': 'Chicken Wings',
      'price_in_paise': 30000,
      'description': 'Spicy chicken wings with sauce',
      'category': categoryAppetizers,
    },
    {
      'name': 'Butter Chicken',
      'price_in_paise': 45000,
      'description': 'Creamy tomato-based chicken curry',
      'category': categoryMainCourse,
    },
    {
      'name': 'Dal Makhani',
      'price_in_paise': 35000,
      'description': 'Rich and creamy black lentils',
      'category': categoryMainCourse,
    },
    {
      'name': 'Biryani',
      'price_in_paise': 40000,
      'description': 'Aromatic basmati rice with spices',
      'category': categoryMainCourse,
    },
    {
      'name': 'Gulab Jamun',
      'price_in_paise': 15000,
      'description': 'Sweet milk dumplings in syrup',
      'category': categoryDesserts,
    },
    {
      'name': 'Ice Cream',
      'price_in_paise': 12000,
      'description': 'Vanilla ice cream with toppings',
      'category': categoryDesserts,
    },
    {
      'name': 'Masala Chai',
      'price_in_paise': 5000,
      'description': 'Traditional Indian spiced tea',
      'category': categoryBeverages,
    },
    {
      'name': 'Fresh Lime Soda',
      'price_in_paise': 8000,
      'description': 'Refreshing lime soda with mint',
      'category': categoryBeverages,
    },
    {
      'name': 'Lassi',
      'price_in_paise': 10000,
      'description': 'Yogurt-based drink with flavors',
      'category': categoryBeverages,
    },
  ];
}

class TableColorHelper {
  static Color getTableColor(int availableSeats, int totalSeats) {
    if (availableSeats == totalSeats) {
      return AppConstants.tableAvailableColor;
    } else if (availableSeats == totalSeats - 1) {
      return AppConstants.tableSingleSeatTakenColor;
    } else if (availableSeats >= 1) {
      return AppConstants.tablePartiallyBookedColor;
    } else {
      return AppConstants.tableFullyBookedColor;
    }
  }

  static String getTableStatusText(int availableSeats, int totalSeats) {
    return '$availableSeats/$totalSeats available';
  }
}
