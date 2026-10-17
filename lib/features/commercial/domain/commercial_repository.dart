abstract class CommercialRepository {
  Future<Map<String, dynamic>> get(String path);
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body);
  Future<Map<String, dynamic>> taxProfile(Map<String, dynamic> body);
}

class CommercialActions {
  const CommercialActions(this.repository);
  final CommercialRepository repository;
  Future<Map<String, dynamic>> enableRenewal(String id, String key) =>
      repository.post(
          '/provider/subscriptions/$id/auto-renew', {'idempotencyKey': key});
  Future<Map<String, dynamic>> tools() =>
      repository.get('/provider/commercial/tools');
  Future<Map<String, dynamic>> analytics({bool advanced = false}) =>
      repository.get('/provider/commercial/analytics?advanced=$advanced');
  Future<Map<String, dynamic>> createTool(Map<String, dynamic> input) =>
      repository.post('/provider/commercial/tools', input);
  Future<Map<String, dynamic>> coupon(Map<String, dynamic> input) =>
      repository.post('/provider/coupons', input);
  Future<Map<String, dynamic>> visibility(String product, String key,
          {bool credits = false}) =>
      repository.post('/provider/commercial/visibility/checkout', {
        'productVersionId': product,
        'idempotencyKey': key,
        'useCredits': credits
      });
  Future<Map<String, dynamic>> document(String id) =>
      repository.get('/invoices/$id/document');
  Future<Map<String, dynamic>> analyticsExport(String key) => repository.post(
      '/provider/commercial/analytics/export',
      {'idempotencyKey': key, 'advanced': true});
  Future<Map<String, dynamic>> plans() =>
      repository.get('/provider/subscription-plans');
  Future<Map<String, dynamic>> subscription() =>
      repository.get('/provider/subscriptions');
  Future<Map<String, dynamic>> finance() =>
      repository.get('/provider/finance/statements');
  Future<Map<String, dynamic>> invoices({bool provider = true}) =>
      repository.get(provider ? '/provider/finance/invoices' : '/invoices');
  Future<Map<String, dynamic>> quote(Map<String, dynamic> booking) =>
      repository.post('/pricing/quote', booking);
  Future<Map<String, dynamic>> checkout(String plan, String key,
          {bool renewal = false, bool trial = false}) =>
      repository.post('/provider/subscriptions/checkout', {
        'planVersionId': plan,
        'idempotencyKey': key,
        'change': renewal ? 'renewal' : 'immediate',
        'trial': trial
      });
  Future<Map<String, dynamic>> cancel(String id, String reason) => repository
      .post('/provider/subscriptions/$id/cancel-renewal', {'reason': reason});
  Future<Map<String, dynamic>> verify(String id, Map<String, dynamic> body) =>
      repository.post('/payments/$id/verify', body);
  Future<Map<String, dynamic>> profile() =>
      repository.get('/provider/tax-profile');
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> body) =>
      repository.taxProfile(body);
}
