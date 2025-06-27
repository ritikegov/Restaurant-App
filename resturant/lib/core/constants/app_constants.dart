class AppConstants {
  // Database Constants
  static const String databaseName = 'restaurant.db';
  static const int databaseVersion = 1;

  // Table Constants
  static const int totalTables = 8;
  static const int seatsPerTable = 4;

  // Table Status Colors
  static const String tableStatusAvailable = 'available';
  static const String tableStatusPartiallyOccupied = 'partially_occupied';
  static const String tableStatusFullyOccupied = 'fully_occupied';

  // SharedPreferences Keys
  static const String keyLoggedInUser = 'logged_in_user';
  static const String keyUserBookedTable = 'user_booked_table';

  // Toast Messages
  static const String userAlreadyExists = 'User already exists!';
  static const String invalidCredentials = 'Invalid username or password!';
  static const String loginSuccessful = 'Login successful!';
  static const String registrationSuccessful = 'Registration successful!';
  static const String tableBookedSuccessfully = 'Table booked successfully!';
  static const String tableAlreadyBooked = 'Table already booked!';
  static const String userAlreadyHasTable = 'You already have a table booked!';
  static const String noActiveBooking = 'No active table booking found!';
  static const String orderPlacedSuccessfully = 'Order placed successfully!';

  // Database Tables
  static const String tableUsers = 'users';
  static const String tableTables = 'tables';
  static const String tableMenu = 'menu';
  static const String tableOrders = 'orders';
  static const String tableOrderItems = 'order_items';

  // Menu Categories
  static const String menuCategoryAppetizer = 'Appetizer';
  static const String menuCategoryMainCourse = 'Main Course';
  static const String menuCategoryDessert = 'Dessert';
  static const String menuCategoryBeverage = 'Beverage';

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusDelivered = 'delivered';

  // Validation Messages
  static const String emptyUsernameError = 'Username cannot be empty';
  static const String emptyPasswordError = 'Password cannot be empty';
  static const String usernameMinLengthError =
      'Username must be at least 3 characters';
  static const String passwordMinLengthError =
      'Password must be at least 6 characters';

  // App Strings
  static const String appName = 'Restaurant App';
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String username = 'Username';
  static const String password = 'Password';
  static const String bookTable = 'Book Table';
  static const String viewMenu = 'View Menu';
  static const String myOrders = 'My Orders';
  static const String logout = 'Logout';
  static const String availableSeats = 'Available Seats';
  static const String totalCapacity = 'Total Capacity';
  static const String bookNow = 'Book Now';
  static const String addToOrder = 'Add to Order';
  static const String placeOrder = 'Place Order';
  static const String orderHistory = 'Order History';
  static const String tables = 'Tables';
  static const String menu = 'Menu';
  static const String orders = 'Orders';
}
