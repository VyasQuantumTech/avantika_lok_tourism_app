import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class PanditPoojaServicesPage extends StatefulWidget {
  const PanditPoojaServicesPage({super.key});

  @override
  State<PanditPoojaServicesPage> createState() => _PanditPoojaServicesPageState();
}

class _PanditPoojaServicesPageState extends State<PanditPoojaServicesPage> {
  late Future<PanditPoojaDashboard> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = getIt<PanditPoojaActions>().dashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Pooja Services'),
        actions: [
          IconButton(
            tooltip: 'Add Pooja',
            onPressed: () async {
              await Navigator.of(context).pushNamed(RouteNames.panditPoojaForm);
              if (mounted) setState(_reload);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<PanditPoojaDashboard>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text(
                snapshot.error is ApiException
                    ? (snapshot.error! as ApiException).message
                    : 'Unable to load Pandit services.',
              ),
            );
          }
          final dashboard = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${dashboard.offerings.length} offerings • ${dashboard.pendingActionBookings} bookings need action',
              ),
              const SizedBox(height: 12),
              if (dashboard.offerings.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No Pooja offering yet. Add one and it will be submitted for admin approval.',
                    ),
                  ),
                )
              else
                ...dashboard.offerings.map(
                  (offering) => Card(
                    child: ListTile(
                      title: Text(offering.name),
                      subtitle: Text(
                        '₹${offering.priceAmount.toStringAsFixed(0)} • ${offering.serviceMode} • ${offering.approvalStatus}',
                      ),
                      trailing: Icon(
                        offering.isActive
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                      ),
                      onTap: () async {
                        await Navigator.of(context).pushNamed(
                          RouteNames.panditPoojaForm,
                          arguments: offering,
                        );
                        if (mounted) setState(_reload);
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
