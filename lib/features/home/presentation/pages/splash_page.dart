import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_flavor.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
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
  static const Duration _splashDuration = Duration(milliseconds: 2800);

  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _verticalAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Completer<void> _animationCompleted = Completer<void>();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _splashDuration,
    );

    // Cinematic reveal: appear quickly, hold, then soften out before routing.
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 27,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 56,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 12,
      ),
    ]).animate(_controller);

    // Small overshoot gives impact without making the logo look bouncy.
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.72),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.72, end: 1.055).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.055, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.02).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 12,
      ),
    ]).animate(_controller);

    _verticalAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 12.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 65,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          !_animationCompleted.isCompleted) {
        _animationCompleted.complete();
      }
    });

    _controller.forward();
    unawaited(_playSplashSound());
    unawaited(_resolveInitialRoute());
  }

  Future<void> _playSplashSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(
        AssetSource('audio/splash_sound.mp3'),
        volume: 1,
      );
    } catch (_) {
      // Audio is optional. A missing/unsupported sound must never block startup.
    }
  }

  Future<void> _resolveInitialRoute() async {
    // Restore the session while the splash is animating so the animation does
    // not add avoidable waiting time after initialization has completed.
    final sessionFuture = getIt<RestoreSession>()();

    final results = await Future.wait<dynamic>([
      _animationCompleted.future,
      sessionFuture,
    ]);
    final signedIn = results[1] == true;

    if (!mounted) return;

    final config = getIt<AppConfig>();
    final String route;

    if (!signedIn) {
      route = RouteNames.login;
    } else if (config.flavor == AppFlavor.provider) {
      // Provider flavor must always verify the provider profile on app restore.
      route = RouteNames.providerGate;
    } else {
      route = RouteNames.home;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (_) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = getIt<AppConfig>();
    final isAdmin = config.flavor == AppFlavor.admin;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _verticalAnimation.value),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              ),
            );
          },
          child: isAdmin
              ? Column(
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
                      style: AppTypography.brandTitle.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'A Holy March',
                      style: AppTypography.brandSubtitle.copyWith(fontSize: 11),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Image.asset(
                    config.logoAsset,
                    width: 330,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
        ),
      ),
    );
  }
}
