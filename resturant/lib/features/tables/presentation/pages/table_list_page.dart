import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../bloc/table_bloc.dart';
import '../../../../core/constants/app_constants.dart';

class TableListPageView extends StatefulWidget {
  const TableListPageView({super.key});

  @override
  State<TableListPageView> createState() => _TableListPageViewState();
}

class _TableListPageViewState extends State<TableListPageView> {
  @override
  void initState() {
    super.initState();
    context.read<TableBloc>().add(LoadTablesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Restaurant Tables',
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
      ),
      body: BlocListener<TableBloc, TableState>(
        listener: (context, state) {
          if (state is TableBookingSuccess) {
            Fluttertoast.showToast(
              msg: state.message,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          } else if (state is TableFailure) {
            Fluttertoast.showToast(
              msg: state.message,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          }
        },
        child: BlocBuilder<TableBloc, TableState>(
          builder: (context, state) {
            if (state is TableLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              );
            } else if (state is TablesLoaded) {
              return Column(
                children: [
                  // Status Legend
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Table Status Legend',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildLegendItem(Colors.green, 'Available (4/4)'),
                            const SizedBox(width: 16),
                            _buildLegendItem(Colors.grey, 'Limited (1/4)'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildLegendItem(
                                Colors.yellow.shade700, 'Busy (2-3/4)'),
                            const SizedBox(width: 16),
                            _buildLegendItem(Colors.red, 'Full (0/4)'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tables Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: state.tables.length,
                        itemBuilder: (context, index) {
                          final table = state.tables[index];
                          return _buildTableCard(context, table, state);
                        },
                      ),
                    ),
                  ),
                ],
              );
            } else if (state is TableFailure) {
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
                        context.read<TableBloc>().add(LoadTablesEvent());
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

            return const Center(
              child: Text('No tables available'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTableCard(
      BuildContext context, Map<String, dynamic> table, TablesLoaded state) {
    final tableNumber = table['table_number'] as int;
    final capacity = table['capacity'] as int;
    final availableSeats = table['available_seats'] as int;
    final color = table['color'] as String;
    final isBooked = table['booked_by_user_id'] != null;

    Color cardColor;
    Color textColor = Colors.white;

    switch (color) {
      case 'green':
        cardColor = Colors.green;
        break;
      case 'gray':
        cardColor = Colors.grey;
        break;
      case 'yellow':
        cardColor = Colors.yellow.shade700;
        break;
      case 'red':
        cardColor = Colors.red;
        break;
      default:
        cardColor = Colors.grey;
    }

    final isUserTable = state.userBookedTableId == table['id'];
    final canBook = !state.userHasBooking && availableSeats > 0 && !isBooked;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUserTable
            ? const BorderSide(color: Colors.orange, width: 3)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [cardColor, cardColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Table Number
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Table $tableNumber',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (isUserTable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Yours',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              // Table Icon
              Icon(
                Icons.table_restaurant,
                size: 48,
                color: textColor.withOpacity(0.8),
              ),

              // Seat Information
              Column(
                children: [
                  Text(
                    '$availableSeats/$capacity',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Available Seats',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.9),
                    ),
                  ),
                ],
              ),

              // Book Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canBook
                      ? () => _showBookingConfirmation(context, table)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canBook ? Colors.white : Colors.grey.shade400,
                    foregroundColor: canBook ? cardColor : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    _getButtonText(
                        canBook, isBooked, state.userHasBooking, isUserTable),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText(
      bool canBook, bool isBooked, bool userHasBooking, bool isUserTable) {
    if (isUserTable) return 'Your Table';
    if (!canBook && userHasBooking) return 'Already Booked';
    if (isBooked) return 'Occupied';
    if (canBook) return 'Book Now';
    return 'Not Available';
  }

  void _showBookingConfirmation(
      BuildContext context, Map<String, dynamic> table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book Table ${table['table_number']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Table Number: ${table['table_number']}'),
            Text('Capacity: ${table['capacity']} seats'),
            Text('Available: ${table['available_seats']} seats'),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to book this table?',
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
              context
                  .read<TableBloc>()
                  .add(BookTableEvent(tableId: table['id']));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Book Table'),
          ),
        ],
      ),
    );
  }
}
