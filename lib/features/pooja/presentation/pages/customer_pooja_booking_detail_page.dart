import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class CustomerPoojaBookingDetailPage extends StatefulWidget {
  const CustomerPoojaBookingDetailPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  State<CustomerPoojaBookingDetailPage> createState() => _CustomerPoojaBookingDetailPageState();
}

class _CustomerPoojaBookingDetailPageState extends State<CustomerPoojaBookingDetailPage> {
  late Future<PoojaBooking> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = getIt<CustomerPoojaActions>().booking(widget.bookingId);

  String _poojaName(PoojaBooking booking) =>
      booking.pricingSnapshot['poojaName']?.toString() ??
      booking.pricingSnapshot['name']?.toString() ??
      'Pooja';

  String _panditName(PoojaBooking booking) =>
      booking.pricingSnapshot['panditName']?.toString() ??
      booking.pricingSnapshot['providerName']?.toString() ??
      'Pandit';

  String _money(PoojaBooking booking) {
    final code = booking.currency.trim().toUpperCase();
    return '${code == 'INR' ? '₹' : '$code '}${booking.totalAmount.toStringAsFixed(0)}';
  }

  String _status(PoojaBooking booking) {
    if (booking.isCompleted) return 'Completed';
    if (booking.isInProgress) return 'Pooja in progress';
    if (booking.providerDecision == 'rejected') return 'Rejected by Pandit';
    if (booking.status == 'cancelled') return 'Cancelled';
    if (booking.isAwaitingPandit) return 'Waiting for Pandit';
    if (booking.providerDecision == 'accepted') return 'Confirmed';
    return booking.status;
  }

  Future<void> _withdraw(PoojaBooking booking) async {
    final yes = await AppDialogs.confirm(
      context,
      title: 'Withdraw request?',
      message: 'This booking is still waiting for the Pandit. Do you want to withdraw it?',
      confirmLabel: 'Withdraw',
      destructive: true,
    );
    if (!yes) return;
    await _run(() => getIt<CustomerPoojaActions>().withdraw(booking.id), 'Booking withdrawn.');
  }

  Future<void> _cancel(PoojaBooking booking) async {
    final reason = await AppDialogs.textInput(
      context,
      title: 'Cancel Pooja booking',
      label: 'Reason',
      helperText: 'Please provide a short cancellation reason.',
      confirmLabel: 'Cancel booking',
      maxLength: 250,
    );
    if (reason == null || reason.trim().length < 2) return;
    await _run(() => getIt<CustomerPoojaActions>().cancel(booking.id, reason.trim()), 'Booking cancelled.');
  }

  Future<void> _run(Future<PoojaBooking> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      AppFeedback.success(context, success);
      setState(_load);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } catch (_) {
      if (mounted) AppFeedback.error(context, 'Unable to complete this action.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(PoojaBooking booking) async {
    int rating = 5;
    final title = TextEditingController();
    final comment = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Review this Pooja'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      onPressed: () => setDialogState(() => rating = value),
                      icon: Icon(value <= rating ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.star),
                    );
                  }),
                ),
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Title (optional)')),
                const SizedBox(height: 10),
                TextField(
                  controller: comment,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'Your review', hintText: 'Tell us about your Pooja experience'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (comment.text.trim().length < 5) {
                  AppFeedback.error(context, 'Please write at least 5 characters.');
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
    if (submitted == true) {
      try {
        await getIt<CustomerPoojaActions>().review(
          bookingId: booking.id,
          rating: rating,
          title: title.text,
          comment: comment.text,
        );
        if (mounted) AppFeedback.success(context, 'Review submitted for approval.');
      } on ApiException catch (error) {
        if (mounted) AppFeedback.error(context, error.message);
      } catch (_) {
        if (mounted) AppFeedback.error(context, 'Unable to submit your review.');
      }
    }
    title.dispose();
    comment.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Booking Details',
      subtitle: 'Status, OTPs and service information',
      child: FutureBuilder<PoojaBooking>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(message: 'Loading booking details…');
          }
          if (snapshot.hasError || snapshot.data == null) {
            final error = snapshot.error;
            return AppErrorState(
              message: error is ApiException ? error.message : 'Unable to load booking details.',
              onRetry: () => setState(_load),
            );
          }
          final booking = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(_load);
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                            child: Icon(Icons.temple_hindu_outlined, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_poojaName(booking), style: AppTypography.title),
                                const SizedBox(height: 3),
                                Text(_panditName(booking), style: AppTypography.caption),
                              ],
                            ),
                          ),
                          Text(_money(booking), style: AppTypography.title.copyWith(color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          AppStatusChip(label: _status(booking)),
                          const Spacer(),
                          Text(booking.bookingNumber, style: AppTypography.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppPanel(
                  child: Column(
                    children: [
                      AppDetailRow(label: 'Service date', value: booking.serviceDate, icon: Icons.calendar_today_outlined),
                      AppDetailRow(label: 'Start time', value: booking.startTime?.substring(0, booking.startTime!.length >= 5 ? 5 : booking.startTime!.length) ?? '—', icon: Icons.schedule_outlined),
                      AppDetailRow(label: 'Pandit', value: _panditName(booking), icon: Icons.person_outline_rounded),
                      AppDetailRow(label: 'Amount', value: _money(booking), icon: Icons.payments_outlined),
                      if (booking.notes?.trim().isNotEmpty == true)
                        AppDetailRow(label: 'Notes', value: booking.notes!, icon: Icons.notes_rounded),
                    ],
                  ),
                ),
                if (booking.hasCustomerOtpAccess) ...[
                  const SizedBox(height: 14),
                  AppPanel(
                    backgroundColor: AppColors.primarySoft,
                    borderColor: AppColors.brandBorder,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pooja verification OTPs', style: AppTypography.sectionTitle),
                        const SizedBox(height: 5),
                        Text(
                          booking.isInProgress
                              ? 'Pooja has started. Share the End OTP only after the Pooja is fully completed.'
                              : 'Share the Start OTP only when the Pooja is ready to begin. Keep the End OTP private until completion.',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _OtpTile(label: 'START OTP', otp: booking.poojaStartOtp, icon: Icons.play_circle_outline_rounded)),
                            const SizedBox(width: 10),
                            Expanded(child: _OtpTile(label: 'END OTP', otp: booking.poojaEndOtp, icon: Icons.stop_circle_outlined)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_busy) const LinearProgressIndicator(),
                if (booking.isAwaitingPandit)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _withdraw(booking),
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Withdraw Booking'),
                    ),
                  ),
                if (booking.canCustomerCancel && booking.serviceStartedAt == null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _cancel(booking),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Booking'),
                    ),
                  ),
                ],
                if (booking.isCompleted) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _review(booking),
                      icon: const Icon(Icons.star_outline_rounded),
                      label: const Text('Write Review'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OtpTile extends StatelessWidget {
  const _OtpTile({required this.label, required this.otp, required this.icon});

  final String label;
  final String? otp;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final value = otp?.trim();
    final available = value != null && value.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(13)),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 21),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.tiny.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          SelectableText(
            available ? value : '------',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              letterSpacing: 2.2,
              color: available ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
