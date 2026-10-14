import 'package:flutter/foundation.dart';
import '../domain/entities/saved_item.dart';
import '../domain/usecases/favorites_actions.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this.actions);
  final FavoritesActions actions;
  List<SavedItem> items = [];
  final Set<String> busy = {};
  Object? error;
  Future<void>? _loading;
  bool loaded = false;
  int _session = 0;
  void reset() {
    _session++;
    items = [];
    busy.clear();
    loaded = false;
    error = null;
    _loading = null;
  }

  String? idFor(String type, String id) {
    for (final f in items) {
      if (f.type == type && f.targetId == id) return f.id;
    }
    return null;
  }

  Future<void> load({bool force = false}) {
    if (_loading != null) return _loading!;
    if (loaded && !force) return Future.value();
    final session = _session;
    _loading = _fetch(session);
    return _loading!;
  }

  Future<void> _fetch(int session) async {
    try {
      final result = await actions.list();
      if (session != _session) return;
      items = result;
      loaded = true;
      error = null;
    } catch (e) {
      if (session == _session) error = e;
    } finally {
      if (session == _session) {
        _loading = null;
        notifyListeners();
      }
    }
  }

  Future<void> toggle(String type, String targetId) async {
    final key = '$type:$targetId';
    if (busy.isNotEmpty) return;
    busy.add(key);
    notifyListeners();
    final session = _session;
    try {
      await load();
      if (session != _session) return;
      if (!loaded) throw error ?? StateError('Unable to load favourites');
      final id = idFor(type, targetId);
      if (id == null) {
        final savedId = await actions.save(type, targetId);
        if (session != _session) return;
        items = [
          ...items,
          SavedItem(id: savedId, type: type, targetId: targetId)
        ];
      } else {
        await actions.remove(id);
        if (session != _session) return;
        items = items.where((f) => f.id != id).toList();
      }
      await load(force: true);
    } finally {
      if (session == _session) {
        busy.remove(key);
        notifyListeners();
      }
    }
  }
}
