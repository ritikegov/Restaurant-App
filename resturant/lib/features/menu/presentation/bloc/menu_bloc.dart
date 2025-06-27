import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../shared/services/shared_preferences_service.dart';
import '../../../../core/constants/app_constants.dart';

// Events
abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object> get props => [];
}

class LoadMenuEvent extends MenuEvent {}

class LoadMenuByCategoryEvent extends MenuEvent {
  final String category;

  const LoadMenuByCategoryEvent({required this.category});

  @override
  List<Object> get props => [category];
}

class AddToOrderEvent extends MenuEvent {
  final Map<String, dynamic> menuItem;
  final int quantity;

  const AddToOrderEvent({required this.menuItem, required this.quantity});

  @override
  List<Object> get props => [menuItem, quantity];
}

class RemoveFromOrderEvent extends MenuEvent {
  final int menuItemId;

  const RemoveFromOrderEvent({required this.menuItemId});

  @override
  List<Object> get props => [menuItemId];
}

class UpdateOrderQuantityEvent extends MenuEvent {
  final int menuItemId;
  final int quantity;

  const UpdateOrderQuantityEvent(
      {required this.menuItemId, required this.quantity});

  @override
  List<Object> get props => [menuItemId, quantity];
}

class PlaceOrderEvent extends MenuEvent {}

class ClearOrderEvent extends MenuEvent {}

// States
abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<Map<String, dynamic>> menuItems;
  final Map<int, Map<String, dynamic>> currentOrder;
  final double totalAmount;
  final bool hasActiveBooking;

  const MenuLoaded({
    required this.menuItems,
    required this.currentOrder,
    required this.totalAmount,
    required this.hasActiveBooking,
  });

  @override
  List<Object> get props =>
      [menuItems, currentOrder, totalAmount, hasActiveBooking];
}

class OrderPlacedSuccess extends MenuState {
  final String message;

  const OrderPlacedSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class MenuFailure extends MenuState {
  final String message;

  const MenuFailure({required this.message});

  @override
  List<Object> get props => [message];
}

// BLoC
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final DatabaseHelper _databaseHelper;
  Map<int, Map<String, dynamic>> _currentOrder = {};

