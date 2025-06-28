import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:restaurant_app/app_router.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/table_bloc.dart';
import '../../bloc/booking_bloc.dart';
import '../../models/table_model.dart';

@RoutePage()
class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  TableModel? _selectedTable;

  @override
  void initState() {
    super.initState();
    // Refresh tables when page loads
    context.read<TableBloc>().add(TableRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Table'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              try {
                context.router.replaceAll([HomeRoute()]);
                //  context.router.pushAndClearStack(const HomeRoute());
              } catch (e) {
                AppUtils.showToast(context, 'Navigation error: $e',
                    isError: true);
              }
            },
            tooltip: 'Home',
          ),
        ],
      ),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          try {
            if (state is BookingSuccess) {
              AppUtils.showToast(context, state.message);
              context.router.pop(); // Go back to table view
            } else if (state is BookingError) {
              AppUtils.showToast(context, state.message, isError: true);
            }
          } catch (e) {
            AppUtils.showToast(context, 'Navigation error: $e', isError: true);
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Booking instructions
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Booking Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• You can book only one seat at a time'),
                    const Text(
                        '• Multiple people can book the same table if seats are available'),
                    const Text(
                        '• You can book again after 23 hours from your last booking'),
                    const Text(
                        '• Please check-in within 30 minutes of booking'),
                  ],
                ),
              ),

              // Available tables
              Expanded(
                child: BlocBuilder<TableBloc, TableState>(
                  builder: (context, state) {
                    if (state is TableLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is TableLoaded) {
                      final availableTables = state.tables
                          .where((table) => table.isAvailable)
                          .toList();

                      if (availableTables.isEmpty) {
                        return _buildNoTablesAvailable();
                      }

                      return _buildTablesSelection(availableTables);
                    } else if (state is TableError) {
                      return _buildErrorWidget(state.message);
                    } else {
                      return const Center(child: Text('Loading tables...'));
                    }
                  },
                ),
              ),

              // Book button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: BlocBuilder<BookingBloc, BookingState>(
                  builder: (context, state) {
                    final isLoading = state is BookingLoading;

                    return ElevatedButton(
                      onPressed: (_selectedTable != null && !isLoading)
                          ? _handleBookTable
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _selectedTable != null
                                  ? 'Book ${_selectedTable!.name}'
                                  : 'Select a Table',
                              style: const TextStyle(fontSize: 16),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTablesSelection(List<TableModel> availableTables) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Available Tables (${availableTables.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: availableTables.length,
            itemBuilder: (context, index) {
              final table = availableTables[index];
              return _buildTableSelectionCard(table);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableSelectionCard(TableModel table) {
    try {
      final isSelected = _selectedTable?.id == table.id;
      final color = TableColorHelper.getTableColor(
          table.availableSeats, table.totalCapacity);
      final statusText = TableColorHelper.getTableStatusText(
          table.availableSeats, table.totalCapacity);

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTable = table;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue : color,
                width: isSelected ? 3 : 2,
              ),
              color: isSelected ? Colors.blue[50] : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(
                    Icons.table_restaurant,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        table.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Capacity: ${table.totalCapacity} seats',
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
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error displaying table: $e'),
        ),
      );
    }
  }

  Widget _buildNoTablesAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Tables Available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'All tables are currently full. Please try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<TableBloc>().add(TableRefreshRequested());
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
            'Error Loading Tables',
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

  void _handleBookTable() async {
    try {
      if (_selectedTable == null) return;

      final authBloc = context.read<AuthBloc>();
      final userId = await authBloc.getCurrentUserId();

      if (userId == null) {
        AppUtils.showToast(context, 'User not logged in', isError: true);
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Book ${_selectedTable!.name}?'),
              const SizedBox(height: 8),
              const Text(
                  'Note: You will have 30 minutes to check-in after booking.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Book Now'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        context.read<BookingBloc>().add(
              BookingCreate(
                userId: userId,
                tableId: _selectedTable!.id!,
              ),
            );
      }
    } catch (e) {
      AppUtils.showToast(context, 'Booking error: $e', isError: true);
    }
  }
}
