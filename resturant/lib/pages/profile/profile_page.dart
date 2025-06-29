import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/booking_bloc.dart';
import '../../bloc/order_bloc.dart';
import '../../repositories/order_repository.dart';
import '../../app_router.dart';

@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _username;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final username = await authBloc.getCurrentUsername();
      final userId = await authBloc.getCurrentUserId();

      if (mounted) {
        setState(() {
          _username = username;
          _userId = userId;
        });
      }

      if (userId != null) {
        context.read<OrderBloc>().add(OrderLoadHistory(userId: userId));
      }
    } catch (e) {
      AppUtils.showToast(context, 'Error loading user info: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              try {
                context.router.replaceAll([HomeRoute()]);
              } catch (e) {
                AppUtils.showToast(context, 'Navigation error: $e',
                    isError: true);
              }
            },
            tooltip: 'Home',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildUserInfoCard()),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildLastOrderActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.person, size: 40, color: Colors.blue[700]),
          ),
          const SizedBox(height: 16),
          Text(
            _username ?? 'User',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Member since ${_getJoinDate()}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.event_seat, color: Colors.green),
              title: const Text('Book a Table'),
              subtitle: const Text('Reserve your table now'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                try {
                  context.router.push(const BookingRoute());
                } catch (e) {
                  AppUtils.showToast(context, 'Navigation error: $e',
                      isError: true);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.restaurant_menu, color: Colors.orange),
              title: const Text('Browse Menu'),
              subtitle: const Text('See our delicious offerings'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                try {
                  context.router.push(const MenuRoute());
                } catch (e) {
                  AppUtils.showToast(context, 'Navigation error: $e',
                      isError: true);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.purple),
              title: const Text('Order History'),
              subtitle: const Text('View your past orders'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                try {
                  context.router.push(const OrderHistoryRoute());
                } catch (e) {
                  AppUtils.showToast(context, 'Navigation error: $e',
                      isError: true);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              subtitle: const Text('Sign out of your account'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastOrderActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            BlocBuilder<OrderBloc, OrderState>(
              builder: (context, orderState) {
                if (orderState is OrderHistoryLoaded &&
                    orderState.orders.isNotEmpty) {
                  final recentOrder = orderState.orders.first;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Icon(Icons.restaurant, color: Colors.green[700]),
                    ),
                    title: Text(
                        'Last Order: ${AppUtils.formatPriceFromPaise(recentOrder.totalAmountInPaise)}'),
                    subtitle: Text(
                        '${AppUtils.formatEpochToIST(recentOrder.orderTimeEpoch)} '),
                  );
                }
                return const ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.restaurant, color: Colors.white),
                  ),
                  title: Text('No orders yet'),
                  subtitle: Text('Place your first order'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getJoinDate() {
    return 'Today';
  }

  void _handleLogout() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        context.read<AuthBloc>().add(AuthLogoutRequested());
        context.router.replaceAll([const LoginRoute()]);
      }
    } catch (e) {
      AppUtils.showToast(context, 'Logout error: $e', isError: true);
    }
  }

  Future<void> _handleRefresh() async {
    try {
      _loadUserInfo();
    } catch (e) {
      AppUtils.showToast(context, 'Refresh error: $e', isError: true);
    }
  }
}
