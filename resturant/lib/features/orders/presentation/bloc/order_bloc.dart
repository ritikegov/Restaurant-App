import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../shared/services/shared_preferences_service.dart';

// Events
abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object> get props => [];
}

class LoadOrderHistoryEvent extends OrderEvent {}

class LoadOrderItemsEvent extends OrderEvent {
  final int orderId;

  const LoadOrderItemsEvent({required this.orderId});

  @override
  List<Object> get props => [orderId];
}

// States
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderHistoryLoaded extends OrderState {
  final List<Map<String, dynamic>> orders;

  const OrderHistoryLoaded({required this.orders});

  @override
  List<Object> get props => [orders];
}

class OrderItemsLoaded extends OrderState {
  final List<Map<String, dynamic>> orderItems;
  final Map<String, dynamic> orderDetails;

  const OrderItemsLoaded(
      {required this.orderItems, required this.orderDetails});

  @override
  List<Object> get props => [orderItems, orderDetails];
}

class OrderFailure extends OrderState {
  final String message;

  const OrderFailure({required this.message});

  @override
  List<Object> get props => [message];
}

// BLoC
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final DatabaseHelper _databaseHelper;

  OrderBloc({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        super(OrderInitial()) {
    on<LoadOrderHistoryEvent>(_onLoadOrderHistory);
    on<LoadOrderItemsEvent>(_onLoadOrderItems);
  }

  Future<void> _onLoadOrderHistory(
      LoadOrderHistoryEvent event, Emitter<OrderState> emit) async {
    try {
      emit(OrderLoading());

      final userId = await SharedPreferencesService.getLoggedInUserId();
      if (userId == null) {
        emit(const OrderFailure(message: 'Please login first'));
        return;
      }

      final orders = await _databaseHelper.getUserOrders(userId);

      // Process orders to format dates and add additional info
      final processedOrders = orders.map((order) {
        final orderDate = DateTime.parse(order['order_date']);
        final formattedDate = _formatDate(orderDate);

        return {
          ...order,
          'formatted_date': formattedDate,
          'formatted_time': _formatTime(orderDate),
          'formatted_amount':
              '\$${(order['total_amount'] as double).toStringAsFixed(2)}',
        };
      }).toList();

      emit(OrderHistoryLoaded(orders: processedOrders));
    } catch (e) {
      emit(OrderFailure(
          message: 'Failed to load order history: ${e.toString()}'));
    }
  }

  Future<void> _onLoadOrderItems(
      LoadOrderItemsEvent event, Emitter<OrderState> emit) async {
    try {
      emit(OrderLoading());

      final orderItems = await _databaseHelper.getOrderItems(event.orderId);

      // Get order details
      final userId = await SharedPreferencesService.getLoggedInUserId();
      if (userId == null) {
        emit(const OrderFailure(message: 'Please login first'));
        return;
      }

      final orders = await _databaseHelper.getUserOrders(userId);
      final orderDetails = orders.firstWhere(
        (order) => order['id'] == event.orderId,
        orElse: () => {},
      );

      if (orderDetails.isEmpty) {
        emit(const OrderFailure(message: 'Order not found'));
        return;
      }

      // Process order items to add formatting
      final processedOrderItems = orderItems.map((item) {
        final totalPrice = (item['price'] as double);
        final quantity = item['quantity'] as int;
        final unitPrice = totalPrice / quantity;

        return {
          ...item,
          'formatted_unit_price': '\$${unitPrice.toStringAsFixed(2)}',
          'formatted_total_price': '\$${totalPrice.toStringAsFixed(2)}',
        };
      }).toList();

      // Process order details
      final orderDate = DateTime.parse(orderDetails['order_date']);
      final processedOrderDetails = {
        ...orderDetails,
        'formatted_date': _formatDate(orderDate),
        'formatted_time': _formatTime(orderDate),
        'formatted_amount':
            '\$${(orderDetails['total_amount'] as double).toStringAsFixed(2)}',
      };

      emit(OrderItemsLoaded(
        orderItems: processedOrderItems,
        orderDetails: processedOrderDetails,
      ));
    } catch (e) {
      emit(
          OrderFailure(message: 'Failed to load order items: ${e.toString()}'));
    }
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute $period';
  }
}
