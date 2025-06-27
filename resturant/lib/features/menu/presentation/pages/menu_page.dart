import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../bloc/menu_bloc.dart';
import '../../../../core/constants/app_constants.dart';

class MenuPageView extends StatefulWidget {
  const MenuPageView({super.key});

  @override
  State<MenuPageView> createState() => _MenuPageViewState();
}

class _MenuPageViewState extends State<MenuPageView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = [
    'All',
    AppConstants.menuCategoryAppetizer,
    AppConstants.menuCategoryMainCourse,
    AppConstants.menuCategoryDessert,
    AppConstants.menuCategoryBeverage,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    context.read<MenuBloc>().add(LoadMenuEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Menu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            if (index == 0) {
              context.read<MenuBloc>().add(LoadMenuEvent());
            } else {
              context
                  .read<MenuBloc>()
                  .add(LoadMenuByCategoryEvent(category: _categories[index]));
            }
          },
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: BlocListener<MenuBloc, MenuState>(
        listener: (context, state) {
          if (state is OrderPlacedSuccess) {
            Fluttertoast.showToast(
              msg: state.message,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          } else if (state is MenuFailure) {
            Fluttertoast.showToast(
              msg: state.message,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          }
        },
        child: BlocBuilder<MenuBloc, MenuState>(
          builder: (context, state) {
            if (state is MenuLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              );
            } else if (state is MenuLoaded) {
              return Column(
                children: [
                  // Current Order Summary
                  if (state.currentOrder.isNotEmpty) _buildOrderSummary(state),

                  // Menu Items
                  Expanded(
                    child: state.menuItems.isEmpty
                        ? const Center(child: Text('No menu items available'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.menuItems.length,
                            itemBuilder: (context, index) {
                              final menuItem = state.menuItems[index];
                              final quantity =
                                  state.currentOrder[menuItem['id']]
                                          ?['quantity'] ??
                                      0;
                              return _buildMenuItemCard(context, menuItem,
                                  quantity, state.hasActiveBooking);
                            },
                          ),
                  ),
                ],
              );
            } else if (state is MenuFailure) {
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
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<MenuBloc>().add(LoadMenuEvent());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: Text('Loading menu...'));
          },
        ),
      ),
    );
  }

  Widget _buildOrderSummary(MenuLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Order',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<MenuBloc>().add(ClearOrderEvent());
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${state.currentOrder.length} items • \$${state.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.hasActiveBooking
                  ? () => _showOrderConfirmation(context, state)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                state.hasActiveBooking
                    ? 'Place Order (\$${state.totalAmount.toStringAsFixed(2)})'
                    : 'Book a table first',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(BuildContext context, Map<String, dynamic> menuItem,
      int quantity, bool hasActiveBooking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Menu Item Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuItem['item_name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    menuItem['description'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${(menuItem['price'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          menuItem['category'],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quantity Controls
            Column(
              children: [
                if (quantity > 0) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<MenuBloc>().add(
                                UpdateOrderQuantityEvent(
                                  menuItemId: menuItem['id'],
                                  quantity: quantity - 1,
                                ),
                              );
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          quantity.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: hasActiveBooking
                            ? () {
                                context.read<MenuBloc>().add(
                                      UpdateOrderQuantityEvent(
                                        menuItemId: menuItem['id'],
                                        quantity: quantity + 1,
                                      ),
                                    );
                              }
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: hasActiveBooking ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: hasActiveBooking
                        ? () {
                            context.read<MenuBloc>().add(
                                  AddToOrderEvent(
                                    menuItem: menuItem,
                                    quantity: 1,
                                  ),
                                );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasActiveBooking ? Colors.orange : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      hasActiveBooking ? 'Add' : 'Book Table',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderConfirmation(BuildContext context, MenuLoaded state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items: ${state.currentOrder.length}'),
            Text('Total: \$${state.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to place this order?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<MenuBloc>().add(PlaceOrderEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }
}
