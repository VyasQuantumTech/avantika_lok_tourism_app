import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/health_status.dart';
import '../../domain/usecases/get_service_health.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  late Future<HealthStatus> _healthFuture;

  @override
  void initState() {
    super.initState();
    _loadHealth();
  }

  void _loadHealth() {
    _healthFuture = getIt<GetServiceHealth>()();
  }

  void _retry() {
    setState(_loadHealth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Health')),
      body: SafeArea(
        child: FutureBuilder<HealthStatus>(
          future: _healthFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        'Health API request failed',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final health = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                _retry();
                await _healthFuture;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(Icons.cloud_done, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Status: ${health.status}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (health.service != null) ...[
                    const SizedBox(height: 8),
                    Text('Service: ${health.service}', textAlign: TextAlign.center),
                  ],
                  if (health.timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text('Timestamp: ${health.timestamp}', textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    const JsonEncoder.withIndent('  ').convert(health.raw),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
