import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'pages/auth/login_page.dart';
import 'pages/auth/signup_page.dart';
import 'pages/home/home_page.dart';
import 'pages/booking/booking_page.dart';
import 'pages/menu/menu_page.dart';
import 'pages/order/order_page.dart';
import 'pages/order/order_history_page.dart';
import 'pages/profile/profile_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
        // Auth Routes
        AutoRoute(
          page: LoginRoute.page,
          path: '/login',
          initial: true,
        ),
        AutoRoute(
          page: SignupRoute.page,
          path: '/signup',
        ),

        // Main App Routes
        AutoRoute(
          page: HomeRoute.page,
          path: '/home',
        ),
        AutoRoute(
          page: BookingRoute.page,
          path: '/booking',
        ),
        AutoRoute(
          page: MenuRoute.page,
          path: '/menu',
        ),
        AutoRoute(
          page: OrderRoute.page,
          path: '/order',
        ),
        AutoRoute(
          page: OrderHistoryRoute.page,
          path: '/order-history',
        ),
        AutoRoute(
          page: ProfileRoute.page,
          path: '/profile',
        ),
      ];
}
