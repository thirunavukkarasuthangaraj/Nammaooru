import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

/// Transport / fleet tracking API.
///
/// Public  : /transport/public/**  (no login)
/// Account : /transport/me, /transport/register
/// Owner   : /transport/owner/**
/// Driver  : /transport/driver/**
class TransportService {
  TransportService._();
  static final TransportService instance = TransportService._();

  Map<String, dynamic> _unwrap(Response r) {
    final body = r.data;
    if (body is Map<String, dynamic>) return body;
    return {'success': false, 'message': 'Unexpected response'};
  }

  Map<String, dynamic> _err(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['message'] != null) return {'success': false, 'message': d['message'].toString()};
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return {'success': false, 'message': 'Please log in to continue', 'authError': true};
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
    return {'success': false, 'message': e.toString()};
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? q, bool auth = true}) async {
    try {
      return _unwrap(await ApiClient.get(path, queryParameters: q, includeAuth: auth));
    } catch (e) {
      return _err(e);
    }
  }

  Future<Map<String, dynamic>> _post(String path, {dynamic data, bool auth = true}) async {
    try {
      return _unwrap(await ApiClient.post(path, data: data, includeAuth: auth));
    } catch (e) {
      return _err(e);
    }
  }

  Future<Map<String, dynamic>> _put(String path, {dynamic data}) async {
    try {
      return _unwrap(await ApiClient.put(path, data: data));
    } catch (e) {
      return _err(e);
    }
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    try {
      return _unwrap(await ApiClient.delete(path));
    } catch (e) {
      return _err(e);
    }
  }

  // ---------- public ----------
  Future<Map<String, dynamic>> publicBuses() => _get('/transport/public/buses', auth: false);

  Future<Map<String, dynamic>> publicPositions(List<int> ids) =>
      _get('/transport/public/positions', q: {'ids': ids.join(',')}, auth: false);

  // ---------- account ----------
  Future<Map<String, dynamic>> me() => _get('/transport/me');

  Future<Map<String, dynamic>> register({required String companyName, String? ownerName, String? phone}) =>
      _post('/transport/register', data: {'companyName': companyName, 'ownerName': ownerName, 'phone': phone});

  // ---------- owner ----------
  Future<Map<String, dynamic>> ownerBootstrap() => _get('/transport/owner/bootstrap');
  Future<Map<String, dynamic>> ownerLive() => _get('/transport/owner/live');

  Future<Map<String, dynamic>> saveVehicle(Map<String, dynamic> v) => _post('/transport/owner/vehicles', data: v);
  Future<Map<String, dynamic>> deleteVehicle(int id) => _delete('/transport/owner/vehicles/$id');

  Future<Map<String, dynamic>> saveDriver(Map<String, dynamic> d) => _post('/transport/owner/drivers', data: d);
  Future<Map<String, dynamic>> deleteDriver(int id) => _delete('/transport/owner/drivers/$id');

  Future<Map<String, dynamic>> saveRoute(Map<String, dynamic> r) => _post('/transport/owner/routes', data: r);
  Future<Map<String, dynamic>> deleteRoute(int id) => _delete('/transport/owner/routes/$id');

  Future<Map<String, dynamic>> ownerTrips({int? vehicleId, int page = 0, int size = 30}) =>
      _get('/transport/owner/trips', q: {'page': page, 'size': size, if (vehicleId != null) 'vehicleId': vehicleId});

  Future<Map<String, dynamic>> ownerTripTrail(int tripId) => _get('/transport/owner/trips/$tripId/trail');

  // ---------- driver ----------
  Future<Map<String, dynamic>> driverContext() => _get('/transport/driver/context');
  Future<Map<String, dynamic>> startTrip(int vehicleId) => _post('/transport/driver/trips/start', data: {'vehicleId': vehicleId});
  Future<Map<String, dynamic>> endTrip(int tripId, {double? distanceKm}) =>
      _post('/transport/driver/trips/$tripId/end', data: {'distanceKm': distanceKm});

  // Used from the foreground isolate too (see transport_gps_task.dart), which
  // posts directly with its own Dio because ApiClient is not initialised there.
  Future<Map<String, dynamic>> sendPositions(int tripId, List<Map<String, dynamic>> points) =>
      _post('/transport/driver/positions', data: {'tripId': tripId, 'points': points});

  // ---------- admin (unused in app, kept for parity) ----------
  Future<Map<String, dynamic>> adminSetStatus(int id, String status) =>
      _put('/transport/admin/transporters/$id/status', data: {'status': status});
}
