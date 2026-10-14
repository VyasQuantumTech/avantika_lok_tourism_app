import '../../domain/entities/booking_lifecycle.dart';

BookingLifecycle bookingLifecycleFromJson(Map<String, dynamic> json) {
  Map<String, dynamic> map(dynamic value) =>
      value is Map ? value.map((key, value) => MapEntry('$key', value)) : {};
  final pricing = map(json['pricingSnapshot'] ?? json['pricing_snapshot']);
  final summary = map(json['serviceSummary'] ?? pricing['serviceSummary']);
  final metadata = map(json['metadata']);
  final payment = map(json['paymentState']);
  final type = '${json['bookingType'] ?? json['booking_type'] ?? ''}';
  return BookingLifecycle(
    status: '${json['status'] ?? 'pending'}',
    providerDecision:
        '${json['providerDecision'] ?? json['provider_decision'] ?? 'pending'}',
    paymentPolicy:
        '${json['paymentPolicy'] ?? metadata['paymentPolicy'] ?? (type == 'package' && json['paymentRequired'] == true ? 'online_required' : 'disabled')}',
    paymentStatus: '${payment['status'] ?? 'not_started'}',
    startedAt: DateTime.tryParse(
        '${json['serviceStartedAt'] ?? json['service_started_at'] ?? ''}'),
    endedAt: DateTime.tryParse(
        '${json['serviceEndedAt'] ?? json['service_ended_at'] ?? ''}'),
    holdExpiresAt: DateTime.tryParse('${json['holdExpiresAt'] ?? ''}'),
    serviceName: (summary['name'] ?? pricing['poojaName'] ?? pricing['name'])
        ?.toString(),
    providerName: (summary['providerName'] ??
            pricing['panditName'] ??
            pricing['providerName'])
        ?.toString(),
    unitName: summary['unitName']?.toString(),
  );
}
