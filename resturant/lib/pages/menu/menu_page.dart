import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../bloc/menu_bloc.dart';
import '../../models/menu_item_model.dart';
import '../../app_router.dart';

@RoutePage()
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<MenuBloc>().add(MenuRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.menu),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              try {
                context.router.push(const OrderRoute());
              } catch (e) {
                AppUtils.showToast(
                    context, '${AppConstants.errorNavigation} $e',
                    isError: true);
              }
            },
          ),
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
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: BlocBuilder<MenuBloc, MenuState>(
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
        ),
      ),
    );
  }

  Widget _buildMenuContent(MenuLoaded state) {
    return Column(
      children: [
        if (state.categories.isNotEmpty) _buildCategoryFilter(state.categories),
        Expanded(
          child: state.menuItems.isEmpty
              ? _buildEmptyMenu()
              : _buildMenuList(state.menuItems),
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
                backgroundColor: Color.fromARGB(245, 247, 136, 38),
                selectedColor: Colors.blue[100],
                checkmarkColor: Color(0xFF001F54),
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
              selectedColor: Color.fromARGB(245, 247, 136, 38),
              checkmarkColor: Color(0xFF001F54),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuList(List<MenuItemModel> menuItems) {
    final groupedItems = <String, List<MenuItemModel>>{};
    for (final item in menuItems) {
      groupedItems.putIfAbsent(item.category, () => []).add(item);
    }

    if (_selectedCategory != null) {
      final categoryItems = groupedItems[_selectedCategory] ?? [];
      return _buildCategorySection(_selectedCategory!, categoryItems);
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedItems.length,
        itemBuilder: (context, index) {
          final category = groupedItems.keys.elementAt(index);
          final items = groupedItems[category]!;
          return _buildCategorySection(category, items);
        },
      );
    }
  }

  Widget _buildCategorySection(String category, List<MenuItemModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedCategory == null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF001F54),
              ),
            ),
          ),
        ],
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildMenuItemCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item) {
    try {
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
                  border: Border.all(color: Color(0xFF001F54)!),
                ),
                child: Icon(
                  _getCategoryIcon(item.category),
                  color: Color(0xFF001F54),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item.description.isNotEmpty)
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppUtils.formatPriceFromPaise(item.priceInPaise),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Chip(
                          label: Text(
                            item.category,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Color.fromARGB(245, 247, 136, 38),
                          labelStyle: TextStyle(color: Color(0xFF001F54)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${AppConstants.errorDisplayingItem} $e'),
        ),
      );
    }
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
            AppConstants.noMenuItems,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory != null
                ? '${AppConstants.noItemsInCategory} $_selectedCategory ${AppConstants.categoryText}'
                : AppConstants.menuIsEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
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

  Future<void> _handleRefresh() async {
    try {
      context.read<MenuBloc>().add(MenuRefreshRequested());
    } catch (e) {
      AppUtils.showToast(context, '${AppConstants.refreshError} $e',
          isError: true);
    }
  }
}
