import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:restaurant_app/app_router.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/order_bloc.dart';
import '../../models/order_model.dart';

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
                // context.router.pushAndClearStack(const HomeRoute());
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
              _loadOrderHistory(); // Reload after action
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
        // Current order section
        if (state.currentOrder != null) ...[
          _buildCurrentOrderSection(state.currentOrder!),
          const Divider(thickness: 8),
        ],

        // Order history section
        Expanded(
          child: state.orders.isEmpty
              ? _buildEmptyHistory()
              : _buildOrdersList(state.orders),
        ),
      ],
    );
  }

  Widget _buildCurrentOrderSection(OrderModel currentOrder) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Current Order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildOrderCard(currentOrder, isCurrent: true),
        ],
      ),
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
              // Order header
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
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 8),

              // Order details
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

              // Amount
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

              // Action buttons
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

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case AppConstants.orderStatusPending:
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case AppConstants.orderStatusPreparing:
        color = Colors.blue;
        icon = Icons.restaurant;
        break;
      case AppConstants.orderStatusReady:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case AppConstants.orderStatusServed:
        color = Colors.purple;
        icon = Icons.room_service;
        break;
      case AppConstants.orderStatusCompleted:
        color = Colors.grey;
        icon = Icons.done_all;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
    );
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
              Navigator.of(context).pop(); // Go back to order food
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

  void _viewOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id} Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Status', order.status.toUpperCase()),
              _buildDetailRow('Order Time',
                  AppUtils.formatEpochToIST(order.orderTimeEpoch)),
              _buildDetailRow('Table', 'Table ${order.tableId}'),
              _buildDetailRow('Total Amount',
                  AppUtils.formatPriceFromPaise(order.totalAmountInPaise)),
              const SizedBox(height: 16),
              const Text(
                'Order Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Loading items...',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              // TODO: Load and display order items
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
