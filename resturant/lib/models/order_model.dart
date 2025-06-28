import '../core/constants.dart';

class OrderModel {
  final int? id;
  final int userId;
  final int tableId;
  final int totalAmountInPaise;
  final int orderTimeEpoch;
  final String status;

  const OrderModel({
    this.id,
    required this.userId,
    required this.tableId,
    required this.totalAmountInPaise,
    required this.orderTimeEpoch,
    required this.status,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    try {
      return OrderModel(
        id: map['id'] as int?,
        userId: map['user_id'] as int? ?? 0,
        tableId: map['table_id'] as int? ?? 0,
        totalAmountInPaise: map['total_amount_in_paise'] as int? ?? 0,
        orderTimeEpoch: map['order_time_epoch'] as int? ?? 0,
        status: map['status'] as String? ?? AppConstants.orderStatusPending,
      );
    } catch (e) {
      throw Exception('Failed to create OrderModel from map: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      final map = <String, dynamic>{
        'user_id': userId,
        'table_id': tableId,
        'total_amount_in_paise': totalAmountInPaise,
        'order_time_epoch': orderTimeEpoch,
        'status': status,
      };

      if (id != null) {
        map['id'] = id;
      }

      return map;
    } catch (e) {
      throw Exception('Failed to convert OrderModel to map: $e');
    }
  }

  OrderModel copyWith({
    int? id,
    int? userId,
    int? tableId,
    int? totalAmountInPaise,
    int? orderTimeEpoch,
    String? status,
  }) {
    try {
      return OrderModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        tableId: tableId ?? this.tableId,
        totalAmountInPaise: totalAmountInPaise ?? this.totalAmountInPaise,
        orderTimeEpoch: orderTimeEpoch ?? this.orderTimeEpoch,
        status: status ?? this.status,
      );
    } catch (e) {
      throw Exception('Failed to copy OrderModel: $e');
    }
  }

  double get totalAmountInRupees => totalAmountInPaise / 100.0;

  bool get isPending => status == AppConstants.orderStatusPending;
  bool get isPreparing => status == AppConstants.orderStatusPreparing;
  bool get isReady => status == AppConstants.orderStatusReady;
  bool get isServed => status == AppConstants.orderStatusServed;
  bool get isCompleted => status == AppConstants.orderStatusCompleted;

  @override
  String toString() {
    return 'OrderModel(id: $id, userId: $userId, tableId: $tableId, totalAmountInPaise: $totalAmountInPaise, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel &&
        other.id == id &&
        other.userId == userId &&
        other.tableId == tableId &&
        other.totalAmountInPaise == totalAmountInPaise &&
        other.orderTimeEpoch == orderTimeEpoch &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        tableId.hashCode ^
        totalAmountInPaise.hashCode ^
        orderTimeEpoch.hashCode ^
        status.hashCode;
  }
}

class OrderItemModel {
  final int? id;
  final int orderId;
  final int menuItemId;
  final int quantity;
  final int priceInPaise;

  const OrderItemModel({
    this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.priceInPaise,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    try {
      return OrderItemModel(
        id: map['id'] as int?,
        orderId: map['order_id'] as int? ?? 0,
        menuItemId: map['menu_item_id'] as int? ?? 0,
        quantity: map['quantity'] as int? ?? 0,
        priceInPaise: map['price_in_paise'] as int? ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to create OrderItemModel from map: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      final map = <String, dynamic>{
        'order_id': orderId,
        'menu_item_id': menuItemId,
        'quantity': quantity,
        'price_in_paise': priceInPaise,
      };

      if (id != null) {
        map['id'] = id;
      }

      return map;
    } catch (e) {
      throw Exception('Failed to convert OrderItemModel to map: $e');
    }
  }

  OrderItemModel copyWith({
    int? id,
    int? orderId,
    int? menuItemId,
    int? quantity,
    int? priceInPaise,
  }) {
    try {
      return OrderItemModel(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        menuItemId: menuItemId ?? this.menuItemId,
        quantity: quantity ?? this.quantity,
        priceInPaise: priceInPaise ?? this.priceInPaise,
      );
    } catch (e) {
      throw Exception('Failed to copy OrderItemModel: $e');
    }
  }

  double get priceInRupees => priceInPaise / 100.0;
  int get totalPriceInPaise => quantity * priceInPaise;
  double get totalPriceInRupees => totalPriceInPaise / 100.0;

  @override
  String toString() {
    return 'OrderItemModel(id: $id, orderId: $orderId, menuItemId: $menuItemId, quantity: $quantity, priceInPaise: $priceInPaise)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItemModel &&
        other.id == id &&
        other.orderId == orderId &&
        other.menuItemId == menuItemId &&
        other.quantity == quantity &&
        other.priceInPaise == priceInPaise;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        orderId.hashCode ^
        menuItemId.hashCode ^
        quantity.hashCode ^
        priceInPaise.hashCode;
  }
}
