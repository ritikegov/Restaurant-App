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

    context.read<OrderBloc>().add(OrderLoadCart());
    context.read<MenuBloc>().add(MenuRefreshRequested());

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
      AppUtils.showToast(context, '${AppConstants.errorOrder} $e',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.orderFood),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              try {
                context.router.replaceAll([HomeRoute()]);
              } catch (e) {
                AppUtils.showToast(
                    context, '${AppConstants.errorNavigation} $e',
                    isError: true);
              }
            },
            tooltip: AppConstants.home,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu),
                  const SizedBox(width: 8),
                  Text(AppConstants.menu),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart),
                  const SizedBox(width: 8),
                  Text(AppConstants.cart),
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
                context.router.push(const OrderHistoryRoute());
              }
            } else if (state is OrderError) {
              AppUtils.showToast(context, state.message, isError: true);
            }
          } catch (e) {
            AppUtils.showToast(context, '${AppConstants.errorNavigation} $e',
                isError: true);
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
          return Center(child: Text(AppConstants.loadingMenu));
        }
      },
    );
  }

  Widget _buildMenuContent(MenuLoaded state) {
    return Column(
      children: [
        if (state.categories.isNotEmpty) _buildCategoryFilter(state.categories),
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
                label: Text(AppConstants.all),
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
                        label: Text(AppConstants.add),
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
          return _buildEmptyHistory();
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
        _buildCartSummary(state),
      ],
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

  Widget _buildCartItemCard(CartItem cartItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
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
                    '${AppConstants.total}: ${AppUtils.formatPriceFromPaise(cartItem.totalPriceInPaise)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
                '${AppConstants.totalItems}: ${state.totalItems}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${AppConstants.total}: ${AppUtils.formatPriceFromPaise(state.totalAmountInPaise)}',
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
                  child: Text(AppConstants.clearCart),
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
                  child: Text(
                    AppConstants.placeOrder,
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
            AppConstants.yourCartIsEmpty,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.addSomeDeliciousItems,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _tabController.animateTo(0);
            },
            child: Text(AppConstants.browseMenu),
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
            AppConstants.noMenuItemsAvailable,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<MenuBloc>().add(MenuRefreshRequested());
            },
            child: Text(AppConstants.refresh),
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
            AppConstants.errorLoadingMenu,
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
            child: Text(AppConstants.retry),
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
        title: Text(AppConstants.clearCart),
        content: Text(AppConstants.confirmClearCart),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppConstants.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<OrderBloc>().add(OrderClearCart());
            },
            child: Text(AppConstants.clear),
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
        AppUtils.showToast(context, AppConstants.userNotLogin, isError: true);
        return;
      }

      final bookingState = context.read<BookingBloc>().state;
      if (bookingState is BookingLoaded && bookingState.userBooking != null) {
        final booking = bookingState.userBooking!;

        if (booking['status'] != AppConstants.bookingStatusCheckedIn) {
          AppUtils.showToast(context, AppConstants.errorCheckinRequired,
              isError: true);
          return;
        }

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppConstants.confirmOrder),
            content: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrderCartLoaded) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppConstants.table}: ${booking['table_name']}'),
                      Text('${AppConstants.items}: ${state.totalItems}'),
                      Text(
                          '${AppConstants.total}: ${AppUtils.formatPriceFromPaise(state.totalAmountInPaise)}'),
                      const SizedBox(height: 8),
                      Text(AppConstants.proceedWithOrder),
                    ],
                  );
                }
                return Text(AppConstants.proceedWithOrder);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppConstants.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppConstants.placeOrder),
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
      AppUtils.showToast(context, '${AppConstants.errorOrder} $e',
          isError: true);
    }
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text(AppConstants.orderPlaced),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConstants.orderPlacedMessage),
            SizedBox(height: 8),
            Text(AppConstants.trackOrderMessage),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppConstants.continueOrdering),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              try {
                context.router.push(const OrderHistoryRoute());
              } catch (e) {
                AppUtils.showToast(
                    context, '${AppConstants.errorNavigation} $e',
                    isError: true);
              }
            },
            child: Text(AppConstants.viewOrder),
          ),
        ],
      ),
    );
  }
}
