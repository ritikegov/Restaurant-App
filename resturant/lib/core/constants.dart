import 'package:flutter/material.dart';

class AppConstants {
  // Table Configuration
  static const int totalTables = 8;
  static const int seatsPerTable = 4;

  // Timing Configuration (in hours)
  static const int bookingDurationHours = 23;
  static const int checkinTimeoutMinutes = 30;
  static const int noShowTimeoutMinutes = 15;

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // Time Zone
  static const String timeZone = 'Asia/Kolkata';

  // Colors for Table Status
  static const Color tableAvailableColor = Colors.green;
  static const Color tablePartiallyBookedColor = Colors.orange;
  static const Color tableMostlyBookedColor = Colors.yellow;
  static const Color tableFullyBookedColor = Colors.red;
  static const Color tableSingleSeatTakenColor = Colors.grey;

  // Database Table Names
  static const String usersTable = 'users';
  static const String tablesTable = 'tables';
  static const String bookingsTable = 'bookings';
  static const String menuItemsTable = 'menu_items';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';

  // Database Version
  static const int databaseVersion = 1;
  static const String databaseName = 'restaurant_app.db';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 20;
  static const int minUsernameLength = 3;

  // SharedPreferences Keys
  static const String prefKeyUserId = 'user_id';
  static const String prefKeyUsername = 'username';
  static const String prefKeyIsLoggedIn = 'is_logged_in';

  // App Strings
  static const String appName = 'Restaurant App';

  // Error Messages
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
  static const String errorCannotBookWithin23Hours =
      'You can book again after 23 hours from your last booking';
  static const String errorCheckinRequired = 'Please check-in to place orders';
  static const String errorDatabaseOperation = 'Database operation failed';

  // Success Messages
  static const String successUserCreated = 'User created successfully';
  static const String successLoginSuccessful = 'Login successful';
  static const String successBookingCreated = 'Table booked successfully';
  static const String successBookingCancelled =
      'Booking cancelled successfully';
  static const String successBookingModified = 'Booking modified successfully';
  static const String successCheckedIn = 'Checked in successfully';
  static const String successOrderPlaced = 'Order placed successfully';

  // Booking Status
  static const String bookingStatusActive = 'ACTIVE';
  static const String bookingStatusCheckedIn = 'CHECKED_IN';
  static const String bookingStatusCompleted = 'COMPLETED';
  static const String bookingStatusCancelled = 'CANCELLED';
  static const String bookingStatusNoShow = 'NO_SHOW';

  // Order Status
  static const String orderStatusPending = 'PENDING';
  static const String orderStatusPreparing = 'PREPARING';
  static const String orderStatusReady = 'READY';
  static const String orderStatusServed = 'SERVED';
  static const String orderStatusCompleted = 'COMPLETED';

  // Menu Categories
  static const String categoryAppetizers = 'Appetizers';
  static const String categoryMainCourse = 'Main Course';
  static const String categoryDesserts = 'Desserts';
  static const String categoryBeverages = 'Beverages';

  // Table Names List
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

  // Sample Menu Data
  static const List<Map<String, dynamic>> sampleMenuItems = [
    {
      'name': 'Paneer Tikka',
      'price_in_paise': 25000, // ₹250
      'description': 'Grilled cottage cheese with spices',
      'category': categoryAppetizers,
    },
    {
      'name': 'Chicken Wings',
      'price_in_paise': 30000, // ₹300
      'description': 'Spicy chicken wings with sauce',
      'category': categoryAppetizers,
    },
    {
      'name': 'Butter Chicken',
      'price_in_paise': 45000, // ₹450
      'description': 'Creamy tomato-based chicken curry',
      'category': categoryMainCourse,
    },
    {
      'name': 'Dal Makhani',
      'price_in_paise': 35000, // ₹350
      'description': 'Rich and creamy black lentils',
      'category': categoryMainCourse,
    },
    {
      'name': 'Biryani',
      'price_in_paise': 40000, // ₹400
      'description': 'Aromatic basmati rice with spices',
      'category': categoryMainCourse,
    },
    {
      'name': 'Gulab Jamun',
      'price_in_paise': 15000, // ₹150
      'description': 'Sweet milk dumplings in syrup',
      'category': categoryDesserts,
    },
    {
      'name': 'Ice Cream',
      'price_in_paise': 12000, // ₹120
      'description': 'Vanilla ice cream with toppings',
      'category': categoryDesserts,
    },
    {
      'name': 'Masala Chai',
      'price_in_paise': 5000, // ₹50
      'description': 'Traditional Indian spiced tea',
      'category': categoryBeverages,
    },
    {
      'name': 'Fresh Lime Soda',
      'price_in_paise': 8000, // ₹80
      'description': 'Refreshing lime soda with mint',
      'category': categoryBeverages,
    },
    {
      'name': 'Lassi',
      'price_in_paise': 10000, // ₹100
      'description': 'Yogurt-based drink with flavors',
      'category': categoryBeverages,
    },
  ];
}

// Helper class for color management
class TableColorHelper {
  static Color getTableColor(int availableSeats, int totalSeats) {
    if (availableSeats == totalSeats) {
      return AppConstants.tableAvailableColor; // All seats available - Green
    } else if (availableSeats == totalSeats - 1) {
      return AppConstants.tableSingleSeatTakenColor; // 1 seat taken - Gray
    } else if (availableSeats >= 1) {
      return AppConstants
          .tablePartiallyBookedColor; // 2-3 seats taken - Orange/Yellow
    } else {
      return AppConstants.tableFullyBookedColor; // No seats available - Red
    }
  }

  static String getTableStatusText(int availableSeats, int totalSeats) {
    return '$availableSeats/$totalSeats available';
  }
}
