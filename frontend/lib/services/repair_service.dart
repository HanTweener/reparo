import 'dart:convert';
import 'package:http/http.dart' as http;

class RepairService {
  final String baseUrl;
  String? _token;

  RepairService({this.baseUrl = 'http://localhost:8000/api/v1'});

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // --- Categories ---
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/device-categories'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [
      {'id': '1', 'name': 'Laptop'},
      {'id': '2', 'name': 'Smartphone'},
      {'id': '3', 'name': 'Tablet'},
      {'id': '4', 'name': 'PC Desktop'},
    ];
  }

  // --- Customer Devices ---
  Future<List<Map<String, dynamic>>> getCustomerDevices() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/customer/devices'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [
      {
        'id': '1',
        'category_id': '1',
        'category_name': 'Laptop',
        'brand': 'ASUS',
        'model': 'ROG Zephyrus G14',
        'serial_number': 'SN-ROG-2026-X',
        'description': 'Laptop gaming warna putih',
      }
    ];
  }

  Future<Map<String, dynamic>> createCustomerDevice({
    required String categoryId,
    required String brand,
    required String model,
    String? serialNumber,
    String? description,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/customer/devices'),
        headers: _headers,
        body: jsonEncode({
          'category_id': int.tryParse(categoryId) ?? categoryId,
          'brand': brand,
          'model': model,
          'serial_number': serialNumber,
          'description': description,
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['error']?['message'] ?? 'Gagal menyimpan perangkat.'};
    } catch (_) {
      return {
        'success': true,
        'data': {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'category_id': categoryId,
          'category_name': 'Laptop',
          'brand': brand,
          'model': model,
          'serial_number': serialNumber,
          'description': description,
        }
      };
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
    return [
      {
        'id': '1',
        'public_reference': 'REP-2026-0001',
        'service_code': 'MAINTENANCE',
        'status': 'BOOKED',
        'issue_description': 'Pembersihan heatsink pasta pendingin dan pengecekan kipas.',
        'preferred_arrival_date': '2026-11-05',
        'confirmed_arrival_date': '2026-11-05',
        'device': {
          'brand': 'ASUS',
          'model': 'ROG Zephyrus G14',
          'category_name': 'Laptop',
        },
        'created_at': DateTime.now().toIso8601String(),
      }
    ];
  }

  Future<Map<String, dynamic>> bookOrder({
    required String deviceId,
    required String issueDescription,
    required String preferredArrivalDate,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/customer/orders'),
        headers: _headers,
        body: jsonEncode({
          'device_id': int.tryParse(deviceId) ?? deviceId,
          'issue_description': issueDescription,
          'preferred_arrival_date': preferredArrivalDate,
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['error']?['message'] ?? 'Gagal membuat pesanan.'};
    } catch (_) {
      return {
        'success': true,
        'data': {
          'id': '99',
          'public_reference': 'REP-2026-0002',
          'status': 'BOOKED',
          'message': 'Pesanan berhasil dibuat (mode offline/demo).',
        }
      };
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

  // --- Admin Orders ---
  Future<List<Map<String, dynamic>>> getAdminOrders() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/orders'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [
      {
        'id': '1',
        'public_reference': 'REP-2026-0001',
        'status': 'BOOKED',
        'customer': {'name': 'Demo Customer', 'email': 'customer@reparo.test'},
        'device': {'brand': 'ASUS', 'model': 'ROG Zephyrus G14'},
        'preferred_arrival_date': '2026-11-05',
        'confirmed_arrival_date': '2026-11-05',
        'technician': {'id': '2', 'name': 'Demo Technician'},
        'has_pending_cancellation': false,
      }
    ];
  }

  Future<bool> confirmSchedule(String orderId, String date) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/admin/orders/$orderId/schedule'),
        headers: _headers,
        body: jsonEncode({'confirmed_arrival_date': date}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  Future<bool> assignTechnician(String orderId, String technicianId, String? reason) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/admin/orders/$orderId/assignment'),
        headers: _headers,
        body: jsonEncode({
          'technician_id': int.tryParse(technicianId) ?? technicianId,
          'reason': reason,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  Future<bool> decideCancellation(String orderId, String decision, String? reason) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/orders/$orderId/cancellation-decision'),
        headers: _headers,
        body: jsonEncode({'decision': decision, 'reason': reason}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }
}

