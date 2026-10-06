import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
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

  void _reload() => _future = getIt<GetMyProfileDashboard>()();

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
                ProviderHeroCard(
                  eyebrow: 'Net collected',
                  value: '${financial.currency} ${financial.netCollected.toStringAsFixed(2)}',
                  subtitle: 'Captured payments after processed refunds',
                  icon: Icons.account_balance_wallet_rounded,
                ),
                SizedBox(height: AppDimensions.sectionGap),
                Row(
                  children: [
                    Expanded(
                      child: AppMetricCard(
                        label: 'Gross captured',
                        value: '${financial.currency} ${financial.grossCaptured.toStringAsFixed(0)}',
                        icon: Icons.south_west_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppMetricCard(
                        label: 'Refunded',
                        value: '${financial.currency} ${financial.processedRefunds.toStringAsFixed(0)}',
                        icon: Icons.replay_rounded,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.sectionGap),
                const AppSectionTitle(
                  title: 'Earnings breakdown',
                  subtitle: 'Only values supported by the current API are shown',
                ),
                const SizedBox(height: 10),
                AppPanel(
                  child: Column(
                    children: [
                      _MoneyRow(
                        label: 'Gross captured',
                        value: _money(financial.currency, financial.grossCaptured),
                        icon: Icons.payments_outlined,
                      ),
                      Divider(color: AppColors.divider),
                      _MoneyRow(
                        label: 'Processed refunds',
                        value: '- ${_money(financial.currency, financial.processedRefunds)}',
                        icon: Icons.replay_outlined,
                      ),
                      Divider(color: AppColors.divider),
                      _MoneyRow(
                        label: 'Net collected',
                        value: _money(financial.currency, financial.netCollected),
                        icon: Icons.account_balance_wallet_outlined,
                        strong: true,
                      ),
                    ],
                  ),
                ),
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
                        Icon(Icons.account_balance_outlined, color: AppColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Payout balance is not shown because the current backend does not expose a commission/payout ledger yet.',
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
