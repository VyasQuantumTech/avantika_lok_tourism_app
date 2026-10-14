class HomeDashboard {
  const HomeDashboard({
    required this.profile,
    this.sections = const [],
    required this.services,
    required this.destinations,
    required this.accommodations,
    required this.menu,
    required this.secondaryMenu,
  });

  final List<HomeFeedSection> sections;
  final UserProfile profile;
  final List<ServiceItem> services;
  final List<DestinationItem> destinations;
  final List<AccommodationItem> accommodations;
  final List<MenuItem> menu;
  final List<MenuItem> secondaryMenu;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.avatar,
  });

  final String name;
  final String email;
  final String avatar;
}

class ServiceItem {
  const ServiceItem({required this.title, required this.icon});

  final String title;
  final String icon;
}

class DestinationItem {
  const DestinationItem({required this.title, required this.image});

  final String title;
  final String image;
}

class AccommodationItem {
  const AccommodationItem({
    required this.name,
    required this.address,
    required this.price,
    required this.image,
    required this.isFavorite,
  });

  final String name;
  final String address;
  final int price;
  final String image;
  final bool isFavorite;
}

class MenuItem {
  const MenuItem({required this.title, required this.icon});

  final String title;
  final String icon;
}

class HomeFeedSection {
  const HomeFeedSection(
      {required this.type, required this.title, required this.items});
  final String type;
  final String title;
  final List<HomeFeedItem> items;
}

class HomeFeedItem {
  const HomeFeedItem(
      {required this.id,
      required this.type,
      required this.title,
      this.slug = '',
      this.summary = '',
      this.imageUrl = '',
      this.location = '',
      this.prices = const [],
      this.eventAt,
      this.favoriteId});
  final String id, type, title, slug, summary, imageUrl, location;
  final List<String> prices;
  final DateTime? eventAt;
  final String? favoriteId;
  bool get canSave => const [
        'place',
        'pooja',
        'accommodation',
        'transport',
        'package'
      ].contains(type);
}

class HomeFeedPage {
  const HomeFeedPage({required this.items, required this.hasNextPage});
  final List<HomeFeedItem> items;
  final bool hasNextPage;
}

class HomePackageDetail {
  const HomePackageDetail(
      {required this.title,
      required this.description,
      required this.durationDays,
      required this.durationNights,
      required this.itinerary,
      required this.prices,
      required this.inclusions,
      required this.exclusions});
  final String title, description;
  final int durationDays, durationNights;
  final List<String> itinerary, prices, inclusions, exclusions;
}
