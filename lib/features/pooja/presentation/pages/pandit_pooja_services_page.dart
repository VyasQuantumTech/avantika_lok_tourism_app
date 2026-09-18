import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class PanditPoojaServicesPage extends StatefulWidget {
  const PanditPoojaServicesPage({super.key});

  @override
  State<PanditPoojaServicesPage> createState() => _PanditPoojaServicesPageState();
}

class _PanditPoojaServicesPageState extends State<PanditPoojaServicesPage> {
  final _searchController = TextEditingController();
  late Future<PanditPoojaDashboard> _future;
  String _query = '';
  String _sort = 'name';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() => _future = getIt<PanditPoojaActions>().dashboard();

  List<PanditOffering> _visible(List<PanditOffering> source) {
    final q = _query.trim().toLowerCase();
    final result = source.where((offering) {
      if (q.isEmpty) return true;
      return [
        offering.name,
        offering.shortDescription ?? '',
        offering.serviceMode,
        offering.approvalStatus,
      ].any((value) => value.toLowerCase().contains(q));
    }).toList();
    result.sort((a, b) {
      switch (_sort) {
        case 'price_high':
          return b.priceAmount.compareTo(a.priceAmount);
        case 'price_low':
          return a.priceAmount.compareTo(b.priceAmount);
        case 'status':
          return a.approvalStatus.compareTo(b.approvalStatus);
        default:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
    return result;
  }

  Future<void> _openForm([PanditOffering? offering]) async {
    await Navigator.of(context).pushNamed(RouteNames.panditPoojaForm, arguments: offering);
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Pooja services',
      subtitle: 'Manage offerings submitted for listing',
      actions: [
        IconButton(
          tooltip: 'Add Pooja service',
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
      child: FutureBuilder<PanditPoojaDashboard>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(message: 'Loading Pooja services…');
          }
          if (snapshot.hasError || snapshot.data == null) {
            return AppErrorState(
              message: snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'Unable to load Pooja services.',
              onRetry: () => setState(_reload),
            );
          }
          final dashboard = snapshot.data!;
          final visible = _visible(dashboard.offerings);
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppMetricCard(
                        label: 'Offerings',
                        value: '${dashboard.offerings.length}',
                        footer: 'All configured services',
                        icon: Icons.temple_hindu_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppMetricCard(
                        label: 'Need action',
                        value: '${dashboard.pendingActionBookings}',
                        footer: 'Bookings pending action',
                        icon: Icons.pending_actions_outlined,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.sectionGap),
                AppSearchSortBar<String>(
                  controller: _searchController,
                  hintText: 'Search service, mode or status',
                  sortValue: _sort,
                  onChanged: (value) => setState(() => _query = value),
                  onSortChanged: (value) => setState(() => _sort = value ?? 'name'),
                  sortItems: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'price_high', child: Text('Price high-low')),
                    DropdownMenuItem(value: 'price_low', child: Text('Price low-high')),
                    DropdownMenuItem(value: 'status', child: Text('Approval status')),
                  ],
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  AppEmptyState(
                    title: dashboard.offerings.isEmpty ? 'No Pooja services yet' : 'No matching services',
                    message: dashboard.offerings.isEmpty
                        ? 'Add a Pooja service and submit it through the existing approval flow.'
                        : 'Try a different search term.',
                    icon: Icons.temple_hindu_outlined,
                    actionLabel: dashboard.offerings.isEmpty ? 'Add Pooja service' : null,
                    onAction: dashboard.offerings.isEmpty ? () => _openForm() : null,
                  )
                else
                  ...visible.map(
                    (offering) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OfferingCard(offering: offering, onEdit: () => _openForm(offering)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add service'),
      ),
    );
  }
}

class _OfferingCard extends StatelessWidget {
  const _OfferingCard({required this.offering, required this.onEdit});

  final PanditOffering offering;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.temple_hindu_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offering.name, style: AppTypography.sectionTitle),
                    const SizedBox(height: 4),
                    Text(
                      '${offering.currency} ${offering.priceAmount.toStringAsFixed(0)} • ${offering.serviceMode}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              AppStatusChip(label: offering.approvalStatus),
            ],
          ),
          if (offering.shortDescription?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              offering.shortDescription!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppStatusChip(label: offering.isActive ? 'active' : 'inactive'),
              if (offering.durationMinutes != null)
                AppStatusChip(label: '${offering.durationMinutes} min', tone: AppStatusTone.neutral),
              if (offering.media.isNotEmpty)
                AppStatusChip(label: '${offering.media.length} images', tone: AppStatusTone.info),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('View / edit service'),
            ),
          ),
        ],
      ),
    );
  }
}
