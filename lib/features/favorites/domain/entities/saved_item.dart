import '../../../home/domain/entities/home_dashboard.dart';

class SavedItem {
  const SavedItem(
      {required this.id,
      required this.type,
      required this.targetId,
      this.item});
  final String id, type, targetId;
  final HomeFeedItem? item;
}
