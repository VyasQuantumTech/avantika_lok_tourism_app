import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/usecases/booking_actions.dart';

class RideTrackingPanel extends StatefulWidget {
  const RideTrackingPanel({required this.bookingId, super.key});
  final String bookingId;
  @override
  State<RideTrackingPanel> createState() => _TrackingState();
}

class _TrackingState extends State<RideTrackingPanel> {
  late Future<Map<String, dynamic>> future;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() { future = getIt<BookingActions>().tracking(widget.bookingId); }
  @override
  Widget build(BuildContext context) => AppPanel(
      child: FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingView();
            }
            if (snapshot.hasError) {
              return AppErrorState(
                  message: snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'Unable to load ride updates.',
                  onRetry: () => setState(load));
            }
            final data = snapshot.data!;
            final assignment =
                data['assignment'] is Map ? data['assignment'] as Map : {};
            final driver =
                assignment['driver'] is Map ? assignment['driver'] as Map : {};
            final location =
                data['lastLocation'] is Map ? data['lastLocation'] as Map : {};
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ride updates',
                      style: Theme.of(context).textTheme.titleMedium),
                  AppDetailRow(
                      label: 'Driver',
                      value: '${driver['name'] ?? 'Awaiting assignment'}',
                      icon: Icons.person_outline),
                  if (assignment['arrivedAt'] != null)
                    const Text('Your driver has arrived.'),
                  if (location.isNotEmpty) ...[
                    Text(
                        'Last reported location: ${location['latitude']}, ${location['longitude']}'),
                    Text(
                        'Reported at: ${DateTime.tryParse('${location['recordedAt']}')?.toLocal() ?? location['recordedAt']}'),
                  ] else
                    const Text('No location has been reported yet.'),
                  TextButton.icon(
                      onPressed: () => setState(load),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh ride updates')),
                ]);
          }));
}
