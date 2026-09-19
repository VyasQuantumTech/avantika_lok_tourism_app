import 'package:flutter/material.dart';

class HomeIconMapper {
  const HomeIconMapper._();

  static IconData fromKey(String key) {
    switch (key) {
      case 'home':
        return Icons.home_outlined;
      case 'destinations':
        return Icons.alt_route_outlined;
      case 'hotel':
        return Icons.hotel_outlined;
      case 'puja':
        return Icons.self_improvement;
      case 'explore':
        return Icons.account_balance_outlined;
      case 'panditji':
        return Icons.person_outline;
      case 'vehicle':
      case 'transport':
        return Icons.directions_car_outlined;
      case 'settings':
        return Icons.settings_outlined;
      case 'signout':
        return Icons.logout;
      case 'about':
        return Icons.info_outline;
      case 'help':
        return Icons.chat_bubble_outline;
      case 'terms':
        return Icons.article_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}
