import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/provider_ui.dart';
import '../../domain/entities/profile_dashboard.dart';
import '../../domain/usecases/get_my_profile_dashboard.dart';

class ProviderEarningsPage extends StatefulWidget {
  const ProviderEarningsPage({super.key});

  @override
  State<ProviderEarningsPage> createState() => _ProviderEarningsPageState();
}

class _ProviderEarningsPageState extends State<ProviderEarningsPage> {
  late Future<ProfileDashboard> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() { _future = getIt<GetMyProfileDashboard>()(); }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'My earnings',
      subtitle: 'Captured payments and refund summary',
      child: FutureBuilder<ProfileDashboard>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(message: 'Loading earnings…');
          }
          if (snapshot.hasError || snapshot.data?.provider == null) {
            return AppErrorState(
              message: snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'Unable to load earnings.',
              onRetry: () => setState(_reload),
            );
          }

          final financial = snapshot.data!.provider!.financial;
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const AppSectionTitle(
                    title: 'Earnings by currency',
                    subtitle: 'Captured payments after processed refunds'),
                if (financial.currencies.isEmpty)
                  const AppPanel(
                      child: Text('Financial summary is unavailable.')),
                for (final row in financial.currencies) ...[
                  const SizedBox(height: 12),
                  ProviderHeroCard(
                      eyebrow: 'Net collected',
                      value: _money(row.currency, row.netCollected),
                      subtitle: row.currency,
                      icon: Icons.account_balance_wallet_rounded),
                  const SizedBox(height: 12),
                  AppPanel(
                      child: Column(children: [
                    _MoneyRow(
                        label: 'Gross captured',
                        value: _money(row.currency, row.grossCaptured),
                        icon: Icons.payments_outlined),
                    Divider(color: AppColors.divider),
                    _MoneyRow(
                        label: 'Processed refunds',
                        value: _money(row.currency, row.processedRefunds),
                        icon: Icons.replay_outlined),
                    Divider(color: AppColors.divider),
                    _MoneyRow(
                        label: 'Net collected',
                        value: _money(row.currency, row.netCollected),
                        icon: Icons.account_balance_wallet_outlined,
                        strong: true),
                  ])),
                ],
                const SizedBox(height: 14),
                if (financial.note?.trim().isNotEmpty == true)
                  ProviderInfoBanner(
                    title: 'Earnings note',
                    message: financial.note!,
                  ),
                if (financial.payoutBalance == null) ...[
                  const SizedBox(height: 12),
                  AppPanel(
                    backgroundColor: AppColors.warningSoft,
                    borderColor: AppColors.warning.withValues(alpha: .2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.account_balance_outlined,
                            color: AppColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Payout balance is not available yet.',
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
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

  static String _money(String currency, double value) =>
      '$currency ${value.toStringAsFixed(2)}';
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    required this.icon,
    this.strong = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 11),
          Expanded(child: Text(label, style: AppTypography.body)),
          Text(
            value,
            style: AppTypography.label.copyWith(
              color: strong ? AppColors.primaryDark : AppColors.textPrimary,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