  MenuBloc({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        super(MenuInitial()) {
    on<LoadMenuEvent>(_onLoadMenu);
    on<LoadMenuByCategoryEvent>(_onLoadMenuByCategory);
    on<AddToOrderEvent>(_onAddToOrder);
    on<RemoveFromOrderEvent>(_onRemoveFromOrder);
    on<UpdateOrderQuantityEvent>(_onUpdateOrderQuantity);
    on<PlaceOrderEvent>(_onPlaceOrder);
    on<ClearOrderEvent>(_onClearOrder);
  }

  Future<void> _onLoadMenu(LoadMenuEvent event, Emitter<MenuState> emit) async {
    try {
      emit(MenuLoading());

      final menuItems = await _databaseHelper.getAllMenuItems();
      final hasActiveBooking =
          await SharedPreferencesService.hasUserBookedTable();

      emit(MenuLoaded(
        menuItems: menuItems,
        currentOrder: Map.from(_currentOrder),
        totalAmount: _calculateTotalAmount(),
        hasActiveBooking: hasActiveBooking,
      ));
    } catch (e) {
      emit(MenuFailure(message: 'Failed to load menu: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMenuByCategory(
      LoadMenuByCategoryEvent event, Emitter<MenuState> emit) async {
    try {
      emit(MenuLoading());

      final menuItems = await _databaseHelper.getMenuByCategory(event.category);
      final hasActiveBooking =
          await SharedPreferencesService.hasUserBookedTable();

      emit(MenuLoaded(
        menuItems: menuItems,
        currentOrder: Map.from(_currentOrder),
        totalAmount: _calculateTotalAmount(),
        hasActiveBooking: hasActiveBooking,
      ));
    } catch (e) {
      emit(MenuFailure(
          message: 'Failed to load menu by category: ${e.toString()}'));
    }
  }

  Future<void> _onAddToOrder(
      AddToOrderEvent event, Emitter<MenuState> emit) async {
    try {
      // Check if user has active booking
      final hasActiveBooking =
          await SharedPreferencesService.hasUserBookedTable();
      if (!hasActiveBooking) {
        emit(const MenuFailure(message: AppConstants.noActiveBooking));
        return;
      }

      final menuItemId = event.menuItem['id'] as int;

      if (_currentOrder.containsKey(menuItemId)) {
        // Update quantity if item already in order
        final existingItem = _currentOrder[menuItemId]!;
        final newQuantity = (existingItem['quantity'] as int) + event.quantity;
        _currentOrder[menuItemId] = {
          ...existingItem,
          'quantity': newQuantity,
        };
      } else {
        // Add new item to order
        _currentOrder[menuItemId] = {
          ...event.menuItem,
          'quantity': event.quantity,
        };
      }

      // Reload current state with updated order
      final currentState = state;
      if (currentState is MenuLoaded) {
        emit(MenuLoaded(
          menuItems: currentState.menuItems,
          currentOrder: Map.from(_currentOrder),
          totalAmount: _calculateTotalAmount(),
          hasActiveBooking: hasActiveBooking,
        ));
      }
    } catch (e) {
      emit(
          MenuFailure(message: 'Failed to add item to order: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveFromOrder(
      RemoveFromOrderEvent event, Emitter<MenuState> emit) async {
    try {
      _currentOrder.remove(event.menuItemId);

      final currentState = state;
      if (currentState is MenuLoaded) {
        emit(MenuLoaded(
          menuItems: currentState.menuItems,
          currentOrder: Map.from(_currentOrder),
          totalAmount: _calculateTotalAmount(),
          hasActiveBooking: currentState.hasActiveBooking,
        ));
      }
    } catch (e) {
      emit(MenuFailure(
          message: 'Failed to remove item from order: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateOrderQuantity(
      UpdateOrderQuantityEvent event, Emitter<MenuState> emit) async {
    try {
      if (_currentOrder.containsKey(event.menuItemId)) {
        if (event.quantity <= 0) {
          _currentOrder.remove(event.menuItemId);
        } else {
          _currentOrder[event.menuItemId] = {
            ..._currentOrder[event.menuItemId]!,
            'quantity': event.quantity,
          };
        }

        final currentState = state;
        if (currentState is MenuLoaded) {
          emit(MenuLoaded(
            menuItems: currentState.menuItems,
            currentOrder: Map.from(_currentOrder),
            totalAmount: _calculateTotalAmount(),
            hasActiveBooking: currentState.hasActiveBooking,
          ));
        }
      }
    } catch (e) {
      emit(MenuFailure(message: 'Failed to update quantity: ${e.toString()}'));
    }
  }

  Future<void> _onPlaceOrder(
      PlaceOrderEvent event, Emitter<MenuState> emit) async {
    try {
      emit(MenuLoading());

      // Check if user has active booking
      final hasActiveBooking =
          await SharedPreferencesService.hasUserBookedTable();
      if (!hasActiveBooking) {
        emit(const MenuFailure(message: AppConstants.noActiveBooking));
        return;
      }

      // Check if order is not empty
      if (_currentOrder.isEmpty) {
        emit(const MenuFailure(message: 'Please add items to your order'));
        return;
      }

      // Get user and table information
      final userId = await SharedPreferencesService.getLoggedInUserId();
      final tableId = await SharedPreferencesService.getUserBookedTable();

      if (userId == null || tableId == null) {
        emit(const MenuFailure(message: 'Invalid user or table information'));
        return;
      }

      // Create order
      final order = {
        'user_id': userId,
        'table_id': tableId,
        'total_amount': _calculateTotalAmount(),
        'order_date': DateTime.now().toIso8601String(),
        'status': AppConstants.orderStatusPending,
      };

      final orderId = await _databaseHelper.insertOrder(order);

      // Insert order items
      for (final orderItem in _currentOrder.values) {
        final orderItemData = {
          'order_id': orderId,
          'menu_item_id': orderItem['id'],
          'quantity': orderItem['quantity'],
          'price':
              (orderItem['price'] as double) * (orderItem['quantity'] as int),
        };

        await _databaseHelper.insertOrderItem(orderItemData);
      }

      // Clear current order
      _currentOrder.clear();

      emit(const OrderPlacedSuccess(
          message: AppConstants.orderPlacedSuccessfully));

      // Reload menu to show empty order
      add(LoadMenuEvent());
    } catch (e) {
      emit(MenuFailure(message: 'Failed to place order: ${e.toString()}'));
    }
  }

  Future<void> _onClearOrder(
      ClearOrderEvent event, Emitter<MenuState> emit) async {
    try {
      _currentOrder.clear();

      final currentState = state;
      if (currentState is MenuLoaded) {
        emit(MenuLoaded(
          menuItems: currentState.menuItems,
          currentOrder: Map.from(_currentOrder),
          totalAmount: 0.0,
          hasActiveBooking: currentState.hasActiveBooking,
        ));
      }
    } catch (e) {
      emit(MenuFailure(message: 'Failed to clear order: ${e.toString()}'));
    }
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (final item in _currentOrder.values) {
      final price = item['price'] as double;
      final quantity = item['quantity'] as int;
      total += price * quantity;
    }
    return total;
  }
}
