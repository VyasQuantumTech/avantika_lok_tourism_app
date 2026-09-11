import 'package:flutter/material.dart';

import '../../widgets/provider_dashboard_shell.dart';

class TransportDashboardPage extends StatelessWidget {
  const TransportDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderDashboardShell(
      config: ProviderDashboardConfig(
        partnerTitle: 'Avantika Lok\nTransport Partner',
        quickActions: [
          ProviderQuickAction(icon: Icons.add_box, label: 'Add Vehicle'),
          ProviderQuickAction(icon: Icons.directions_car, label: 'Manage Fleet'),
          ProviderQuickAction(icon: Icons.account_balance_wallet, label: 'View Earnings'),
        ],
        metrics: [
          ProviderMetric(
            label: "Today's Income",
            value: '₹ 9,200',
            footer: '↑ 18% today',
            icon: Icons.currency_rupee,
          ),
          ProviderMetric(
            label: 'Upcoming Rides',
            value: '4',
            footer: 'Action Needed',
            icon: Icons.route,
          ),
          ProviderMetric(
            label: 'Overall Rating',
            value: '4.8 ★',
            footer: 'Top Rated',
            icon: Icons.star,
          ),
        ],
        todayTitle: "Today's Rides (4)",
        todayBooking: ProviderBooking(
          icon: Icons.local_taxi,
          title: 'Sedan Trip to Omkareshwar',
          lines: [
            'Start 06:00 AM - 10:00 PM',
            'Customer: Amit Shah',
            'Pickup: Ujjain Railway Station',
            'Payout: ₹ 7,100 (Outstation)',
          ],
          primaryAction: 'START TRIP',
          secondaryAction: 'Call Customer',
        ),
        requestBooking: ProviderBooking(
          icon: Icons.local_taxi,
          title: 'Local City Tour',
          lines: [
            'Customer: Neha Joshi',
            'Type: Hourly Pkg (6 hrs)',
            'Pickup: Mahakal Lok',
            'Net Earnings: ₹ 2,800',
          ],
          primaryAction: 'Accept',
          secondaryAction: 'Decline',
        ),
        listingsTitle: 'My Vehicle Fleet',
        listings: [
          ProviderListing(
            imageAsset: 'assets/images/destinations/badrinath.jpg',
            title: 'Deluxe Sedan',
            price: '₹ 1,800 / Day',
          ),
          ProviderListing(
            imageAsset: 'assets/images/destinations/kedarnath.jpg',
            title: 'Family SUV',
            price: '₹ 3,500 / Day',
          ),
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
}
