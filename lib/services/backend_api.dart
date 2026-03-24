import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

import '../config/api_config.dart';

/// HTTP client for the MEZAHUB Flask backend (restaurant app).
class BackendApi {
  static String baseUrl = kBackendBaseUrl;
  static String get _baseUrl => baseUrl;

  static Box get _authBox => Hive.box('auth');

  static Future<String?> _getAccessToken() async {
    return _authBox.get('access_token') as String?;
  }

  static String? _getRefreshToken() {
    return _authBox.get('refresh_token') as String?;
  }

  static bool _isConnectionRefused(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('connection refused') ||
        msg.contains('connectionrefused') ||
        (e is SocketException && e.message.contains('refused'));
  }

  static bool _isTokenExpiredResponse(String body) {
    final lower = body.toLowerCase();
    return lower.contains('token') && lower.contains('expired');
  }

  /// Refresh access token using refresh token. Returns true if a new access token was saved.
  static Future<bool> _refreshAccessToken() async {
    final refreshToken = _getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    final uri = Uri.parse('$_baseUrl/auth/refresh');
    try {
      final res = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final access = data['access_token'] as String?;
      if (access == null || access.isEmpty) return false;
      await _authBox.put('access_token', access);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<http.Response> _request(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool auth = true,
    bool retryingAfterRefresh = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final token = auth ? await _getAccessToken() : null;
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
      if (auth && token != null) 'Authorization': 'Bearer $token',
    };
    try {
      http.Response res;
      switch (method.toUpperCase()) {
        case 'GET':
          res = await http.get(uri, headers: mergedHeaders);
          break;
        case 'POST':
          res = await http.post(uri, headers: mergedHeaders, body: body);
          break;
        case 'PATCH':
          res = await http.patch(uri, headers: mergedHeaders, body: body);
          break;
        case 'PUT':
          res = await http.put(uri, headers: mergedHeaders, body: body);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }
      // On 401 "Token has expired", try refresh once and retry
      if (auth &&
          !retryingAfterRefresh &&
          res.statusCode == 401 &&
          _isTokenExpiredResponse(res.body)) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return _request(
            method,
            path,
            headers: headers,
            body: body,
            auth: auth,
            retryingAfterRefresh: true,
          );
        }
        // Refresh failed (e.g. refresh token also expired) – clear tokens and user so app can show login
        await _authBox.delete('access_token');
        await _authBox.delete('refresh_token');
        try {
          await Hive.box('user').delete('currentUser');
        } catch (_) {}
        throw Exception('Session expired. Please log in again.');
      }
      return res;
    } catch (e) {
      if (_isConnectionRefused(e)) {
        throw Exception(
          'Server not reachable at $uri. '
          'Start the backend: cd mezahub-backend && python run.py. '
          'On a physical device, set your PC IP in lib/config/api_config.dart.',
        );
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _multipartRequest(
    String method,
    String path, {
    required File file,
    String fieldName = 'image',
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final token = auth ? await _getAccessToken() : null;
    final request = http.MultipartRequest(method.toUpperCase(), uri);
    if (auth && token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_extractError(response.body));
      }
      if (response.body.trim().isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } catch (e) {
      if (_isConnectionRefused(e)) {
        throw Exception(
          'Server not reachable at $uri. '
          'Start the backend: cd mezahub-backend && python run.py. '
          'On a physical device, set your PC IP in lib/config/api_config.dart.',
        );
      }
      rethrow;
    }
  }

  // ---------- AUTH ----------
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _request(
      'POST',
      '/auth/login',
      auth: false,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      final err = res.body;
      throw Exception(err.contains('error') ? _extractError(err) : 'Login failed: $err');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _authBox.put('access_token', data['access_token'] as String);
    await _authBox.put('refresh_token', data['refresh_token'] as String?);
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final res = await _request(
      'POST',
      '/auth/register',
      auth: false,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone ?? '',
      }),
    );
    if (res.statusCode != 201) {
      throw Exception(_extractError(res.body));
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _authBox.put('access_token', data['access_token'] as String);
    await _authBox.put('refresh_token', data['refresh_token'] as String?);
    return data;
  }

  static String _extractError(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      return m['error']?.toString() ?? body;
    } catch (_) {
      return body;
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await _request('GET', '/auth/profile');
    if (res.statusCode != 200) throw Exception('Profile: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateProfile({String? name, String? phone}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    final res = await _request('PUT', '/auth/profile', body: jsonEncode(body));
    if (res.statusCode != 200) throw Exception('Update profile: ${res.body}');
  }

  static Future<Map<String, dynamic>> uploadProfileImage(File file) async {
    return _multipartRequest('POST', '/auth/profile/image', file: file);
  }

  // ---------- RESTAURANTS (mine) ----------
  /// GET /restaurants?mine=1 – restaurants owned by current user.
  static Future<List<dynamic>> getMyRestaurants() async {
    final res = await _request('GET', '/restaurants?mine=1');
    if (res.statusCode != 200) throw Exception('Restaurants: ${res.body}');
    final list = jsonDecode(res.body);
    return list is List ? list : [];
  }

  /// POST /restaurants – create restaurant (e.g. on first login if none).
  static Future<Map<String, dynamic>> createRestaurant({
    required String name,
    String? description,
    String? address,
    String? cuisineType,
    String? phone,
    String? coverImage,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;
    if (address != null) body['address'] = address;
    if (cuisineType != null) body['cuisine_type'] = cuisineType;
    if (phone != null) body['phone'] = phone;
    if (coverImage != null) body['cover_image'] = coverImage;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    final res = await _request('POST', '/restaurants', body: jsonEncode(body));
    if (res.statusCode != 201) throw Exception(_extractError(res.body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// PUT /restaurants/<id> – update restaurant (owner or admin).
  static Future<Map<String, dynamic>> updateRestaurant(
    int restaurantId, {
    String? name,
    String? description,
    String? address,
    String? cuisineType,
    String? phone,
    bool? isOpen,
    String? coverImage,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (address != null) body['address'] = address;
    if (cuisineType != null) body['cuisine_type'] = cuisineType;
    if (phone != null) body['phone'] = phone;
    if (isOpen != null) body['is_open'] = isOpen;
    if (coverImage != null) body['cover_image'] = coverImage;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (body.isEmpty) throw Exception('No fields to update');
    final res = await _request('PUT', '/restaurants/$restaurantId', body: jsonEncode(body));
    if (res.statusCode != 200) throw Exception(_extractError(res.body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadRestaurantCoverImage(
    int restaurantId,
    File file,
  ) async {
    return _multipartRequest(
      'POST',
      '/restaurants/$restaurantId/cover-image',
      file: file,
    );
  }

  static Future<Map<String, dynamic>> uploadRestaurantLogoImage(
    int restaurantId,
    File file,
  ) async {
    return _multipartRequest(
      'POST',
      '/restaurants/$restaurantId/logo-image',
      file: file,
    );
  }

  // ---------- ORDERS ----------
  static Future<List<dynamic>> getOrders({int page = 1, int perPage = 50}) async {
    final res = await _request('GET', '/orders?page=$page&per_page=$perPage');
    if (res.statusCode != 200) throw Exception('Orders: ${res.body}');
    final list = jsonDecode(res.body);
    return list is List ? list : [];
  }

  static Future<Map<String, dynamic>> getOrder(int orderId) async {
    final res = await _request('GET', '/orders/$orderId');
    if (res.statusCode != 200) throw Exception('Order: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status, {String? notes}) async {
    final body = <String, dynamic>{'status': status};
    if (notes != null) body['notes'] = notes;
    final res = await _request('PATCH', '/orders/$orderId/status', body: jsonEncode(body));
    if (res.statusCode != 200) throw Exception(_extractError(res.body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> assignRider(int orderId, int riderId) async {
    final res = await _request(
      'POST',
      '/orders/$orderId/assign-rider',
      body: jsonEncode({'rider_id': riderId}),
    );
    if (res.statusCode != 200) throw Exception(_extractError(res.body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------- RIDERS ----------
  static Future<List<dynamic>> getRiders() async {
    final res = await _request('GET', '/riders');
    if (res.statusCode != 200) throw Exception('Riders: ${res.body}');
    final list = jsonDecode(res.body);
    return list is List ? list : [];
  }

  // ---------- MENU (categories & items for upload dish) ----------
  /// GET /restaurants/<id>/menu – categories with items (for loading categories in upload screen).
  static Future<Map<String, dynamic>> getRestaurantMenu(int restaurantId) async {
    final res = await _request('GET', '/restaurants/$restaurantId/menu');
    if (res.statusCode != 200) throw Exception(_extractError(res.body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// POST /restaurants/<id>/menu/categories – create category (name, description?, display_order?).
  static Future<Map<String, dynamic>> createMenuCategory(
    int restaurantId, {
    required String name,
    String? description,
    int? displayOrder,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;
    if (displayOrder != null) body['display_order'] = displayOrder;
    final res = await _request(
      'POST',
      '/restaurants/$restaurantId/menu/categories',
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) throw Exception(_extractError(res.body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// POST /restaurants/<id>/menu/items – create menu item.
  static Future<Map<String, dynamic>> createMenuItem(
    int restaurantId, {
    required int categoryId,
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    int? preparationTime,
    bool available = true,
  }) async {
    final body = <String, dynamic>{
      'category_id': categoryId,
      'name': name,
      'price': price,
      'available': available,
    };
    if (description != null && description.isNotEmpty) body['description'] = description;
    if (imageUrl != null && imageUrl.isNotEmpty) body['image_url'] = imageUrl;
    if (preparationTime != null) body['preparation_time'] = preparationTime;
    final res = await _request(
      'POST',
      '/restaurants/$restaurantId/menu/items',
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) throw Exception(_extractError(res.body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadMenuItemImage(
    int restaurantId,
    int itemId,
    File file,
  ) async {
    return _multipartRequest(
      'POST',
      '/restaurants/$restaurantId/menu/items/$itemId/image',
      file: file,
    );
  }
}
