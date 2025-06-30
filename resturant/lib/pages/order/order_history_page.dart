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
      AppUtils.showToast(context, '${AppConstants.errorLoadingOrders} $e',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.orderHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              try {
                context.maybePop();
                context.router.push(HomeRoute());
              } catch (e) {
                AppUtils.showToast(
                    context, '${AppConstants.errorNavigation} $e',
                    isError: true);
              }
            },
            tooltip: AppConstants.home,
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
                return Center(child: Text(AppConstants.loadingOrders));
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
            '${AppConstants.orderHistoryCount} (${orders.length})',
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
                    '${AppConstants.orderPrefix}${order.id}',
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
                    '${AppConstants.tablePrefix}${order.tableId}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppConstants.totalAmount,
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
                        label: Text(AppConstants.cancel),
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
                        label: Text(AppConstants.viewDetails),
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
                    label: Text(AppConstants.viewDetails),
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
          child: Text('${AppConstants.errorDisplayingOrder} $e'),
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
            AppConstants.noOrdersYet,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.noOrdersDescription,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.restaurant_menu),
            label: Text(AppConstants.orderNow),
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
            AppConstants.errorLoadingOrdersTitle,
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
            child: Text(AppConstants.retry),
          ),
        ],
      ),
    );
  }

  void _handleCancelOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppConstants.cancelOrder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppConstants.confirmCancelOrder}${order.id}?'),
            const SizedBox(height: 8),
            Text(
                '${AppConstants.amount} ${AppUtils.formatPriceFromPaise(order.totalAmountInPaise)}'),
            const SizedBox(height: 8),
            const Text(
              AppConstants.cancelOrderNote,
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
            child: Text(AppConstants.no),
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
                AppUtils.showToast(context, '${AppConstants.cancelError} $e',
                    isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppConstants.yesCancelOrder,
                style: const TextStyle(color: Colors.white)),
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
            title: Text(
                '${AppConstants.orderPrefix}${order.id} ${AppConstants.orderDetailsTitle}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(AppConstants.orderTime,
                      AppUtils.formatEpochToIST(order.orderTimeEpoch)),
                  _buildDetailRow(AppConstants.table,
                      '${AppConstants.tablePrefix}${order.tableId}'),
                  _buildDetailRow(AppConstants.totalAmount,
                      AppUtils.formatPriceFromPaise(order.totalAmountInPaise)),
                  const SizedBox(height: 16),
                  const Text(
                    AppConstants.orderItems,
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
                                      '${AppConstants.quantity} ${item['quantity']} × ${AppUtils.formatPriceFromPaise(item['price'])}',
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
                      AppConstants.noItemsFound,
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
                child: Text(AppConstants.close),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      AppUtils.showToast(context, '${AppConstants.errorLoadingOrderDetails} $e',
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
      AppUtils.showToast(context, '${AppConstants.refreshError} $e',
          isError: true);
    }
  }
}
