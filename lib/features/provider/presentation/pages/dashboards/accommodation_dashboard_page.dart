import 'package:flutter/material.dart';
import '../../../../../app/router/route_names.dart';
import '../../widgets/provider_dashboard_shell.dart';

class AccommodationDashboardPage extends StatelessWidget {
  const AccommodationDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => const ProviderDashboardShell(
    config: ProviderDashboardConfig(
      expectedProviderType: 'hotel_manager',
      partnerTitle: 'Avantika Lok\nStay Partner',
      domainTitle: 'Accommodation Summary',
      quickActions: [
        ProviderQuickAction(icon: Icons.hotel_outlined, label: 'Manage Stays', routeName: RouteNames.providerAccommodationManagement),
        ProviderQuickAction(icon: Icons.calendar_month_outlined, label: 'Bookings', routeName: RouteNames.providerAccommodationBookings),
        ProviderQuickAction(icon: Icons.account_balance_wallet_outlined, label: 'View Earnings'),
      ],
      bottomItems: [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Bookings'),
        NavigationDestination(icon: Icon(Icons.apartment_outlined), label: 'Inventory'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Earnings'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    ),
  );
}
