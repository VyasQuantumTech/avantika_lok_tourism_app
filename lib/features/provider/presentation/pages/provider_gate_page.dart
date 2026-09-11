import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/domain/usecases/logout_user.dart';
import '../../domain/entities/provider_account_status.dart';
import '../../domain/usecases/check_provider_status.dart';

class ProviderGatePage extends StatefulWidget {
  const ProviderGatePage({super.key});

  @override
  State<ProviderGatePage> createState() => _ProviderGatePageState();
}

class _ProviderGatePageState extends State<ProviderGatePage> {
  bool _checking = true;
  bool _loggingOut = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkProviderStatus();
  }

  Future<void> _checkProviderStatus() async {
    if (mounted) {
      setState(() {
        _checking = true;
        _error = null;
      });
    }

    try {
      final status = await getIt<CheckProviderStatus>()();
      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        _resolveDestination(status),
        (_) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = 'Unable to verify your provider profile right now.';
      });
    }
  }

  String _resolveDestination(ProviderAccountStatus status) {
    if (!status.isProvider) {
      return RouteNames.providerRegistration;
    }

    switch (status.providerType) {
      case 'pandit':
        return RouteNames.panditDashboard;
      case 'hotel_manager':
        return RouteNames.accommodationDashboard;
      case 'vehicle_owner':
        return RouteNames.transportDashboard;
      default:
        // Existing/legacy providers with an unsupported type must not be sent
        // into a wrong dashboard. Keep them on the gate with a useful error.
        throw ApiException(
          'Provider type "${status.providerType ?? 'unknown'}" is not supported by this app yet.',
        );
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    try {
      await getIt<LogoutUser>()();
    } catch (_) {
      // AuthRepository always clears the local session in its own finally.
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _checking
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 18),
                      Text(
                        'Checking provider profile...',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 44,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Could not open provider dashboard',
                        textAlign: TextAlign.center,
                        style: AppTypography.sectionTitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ?? 'Please try again.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _checkProviderStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Retry'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loggingOut ? null : _logout,
                        child: Text(_loggingOut ? 'Signing out...' : 'Sign out'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
