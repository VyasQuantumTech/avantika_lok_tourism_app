import 'package:flutter/material.dart';

import '../../widgets/provider_dashboard_shell.dart';

class AccommodationDashboardPage extends StatelessWidget {
  const AccommodationDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderDashboardShell(
      config: ProviderDashboardConfig(
        partnerTitle: 'Avantika Lok\nStay Partner',
        quickActions: [
          ProviderQuickAction(icon: Icons.hotel, label: 'Add Room/Offer'),
          ProviderQuickAction(icon: Icons.calendar_month, label: 'Block Dates'),
          ProviderQuickAction(icon: Icons.account_balance_wallet, label: 'View Earnings'),
        ],
        metrics: [
          ProviderMetric(
            label: "Today's Income",
            value: '₹ 12,800',
            footer: '↑ 18% today',
            icon: Icons.currency_rupee,
          ),
          ProviderMetric(
            label: 'Pending Check-ins',
            value: '5',
            footer: 'Action Needed',
            icon: Icons.login,
          ),
          ProviderMetric(
            label: 'Overall Rating',
            value: '4.7 ★',
            footer: 'Top Rated',
            icon: Icons.star,
          ),
        ],
        todayTitle: "Today's Arrivals (5)",
        todayBooking: ProviderBooking(
          icon: Icons.bed,
          title: 'Deluxe Twin Room, Shirdi Sai',
          lines: [
            'Arr: 14:00 – Dep: 12:00',
            'Customer: Vikram Singh',
            'Hotel: Shri Ganesh Sadan, Ujjain',
            'Payout: ₹ 4,200 (2 Nights)',
          ],
          primaryAction: 'CONFIRM ARRIVAL',
          secondaryAction: 'Call Guest',
        ),
        requestBooking: ProviderBooking(
          icon: Icons.bed,
          title: 'Suite Room, Kedarnath',
          lines: [
            'Check-in Tomorrow',
            'Customer: Priya Sharma',
            'Type: Resort Stay',
            'Net Earnings: ₹ 5,500',
          ],
          primaryAction: 'Accept',
          secondaryAction: 'Decline',
        ),
        listingsTitle: 'My Room Listings',
        listings: [
          ProviderListing(
            imageAsset: 'assets/images/accommodations/hotel_1.jpg',
            title: 'Deluxe Twin',
            price: '₹ 2,100 / Night',
          ),
          ProviderListing(
            imageAsset: 'assets/images/accommodations/hotel_2.jpg',
            title: 'Executive Suite',
            price: '₹ 5,500 / Night',
          ),
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
}
