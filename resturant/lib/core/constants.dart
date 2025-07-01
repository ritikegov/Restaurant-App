import 'package:flutter/material.dart';

class AppConstants {
  static const int totalTables = 8;
  static const int seatsPerTable = 4;

  static const int checkinTimeoutMinutes = 30;

  static const String currencySymbol = '₹';
  static const String exclamation = '!';

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
  static const String user = 'User';
  static const String loginUsername = 'Username';
  static const String loginPassword = 'Password';
  static const String userNotLogin = 'User not logged in';
  static const String login = 'Login';
  static const String loginFailed = 'Login failed:';
  static const String logoutFailed = 'Logout failed:';
  static const String home = 'Home';
  static const String signUp = 'Sign Up';
  static const String signUpFailed = 'Signup failed:';
  static const String refresh = 'Refresh';
  static const String welcome = 'Welcome';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirmPassword = 'Confirm Password';
  static const String confrimPasswordDescription =
      'Please confirm your password';
  static const String alreadyAccountDescription =
      'Already have an account? Login';
  static const String passwordNotMatch = 'Passwords do not match';
  static const String checkinSuccessMessage = 'Checked in successfully!';
  static const String errorCheckinMessage = 'Failed to check in';
  static const String checkoutSuccessMessage = 'Checked out successfully!';
  static const String errorCheckoutMessage = 'Failed to checkout';

  static const String appName = 'Mezbaan';

  static const String errorUserExists = 'User already exists';
  static const String errorInvalidCredentials = 'Invalid username or password';
  static const String errorUsernameRequired = 'Username is required';
  static const String errorPasswordRequired = 'Password is required';
  static const String errorCreateUserFailed = 'Failed to create user';
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
  static const String errorNavigation = 'Navigation error:';
  static const String errorLogin = 'Login error:';
  static const String errorValidation = 'Validation error';
  static const String errorDisplayTable = 'Error displaying table:';
  static const String errorTableLoading = 'Error Loading Tables';
  static const String errorBooking = 'Booking error:';
  static const String errorUserLoading = 'Error loading user info:';
  static const String errorBookingLoading = 'Error loading booking:';

  static const int noShowTimeoutMinutes = 15;

  static const String createAccount = 'Create Account';
  static const String singupMessage = 'Don\'t have an account? Sign up';
  static const String errorSignUp = 'Signup error:';
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

  static const String bookingTable = 'Book a Table';
  static const String bookingTableInfo = 'Booking Information';
  static const String bookingTableInfoMessage_1 =
      '• You can book only one seat at a time before checkout';
  static const String bookingTableInfoMessage_2 =
      '• You are eligible to rebook table after checkout';
  static const String booking = 'Book';
  static const String bookingSelectTable = 'Select a Table';
  static const String bookingAvailableTable = 'Available Tables';
  static const String bookingTableCapacity = 'Total Capacity:';
  static const String confirmBooking = 'Confirm Booking';
  static const String bookingDescription = 'confirm you booking ';
  static const String bookingNow = 'Book Now';
  static const String bookingModifiedMessage = 'Booking modified successfully!';
  static const String errorBookingModified = 'Failed to modify booking';

  static const String seat = 'seats';
  static const String noTableAvailable = 'No Tables Available';
  static const String noTableAvailableDescription =
      'All tables are currently full. Please try again later.';
  static const String tableSuccessMessage = 'Table booked successfully!';

  static const String orderStatusPending = 'PENDING';
  static const String orderStatusPreparing = 'PREPARING';
  static const String orderStatusReady = 'READY';
  static const String orderStatusServed = 'SERVED';
  static const String orderStatusCompleted = 'COMPLETED';

  static const String categoryAppetizers = 'Appetizers';
  static const String categoryMainCourse = 'Main Course';
  static const String categoryDesserts = 'Desserts';
  static const String categoryBeverages = 'Beverages';

  static const String loadingState = 'Loading tables...';

  static const String logout = 'Logout';
  static const String currentBooking = 'Current Booking';
  static const String table = 'Table';
  static const String booked = 'Booked';
  static const String checkIn = 'Check In';
  static const String orderFood = 'Order Food';
  static const String checkout = 'Checkout';
  static const String bookTable = 'Book Table';
  static const String reserveYourTable = 'Reserve your table';
  static const String menu = 'Menu';
  static const String browseOurDeliciousMenu = 'Browse our delicious menu';
  static const String orderHistory = 'Order History';
  static const String viewYourPastOrders = 'View your past orders';
  static const String profile = 'Profile';
  static const String manageYourAccount = 'Manage your account';
  static const String bookTablesOrderFood =
      'Book tables, order food, and enjoy your dining experience';

  static const String errorCheckingIn = 'Error checking in:';
  static const String errorCheckingOut = 'Error checking out:';
  static const String checkinFirstMessage =
      'You must check-in to place an order';
  static const String errorCreateBooking = 'Failed to create booking';
  static const String errorCancellingBooking = 'Error cancelling booking:';
  static const String errorCancelOrder = 'Failed to cancel order';
  static const String logoutError = 'Logout error:';
  static const String refreshError = 'Refresh error:';
  static const String unknown = 'Unknown';
  static const String confirmCheckout = 'Do you want to checkout';
  static const String yesCheckout = 'Yes, Checkout';
  static const String no = 'No';
  static const String cancelBooking = 'Cancel Booking';
  static const String confirmCancelBooking = 'Do you want to cancel booking';
  static const String bookingCancelMessage = 'Booking cancelled successfully!';
  static const String errorBookingCancel = 'Failed to cancel booking';
  static const String yes = 'Yes';
  static const String confirmLogout = 'Do you want to logout';
  static const String errorDisplayingBooking = 'Error displaying booking:';
  static const String failedToSaveSession = 'Failed to save user session:';
  static const String failedToClearSession = 'Failed to clear user session:';

