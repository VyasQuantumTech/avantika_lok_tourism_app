import 'package:flutter/material.dart';

import '../../widgets/provider_dashboard_shell.dart';

class PanditDashboardPage extends StatelessWidget {
  const PanditDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderDashboardShell(
      config: ProviderDashboardConfig(
        partnerTitle: 'Avantika Lok\nPandit Partner',
        quickActions: [
          ProviderQuickAction(icon: Icons.add_circle, label: 'Add New Pooja'),
          ProviderQuickAction(icon: Icons.calendar_month, label: 'Update Slots'),
          ProviderQuickAction(icon: Icons.account_balance_wallet, label: 'View Earnings'),
        ],
        metrics: [
          ProviderMetric(
            label: "Today's Income",
            value: '₹ 4,500',
            footer: '↑ 18% today',
            icon: Icons.currency_rupee,
          ),
          ProviderMetric(
            label: 'Pending Orders',
            value: '3 Requests',
            footer: 'Action Needed',
            icon: Icons.receipt_long,
          ),
          ProviderMetric(
            label: 'Overall Rating',
            value: '4.9 ★',
            footer: 'Top Rated',
            icon: Icons.star,
          ),
        ],
        todayTitle: "Today's Bookings (3)",
        todayBooking: ProviderBooking(
          icon: Icons.temple_hindu,
          title: 'Mahamrityunjay Jaap',
          lines: [
            '10:30 AM - 12:00 PM',
            'Customer: Rahul Sharma',
            'Venue: Mahakaleshwar Temple Area, Ujjain',
            'Payout: ₹ 2,100 (Samagri Included)',
          ],
          primaryAction: 'START POOJA SERVICE',
          secondaryAction: 'Call Customer',
        ),
        requestBooking: ProviderBooking(
          icon: Icons.temple_hindu,
          title: 'Satyanarayan Katha',
          lines: [
            'Tomorrow, 09:00 AM',
            'Customer: Anita Patel',
            'Type: Home Visit (5 km away)',
            'Net Earnings: ₹ 1,500',
          ],
          primaryAction: 'Accept',
          secondaryAction: 'Decline',
        ),
        listingsTitle: 'My Pooja Services',
        listings: [
          ProviderListing(
            imageAsset: 'assets/images/destinations/ujjain.jpg',
            title: 'Rudrabhishek',
            price: '₹ 1,800 / Slot',
          ),
          ProviderListing(
            imageAsset: 'assets/images/destinations/somnath.jpg',
            title: 'Kalsarp Dosh Pooja',
            price: '₹ 3,500 / Slot',
          ),
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
}
