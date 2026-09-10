import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../auth/domain/usecases/restore_session.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    unawaited(_resolveInitialRoute());
  }

  Future<void> _resolveInitialRoute() async {
    final minimumSplash = Future<void>.delayed(const Duration(milliseconds: 1200));
    final sessionFuture = getIt<RestoreSession>()();
    final results = await Future.wait<dynamic>([minimumSplash, sessionFuture]);
    final signedIn = results[1] == true;

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      signedIn ? RouteNames.home : RouteNames.login,
      (_) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AssetConstants.logoMark,
                    width: 205,
                    height: 194,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Avantika Lok',
                    style: AppTypography.brandTitle.copyWith(
                      fontSize: 30,
                      color: const Color(0xFFFF7424),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'A Holy March',
                    style: AppTypography.brandSubtitle.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