  static const String loadingMenu = 'Loading menu...';
  static const String noMenuItems = 'No Menu Items';
  static const String menuIsEmpty = 'Menu is empty';
  static const String noItemsInCategory = 'No items in';
  static const String categoryText = 'category';
  static const String errorLoadingMenu = 'Error Loading Menu';
  static const String errorDisplayingItem = 'Error displaying item:';
  static const String all = 'All';

  static const String errorLoadingOrders = 'Error loading orders:';
  static const String loadingOrders = 'Loading orders...';
  static const String orderHistoryCount = 'Order History';
  static const String orderPrefix = 'Order #';
  static const String tablePrefix = 'Table ';
  static const String totalAmount = 'Total Amount';
  static const String viewDetails = 'View Details';
  static const String noOrdersYet = 'No Orders Yet';
  static const String noOrdersDescription =
      'You haven\'t placed any orders yet';
  static const String orderNow = 'Order Now';
  static const String errorLoadingOrdersTitle = 'Error Loading Orders';
  static const String errorDisplayingOrder = 'Error displaying order:';
  static const String confirmCancelOrder = 'Do you want to  cancel order #';
  static const String amount = 'Amount:';
  static const String cancelOrderNote =
      'Note: Only pending orders can be cancelled.';
  static const String yesCancelOrder = 'Yes, Cancel';
  static const String cancelError = 'Cancel error:';
  static const String orderDetailsTitle = 'Details';
  static const String orderSuccessMessage = 'Order placed successfully!';
  static const String orderFailedMessage = 'Failed to place order';
  static const String failedToLoadOrderHistory =
      'Failed to load order history:';
  static const String failedtoLoadCurrentOrder =
      'Failed to load current order:';
  static const String orderCancelSuccessMessage =
      'Order cancelled successfully';
  static const String orderTime = 'Order Time';
  static const String orderItems = 'Order Items:';
  static const String cancelOrder = 'cancelError';
  static const String orderStatusUpdate = 'Order status updated';
  static const String quantity = 'Qty:';
  static const String noItemsFound = 'No items found';
  static const String close = 'Close';
  static const String errorLoadingOrderDetails = 'Error loading order details:';

  static const String cart = 'Cart';
  static const String errorOrder = 'Error loading order:';
  static const String add = 'Add';
  static const String yourCartIsEmpty = 'Your cart is empty';
  static const String addSomeDeliciousItems =
      'Add some delicious items from the menu';
  static const String browseMenu = 'Browse Menu';
  static const String noMenuItemsAvailable = 'No menu items available';
  static const String loadingCart = 'Loading cart...';
  static const String total = 'Total';
  static const String totalItems = 'Total Items';
  static const String clearCart = 'Clear Cart';
  static const String placeOrder = 'Place Order';
  static const String confirmClearCart = 'Do you want to clear the cart';
  static const String clear = 'Clear';
  static const String confirmOrder = 'Confirm Order';
  static const String items = 'Items';
  static const String proceedWithOrder = 'Do you want to place the order';
  static const String orderPlaced = 'Order Placed!';
  static const String orderPlacedMessage =
      'Your order has been placed successfully.';
  static const String trackOrderMessage =
      'You can track your order in the Order History.';
  static const String continueOrdering = 'Continue Ordering';
  static const String viewOrder = 'View Order';

  static const String memberSince = 'Member since';
  static const String quickActions = 'Quick Actions';
  static const String recentActivity = 'Recent Activity';
  static const String lastOrder = 'Last Order:';
  static const String noOrdersYetProfile = 'No orders yet';
  static const String placeYourFirstOrder = 'Place your first order';
  static const String seeOurDeliciousOfferings = 'See our delicious offerings';
  static const String signOutOfYourAccount = 'Sign out of your account';
  static const String errorLoadingUserInfo = 'Error loading user info:';
  static const String today = 'Today';
  static const String failedUserLoad = 'Failed to load user booking:';
  static const String failedUserHistoryLoad = 'Failed to load booking history:';
  static const String failedMenuLoadMesage = 'Failed to load menu:';
  static const String failedRefreshMenu = 'Failed to refresh menu:';
  static const String failedToFilterMenu = 'Failed to filter menu:';
  static const String failedToLoadTable = 'Failed to load tables:';
  static const String failedToRefreshTable = 'Failed to refresh tables:';
  static const String failedToUpdateTable =
      'Failed to update table availability:';
  static const String failedToLoadCart = 'Failed to load cart:';
  static const String failedToAdd = 'Failed to add item:';
  static const String filedToRemoveItems = 'Failed to remove item:';
  static const String failedToUpdateItems = 'Failed to update quantity:';
  static const String failedToClearCart = 'Failed to clear cart:';
  static const String failedToUpdateOrderStatus =
      'Failed to update order status';
  static const String cartEmpty = 'Cart is empty';

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
