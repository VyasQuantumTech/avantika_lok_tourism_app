import '../../../../core/ network/api_client.dart';
import '../../../../core/utils/media_urls.dart';
import '../../domain/entities/home_dashboard.dart';
import '../models/home_dashboard_model.dart';
import '../models/home_feed_model.dart';

abstract class HomeRemoteDataSource {
  Future<HomeDashboard> getDashboard();
  Future<HomePackageDetail> getPackage(String id);
  Future<HomeFeedPage> getSection(String type, int page);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this.api);
  final ApiClient api;
  @override
  Future<HomeFeedPage> getSection(String type, int page) async {
    final response = await api.get(
        '/api/v1/dashboard/sections/${Uri.encodeComponent(type)}?page=$page&limit=20',
        authenticated: true);
    final section = response['data']['section'] as Map;
    final pagination = section['pagination'] as Map;
    return HomeFeedPage(
        items: (section['items'] as List)
            .map((i) => HomeFeedItemModel.fromJson(
                Map<String, dynamic>.from(i as Map), api.baseUrl))
            .toList(),
        hasNextPage:
            (pagination['page'] as num) < (pagination['totalPages'] as num));
  }

  @override
  Future<HomePackageDetail> getPackage(String id) async {
    final response =
        await api.get('/api/v1/tourism/packages/${Uri.encodeComponent(id)}');
    final data = response['data'] as Map;
    final p = (data['package'] ?? data) as Map;
    return HomePackageDetail(
      title: '${p['title'] ?? ''}',
      description: '${p['description'] ?? p['summary'] ?? ''}',
      durationDays: (p['durationDays'] as num).toInt(),
      durationNights: (p['durationNights'] as num).toInt(),
      itinerary: (p['itinerary'] as List? ?? [])
          .map((day) =>
              "Day ${day['dayNumber']}: ${day['title'] ?? ''}\n${day['description'] ?? ''}")
          .toList(),
      prices: (p['pricing'] as List? ?? [])
          .map((price) => "${price['currency']} ${price['amount']}")
          .toList(),
      inclusions: (p['inclusions'] as List? ?? []).map((i) => '$i').toList(),
      exclusions: (p['exclusions'] as List? ?? []).map((i) => '$i').toList(),
    );
  }

  @override
  Future<HomeDashboard> getDashboard() async {
    final response = await api.get('/api/v1/dashboard', authenticated: true);
    final json =
        Map<String, dynamic>.from(response['data']['dashboard'] as Map);
    return HomeDashboard(
      profile: UserProfileModel.fromJson({
        ...Map<String, dynamic>.from(json['profile'] as Map),
        'avatar':
            resolveMediaUrl('${json['profile']['avatar'] ?? ''}', api.baseUrl)
      }),
      services: (json['services'] as List)
          .map((s) =>
              ServiceItemModel.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
      destinations: const [],
      accommodations: const [],
      menu: (json['menu'] as List? ?? [])
          .map((i) =>
              MenuItemModel.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      secondaryMenu: const [],
      sections: (json['sections'] as List)
          .map((s) => HomeFeedSection(
              type: '${s['type']}',
              title: '${s['title']}',
              items: (s['items'] as List)
                  .map((i) => HomeFeedItemModel.fromJson(
                      Map<String, dynamic>.from(i as Map), api.baseUrl))
                  .toList()))
          .toList(),
    );
  }
}
