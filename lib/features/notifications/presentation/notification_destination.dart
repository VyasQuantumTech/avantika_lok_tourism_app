import '../../../app/config/app_flavor.dart';
import '../../../app/router/route_names.dart';
import '../domain/entities/app_notification.dart';

class NotificationDestination {
  const NotificationDestination(this.route, {this.arguments});
  final String route;
  final Object? arguments;
}

// Translate only supported, flavor-owned backend routes. Never navigate to a
// URL or an arbitrary route string supplied by a push payload.
NotificationDestination? notificationDestination(
    AppNotification item, AppFlavor flavor,
    {String? providerType}) {
  final expected = flavor == AppFlavor.user ? 'customer' : flavor.name;
  final uri = Uri.tryParse(item.route);
  if (item.appFlavor != expected ||
      uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  final parts = uri.pathSegments;
  if (parts.length < 2 || parts.length > 3 || parts.first != expected) {
    return null;
  }
  final entity = parts[1];
  if (flavor == AppFlavor.admin) {
    return null; // Admin operations live in the existing web panel.
  }
  if (flavor == AppFlavor.user) {
    switch (entity) {
      case 'bookings':
        final type = item.data['bookingType'];
        final id = item.data['bookingId']?.toString() ??
            (parts.length == 3 ? parts[2] : null);
        if (type == 'pooja' && id != null && id.isNotEmpty) {
          return NotificationDestination(RouteNames.customerPoojaBookingDetail,
              arguments: id);
        }
        return NotificationDestination(switch (type) {
          'pooja' => RouteNames.customerPoojaBookings,
          'accommodation' => RouteNames.customerAccommodationBookings,
          'transport' => RouteNames.customerTransportBookings,
          _ => RouteNames.customerBookings
        });
      case 'profile':
        return const NotificationDestination(RouteNames.customerProfile);
      case 'accommodations':
        return const NotificationDestination(RouteNames.accommodations);
      case 'transport':
        return const NotificationDestination(RouteNames.transport);
      case 'poojas':
        return const NotificationDestination(RouteNames.poojas);
    }
    return null;
  }
  switch (entity) {
    case 'kyc':
      return const NotificationDestination(RouteNames.providerKyc);
    case 'profile':
      return const NotificationDestination(RouteNames.providerProfile);
    case 'reviews':
      return const NotificationDestination(RouteNames.providerReviews);
    case 'dashboard':
      return const NotificationDestination(RouteNames.providerGate);
    case 'schedule':
      return providerType == 'pandit'
          ? const NotificationDestination(RouteNames.panditAvailability)
          : const NotificationDestination(RouteNames.providerGate);
    case 'bookings':
      return NotificationDestination(switch (providerType) {
        'pandit' => RouteNames.panditPoojaBookings,
        'hotel_manager' => RouteNames.providerAccommodationBookings,
        'vehicle_owner' => RouteNames.providerTransportBookings,
        _ => RouteNames.providerGate
      });
    case 'inventory':
    case 'accommodations':
    case 'transport':
    case 'poojas':
      return NotificationDestination(switch (providerType) {
        'pandit' => RouteNames.panditPoojaServices,
        'hotel_manager' => RouteNames.providerAccommodationManagement,
        'vehicle_owner' => RouteNames.providerTransportManagement,
        _ => RouteNames.providerGate
      });
  }
  return null;
}
