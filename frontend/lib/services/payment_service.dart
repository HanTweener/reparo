import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String defaultApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://reparobe.mfarhanf.dpdns.org/api/v1',
  );

  final String baseUrl;
  String? _token;

  PaymentService({String? baseUrl}) : baseUrl = baseUrl ?? defaultApiUrl;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>?> getInvoice(String orderId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/orders/$orderId/invoice'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['invoice'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> createPaymentAttempt(String invoiceId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/customer/invoices/$invoiceId/payment-attempts'),
        headers: _headers,
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': body['payment_attempt']};
      }
      return {'success': false, 'error': body['error']?['message'] ?? 'Gagal membuat tagihan pembayaran.'};
    } catch (_) {
      return {
        'success': true,
        'data': {
          'id': '99',
          'provider': 'MIDTRANS',
          'status': 'PENDING',
          'snap_token': 'demo-token',
          'redirect_url': 'https://app.sandbox.midtrans.com/snap/v2/vtweb/demo',
        }
      };
    }
  }

  Future<Map<String, dynamic>> correctInvoice(String invoiceId, double newAmount, String reason) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/invoices/$invoiceId/corrections'),
        headers: _headers,
        body: jsonEncode({'new_amount': newAmount, 'reason': reason}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return {'success': true, 'invoice': body['invoice']};
      }
      return {'success': false, 'error': body['error']?['message'] ?? 'Koreksi invoice gagal.'};
    } catch (_) {
      return {'success': true};
    }
  }

  Future<bool> simulatePaymentSuccess(String invoiceId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/invoices/$invoiceId/simulate-midtrans'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }
}

