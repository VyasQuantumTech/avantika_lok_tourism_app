import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../constants/asset_constants.dart';

/// Shared decoration only: navigation, forms and page state stay in their pages.
class TempleArt {
  const TempleArt._();

  static LinearGradient get brandGradient => AppColors.brandGradient;

  static DecorationImage headerImage({bool strong = false}) => DecorationImage(
        image: const ExactAssetImage(AssetConstants.templeLandscape),
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        colorFilter: ColorFilter.mode(
          strong
              ? AppColors.primaryDark.withValues(alpha: .76)
              : AppColors.background.withValues(alpha: .78),
          BlendMode.srcOver,
        ),
      );
}

class TempleAppBarBackground extends StatelessWidget {
  const TempleAppBarBackground({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          image: TempleArt.headerImage(),
          border: Border(bottom: BorderSide(color: AppColors.brandBorder)),
        ),
      );
}

/// Locally bundled artwork; the gentle fade keeps content legible on long pages.
class TempleBackdrop extends StatelessWidget {
  const TempleBackdrop({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.brandSoft,
                        AppColors.background,
                        AppColors.background
                      ],
                      stops: const [0, .32, 1],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 215,
                        child: ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Colors.white,
                              Colors.transparent
                            ],
                            stops: [0, .55, 1],
                          ).createShader(rect),
                          blendMode: BlendMode.dstIn,
                          child: Opacity(
                            opacity: .24,
                            child: Image.asset(AssetConstants.templeLandscape,
                                scale: 1,
                                fit: BoxFit.cover,
                                alignment: Alignment.bottomCenter),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 230,
                        child: ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.white],
                          ).createShader(rect),
                          blendMode: BlendMode.dstIn,
                          child: Opacity(
                            opacity: .10,
                            child: Image.asset(AssetConstants.templeLandscape,
                                scale: 1,
                                fit: BoxFit.cover,
                                alignment: Alignment.bottomCenter),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      );
}

/// Retains Flutter's Scaffold behavior, adding the same backdrop to every screen.
class TempleScaffold extends StatelessWidget {
  const TempleScaffold({
    super.key,
    this.appBar,
    this.body,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: appBar,
        backgroundColor: backgroundColor ?? AppColors.background,
        drawer: drawer,
        body: TempleBackdrop(child: body ?? const SizedBox.expand()),
        bottomNavigationBar: bottomNavigationBar == null
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.surface, AppColors.brandSoft]),
                  border: Border(top: BorderSide(color: AppColors.brandBorder)),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, -4))
                  ],
                ),
                child: bottomNavigationBar,
              ),
        floatingActionButton: floatingActionButton,
      );
}

/// Flutter destinations and callbacks are preserved; only the selected art changes.
class TempleNavigationBar extends StatelessWidget {
  const TempleNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.height,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<Widget> destinations;
  final double? height;

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        height: height,
        indicatorColor: Colors.transparent,
        destinations: [
          for (final destination in destinations)
            if (destination is NavigationDestination)
              NavigationDestination(
                icon: destination.icon,
                label: destination.label,
                tooltip: destination.tooltip,
                enabled: destination.enabled,
                selectedIcon: Container(
                  width: 56,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: TempleArt.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: .15),
                          blurRadius: 10)
                    ],
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: AppColors.onPrimary, size: 24),
                    child: destination.selectedIcon ?? destination.icon,
                  ),
                ),
              )
            else
              destination,
        ],
      );
}
