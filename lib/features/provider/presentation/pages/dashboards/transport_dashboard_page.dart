import 'package:flutter/material.dart';
import '../../../../../app/router/route_names.dart';
import '../../widgets/provider_dashboard_shell.dart';

class TransportDashboardPage extends StatelessWidget {
  const TransportDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => const ProviderDashboardShell(
    config: ProviderDashboardConfig(
      expectedProviderType: 'vehicle_owner',
      partnerTitle: 'Avantika Lok\nTransport Partner',
      domainTitle: 'Fleet & Route Summary',
      quickActions: [
        ProviderQuickAction(icon: Icons.directions_car_outlined, label: 'Manage Fleet', routeName: RouteNames.providerTransportManagement),
        ProviderQuickAction(icon: Icons.route_outlined, label: 'Rides', routeName: RouteNames.providerTransportBookings),
        ProviderQuickAction(icon: Icons.account_balance_wallet_outlined, label: 'View Earnings'),
      ],
      bottomItems: [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Rides'),
        NavigationDestination(icon: Icon(Icons.directions_car_outlined), label: 'Fleet'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Earnings'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    ),
  );
}
