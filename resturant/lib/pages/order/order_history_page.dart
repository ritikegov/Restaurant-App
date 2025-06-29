import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:restaurant_app/app_router.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/order_bloc.dart';
import '../../models/order_model.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/menu_repository.dart';

@RoutePage()
class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  void _loadOrderHistory() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final userId = await authBloc.getCurrentUserId();
      if (userId != null) {
        context.read<OrderBloc>().add(OrderLoadHistory(userId: userId));
      }
    } catch (e) {
      AppUtils.showToast(context, 'Error loading orders: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              try {
                context.maybePop();
                context.router.push(HomeRoute());
              } catch (e) {
                AppUtils.showToast(context, 'Navigation error: $e',
                    isError: true);
              }
            },
            tooltip: 'Home',
          ),
        ],
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          try {
            if (state is OrderSuccess) {
              AppUtils.showToast(context, state.message);
              _loadOrderHistory();
            } else if (state is OrderError) {
              AppUtils.showToast(context, state.message, isError: true);
            }
          } catch (e) {
            AppUtils.showToast(context, 'Error: $e', isError: true);
          }
        },
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              if (state is OrderLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is OrderHistoryLoaded) {
                return _buildOrderHistory(state);
              } else if (state is OrderError) {
                return _buildErrorWidget(state.message);
              } else {
                return const Center(child: Text('Loading orders...'));
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHistory(OrderHistoryLoaded state) {
    return Column(
      children: [
        Expanded(
          child: state.orders.isEmpty
              ? _buildEmptyHistory()
              : _buildOrdersList(state.orders),
        ),
      ],
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Order History (${orders.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOrderCard(order),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order, {bool isCurrent = false}) {
    try {
      return Card(
        elevation: isCurrent ? 4 : 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    AppUtils.formatEpochToIST(order.orderTimeEpoch),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.table_restaurant,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Table ${order.tableId}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    AppUtils.formatPriceFromPaise(order.totalAmountInPaise),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (order.isPending && isCurrent) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleCancelOrder(order),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewOrderDetails(order),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _viewOrderDetails(order),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error displaying order: $e'),
        ),
      );
    }
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Orders Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t placed any orders yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Order Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Orders',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrderHistory,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _handleCancelOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel order #${order.id}?'),
            const SizedBox(height: 8),
            Text(
                'Amount: ${AppUtils.formatPriceFromPaise(order.totalAmountInPaise)}'),
            const SizedBox(height: 8),
            const Text(
              'Note: Only pending orders can be cancelled.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                final authBloc = context.read<AuthBloc>();
                final userId = await authBloc.getCurrentUserId();
                if (userId != null) {
                  context.read<OrderBloc>().add(
                        OrderCancel(orderId: order.id!, userId: userId),
                      );
                }
              } catch (e) {
                AppUtils.showToast(context, 'Cancel error: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewOrderDetails(OrderModel order) async {
    try {
      final orderRepository = OrderRepository();
      final orderItems =
          await orderRepository.getOrderItemsByOrderId(order.id!);
      final menuRepository = MenuRepository();

      List<Map<String, dynamic>> itemDetails = [];
      for (final item in orderItems) {
        final menuItem = await menuRepository.getMenuItemById(item.menuItemId);
        if (menuItem != null) {
          itemDetails.add({
            'name': menuItem.name,
            'quantity': item.quantity,
            'price': item.priceInPaise,
            'total': item.totalPriceInPaise,
          });
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Order #${order.id} Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Order Time',
                      AppUtils.formatEpochToIST(order.orderTimeEpoch)),
                  _buildDetailRow('Table', 'Table ${order.tableId}'),
                  _buildDetailRow('Total Amount',
                      AppUtils.formatPriceFromPaise(order.totalAmountInPaise)),
                  const SizedBox(height: 16),
                  const Text(
                    'Order Items:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (itemDetails.isNotEmpty) ...[
                    ...itemDetails.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Qty: ${item['quantity']} × ${AppUtils.formatPriceFromPaise(item['price'])}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                AppUtils.formatPriceFromPaise(item['total']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ] else ...[
                    const Text(
                      'No items found',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      AppUtils.showToast(context, 'Error loading order details: $e',
          isError: true);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    try {
      _loadOrderHistory();
    } catch (e) {
      AppUtils.showToast(context, 'Refresh error: $e', isError: true);
    }
  }
}
