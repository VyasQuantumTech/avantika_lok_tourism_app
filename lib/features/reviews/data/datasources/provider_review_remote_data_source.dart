import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';
import '../../domain/entities/provider_review.dart';

abstract class ProviderReviewRemoteDataSource {
  Future<List<ProviderReview>> list({String? query});
  Future<ProviderReview> getById(String id);
  Future<ProviderReview> respond(String id, String response);
}

class ProviderReviewRemoteDataSourceImpl implements ProviderReviewRemoteDataSource {
  const ProviderReviewRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<ProviderReview>> list({String? query}) async {
    final q = query?.trim();
    final path = q == null || q.isEmpty
        ? '${Endpoints.providerReviews}?limit=100'
        : '${Endpoints.providerReviews}?limit=100&q=${Uri.encodeQueryComponent(q)}';
    final response = await _apiClient.get(path, authenticated: true);
    return _items(response).map(_fromJson).toList(growable: false);
  }

  @override
  Future<ProviderReview> getById(String id) async {
    final response = await _apiClient.get(
      '${Endpoints.providerReviews}/${Uri.encodeComponent(id)}',
      authenticated: true,
    );
    return _fromJson(_object(response));
  }

  @override
  Future<ProviderReview> respond(String id, String responseText) async {
    final response = await _apiClient.put(
      '${Endpoints.providerReviews}/${Uri.encodeComponent(id)}/response',
      authenticated: true,
      body: <String, dynamic>{'response': responseText.trim()},
    );
    final object = _object(response);
    if (object.isEmpty) return getById(id);
    return _fromJson(object);
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> response) {
    dynamic node = response['data'] ?? response;
    if (node is Map) {
      node = node['items'] ?? node['reviews'] ?? node['rows'] ?? node['results'] ?? node['data'] ?? node;
    }
    if (node is! List) return const <Map<String, dynamic>>[];
    return node.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(growable: false);
  }

  Map<String, dynamic> _object(Map<String, dynamic> response) {
    dynamic node = response['data'] ?? response;
    if (node is Map) {
      node = node['review'] ?? node['item'] ?? node;
    }
    return node is Map ? node.cast<String, dynamic>() : const <String, dynamic>{};
  }

  ProviderReview _fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map(dynamic value) => value is Map ? value.cast<String, dynamic>() : const {};
    String? text(dynamic value) {
      final v = value?.toString().trim();
      return v == null || v.isEmpty || v == 'null' ? null : v;
    }

    final booking = map(json['booking']);
    final customer = map(json['customer'] ?? json['reviewer'] ?? booking['customer']);
    final subject = map(json['subject'] ?? json['service'] ?? json['target']);
    final snapshot = map(booking['pricingSnapshot'] ?? json['pricingSnapshot']);
    final providerResponse = map(json['providerResponse']);
    final responseText = text(
      json['response'] ??
          json['providerResponseText'] ??
          providerResponse['response'] ??
          providerResponse['text'],
    );

    final created = text(json['createdAt'] ?? json['created_at']);
    final responded = text(
      json['respondedAt'] ?? json['providerRespondedAt'] ?? providerResponse['createdAt'],
    );

    return ProviderReview(
      id: text(json['id'] ?? json['reviewId']) ?? '',
      rating: int.tryParse('${json['rating'] ?? 0}') ?? 0,
      title: text(json['title']),
      comment: text(json['comment'] ?? json['review']),
      bookingId: text(json['bookingId'] ?? booking['id']),
      bookingNumber: text(json['bookingNumber'] ?? booking['bookingNumber']),
      serviceName: text(
        json['serviceName'] ??
            subject['name'] ??
            snapshot['poojaName'] ??
            snapshot['packageName'] ??
            snapshot['accommodationName'] ??
            snapshot['vehicleName'],
      ),
      customerName: text(
        json['customerName'] ??
            customer['name'] ??
            customer['fullName'] ??
            [customer['firstName'], customer['lastName']]
                .where((e) => text(e) != null)
                .join(' '),
      ),
      response: responseText,
      createdAt: created == null ? null : DateTime.tryParse(created),
      respondedAt: responded == null ? null : DateTime.tryParse(responded),
    );
  }
}
