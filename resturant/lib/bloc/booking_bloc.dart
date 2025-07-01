import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/core/constants.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';

abstract class BookingEvent {}

class BookingCreate extends BookingEvent {
  final int userId;
  final int tableId;

  BookingCreate({required this.userId, required this.tableId});
}

class BookingCancel extends BookingEvent {
  final int bookingId;
  final int userId;

  BookingCancel({required this.bookingId, required this.userId});
}

class BookingCheckin extends BookingEvent {
  final int bookingId;
  final int userId;

  BookingCheckin({required this.bookingId, required this.userId});
}

class BookingModify extends BookingEvent {
  final int bookingId;
  final int userId;
  final int newTableId;

  BookingModify(
      {required this.bookingId,
      required this.userId,
      required this.newTableId});
}

class BookingCheckout extends BookingEvent {
  final int bookingId;
  final int userId;

  BookingCheckout({required this.bookingId, required this.userId});
}

class BookingLoadUserBooking extends BookingEvent {
  final int userId;

  BookingLoadUserBooking({required this.userId});
}

class BookingLoadHistory extends BookingEvent {
  final int userId;

  BookingLoadHistory({required this.userId});
}

class BookingCheckExpired extends BookingEvent {}

abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingLoaded extends BookingState {
  final List<BookingModel> bookings;
  final Map<String, dynamic>? userBooking;

  BookingLoaded({required this.bookings, this.userBooking});
}

class BookingSuccess extends BookingState {
  final String message;
  final BookingModel? booking;

  BookingSuccess({required this.message, this.booking});
}

class BookingError extends BookingState {
  final String message;

  BookingError({required this.message});
}

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository = BookingRepository();

  BookingBloc() : super(BookingInitial()) {
    on<BookingCreate>(_onCreateBooking);
    on<BookingCancel>(_onCancelBooking);
    on<BookingCheckin>(_onCheckinBooking);
    on<BookingModify>(_onModifyBooking);
    on<BookingCheckout>(_onCheckoutBooking);
    on<BookingLoadUserBooking>(_onLoadUserBooking);
    on<BookingLoadHistory>(_onLoadHistory);
    on<BookingCheckExpired>(_onCheckExpired);
  }

  Future<void> _onCreateBooking(
      BookingCreate event, Emitter<BookingState> emit) async {
    try {
      emit(BookingLoading());

      final booking =
          await _bookingRepository.createBooking(event.userId, event.tableId);

      if (booking != null) {
        emit(BookingSuccess(
          message: AppConstants.tableSuccessMessage,
          booking: booking,
        ));

        add(BookingLoadUserBooking(userId: event.userId));
      } else {
        emit(BookingError(message: AppConstants.errorCreateBooking));
      }
    } catch (e) {
      emit(BookingError(message: e.toString()));
    }
  }

  Future<void> _onCancelBooking(
      BookingCancel event, Emitter<BookingState> emit) async {
    try {
      emit(BookingLoading());

      final success =
          await _bookingRepository.cancelBooking(event.bookingId, event.userId);

      if (success) {
        emit(BookingSuccess(message: AppConstants.bookingCancelMessage));

        add(BookingLoadUserBooking(userId: event.userId));
      } else {
        emit(BookingError(message: AppConstants.errorBookingCancel));
      }
    } catch (e) {
      emit(BookingError(message: e.toString()));
    }
  }

  Future<void> _onCheckinBooking(
      BookingCheckin event, Emitter<BookingState> emit) async {
    try {
      emit(BookingLoading());

      final success = await _bookingRepository.checkinBooking(
          event.bookingId, event.userId);

      if (success) {
        emit(BookingSuccess(message: AppConstants.checkinSuccessMessage));

        add(BookingLoadUserBooking(userId: event.userId));
      } else {
        emit(BookingError(message: AppConstants.errorCheckinMessage));
      }
    } catch (e) {
      emit(BookingError(message: e.toString()));
    }
  }

  Future<void> _onModifyBooking(
      BookingModify event, Emitter<BookingState> emit) async {
    try {
      emit(BookingLoading());

      final success = await _bookingRepository.modifyBooking(
        event.bookingId,
        event.userId,
        event.newTableId,
      );

      if (success) {
        emit(BookingSuccess(message: AppConstants.bookingModifiedMessage));

        add(BookingLoadUserBooking(userId: event.userId));
      } else {
        emit(BookingError(message: AppConstants.errorBookingModified));
      }
    } catch (e) {
      emit(BookingError(message: e.toString()));
    }
  }

  Future<void> _onCheckoutBooking(
      BookingCheckout event, Emitter<BookingState> emit) async {
    try {
      emit(BookingLoading());

      final success = await _bookingRepository.checkoutBooking(
          event.bookingId, event.userId);

      if (success) {
        emit(BookingSuccess(message: AppConstants.checkoutSuccessMessage));

        add(BookingLoadUserBooking(userId: event.userId));
      } else {
        emit(BookingError(message: AppConstants.errorCheckoutMessage));
      }
    } catch (e) {
      emit(BookingError(message: e.toString()));
    }
  }

  Future<void> _onLoadUserBooking(
      BookingLoadUserBooking event, Emitter<BookingState> emit) async {
    try {
      final activeBooking =
          await _bookingRepository.getActiveBookingByUserId(event.userId);
      Map<String, dynamic>? userBookingDetails;

      if (activeBooking != null) {
        userBookingDetails =
            await _bookingRepository.getBookingWithDetails(activeBooking.id!);
      }

      final bookings =
          await _bookingRepository.getBookingsByUserId(event.userId);

      emit(BookingLoaded(
        bookings: bookings,
        userBooking: userBookingDetails,
      ));
    } catch (e) {
      emit(BookingError(
          message: '${AppConstants.failedUserLoad} ${e.toString()}'));
    }
  }

  Future<void> _onLoadHistory(
      BookingLoadHistory event, Emitter<BookingState> emit) async {
    try {
      emit(BookingLoading());

      final bookings =
          await _bookingRepository.getBookingsByUserId(event.userId);

      emit(BookingLoaded(bookings: bookings));
    } catch (e) {
      emit(BookingError(
          message: '${AppConstants.failedUserHistoryLoad} ${e.toString()}'));
    }
  }

  Future<void> _onCheckExpired(
      BookingCheckExpired event, Emitter<BookingState> emit) async {
    try {
      await _bookingRepository.handleExpiredBookings();
    } catch (e) {}
  }

  BookingModel? getCurrentUserBooking() {
    final currentState = state;
    if (currentState is BookingLoaded && currentState.userBooking != null) {
      try {
        return BookingModel.fromMap(currentState.userBooking!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool hasActiveBooking() {
    final booking = getCurrentUserBooking();
    return booking?.isActive == true || booking?.isCheckedIn == true;
  }
}
