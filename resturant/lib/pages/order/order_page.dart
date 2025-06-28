import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/booking_bloc.dart';
import '../../bloc/menu_bloc.dart';
import '../../bloc/order_bloc.dart';
import '../../models/menu_item_model.dart';
import '../../app_router.dart';

@RoutePage()
class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load cart and menu
    context.read<OrderBloc>().add(OrderLoadCart());
    context.read<MenuBloc>().add(MenuRefreshRequested());

    // Load current order for user
    _loadCurrentOrder();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentOrder() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final userId = await authBloc.getCurrentUserId();
      if (userId != null) {
        context.read<OrderBloc>().add(OrderLoadCurrent(userId: userId));
      }
    } catch (e) {
      AppUtils.showToast(context, 'Error loading order: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Food'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu),
                  const SizedBox(width: 8),
                  const Text('Menu'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart),
                  const SizedBox(width: 8),
                  const Text('Cart'),
                  BlocBuilder<OrderBloc, OrderState>(
                    builder: (context, state) {
                      if (state is OrderCartLoaded && state.totalItems > 0) {
                        return Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.totalItems}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          try {
            if (state is OrderSuccess) {
              AppUtils.showToast(context, state.message);
              if (state.order != null) {
                // Navigate to order history after successful order
                context.router.replaceAll([const OrderHistoryRoute()]);
              }
            } else if (state is OrderError) {
              AppUtils.showToast(context, state.message, isError: true);
            }
          } catch (e) {
            AppUtils.showToast(context, 'Navigation error: $e', isError: true);
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMenuTab(),
            _buildCartTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        if (state is MenuLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MenuLoaded) {
          return _buildMenuContent(state);
        } else if (state is MenuError) {
          return _buildErrorWidget(state.message);
        } else {
          return const Center(child: Text('Loading menu...'));
        }
      },
    );
  }

  Widget _buildMenuContent(MenuLoaded state) {
    return Column(
      children: [
        // Category filter
        if (state.categories.isNotEmpty) _buildCategoryFilter(state.categories),

        // Menu items
        Expanded(
          child: state.menuItems.isEmpty
              ? _buildEmptyMenu()
              : _buildMenuItemsList(state.menuItems),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedCategory == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = null;
                  });
                  context.read<MenuBloc>().add(MenuFilterByCategory());
                },
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.blue[100],
                checkmarkColor: Colors.blue,
              ),
            );
          }

          final category = categories[index - 1];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                });
                context
                    .read<MenuBloc>()
                    .add(MenuFilterByCategory(category: category));
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue[100],
              checkmarkColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItemsList(List<MenuItemModel> menuItems) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, orderState) {
        final quantityInCart =
            context.read<OrderBloc>().getItemQuantityInCart(item.id!);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),

                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        AppUtils.formatPriceFromPaise(item.priceInPaise),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // Add/Remove buttons
                Column(
                  children: [
                    if (quantityInCart > 0) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              context.read<OrderBloc>().add(
                                    OrderUpdateItemQuantity(
                                      menuItemId: item.id!,
                                      quantity: quantityInCart - 1,
                                    ),
                                  );
                            },
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            iconSize: 20,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$quantityInCart',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              context.read<OrderBloc>().add(
                                    OrderAddItem(menuItem: item, quantity: 1),
                                  );
                            },
                            icon: const Icon(Icons.add_circle,
                                color: Colors.green),
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<OrderBloc>().add(
                                OrderAddItem(menuItem: item, quantity: 1),
                              );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartTab() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is OrderCartLoaded) {
          return _buildCartContent(state);
        } else {
          return const Center(child: Text('Loading cart...'));
        }
      },
    );
  }

  Widget _buildCartContent(OrderCartLoaded state) {
    if (state.cartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return Column(
      children: [
        // Cart items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.cartItems.length,
            itemBuilder: (context, index) {
              final cartItem = state.cartItems[index];
              return _buildCartItemCard(cartItem);
            },
          ),
        ),

        // Cart summary and place order
        _buildCartSummary(state),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem cartItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.menuItem.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppUtils.formatPriceFromPaise(
                        cartItem.menuItem.priceInPaise),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${AppUtils.formatPriceFromPaise(cartItem.totalPriceInPaise)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    context.read<OrderBloc>().add(
                          OrderUpdateItemQuantity(
                            menuItemId: cartItem.menuItem.id!,
                            quantity: cartItem.quantity - 1,
                          ),
                        );
                  },
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${cartItem.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    context.read<OrderBloc>().add(
                          OrderAddItem(
                              menuItem: cartItem.menuItem, quantity: 1),
                        );
                  },
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(OrderCartLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Items: ${state.totalItems}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total: ${AppUtils.formatPriceFromPaise(state.totalAmountInPaise)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showClearCartDialog();
                  },
                  child: const Text('Clear Cart'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    _handlePlaceOrder();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Place Order',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some delicious items from the menu',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _tabController.animateTo(0); // Switch to menu tab
            },
            child: const Text('Browse Menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMenu() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No menu items available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<MenuBloc>().add(MenuRefreshRequested());
            },
            child: const Text('Refresh'),
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
            'Error Loading Menu',
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
            onPressed: () {
              context.read<MenuBloc>().add(MenuLoadRequested());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'appetizers':
        return Icons.local_dining;
      case 'main course':
        return Icons.dinner_dining;
      case 'desserts':
        return Icons.cake;
      case 'beverages':
        return Icons.local_drink;
      default:
        return Icons.restaurant;
    }
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to clear all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<OrderBloc>().add(OrderClearCart());
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _handlePlaceOrder() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final userId = await authBloc.getCurrentUserId();

      if (userId == null) {
        AppUtils.showToast(context, 'User not logged in', isError: true);
        return;
      }

      // Get user's active booking to get table ID
      final bookingState = context.read<BookingBloc>().state;
      if (bookingState is BookingLoaded && bookingState.userBooking != null) {
        final booking = bookingState.userBooking!;

        // Check if user is checked in
        if (booking['status'] != AppConstants.bookingStatusCheckedIn) {
          AppUtils.showToast(context, AppConstants.errorCheckinRequired,
              isError: true);
          return;
        }

        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Order'),
            content: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrderCartLoaded) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Table: ${booking['table_name']}'),
                      Text('Items: ${state.totalItems}'),
                      Text(
                          'Total: ${AppUtils.formatPriceFromPaise(state.totalAmountInPaise)}'),
                      const SizedBox(height: 8),
                      const Text('Proceed with the order?'),
                    ],
                  );
                }
                return const Text('Proceed with the order?');
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Place Order'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          context.read<OrderBloc>().add(
                OrderPlaceOrder(
                  userId: userId,
                  tableId: booking['table_id'],
                ),
              );
        }
      } else {
        AppUtils.showToast(context, AppConstants.errorNoActiveBooking,
            isError: true);
      }
    } catch (e) {
      AppUtils.showToast(context, 'Order error: $e', isError: true);
    }
  }
}
