import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/booking_bloc.dart';
import '../../app_router.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadUserBooking();
  }

  void _loadUserInfo() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final username = await authBloc.getCurrentUsername();
      if (mounted) {
        setState(() {
          _username = username;
        });
      }
    } catch (e) {
      AppUtils.showToast(context, 'Error loading user info: $e', isError: true);
    }
  }

  void _loadUserBooking() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final userId = await authBloc.getCurrentUserId();
      if (userId != null) {
        context.read<BookingBloc>().add(BookingLoadUserBooking(userId: userId));
      }
    } catch (e) {
      AppUtils.showToast(context, 'Error loading booking: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${_username ?? 'User'}!'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
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
              BlocBuilder<BookingBloc, BookingState>(
                builder: (context, bookingState) {
                  if (bookingState is BookingLoaded &&
                      bookingState.userBooking != null) {
                    return _buildCurrentBookingCard(bookingState.userBooking!);
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildNavigationCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBookingCard(dynamic booking) {
    try {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_seat, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Current Booking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking['status']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking['status'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Table: ${booking['table_name'] ?? 'Unknown'}'),
              Text(
                  'Booked: ${AppUtils.formatEpochToIST(booking['booking_time_epoch'] ?? 0)}'),
              const SizedBox(height: 12),
              if (booking['status'] == AppConstants.bookingStatusActive) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleCheckin,
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Check In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleCancelBooking,
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (booking['status'] ==
                  AppConstants.bookingStatusCheckedIn) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          try {
                            context.router.push(const OrderRoute());
                          } catch (e) {
                            AppUtils.showToast(context, 'Navigation error: $e',
                                isError: true);
                          }
                        },
                        icon: const Icon(Icons.restaurant, size: 16),
                        label: const Text('Order Food'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleCheckoutBooking,
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Checkout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error displaying booking: $e'),
        ),
      );
    }
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.restaurant,
            size: 32,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Book tables, order food, and enjoy your dining experience',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[100],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildNavigationCard(
          title: 'Book Table',
          subtitle: 'Reserve your table',
          icon: Icons.event_seat,
          color: Colors.green,
          onTap: () async {
            try {
              if (!mounted) return;
              await context.router.push(const BookingRoute());
            } catch (e) {
              if (mounted) {
                AppUtils.showToast(context, 'Navigation error: $e',
                    isError: true);
              }
            }
          },
        ),
        _buildNavigationCard(
          title: 'Menu',
          subtitle: 'Browse our delicious menu',
          icon: Icons.restaurant_menu,
          color: Colors.orange,
          onTap: () async {
            try {
              if (!mounted) return;
              await context.router.push(const MenuRoute());
            } catch (e) {
              if (mounted) {
                AppUtils.showToast(context, 'Navigation error: $e',
                    isError: true);
              }
            }
          },
        ),
        _buildNavigationCard(
          title: 'Order History',
          subtitle: 'View your past orders',
          icon: Icons.history,
          color: Colors.purple,
          onTap: () async {
            try {
              if (!mounted) return;
              await context.router.push(const OrderHistoryRoute());
            } catch (e) {
              if (mounted) {
                AppUtils.showToast(context, 'Navigation error: $e',
                    isError: true);
              }
            }
          },
        ),
        _buildNavigationCard(
          title: 'Profile',
          subtitle: 'Manage your account',
          icon: Icons.person,
          color: Colors.blue,
          onTap: () async {
            try {
              if (!mounted) return;
              await context.router.push(const ProfileRoute());
            } catch (e) {
              if (mounted) {
                AppUtils.showToast(context, 'Navigation error: $e',
                    isError: true);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCheckin() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final userId = await authBloc.getCurrentUserId();
      if (userId != null) {
        final bookingState = context.read<BookingBloc>().state;
        if (bookingState is BookingLoaded && bookingState.userBooking != null) {
          context.read<BookingBloc>().add(
                BookingCheckin(
                  bookingId: bookingState.userBooking!['id'],
                  userId: userId,
                ),
              );
        }
      }
    } catch (e) {
      AppUtils.showToast(context, 'Error checking in: $e', isError: true);
    }
  }

  void _handleCheckoutBooking() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final userId = await authBloc.getCurrentUserId();
      if (userId != null) {
        final bookingState = context.read<BookingBloc>().state;
        if (bookingState is BookingLoaded && bookingState.userBooking != null) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Checkout'),
              content: const Text(
                  'Are you sure you want to checkout? You will be able to book again immediately.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Yes, Checkout',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            context.read<BookingBloc>().add(
                  BookingCheckout(
                    bookingId: bookingState.userBooking!['id'],
                    userId: userId,
                  ),
                );
          }
        }
      }
    } catch (e) {
      AppUtils.showToast(context, 'Error checking out: $e', isError: true);
    }
  }

  void _handleCancelBooking() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final userId = await authBloc.getCurrentUserId();
      if (userId != null) {
        final bookingState = context.read<BookingBloc>().state;
        if (bookingState is BookingLoaded && bookingState.userBooking != null) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancel Booking'),
              content:
                  const Text('Are you sure you want to cancel your booking?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            context.read<BookingBloc>().add(
                  BookingCancel(
                    bookingId: bookingState.userBooking!['id'],
                    userId: userId,
                  ),
                );
          }
        }
      }
    } catch (e) {
      AppUtils.showToast(context, 'Error cancelling booking: $e',
          isError: true);
    }
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
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
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
      _loadUserBooking();
    } catch (e) {
      AppUtils.showToast(context, 'Refresh error: $e', isError: true);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case AppConstants.bookingStatusActive:
        return Colors.orange;
      case AppConstants.bookingStatusCheckedIn:
        return Colors.green;
      case AppConstants.bookingStatusCompleted:
        return Colors.blue;
      case AppConstants.bookingStatusCancelled:
        return Colors.red;
      case AppConstants.bookingStatusNoShow:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
