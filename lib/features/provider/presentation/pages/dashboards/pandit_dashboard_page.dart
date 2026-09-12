import 'package:flutter/material.dart';
import '../../widgets/provider_dashboard_shell.dart';

class PanditDashboardPage extends StatelessWidget {
  const PanditDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => const ProviderDashboardShell(
    config: ProviderDashboardConfig(
      expectedProviderType: 'pandit',
      partnerTitle: 'Avantika Lok\nPandit Partner',
      domainTitle: 'Pooja Service Summary',
      quickActions: [
        ProviderQuickAction(icon: Icons.add_circle_outline, label: 'Add New Pooja'),
        ProviderQuickAction(icon: Icons.calendar_month_outlined, label: 'Update Slots'),
        ProviderQuickAction(icon: Icons.account_balance_wallet_outlined, label: 'View Earnings'),
      ],
      bottomItems: [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.temple_hindu_outlined), label: 'Services'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Earnings'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    ),
  );
}
