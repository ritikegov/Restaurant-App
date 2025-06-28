import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/table_bloc.dart';
import '../../bloc/booking_bloc.dart';
import '../../models/table_model.dart';
import '../../app_router.dart';

@RoutePage()
class TableViewPage extends StatefulWidget {
  const TableViewPage({super.key});

  @override
  State<TableViewPage> createState() => _TableViewPageState();
}

class _TableViewPageState extends State<TableViewPage> {
  @override
  void initState() {
    super.initState();
    // Check for expired bookings when page loads
    context.read<BookingBloc>().add(BookingCheckExpired());
    // Load user's current booking
    _loadUserBooking();
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
        title: const Text('Restaurant Tables'),
        automaticallyImplyLeading: false,
        actions: [
          // Menu button
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () {
              try {
                context.router.push(const MenuRoute());
              } catch (e) {
                AppUtils.showToast(context, 'Navigation error: $e',
                    isError: true);
              }
            },
          ),
          // Order history button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              try {
                context.router.push(const OrderHistoryRoute());
              } catch (e) {
                AppUtils.showToast(context, 'Navigation error: $e',
                    isError: true);
              }
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // Current booking status
            BlocBuilder<BookingBloc, BookingState>(
              builder: (context, bookingState) {
                if (bookingState is BookingLoaded &&
                    bookingState.userBooking != null) {
                  return _buildCurrentBookingCard(bookingState.userBooking!);
                }
                return const SizedBox.shrink();
              },
            ),

            // Tables grid
            Expanded(
              child: BlocBuilder<TableBloc, TableState>(
                builder: (context, state) {
                  if (state is TableLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TableLoaded) {
                    return _buildTablesGrid(state.tables);
                  } else if (state is TableError) {
                    return _buildErrorWidget(state.message);
                  } else {
                    return const Center(child: Text('No tables available'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, bookingState) {
          // Hide FAB if user already has a booking
          if (bookingState is BookingLoaded &&
              bookingState.userBooking != null) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () {
              try {
                context.router.push(const BookingRoute());
              } catch (e) {
                AppUtils.showToast(context, 'Navigation error: $e',
                    isError: true);
              }
            },
            icon: const Icon(Icons.book_online),
            label: const Text('Book Table'),
          );
        },
      ),
    );
  }

  Widget _buildCurrentBookingCard(dynamic booking) {
    try {
      return Card(
        margin: const EdgeInsets.all(16),
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_seat, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Current Booking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    booking['status'] ?? '',
                    style: TextStyle(
                      color: _getStatusColor(booking['status']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Table: ${booking['table_name'] ?? 'Unknown'}'),
              Text(
                  'Booked: ${AppUtils.formatEpochToIST(booking['booking_time_epoch'] ?? 0)}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (booking['status'] ==
                      AppConstants.bookingStatusActive) ...[
                    ElevatedButton.icon(
                      onPressed: _handleCheckin,
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Check In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (booking['status'] ==
                      AppConstants.bookingStatusCheckedIn) ...[
                    ElevatedButton.icon(
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
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _handleCancelBooking,
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.all(16),
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error displaying booking: $e'),
        ),
      );
    }
  }

  Widget _buildTablesGrid(List<TableModel> tables) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: tables.length,
        itemBuilder: (context, index) {
          final table = tables[index];
          return _buildTableCard(table);
        },
      ),
    );
  }

  Widget _buildTableCard(TableModel table) {
    try {
      final color = TableColorHelper.getTableColor(
          table.availableSeats, table.totalCapacity);
      final statusText = TableColorHelper.getTableStatusText(
          table.availableSeats, table.totalCapacity);

      return Card(
        child: InkWell(
          onTap: table.isAvailable ? () => _handleTableTap(table) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_restaurant,
                    size: 48,
                    color: color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    table.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Capacity: ${table.totalCapacity}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!table.isAvailable)
                    const Text(
                      'FULL',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Card(
        child: Center(
          child: Text('Error: $e'),
        ),
      );
    }
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
            'Error loading tables',
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
              context.read<TableBloc>().add(TableLoadRequested());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _handleTableTap(TableModel table) {
    try {
      // Navigate to booking page with selected table
      context.router.push(const BookingRoute());
    } catch (e) {
      AppUtils.showToast(context, 'Navigation error: $e', isError: true);
    }
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

  void _handleCancelBooking() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final userId = await authBloc.getCurrentUserId();
      if (userId != null) {
        final bookingState = context.read<BookingBloc>().state;
        if (bookingState is BookingLoaded && bookingState.userBooking != null) {
          // Show confirmation dialog
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
      context.read<TableBloc>().add(TableRefreshRequested());
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
