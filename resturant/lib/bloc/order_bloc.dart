import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/order_model.dart';
import '../models/menu_item_model.dart';
import '../repositories/order_repository.dart';

abstract class OrderEvent {}

class OrderLoadCart extends OrderEvent {}

class OrderAddItem extends OrderEvent {
  final MenuItemModel menuItem;
  final int quantity;

  OrderAddItem({required this.menuItem, required this.quantity});
}

class OrderRemoveItem extends OrderEvent {
  final int menuItemId;

  OrderRemoveItem({required this.menuItemId});
}

class OrderUpdateItemQuantity extends OrderEvent {
  final int menuItemId;
  final int quantity;

  OrderUpdateItemQuantity({required this.menuItemId, required this.quantity});
}

class OrderClearCart extends OrderEvent {}

class OrderPlaceOrder extends OrderEvent {
  final int userId;
  final int tableId;

  OrderPlaceOrder({required this.userId, required this.tableId});
}

class OrderLoadHistory extends OrderEvent {
  final int userId;

  OrderLoadHistory({required this.userId});
}

class OrderLoadCurrent extends OrderEvent {
  final int userId;

  OrderLoadCurrent({required this.userId});
}

class OrderCancel extends OrderEvent {
  final int orderId;
  final int userId;

  OrderCancel({required this.orderId, required this.userId});
}

class OrderUpdateStatus extends OrderEvent {
  final int orderId;
  final String status;

  OrderUpdateStatus({required this.orderId, required this.status});
}

class CartItem {
  final MenuItemModel menuItem;
  final int quantity;

  const CartItem({required this.menuItem, required this.quantity});

  CartItem copyWith({MenuItemModel? menuItem, int? quantity}) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
    );
  }

  int get totalPriceInPaise => menuItem.priceInPaise * quantity;
  double get totalPriceInRupees => totalPriceInPaise / 100.0;
}

abstract class OrderState {}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderCartLoaded extends OrderState {
  final List<CartItem> cartItems;
  final int totalAmountInPaise;

  OrderCartLoaded({required this.cartItems, required this.totalAmountInPaise});

  int get totalItems => cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmountInRupees => totalAmountInPaise / 100.0;
}

class OrderHistoryLoaded extends OrderState {
  final List<OrderModel> orders;
  final OrderModel? currentOrder;

  OrderHistoryLoaded({required this.orders, this.currentOrder});
}

class OrderSuccess extends OrderState {
  final String message;
  final OrderModel? order;

  OrderSuccess({required this.message, this.order});
}

class OrderError extends OrderState {
  final String message;

