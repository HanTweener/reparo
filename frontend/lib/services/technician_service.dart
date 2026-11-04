import 'dart:convert';
import 'package:http/http.dart' as http;

class TechnicianService {
  static const String defaultApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://reparobe.mfarhanf.dpdns.org/api/v1',
  );

  final String baseUrl;
  String? _token;

  TechnicianService({String? baseUrl}) : baseUrl = baseUrl ?? defaultApiUrl;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<List<Map<String, dynamic>>> getOrders({String scope = 'assigned'}) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/technician/orders?scope=$scope'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getAssignedOrders() => getOrders(scope: 'assigned');

  Future<Map<String, dynamic>> claimOrder(String orderId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/technician/orders/$orderId/claim'),
        headers: _headers,
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Pekerjaan berhasil diambil.'};
      }
      return {'success': false, 'error': body['error']?['message'] ?? 'Gagal mengambil pekerjaan.'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal terhubung ke server: $e'};
    }
  }

  Future<bool> startDiagnosis(String orderId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/technician/orders/$orderId/diagnosis/start'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveDiagnosis(String orderId, String customerSafeSummary) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/technician/orders/$orderId/diagnosis'),
        headers: _headers,
        body: jsonEncode({'customer_safe_summary': customerSafeSummary}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> addEstimate(String orderId, double amount, String? reason) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/technician/orders/$orderId/estimates'),
        headers: _headers,
        body: jsonEncode({
          'amount': amount,
          'currency_code': 'IDR',
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'revision': body['revision']};
      }
      return {'success': false, 'error': body['error']?['message'] ?? 'Gagal menyimpan estimasi biaya.'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal terhubung ke server: $e'};
    }
  }

  Future<bool> startRepair(String orderId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/technician/orders/$orderId/repair/start'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addWorkNote(String orderId, String text) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/technician/orders/$orderId/work-notes'),
        headers: _headers,
        body: jsonEncode({'note_text': text}),
      );
      return res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startQc(String orderId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/technician/orders/$orderId/qc/start'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> submitQcCheck(String orderId, String result, String? note) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/technician/orders/$orderId/qc-checks'),
        headers: _headers,
        body: jsonEncode({'result': result, 'note': note}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return {'success': res.statusCode == 200, 'message': body['message']};
    } catch (e) {
      return {'success': false, 'error': 'Gagal terhubung ke server: $e'};
    }
  }

  Future<Map<String, dynamic>> completeHandover(String orderId, {String? recipientName, String? notes, int? expectedVersion}) async {
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
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      }
      return {'success': false, 'error': body['error']?['message'] ?? 'Serah terima gagal.'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal terhubung ke server: $e'};
    }
  }
}
