import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

enum _BookingSort { newest, oldest, amountHigh, amountLow }

class CustomerPoojaBookingsPage extends StatefulWidget {
  const CustomerPoojaBookingsPage({super.key});

  @override
  State<CustomerPoojaBookingsPage> createState() => _CustomerPoojaBookingsPageState();
}

class _CustomerPoojaBookingsPageState extends State<CustomerPoojaBookingsPage>
    with SingleTickerProviderStateMixin {
  late Future<List<PoojaBooking>> _future;
  late TabController _tabs;
  final TextEditingController _search = TextEditingController();
  String _query = '';
  _BookingSort _sort = _BookingSort.newest;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this)..addListener(() => setState(() {}));
    _reload();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  void _reload() => _future = getIt<CustomerPoojaActions>().bookings();

  String _poojaName(PoojaBooking b) =>
      b.pricingSnapshot['poojaName']?.toString() ?? b.pricingSnapshot['name']?.toString() ?? 'Pooja';
  String _panditName(PoojaBooking b) =>
      b.pricingSnapshot['panditName']?.toString() ?? b.pricingSnapshot['providerName']?.toString() ?? 'Pandit';

  String _status(PoojaBooking b) {
    if (b.isCompleted) return 'Completed';
    if (b.isInProgress) return 'Pooja in progress';
    if (b.providerDecision == 'rejected') return 'Rejected by Pandit';
    if (b.status == 'cancelled') return 'Cancelled';
    if (b.isAwaitingPandit) return 'Waiting for Pandit';
    if (b.providerDecision == 'accepted') return 'Confirmed';
    return b.status;
  }

  bool _matchesTab(PoojaBooking b) {
    switch (_tabs.index) {
      case 0:
        return !b.isCompleted && b.status != 'cancelled' && b.providerDecision != 'rejected';
      case 1:
        return b.isCompleted;
      case 2:
        return b.status == 'cancelled' || b.providerDecision == 'rejected';
      default:
        return true;
    }
  }

  List<PoojaBooking> _visible(List<PoojaBooking> source) {
    final q = _query.trim().toLowerCase();
    final items = source.where((b) {
      if (!_matchesTab(b)) return false;
      if (q.isEmpty) return true;
      return '${_poojaName(b)} ${_panditName(b)} ${b.bookingNumber} ${_status(b)}'
          .toLowerCase()
          .contains(q);
    }).toList();

    DateTime date(PoojaBooking b) => DateTime.tryParse(b.serviceDate) ?? DateTime(1970);
    switch (_sort) {
      case _BookingSort.newest:
        items.sort((a, b) => date(b).compareTo(date(a)));
        break;
      case _BookingSort.oldest:
        items.sort((a, b) => date(a).compareTo(date(b)));
        break;
      case _BookingSort.amountHigh:
        items.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case _BookingSort.amountLow:
        items.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
    }
    return items;
  }

  String _money(PoojaBooking b) {
    final code = b.currency.trim().toUpperCase();
    final prefix = code == 'INR' ? '₹' : '$code ';
    return '$prefix${b.totalAmount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'My Pooja Bookings',
      subtitle: 'Track upcoming and completed services',
      actions: [
        IconButton(
          tooltip: 'Browse Poojas',
          onPressed: () => Navigator.of(context).pushNamed(RouteNames.poojas),
          icon: const Icon(Icons.temple_hindu_outlined),
        ),
      ],
      padding: EdgeInsets.zero,
      child: FutureBuilder<List<PoojaBooking>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(message: 'Loading your bookings…');
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return AppErrorState(
              message: error is ApiException ? error.message : 'Unable to load Pooja bookings.',
              onRetry: () => setState(_reload),
            );
          }
          final all = snapshot.data ?? const <PoojaBooking>[];
          if (all.isEmpty) {
            return AppEmptyState(
              title: 'No bookings yet',
              message: 'Book a Pooja and it will appear here with status and OTP details.',
              icon: Icons.receipt_long_outlined,
              actionLabel: 'Browse Poojas',
              onAction: () => Navigator.of(context).pushNamed(RouteNames.poojas),
            );
          }

          final items = _visible(all);
          return Column(
            children: [
              Material(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                    Tab(text: 'All'),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(_reload);
                    await _future;
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    children: [
                      AppSearchSortBar<_BookingSort>(
                        controller: _search,
                        hintText: 'Search Pooja, Pandit or booking no.',
                        sortValue: _sort,
                        onChanged: (value) => setState(() => _query = value),
                        onSortChanged: (value) {
                          if (value != null) setState(() => _sort = value);
                        },
                        sortItems: const [
                          DropdownMenuItem(value: _BookingSort.newest, child: Text('Newest')),
                          DropdownMenuItem(value: _BookingSort.oldest, child: Text('Oldest')),
                          DropdownMenuItem(value: _BookingSort.amountHigh, child: Text('Amount ↓')),
                          DropdownMenuItem(value: _BookingSort.amountLow, child: Text('Amount ↑')),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 54),
                          child: AppEmptyState(
                            title: 'Nothing here',
                            message: 'No bookings match the selected tab and search.',
                            icon: Icons.search_off_rounded,
                          ),
                        )
                      else
                        ...items.map((booking) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BookingCard(
                                booking: booking,
                                poojaName: _poojaName(booking),
                                panditName: _panditName(booking),
                                status: _status(booking),
                                amount: _money(booking),
                                onTap: () async {
                                  await Navigator.of(context).pushNamed(
                                    RouteNames.customerPoojaBookingDetail,
                                    arguments: booking.id,
                                  );
                                  if (mounted) setState(_reload);
                                },
                              ),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.poojaName,
    required this.panditName,
    required this.status,
    required this.amount,
    required this.onTap,
  });

  final PoojaBooking booking;
  final String poojaName;
  final String panditName;
  final String status;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = booking.startTime;
    final shortTime = time == null || time.isEmpty
        ? ''
        : time.substring(0, time.length >= 5 ? 5 : time.length);
    return AppPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.temple_hindu_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poojaName, style: AppTypography.sectionTitle),
                    Text('Pandit $panditName', style: AppTypography.caption),
                  ],
                ),
              ),
              Text(amount, style: AppTypography.title.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppStatusChip(label: status),
              const Spacer(),
              Text(booking.bookingNumber, style: AppTypography.tiny),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text('${booking.serviceDate}${shortTime.isEmpty ? '' : ' • $shortTime'}', style: AppTypography.caption),
              const Spacer(),
              Text('View details', style: AppTypography.label.copyWith(color: AppColors.primary)),
              Icon(Icons.chevron_right_rounded, size: 19, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}
