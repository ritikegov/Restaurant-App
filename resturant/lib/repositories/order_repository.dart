import '../core/database.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/order_model.dart';

class OrderRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<OrderModel?> createOrder({
    required int userId,
    required int tableId,
    required List<OrderItemModel> orderItems,
  }) async {
    try {
      if (orderItems.isEmpty) {
        throw Exception('Order must contain at least one item');
      }

      int totalAmountInPaise = 0;
      for (final item in orderItems) {
        totalAmountInPaise += item.totalPriceInPaise;
      }

      final order = OrderModel(
        userId: userId,
        tableId: tableId,
        totalAmountInPaise: totalAmountInPaise,
        orderTimeEpoch: AppUtils.getCurrentEpochTime(),
        status: AppConstants.orderStatusPending,
      );

      final orderId = await _databaseHelper.insert(
        AppConstants.ordersTable,
        order.toMap(),
      );

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

      await _databaseHelper.delete(
        AppConstants.orderItemsTable,
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

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
}
