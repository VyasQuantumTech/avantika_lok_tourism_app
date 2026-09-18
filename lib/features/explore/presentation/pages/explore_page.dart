import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/entities/tourism_place.dart';
import '../../domain/usecases/get_tourism_places.dart';
import '../widgets/explore_bottom_navigation.dart';
import '../widgets/tourism_place_card.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late Future<List<TourismPlace>> _future;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _future = getIt<GetTourismPlaces>()();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = getIt<GetTourismPlaces>()());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<TourismPlace>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingView(message: 'Discovering places…');
            }
            if (snapshot.hasError) {
              return AppErrorState(message: 'Unable to load tourism places from the live API.', onRetry: _reload);
            }

            final places = snapshot.data ?? const <TourismPlace>[];
            final categories = <String>['All'];
            for (final place in places) {
              for (final category in place.categories) {
                if (category.name.isNotEmpty && !categories.contains(category.name)) {
                  categories.add(category.name);
                }
              }
            }

            final filtered = places.where((place) {
              final matchesSearch = _query.trim().isEmpty ||
                  place.name.toLowerCase().contains(_query.toLowerCase()) ||
                  place.locationLabel.toLowerCase().contains(_query.toLowerCase());
              final matchesCategory = _selectedCategory == 'All' ||
                  place.categories.any((category) => category.name == _selectedCategory);
              return matchesSearch && matchesCategory;
            }).toList(growable: false);

            return Column(
              children: [
                _Header(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final selected = category == _selectedCategory;
                      return ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedCategory = category),
                        showCheckmark: false,
                        labelStyle: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: selected ? AppColors.onPrimary : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.softSurface,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const AppEmptyState(title: 'No places found', message: 'Try another search or category.', icon: Icons.travel_explore_rounded)
                      : RefreshIndicator(
                          color: AppColors.primaryDark,
                          onRefresh: () async {
                            final future = getIt<GetTourismPlaces>()();
                            setState(() => _future = future);
                            await future;
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: EdgeInsets.fromLTRB(
                              AppDimensions.pagePadding,
                              0,
                              AppDimensions.pagePadding,
                              18,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final place = filtered[index];
                              return TourismPlaceCard(
                                place: place,
                                onTap: () => Navigator.of(context).pushNamed(
                                  RouteNames.exploreDetail,
                                  arguments: place,
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const ExploreBottomNavigation(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppDimensions.pagePadding, 12, AppDimensions.pagePadding, 8),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.menu, size: 28),
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Explore Ujjain',
                  style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.search, color: AppColors.textPrimary, size: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.softSurface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: AppTypography.caption.copyWith(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Search places or locations',
                      hintStyle: AppTypography.caption.copyWith(fontSize: 11),
                      prefixIcon: Icon(Icons.search, color: AppColors.iconPink, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: Icon(Icons.tune, color: AppColors.onPrimary, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
