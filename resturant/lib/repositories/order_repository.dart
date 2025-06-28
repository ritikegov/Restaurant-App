import '../core/database.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/order_model.dart';

class OrderRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Create order with items
  Future<OrderModel?> createOrder({
    required int userId,
    required int tableId,
    required List<OrderItemModel> orderItems,
  }) async {
    try {
      if (orderItems.isEmpty) {
        throw Exception('Order must contain at least one item');
      }

      // Calculate total amount
      int totalAmountInPaise = 0;
      for (final item in orderItems) {
        totalAmountInPaise += item.totalPriceInPaise;
      }

      // Create order
      final order = OrderModel(
        userId: userId,
        tableId: tableId,
        totalAmountInPaise: totalAmountInPaise,
        orderTimeEpoch: AppUtils.getCurrentEpochTime(),
        status: AppConstants.orderStatusPending,
      );

      // Insert order
      final orderId = await _databaseHelper.insert(
        AppConstants.ordersTable,
        order.toMap(),
      );

      // Insert order items
      for (final item in orderItems) {
        final orderItemWithOrderId = item.copyWith(orderId: orderId);
        await _databaseHelper.insert(
          AppConstants.orderItemsTable,
          orderItemWithOrderId.toMap(),
        );
      }

      return order.copyWith(id: orderId);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(int id) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.ordersTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return OrderModel.fromMap(result.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get order by ID: $e');
    }
  }

  // Get orders by user ID
  Future<List<OrderModel>> getOrdersByUserId(int userId) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.ordersTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'order_time_epoch DESC',
      );

      return result.map((map) => OrderModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get orders by user ID: $e');
    }
  }

  // Get order items by order ID
  Future<List<OrderItemModel>> getOrderItemsByOrderId(int orderId) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.orderItemsTable,
        where: 'order_id = ?',
        whereArgs: [orderId],
        orderBy: 'id ASC',
      );

      return result.map((map) => OrderItemModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get order items: $e');
    }
  }

  // Get order with items and details
  Future<Map<String, dynamic>?> getOrderWithDetails(int orderId) async {
    try {
      final result = await _databaseHelper.rawQuery('''
        SELECT o.*, t.name as table_name, u.username
        FROM ${AppConstants.ordersTable} o
        JOIN ${AppConstants.tablesTable} t ON o.table_id = t.id
        JOIN ${AppConstants.usersTable} u ON o.user_id = u.id
        WHERE o.id = ?
      ''', [orderId]);

      if (result.isNotEmpty) {
        final orderData = Map<String, dynamic>.from(result.first);

        // Get order items with menu item details
        final itemsResult = await _databaseHelper.rawQuery('''
          SELECT oi.*, mi.name as item_name, mi.description as item_description
          FROM ${AppConstants.orderItemsTable} oi
          JOIN ${AppConstants.menuItemsTable} mi ON oi.menu_item_id = mi.id
          WHERE oi.order_id = ?
          ORDER BY oi.id ASC
        ''', [orderId]);

        orderData['items'] = itemsResult;
        return orderData;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get order with details: $e');
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final result = await _databaseHelper.update(
        AppConstants.ordersTable,
        {'status': status},
        where: 'id = ?',
        whereArgs: [orderId],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Cancel order (only if pending)
  Future<bool> cancelOrder(int orderId, int userId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      if (order.userId != userId) {
        throw Exception('Unauthorized to cancel this order');
      }

      if (!order.isPending) {
        throw Exception('Only pending orders can be cancelled');
      }

      // Delete order items first (foreign key constraint)
      await _databaseHelper.delete(
        AppConstants.orderItemsTable,
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      // Delete order
      final result = await _databaseHelper.delete(
        AppConstants.ordersTable,
        where: 'id = ? AND user_id = ?',
        whereArgs: [orderId, userId],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Get current order for user at table
  Future<OrderModel?> getCurrentOrderForUser(int userId) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.ordersTable,
        where: 'user_id = ? AND status IN (?, ?, ?)',
        whereArgs: [
          userId,
          AppConstants.orderStatusPending,
          AppConstants.orderStatusPreparing,
          AppConstants.orderStatusReady,
        ],
        orderBy: 'order_time_epoch DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        return OrderModel.fromMap(result.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get current order: $e');
    }
  }

  // Get order statistics for user
  Future<Map<String, dynamic>> getOrderStatistics(int userId) async {
    try {
      final result = await _databaseHelper.rawQuery('''
        SELECT 
          COUNT(*) as total_orders,
          SUM(total_amount_in_paise) as total_spent,
          AVG(total_amount_in_paise) as average_order_value,
          MAX(order_time_epoch) as last_order_time
        FROM ${AppConstants.ordersTable}
        WHERE user_id = ?
      ''', [userId]);

      if (result.isNotEmpty) {
        final data = result.first;
        return {
          'totalOrders': AppUtils.safeParseInt(data['total_orders']),
          'totalSpent': AppUtils.safeParseInt(data['total_spent']),
          'averageOrderValue':
              AppUtils.safeParseInt(data['average_order_value']),
          'lastOrderTime': AppUtils.safeParseInt(data['last_order_time']),
        };
      }

      return {
        'totalOrders': 0,
        'totalSpent': 0,
        'averageOrderValue': 0,
        'lastOrderTime': 0,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }

  // Get orders by status
  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.ordersTable,
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'order_time_epoch DESC',
      );

      return result.map((map) => OrderModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get orders by status: $e');
    }
  }

  // Get recent orders for user
  Future<List<OrderModel>> getRecentOrders(int userId, {int limit = 10}) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.ordersTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'order_time_epoch DESC',
        limit: limit,
      );

      return result.map((map) => OrderModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get recent orders: $e');
    }
  }

  // Check if user can place order (must have checked-in booking)
  Future<bool> canUserPlaceOrder(int userId) async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.bookingsTable,
        where: 'user_id = ? AND status = ?',
        whereArgs: [userId, AppConstants.bookingStatusCheckedIn],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check order eligibility: $e');
    }
  }

  // Get all orders (for admin purposes)
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final result = await _databaseHelper.query(
        AppConstants.ordersTable,
        orderBy: 'order_time_epoch DESC',
      );

      return result.map((map) => OrderModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all orders: $e');
    }
  }
}
