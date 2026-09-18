import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class PanditPoojaBookingsPage extends StatefulWidget {
  const PanditPoojaBookingsPage({super.key});

  @override
  State<PanditPoojaBookingsPage> createState() => _PanditPoojaBookingsPageState();
}

class _PanditPoojaBookingsPageState extends State<PanditPoojaBookingsPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final TabController _tabController;
  late Future<List<PoojaBooking>> _future;
  String _query = '';
  String _sort = 'service_asc';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _reload() => _future = getIt<PanditPoojaActions>().bookings();

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _action(Future<PoojaBooking> future, String success) async {
    try {
      await future;
      if (!mounted) return;
      AppFeedback.success(context, success);
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    }
  }

  Future<void> _cancel(PoojaBooking booking) async {
    final reason = await AppDialogs.textInput(
      context,
      title: 'Cancel Pooja booking',
      label: 'Cancellation reason',
      helperText: 'This reason is stored with the booking.',
      confirmLabel: 'Cancel booking',
    );
    if (reason == null || reason.length < 2) return;
    await _action(
      getIt<PanditPoojaActions>().cancel(booking.id, reason),
      'Booking cancelled.',
    );
  }

  Future<void> _start(PoojaBooking booking) async {
    final otp = await AppDialogs.textInput(
      context,
      title: 'Start Pooja',
      label: 'Customer start OTP',
      helperText: 'Ask the customer for the 6-digit start OTP.',
      confirmLabel: 'Start Pooja',
      keyboardType: TextInputType.number,
      maxLength: 6,
    );
    if (otp?.length != 6) return;
    await _action(
      getIt<PanditPoojaActions>().start(booking.id, otp!),
      'Pooja started successfully.',
    );
  }

  Future<void> _end(PoojaBooking booking) async {
    final otp = await AppDialogs.textInput(
      context,
      title: 'Complete Pooja',
      label: 'Customer end OTP',
      helperText: 'Ask for the end OTP only after the Pooja is finished.',
      confirmLabel: 'Complete Pooja',
      keyboardType: TextInputType.number,
      maxLength: 6,
    );
    if (otp?.length != 6) return;
    await _action(
      getIt<PanditPoojaActions>().end(booking.id, otp!),
      'Pooja completed successfully.',
    );
  }

  String _name(PoojaBooking booking) =>
      booking.pricingSnapshot['poojaName']?.toString().trim().isNotEmpty == true
          ? booking.pricingSnapshot['poojaName'].toString()
          : 'Pooja booking';

  String _customer(PoojaBooking booking) {
    final snapshot = booking.customerSnapshot;
    final direct = snapshot['name']?.toString().trim();
    if (direct?.isNotEmpty == true) return direct!;
    final first = snapshot['firstName']?.toString().trim() ?? '';
    final last = snapshot['lastName']?.toString().trim() ?? '';
    final joined = '$first $last'.trim();
    return joined.isEmpty ? 'Customer' : joined;
  }

  bool _matches(PoojaBooking booking, int tab) {
    final status = booking.status.toLowerCase();
    final decision = booking.providerDecision.toLowerCase();
    switch (tab) {
      case 0:
        return booking.isAwaitingPandit || decision == 'pending';
      case 1:
        return !booking.isCompleted &&
            status != 'cancelled' &&
            decision == 'accepted';
      case 2:
        return booking.isCompleted;
      case 3:
        return status == 'cancelled' || decision == 'rejected';
      default:
        return true;
    }
  }

  List<PoojaBooking> _visible(List<PoojaBooking> bookings, int tab) {
    final q = _query.trim().toLowerCase();
    final result = bookings.where((booking) {
      if (!_matches(booking, tab)) return false;
      if (q.isEmpty) return true;
      return [
        _name(booking),
        _customer(booking),
        booking.bookingNumber,
        booking.status,
        booking.providerDecision,
        booking.serviceDate,
      ].any((value) => value.toLowerCase().contains(q));
    }).toList();

    result.sort((a, b) {
      switch (_sort) {
        case 'service_desc':
          return '${b.serviceDate} ${b.startTime ?? ''}'
              .compareTo('${a.serviceDate} ${a.startTime ?? ''}');
        case 'amount_high':
          return b.totalAmount.compareTo(a.totalAmount);
        case 'amount_low':
          return a.totalAmount.compareTo(b.totalAmount);
        default:
          return '${a.serviceDate} ${a.startTime ?? ''}'
              .compareTo('${b.serviceDate} ${b.startTime ?? ''}');
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pooja bookings'),
            Text('Manage customer bookings and service actions'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: FutureBuilder<List<PoojaBooking>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(message: 'Loading bookings…');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'Unable to load Pooja bookings.',
              onRetry: () => setState(_reload),
            );
          }
          final all = snapshot.data ?? const <PoojaBooking>[];
          return Padding(
            padding: EdgeInsets.all(AppDimensions.pagePadding),
            child: Column(
              children: [
                AppSearchSortBar<String>(
                  controller: _searchController,
                  hintText: 'Search booking, customer or Pooja',
                  sortValue: _sort,
                  onChanged: (value) => setState(() => _query = value),
                  onSortChanged: (value) => setState(() => _sort = value ?? 'service_asc'),
                  sortItems: const [
                    DropdownMenuItem(value: 'service_asc', child: Text('Service date ↑')),
                    DropdownMenuItem(value: 'service_desc', child: Text('Service date ↓')),
                    DropdownMenuItem(value: 'amount_high', child: Text('Amount high-low')),
                    DropdownMenuItem(value: 'amount_low', child: Text('Amount low-high')),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(4, (tab) {
                      return AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          final items = _visible(all, tab);
                          if (items.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: _refresh,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 100),
                                  AppEmptyState(
                                    title: 'No bookings here',
                                    message: 'Bookings matching this status and search will appear here.',
                                    icon: Icons.event_note_outlined,
                                  ),
                                ],
                              ),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final booking = items[index];
                                return _BookingCard(
                                  booking: booking,
                                  poojaName: _name(booking),
                                  customerName: _customer(booking),
                                  onDetails: () => _showDetails(booking),
                                  onAccept: booking.canPanditAccept
                                      ? () => _action(
                                            getIt<PanditPoojaActions>().accept(booking.id),
                                            'Booking accepted.',
                                          )
                                      : null,
                                  onReject: booking.canPanditAccept
                                      ? () => _action(
                                            getIt<PanditPoojaActions>().reject(booking.id),
                                            'Booking rejected.',
                                          )
                                      : null,
                                  onStart: booking.canPanditStart ? () => _start(booking) : null,
                                  onEnd: booking.canPanditEnd ? () => _end(booking) : null,
                                  onCancel: ((booking.status == 'pending' || booking.status == 'confirmed') &&
                                          booking.serviceStartedAt == null)
                                      ? () => _cancel(booking)
                                      : null,
                                );
                              },
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDetails(PoojaBooking booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.cardRadius)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        minChildSize: .5,
        maxChildSize: .92,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: EdgeInsets.all(AppDimensions.pagePadding),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Text(_name(booking), style: AppTypography.titleLarge)),
                AppStatusChip(label: booking.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('#${booking.bookingNumber}', style: AppTypography.caption),
            const SizedBox(height: 18),
            AppPanel(
              child: Column(
                children: [
                  AppDetailRow(label: 'Customer', value: _customer(booking), icon: Icons.person_outline),
                  AppDetailRow(label: 'Service date', value: booking.serviceDate, icon: Icons.calendar_today_outlined),
                  AppDetailRow(label: 'Start time', value: booking.startTime?.substring(0, 5) ?? '—', icon: Icons.schedule_outlined),
                  AppDetailRow(label: 'Amount', value: '${booking.currency} ${booking.totalAmount.toStringAsFixed(2)}', icon: Icons.payments_outlined),
                  AppDetailRow(label: 'Decision', value: booking.providerDecision, icon: Icons.fact_check_outlined),
                  if (booking.notes?.trim().isNotEmpty == true)
                    AppDetailRow(label: 'Notes', value: booking.notes!, icon: Icons.notes_outlined),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _BookingActions(
              booking: booking,
              onAccept: booking.canPanditAccept
                  ? () {
                      Navigator.pop(context);
                      _action(getIt<PanditPoojaActions>().accept(booking.id), 'Booking accepted.');
                    }
                  : null,
              onReject: booking.canPanditAccept
                  ? () {
                      Navigator.pop(context);
                      _action(getIt<PanditPoojaActions>().reject(booking.id), 'Booking rejected.');
                    }
                  : null,
              onStart: booking.canPanditStart
                  ? () {
                      Navigator.pop(context);
                      _start(booking);
                    }
                  : null,
              onEnd: booking.canPanditEnd
                  ? () {
                      Navigator.pop(context);
                      _end(booking);
                    }
                  : null,
              onCancel: ((booking.status == 'pending' || booking.status == 'confirmed') && booking.serviceStartedAt == null)
                  ? () {
                      Navigator.pop(context);
                      _cancel(booking);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.poojaName,
    required this.customerName,
    required this.onDetails,
    this.onAccept,
    this.onReject,
    this.onStart,
    this.onEnd,
    this.onCancel,
  });

  final PoojaBooking booking;
  final String poojaName;
  final String customerName;
  final VoidCallback onDetails;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.temple_hindu_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poojaName, style: AppTypography.sectionTitle),
                    const SizedBox(height: 3),
                    Text(customerName, style: AppTypography.caption),
                    const SizedBox(height: 4),
                    Text('#${booking.bookingNumber}', style: AppTypography.tiny),
                  ],
                ),
              ),
              AppStatusChip(label: booking.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('${booking.serviceDate} ${booking.startTime?.substring(0, 5) ?? ''}', style: AppTypography.caption),
              const Spacer(),
              Text('${booking.currency} ${booking.totalAmount.toStringAsFixed(0)}', style: AppTypography.label),
            ],
          ),
          const SizedBox(height: 12),
          _BookingActions(
            booking: booking,
            onAccept: onAccept,
            onReject: onReject,
            onStart: onStart,
            onEnd: onEnd,
            onCancel: onCancel,
            onDetails: onDetails,
          ),
        ],
      ),
    );
  }
}

class _BookingActions extends StatelessWidget {
  const _BookingActions({
    required this.booking,
    this.onAccept,
    this.onReject,
    this.onStart,
    this.onEnd,
    this.onCancel,
    this.onDetails,
  });

  final PoojaBooking booking;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final VoidCallback? onCancel;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onAccept != null)
          FilledButton.icon(onPressed: onAccept, icon: const Icon(Icons.check_rounded), label: const Text('Accept')),
        if (onReject != null)
          OutlinedButton.icon(onPressed: onReject, icon: const Icon(Icons.close_rounded), label: const Text('Reject')),
        if (onStart != null)
          FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start Pooja')),
        if (onEnd != null)
          FilledButton.icon(onPressed: onEnd, icon: const Icon(Icons.stop_circle_outlined), label: const Text('End Pooja')),
        if (onCancel != null)
          TextButton.icon(onPressed: onCancel, icon: const Icon(Icons.cancel_outlined), label: const Text('Cancel')),
        if (onDetails != null)
          TextButton.icon(onPressed: onDetails, icon: const Icon(Icons.visibility_outlined), label: const Text('Details')),
      ],
    );
  }
}
