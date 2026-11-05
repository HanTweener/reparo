import 'dart:convert';
import 'package:http/http.dart' as http;

class CashierService {
  static const String defaultApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://reparobe.mfarhanf.dpdns.org/api/v1',
  );

  final String baseUrl;
  String? _token;

  CashierService({String? baseUrl}) : baseUrl = baseUrl ?? defaultApiUrl;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// 1. Ambil antrean operasional kasir (independen)
  Future<List<Map<String, dynamic>>> getOrders({String? status, String? search}) async {
    try {
      final queryParams = <String>[];
      if (status != null && status.isNotEmpty) queryParams.add('status=$status');
      if (search != null && search.isNotEmpty) queryParams.add('search=${Uri.encodeComponent(search)}');
      final qs = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final res = await http.get(Uri.parse('$baseUrl/cashier/orders$qs'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [];
  }

  /// 2. Antrean global bersama (pool terbuka)
  Future<List<Map<String, dynamic>>> getGlobalQueue() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/orders/global-queue'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [];
  }

  /// 3. Statistik antrean kasir
  Future<Map<String, dynamic>> getStatistics({String period = 'all'}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/cashier/orders/statistics?period=$period'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'period': period, 'incoming': 0, 'in_progress': 0, 'completed': 0, 'total': 0};
  }

  /// 4. Buat pesanan walk-in kasir
  Future<Map<String, dynamic>> createBooking({
    required String customerName,
    String? customerEmail,
    required String deviceName,
    String? categoryId,
    String serviceCode = 'MAINTENANCE',
    required String issueDescription,
    required String arrivalDate,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/cashier/orders'),
        headers: _headers,
        body: jsonEncode({
          'customer_name': customerName,
          if (customerEmail != null && customerEmail.isNotEmpty) 'customer_email': customerEmail,
          'device_name': deviceName,
          if (categoryId != null && categoryId.isNotEmpty) 'category_id': int.tryParse(categoryId) ?? categoryId,
          'service_code': serviceCode,
          'issue_description': issueDescription,
          'arrival_date': arrivalDate,
          'preferred_arrival_date': arrivalDate,
        }),
      );
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>?;
      } catch (_) {
        body = null;
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': body?['data']};
      }
      return {'success': false, 'error': body?['error']?['message'] ?? 'Gagal membuat pesanan (Status ${res.statusCode}).'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal terhubung ke server: $e'};
    }
  }

  /// 5. Konfirmasi jadwal kedatangan pesanan
  Future<bool> confirmSchedule(String orderId, String date) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/cashier/orders/$orderId/schedule'),
        headers: _headers,
        body: jsonEncode({'confirmed_arrival_date': date, 'arrival_date': date}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 6. Koreksi nominal invoice
  Future<bool> correctInvoice(String invoiceId, double newAmount, String reason) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/cashier/invoices/$invoiceId/corrections'),
        headers: _headers,
        body: jsonEncode({'new_amount': newAmount, 'reason': reason}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 7. Serah terima fisik unit
  Future<bool> completeHandover(String orderId, {String? recipientName, String? notes, int? expectedVersion}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/handover'),
        headers: _headers,
        body: jsonEncode({
          if (recipientName != null && recipientName.isNotEmpty) 'recipient_name': recipientName,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (expectedVersion != null) 'expected_version': expectedVersion,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 8. Master Kategori untuk form pemesanan
  Future<List<Map<String, dynamic>>> getDeviceCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/device-categories'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getServiceCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/service-categories'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [];
  }
}

