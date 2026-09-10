class HomeDashboard {
  const HomeDashboard({
    required this.profile,
    required this.services,
    required this.destinations,
    required this.accommodations,
    required this.menu,
    required this.secondaryMenu,
  });

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