  OrderError({required this.message});
}

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository = OrderRepository();
  final List<CartItem> _cartItems = [];

  OrderBloc() : super(OrderInitial()) {
    on<OrderLoadCart>(_onLoadCart);
    on<OrderAddItem>(_onAddItem);
    on<OrderRemoveItem>(_onRemoveItem);
    on<OrderUpdateItemQuantity>(_onUpdateItemQuantity);
    on<OrderClearCart>(_onClearCart);
    on<OrderPlaceOrder>(_onPlaceOrder);
    on<OrderLoadHistory>(_onLoadHistory);
    on<OrderLoadCurrent>(_onLoadCurrent);
    on<OrderCancel>(_onCancelOrder);
    on<OrderUpdateStatus>(_onUpdateStatus);
  }

  Future<void> _onLoadCart(
      OrderLoadCart event, Emitter<OrderState> emit) async {
    try {
      final totalAmount = _calculateTotalAmount();
      emit(OrderCartLoaded(
        cartItems: List.from(_cartItems),
        totalAmountInPaise: totalAmount,
      ));
    } catch (e) {
      emit(OrderError(message: 'Failed to load cart: ${e.toString()}'));
    }
  }

  Future<void> _onAddItem(OrderAddItem event, Emitter<OrderState> emit) async {
    try {
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item.menuItem.id == event.menuItem.id,
      );

      if (existingItemIndex >= 0) {
        final existingItem = _cartItems[existingItemIndex];
        final newQuantity = existingItem.quantity + event.quantity;
        _cartItems[existingItemIndex] =
            existingItem.copyWith(quantity: newQuantity);
      } else {
        _cartItems.add(CartItem(
          menuItem: event.menuItem,
          quantity: event.quantity,
        ));
      }

      final totalAmount = _calculateTotalAmount();
      emit(OrderCartLoaded(
        cartItems: List.from(_cartItems),
        totalAmountInPaise: totalAmount,
      ));
    } catch (e) {
      emit(OrderError(message: 'Failed to add item: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveItem(
      OrderRemoveItem event, Emitter<OrderState> emit) async {
    try {
      _cartItems.removeWhere((item) => item.menuItem.id == event.menuItemId);

      final totalAmount = _calculateTotalAmount();
      emit(OrderCartLoaded(
        cartItems: List.from(_cartItems),
        totalAmountInPaise: totalAmount,
      ));
    } catch (e) {
      emit(OrderError(message: 'Failed to remove item: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateItemQuantity(
      OrderUpdateItemQuantity event, Emitter<OrderState> emit) async {
    try {
      final itemIndex = _cartItems.indexWhere(
        (item) => item.menuItem.id == event.menuItemId,
      );

      if (itemIndex >= 0) {
        if (event.quantity <= 0) {
          _cartItems.removeAt(itemIndex);
        } else {
          _cartItems[itemIndex] =
              _cartItems[itemIndex].copyWith(quantity: event.quantity);
        }
      }

      final totalAmount = _calculateTotalAmount();
      emit(OrderCartLoaded(
        cartItems: List.from(_cartItems),
        totalAmountInPaise: totalAmount,
      ));
    } catch (e) {
      emit(OrderError(message: 'Failed to update quantity: ${e.toString()}'));
    }
  }

  Future<void> _onClearCart(
      OrderClearCart event, Emitter<OrderState> emit) async {
    try {
      _cartItems.clear();
      emit(OrderCartLoaded(
        cartItems: [],
        totalAmountInPaise: 0,
      ));
    } catch (e) {
      emit(OrderError(message: 'Failed to clear cart: ${e.toString()}'));
    }
  }

  Future<void> _onPlaceOrder(
      OrderPlaceOrder event, Emitter<OrderState> emit) async {
    try {
      emit(OrderLoading());

      if (_cartItems.isEmpty) {
        emit(OrderError(message: 'Cart is empty'));
        return;
      }

      final canOrder = await _orderRepository.canUserPlaceOrder(event.userId);
      if (!canOrder) {
        emit(OrderError(message: 'You must check-in to place an order'));
        return;
      }

      final orderItems = _cartItems.map((cartItem) {
        return OrderItemModel(
          orderId: 0,
          menuItemId: cartItem.menuItem.id!,
          quantity: cartItem.quantity,
          priceInPaise: cartItem.menuItem.priceInPaise,
        );
      }).toList();

      final order = await _orderRepository.createOrder(
        userId: event.userId,
        tableId: event.tableId,
        orderItems: orderItems,
      );

      if (order != null) {
        _cartItems.clear();
        emit(OrderSuccess(
          message: 'Order placed successfully!',
          order: order,
        ));
      } else {
        emit(OrderError(message: 'Failed to place order'));
      }
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  Future<void> _onLoadHistory(
      OrderLoadHistory event, Emitter<OrderState> emit) async {
    try {
      emit(OrderLoading());

      final orders = await _orderRepository.getOrdersByUserId(event.userId);
      final currentOrder =
          await _orderRepository.getCurrentOrderForUser(event.userId);

      emit(OrderHistoryLoaded(
        orders: orders,
        currentOrder: currentOrder,
      ));
    } catch (e) {
      emit(
          OrderError(message: 'Failed to load order history: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCurrent(
      OrderLoadCurrent event, Emitter<OrderState> emit) async {
    try {
      final currentOrder =
          await _orderRepository.getCurrentOrderForUser(event.userId);
      final orders =
          await _orderRepository.getRecentOrders(event.userId, limit: 5);

      emit(OrderHistoryLoaded(
        orders: orders,
        currentOrder: currentOrder,
      ));
    } catch (e) {
      emit(
          OrderError(message: 'Failed to load current order: ${e.toString()}'));
    }
  }

  Future<void> _onCancelOrder(
      OrderCancel event, Emitter<OrderState> emit) async {
    try {
      emit(OrderLoading());

      final success =
          await _orderRepository.cancelOrder(event.orderId, event.userId);

      if (success) {
        emit(OrderSuccess(message: 'Order cancelled successfully'));

        add(OrderLoadHistory(userId: event.userId));
      } else {
        emit(OrderError(message: 'Failed to cancel order'));
      }
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  Future<void> _onUpdateStatus(
      OrderUpdateStatus event, Emitter<OrderState> emit) async {
    try {
      final success =
          await _orderRepository.updateOrderStatus(event.orderId, event.status);

      if (success) {
        emit(OrderSuccess(message: 'Order status updated'));
      } else {
        emit(OrderError(message: 'Failed to update order status'));
      }
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  int _calculateTotalAmount() {
    try {
      return _cartItems.fold(0, (sum, item) => sum + item.totalPriceInPaise);
    } catch (e) {
      return 0;
    }
  }

  List<CartItem> getCurrentCartItems() {
    return List.from(_cartItems);
  }

  int getCartItemCount() {
    try {
      return _cartItems.fold(0, (sum, item) => sum + item.quantity);
    } catch (e) {
      return 0;
    }
  }

  bool isCartEmpty() {
    return _cartItems.isEmpty;
  }

  CartItem? getCartItem(int menuItemId) {
    try {
      return _cartItems.firstWhere((item) => item.menuItem.id == menuItemId);
    } catch (e) {
      return null;
    }
  }

  int getItemQuantityInCart(int menuItemId) {
    try {
      final item = getCartItem(menuItemId);
      return item?.quantity ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
