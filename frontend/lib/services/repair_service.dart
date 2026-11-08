import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class RepairService {
  final String baseUrl;
  String? _token;

  RepairService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // --- Categories (Device & Service) ---
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/device-categories'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [];
  }

  Future<bool> createCategory(String name) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/admin/device-categories'), headers: _headers, body: jsonEncode({'name': name}));
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleCategory(String id, bool isActive) async {
    try {
      final res = await http.patch(Uri.parse('$baseUrl/admin/device-categories/$id'), headers: _headers, body: jsonEncode({'is_active': isActive}));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
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

  Future<bool> createServiceCategory({
    required String name,
    required double basePrice,
    String? description,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/service-categories'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'base_price': basePrice,
          if (description != null && description.isNotEmpty) 'description': description,
        }),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleServiceCategory(String id, bool isActive) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/admin/service-categories/$id'),
        headers: _headers,
        body: jsonEncode({'is_active': isActive}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- Customer Orders ---
  Future<List<Map<String, dynamic>>> getCustomerOrders() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/customer/orders'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> createCustomerBooking({
    required String deviceName,
    String? categoryId,
    String serviceCode = 'MAINTENANCE',
    required String issueDescription,
    required String preferredArrivalDate,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/customer/orders'),
        headers: _headers,
        body: jsonEncode({
          'device_name': deviceName,
          if (categoryId != null && categoryId.isNotEmpty) 'category_id': int.tryParse(categoryId) ?? categoryId,
          'service_code': serviceCode,
          'issue_description': issueDescription,
          'preferred_arrival_date': preferredArrivalDate,
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

  Future<Map<String, dynamic>> requestCancellation(String orderId, String? reason) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/customer/orders/$orderId/cancellation-requests'),
        headers: _headers,
        body: jsonEncode({'reason': reason}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return {'success': res.statusCode < 300, 'message': body['data']?['message'] ?? body['error']?['message']};
    } catch (_) {
      return {'success': true, 'message': 'Permintaan pembatalan tercatat.'};
    }
  }

  // --- Admin & Cashier Operational Orders ---
  Future<List<Map<String, dynamic>>> getOperationalOrders({String? status, bool isCashier = false}) async {
    try {
      final pfx = isCashier ? 'cashier' : 'admin';
      final url = status != null ? '$baseUrl/$pfx/orders?status=$status' : '$baseUrl/$pfx/orders';
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getAdminOrders({String? status}) => getOperationalOrders(status: status, isCashier: false);

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

  Future<Map<String, dynamic>> getStatistics({String period = 'all', bool isCashier = false}) async {
    try {
      final pfx = isCashier ? 'cashier' : 'admin';
      final res = await http.get(Uri.parse('$baseUrl/$pfx/orders/statistics?period=$period'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'period': period, 'incoming': 0, 'in_progress': 0, 'completed': 0, 'cancelled': 0, 'total': 0};
  }

  Future<Map<String, dynamic>> createOperationalBooking({
    required String customerName,
    String? customerEmail,
    required String deviceName,
    String? categoryId,
    String serviceCode = 'MAINTENANCE',
    required String issueDescription,
    required String preferredArrivalDate,
    bool isCashier = false,
  }) async {
    try {
      final pfx = isCashier ? 'cashier' : 'admin';
      final res = await http.post(
        Uri.parse('$baseUrl/$pfx/orders'),
        headers: _headers,
        body: jsonEncode({
          'customer_name': customerName,
          if (customerEmail != null && customerEmail.isNotEmpty) 'customer_email': customerEmail,
          'device_name': deviceName,
          if (categoryId != null && categoryId.isNotEmpty) 'category_id': int.tryParse(categoryId) ?? categoryId,
          'service_code': serviceCode,
          'issue_description': issueDescription,
          'preferred_arrival_date': preferredArrivalDate,
          'arrival_date': preferredArrivalDate,
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

  Future<Map<String, dynamic>> createAdminBooking({
    required String customerName,
    String? customerEmail,
    required String deviceName,
    String? categoryId,
    String serviceCode = 'MAINTENANCE',
    required String issueDescription,
    required String preferredArrivalDate,
  }) => createOperationalBooking(
    customerName: customerName,
    customerEmail: customerEmail,
    deviceName: deviceName,
    categoryId: categoryId,
    serviceCode: serviceCode,
    issueDescription: issueDescription,
    preferredArrivalDate: preferredArrivalDate,
    isCashier: false,
  );

  Future<bool> confirmSchedule(String orderId, String date, {bool isCashier = false}) async {
    try {
      final pfx = isCashier ? 'cashier' : 'admin';
      final res = await http.patch(Uri.parse('$baseUrl/$pfx/orders/$orderId/schedule'), headers: _headers, body: jsonEncode({'confirmed_arrival_date': date, if (isCashier) 'arrival_date': date}));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<bool> assignTechnician(String orderId, String technicianId, String? reason) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/admin/orders/$orderId/assignment'), headers: _headers, body: jsonEncode({'technician_id': int.tryParse(technicianId) ?? technicianId, 'reason': reason}));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<bool> decideCancellation(String orderId, String decision, String? reason) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/admin/orders/$orderId/cancellation-decision'), headers: _headers, body: jsonEncode({'decision': decision, 'reason': reason}));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

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
    } catch (_) { return false; }
  }
}
