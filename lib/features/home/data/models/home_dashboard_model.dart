import '../../domain/entities/home_dashboard.dart';

class HomeDashboardModel extends HomeDashboard {
  const HomeDashboardModel({
    required super.profile,
    required super.services,
    required super.destinations,
    required super.accommodations,
    required super.menu,
    required super.secondaryMenu,
  });

  factory HomeDashboardModel.fromJson(Map<String, dynamic> json) {
    return HomeDashboardModel(
      profile: UserProfileModel.fromJson(json['profile'] as Map<String, dynamic>),
      services: (json['services'] as List<dynamic>)
          .map((item) => ServiceItemModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      destinations: (json['destinations'] as List<dynamic>)
          .map((item) => DestinationItemModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      accommodations: (json['accommodations'] as List<dynamic>)
          .map((item) => AccommodationItemModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      menu: (json['menu'] as List<dynamic>)
          .map((item) => MenuItemModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      secondaryMenu: (json['secondaryMenu'] as List<dynamic>)
          .map((item) => MenuItemModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.name,
    required super.email,
    required super.avatar,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String,
    );
  }
}

class ServiceItemModel extends ServiceItem {
  const ServiceItemModel({required super.title, required super.icon});

  factory ServiceItemModel.fromJson(Map<String, dynamic> json) {
    return ServiceItemModel(
      title: json['title'] as String,
      icon: json['icon'] as String,
    );
  }
}

class DestinationItemModel extends DestinationItem {
  const DestinationItemModel({required super.title, required super.image});

  factory DestinationItemModel.fromJson(Map<String, dynamic> json) {
    return DestinationItemModel(
      title: json['title'] as String,
      image: json['image'] as String,
    );
  }
}

class AccommodationItemModel extends AccommodationItem {
  const AccommodationItemModel({
    required super.name,
    required super.address,
    required super.price,
    required super.image,
    required super.isFavorite,
  });

  factory AccommodationItemModel.fromJson(Map<String, dynamic> json) {
    return AccommodationItemModel(
      name: json['name'] as String,
      address: json['address'] as String,
      price: (json['price'] as num).toInt(),
      image: json['image'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

class MenuItemModel extends MenuItem {
  const MenuItemModel({required super.title, required super.icon});

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      title: json['title'] as String,
      icon: json['icon'] as String,
    );
  }
}
