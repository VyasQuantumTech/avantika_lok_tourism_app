import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_ui.dart';
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

    if ((status.kycStatus ?? 'not_submitted') != 'approved') {
      return RouteNames.providerKyc;
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: _checking
                ? const AppLoadingView(message: 'Checking provider profile…')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not open provider dashboard',
                        message: _error ?? 'Please try again.',
                      ),
                      AppGradientButton(
                        label: 'Retry',
                        onPressed: _checkProviderStatus,
                        icon: Icons.refresh_rounded,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loggingOut ? null : _logout,
                        child: Text(_loggingOut ? 'Signing out…' : 'Sign out'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
