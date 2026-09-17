import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_typography.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle != null && subtitle!.trim().isNotEmpty)
              Text(subtitle!, style: AppTypography.caption),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: padding ?? EdgeInsets.all(AppDimensions.pagePadding),
          child: child,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

class AppPanel extends StatelessWidget {
  const AppPanel({
    required this.child,
    super.key,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: content,
      ),
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.sectionTitle),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: AppTypography.caption),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({required this.label, super.key, this.tone});

  final String label;
  final AppStatusTone? tone;

  @override
  Widget build(BuildContext context) {
    final effective = tone ?? AppStatusTone.fromValue(label);
    final colors = effective.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
      ),
      child: Text(
        _titleCase(label),
        style: AppTypography.tiny.copyWith(
          color: colors.$1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _titleCase(String input) => input
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

enum AppStatusTone {
  success,
  warning,
  error,
  info,
  neutral;

  static AppStatusTone fromValue(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('complete') || value.contains('approve') || value.contains('active') || value.contains('accept')) {
      return success;
    }
    if (value.contains('pending') || value.contains('upcoming') || value.contains('review') || value.contains('progress')) {
      return warning;
    }
    if (value.contains('cancel') || value.contains('reject') || value.contains('fail') || value.contains('inactive')) {
      return error;
    }
    if (value.contains('confirm') || value.contains('publish') || value.contains('listed')) {
      return info;
    }
    return neutral;
  }

  (Color, Color) get colors {
    switch (this) {
      case AppStatusTone.success:
        return (AppColors.success, AppColors.successSoft);
      case AppStatusTone.warning:
        return (AppColors.warning, AppColors.warningSoft);
      case AppStatusTone.error:
        return (AppColors.error, AppColors.errorSoft);
      case AppStatusTone.info:
        return (AppColors.info, AppColors.infoSoft);
      case AppStatusTone.neutral:
        return (AppColors.textSecondary, AppColors.softSurface);
    }
  }
}

class AppSearchSortBar<T> extends StatelessWidget {
  const AppSearchSortBar({
    required this.controller,
    required this.hintText,
    required this.sortValue,
    required this.sortItems,
    required this.onSortChanged,
    super.key,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final T sortValue;
  final List<DropdownMenuItem<T>> sortItems;
  final ValueChanged<T?> onSortChanged;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        controller.clear();
                        onChanged?.call('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          constraints: const BoxConstraints(minWidth: 52),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: sortValue,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              icon: const Icon(Icons.swap_vert_rounded),
              items: sortItems,
              onChanged: onSortChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
    this.onTap,
    this.footer,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTypography.titleLarge),
          const SizedBox(height: 3),
          Text(label, style: AppTypography.caption),
          if (footer != null) ...[
            const SizedBox(height: 6),
            Text(footer!, style: AppTypography.tiny),
          ],
        ],
      ),
    );
  }
}

class AppDetailRow extends StatelessWidget {
  const AppDetailRow({required this.label, required this.value, super.key, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 9),
          ],
          SizedBox(width: 110, child: Text(label, style: AppTypography.caption)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message = 'Loading…'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(message, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    required this.message,
    super.key,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(title, style: AppTypography.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: AppTypography.caption, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

class AppFeedback {
  const AppFeedback._();

  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle_outline_rounded);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.error, Icons.error_outline_rounded);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppColors.info, Icons.info_outline_rounded);

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: AppColors.onPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
        ),
      );
  }
}

class AppDialogs {
  const AppDialogs._();

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelLabel)),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                    : null,
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<String?> textInput(
    BuildContext context, {
    required String title,
    required String label,
    String? helperText,
    String confirmLabel = 'Continue',
    TextInputType? keyboardType,
    int? maxLength,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(labelText: label, helperText: helperText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
