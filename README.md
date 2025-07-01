# Mezbaan (मेज़बान)

## Problem Statement

Restaurants need a simple system where customers can:
- Check table availability and book tables
- Browse menu and place orders
- Manage their bookings and orders
- All functionality should work offline without internet dependency

## Approach and Design Choices
figma : ```https://www.figma.com/design/ulCcWjJaWfaR7chsL9bm0e/Untitled?node-id=0-1&t=Jlm6fxEW2u8C2Ime-1```

### Architecture
- **Clean Architecture** with clear separation of concerns
- **BLoC Pattern** for state management
- **Repository Pattern** for data access
- **SQLite** for offline-first local storage

### Key Design Decisions
1. **Offline-First**: All data stored locally using SQLite, no network dependency
2. **Seat-Based Booking**: Multiple users can book same table if seats available (4 seats per table)
3. **Check-in System**: Users must check-in to place orders, ensuring they're physically present authentication persistence
4. **Time Handling**: Epoch timestamps in database, IST display for users
5. **Currency**: Indian Rupee (₹) with paise-based storage for accuracy

### Technical Stack
- Flutter (Dart 3.4)
- SQLite (sqflite package)
- BLoC for state management
- Auto Route for navigation

### Database Schema
- **Users**: Authentication and profile data
- **Tables**: 8 tables with 4 seats each
- **Bookings**: User table reservations with check-in/checkout
- **Menu Items**: Restaurant menu with categories and pricing
- **Orders**: Customer orders with items and status tracking

## Setup Instructions

### Prerequisites
- Flutter SDK (Dart 3.4+)
- Android Studio or VS Code
- Android device/emulator

### Installation Steps
1. **Clone and setup**
   ```bash
   git clone https://github.com/ritikegov/Restaurant-App.git
   cd restaurant-app
   flutter pub get
   ```

2. **Generate route files**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### First Run
1. Create user account through signup
2. Start using the app

## Assumptions Made

### Business Logic
- Restaurant has 8 tables, each with 4 seats
- Users can book only 1 seat per booking
- Multiple users can share same table if seats available
- Users must check-in physically to place orders
- No time restrictions - users can book again immediately after checkout
- Orders can only be placed after check-in

### Technical Assumptions
- App runs on Android devices
- No network connectivity required
- Users understand basic smartphone navigation
- Single restaurant location (no multi-location support)
- English language only
- Indian currency and timezone

### Data Assumptions
- User credentials stored locally (no cloud sync)
- No payment integration (order tracking only)
- No real-time notifications
- Data persists until app uninstall
- No data backup/restore functionality



## Key Features

- **Authentication**: Simple signup/login with validation
- **Table Booking**: Visual table selection with availability colors
- **Menu Browsing**: Categorized menu with cart functionality  
- **Order Management**: Place orders and view history
- **Profile**: User information and quick actions

## File Structure
```
lib/
├── core/           ------> Constants, database, utilities
├── models/         ------> Data models
├── repositories/   ------> Data access layer
├── bloc/           ------> State management
├── pages/          ------> UI screens
├── widgets/        ------> Reusable components
└── main.dart       ------> App entry point
```

