import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/profile_dashboard.dart';
import '../../domain/usecases/get_my_profile_dashboard.dart';

class ProviderEarningsPage extends StatelessWidget {
  const ProviderEarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('My Earnings', style: AppTypography.sectionTitle),
        centerTitle: true,
      ),
      body: FutureBuilder<ProfileDashboard>(
        future: getIt<GetMyProfileDashboard>()(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final provider = snapshot.data?.provider;
          if (provider == null) {
            return const Center(child: Text('Unable to load earnings.'));
          }
          final f = provider.financial;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Column(
                  children: [
                    _MoneyRow(label: 'Gross Captured', value: _money(f.grossCaptured)),
                    const Divider(),
                    _MoneyRow(label: 'Processed Refunds', value: '- ${_money(f.processedRefunds)}'),
                    const Divider(),
                    _MoneyRow(label: 'Net Collected', value: _money(f.netCollected), strong: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                f.note ?? 'Amounts shown are based on captured payment transactions available from the backend.',
                style: AppTypography.caption,
              ),
              if (f.payoutBalance == null) ...[
                const SizedBox(height: 8),
                Text(
                  'Provider payout balance is not displayed because the current backend does not implement a commission/payout ledger yet.',
                  style: AppTypography.caption.copyWith(color: AppColors.headingPink),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static String _money(double value) => '₹${value.toStringAsFixed(2)}';
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body),
        Text(value, style: AppTypography.body.copyWith(fontWeight: strong ? FontWeight.w700 : FontWeight.w600, color: strong ? AppColors.headingPink : AppColors.textPrimary)),
      ],
    ),
  );
}
