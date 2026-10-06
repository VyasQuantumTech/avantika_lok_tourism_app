import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/provider_ui.dart';
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
      floatingActionButton: ProviderFloatingActionButton(
        onPressed: () => _openForm(),
        icon: Icons.add_rounded,
        label: 'Add service',
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
    return ProviderListCard(
      title: offering.name,
      subtitle: '${offering.currency} ${offering.priceAmount.toStringAsFixed(0)} • ${offering.serviceMode}${offering.durationMinutes == null ? '' : ' • ${offering.durationMinutes} min'}',
      imageUrl: offering.media.isEmpty ? null : offering.media.first.url,
      placeholderIcon: Icons.temple_hindu_rounded,
      status: offering.approvalStatus,
      meta: [
        ProviderMetaItem(Icons.toggle_on_outlined, offering.isActive ? 'Active' : 'Inactive'),
        ProviderMetaItem(Icons.photo_library_outlined, '${offering.media.length} images'),
      ],
      footer: offering.shortDescription?.trim().isNotEmpty == true
          ? Text(
              offering.shortDescription!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            )
          : null,
      actions: [
        ProviderSecondaryButton(
          label: 'View / edit service',
          onPressed: onEdit,
          icon: Icons.edit_outlined,
        ),
      ],
      onTap: onEdit,
    );
  }
}


class _PoojaPlaceholder extends StatelessWidget {
  const _PoojaPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.primarySoft, AppColors.brandSoft]),
    ),
    child: Icon(Icons.temple_hindu_rounded, color: AppColors.primary, size: 30),
  );
}
