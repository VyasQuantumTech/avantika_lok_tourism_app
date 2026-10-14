import 'package:flutter/material.dart';
import '../../../app/di/injection.dart';
import '../../../core/widgets/app_ui.dart';
import 'favorites_controller.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({required this.type, required this.targetId, super.key});
  final String type, targetId;
  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  @override
  void initState() {
    super.initState();
    getIt<FavoritesController>().load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = getIt<FavoritesController>();
    return ListenableBuilder(
        listenable: controller,
        builder: (_, __) {
          final saved = controller.idFor(widget.type, widget.targetId) != null;
          return IconButton(
            tooltip: saved ? 'Remove favourite' : 'Save favourite',
            icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                color: saved ? Theme.of(context).colorScheme.primary : null),
            onPressed: controller.busy.isNotEmpty
                ? null
                : () async {
                    try {
                      await controller.toggle(widget.type, widget.targetId);
                    } catch (_) {
                      if (context.mounted) {
                        AppFeedback.error(context,
                            'Unable to update favourite. Please retry.');
                      }
                    }
                  },
          );
        });
  }
}
