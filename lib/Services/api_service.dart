import 'dart:convert';
import 'package:http/http.dart' as http;
import '/controller/app_constants.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class SessionExpiredException implements Exception {
  final String message;

  SessionExpiredException([
    this.message = 'Session expired. Please log in again.',
  ]);

  @override
  String toString() => message;
}

class ApiService {
  ApiService();

  /// Clears all stored session data
  Future<void> clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('Cleared all stored session data from SharedPreferences');
  }

  /// Login API
  Future<Map<String, dynamic>> authenticateUser({
    required String email,
    required String password,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      debugPrint(
          'Sending authentication request: email=$email, device_id=$deviceId');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.authEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_id': deviceId,
        }),
      );

      final responseData = _decodeJsonMap(
        response,
        fallbackMessage: 'Authentication failed',
      );
      debugPrint('Authentication response: $responseData');

      if (response.statusCode != 200) {
        final errorMessage = responseData['message'] ?? 'Authentication failed';
        if (errorMessage.contains('Device is already associated')) {
          await clearSessionData();
        }
        throw Exception(errorMessage);
      }

      if (responseData['status'] != 'SUCCESS') {
        throw Exception(responseData['message'] ?? 'Authentication failed');
      }

      final cookies = response.headers['set-cookie'];
      if (cookies == null || cookies.isEmpty) {
        throw Exception('No session cookie received');
      }

      // Handle role or group fields
      final isAdmin =
          responseData['is_admin'] == true || responseData['role'] == 'admin';
      final role = responseData['role'] ?? '';
      final groups = List<String>.from(responseData['groups'] ?? []);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_id', deviceId);
      await prefs.setString('sessionId', cookies);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', email);
      await prefs.setBool('isAdmin', isAdmin);
      await prefs.setString('role', role);
      await prefs.setString('groups', jsonEncode(groups));

      debugPrint('isAdmin set to: $isAdmin, role: $role, groups: $groups');

      return {
        'sessionId': cookies,
        'user_id': responseData['user_id'],
        'name': responseData['name'],
        'email': responseData['email'],
        'device_id': deviceId,
        'is_admin': isAdmin,
        'role': role,
        'groups': groups,
        'message': responseData['message'] ?? 'Login successful',
      };
    } catch (e) {
      if (e is SessionExpiredException) {
        rethrow;
      }
      debugPrint('Authentication error: $e');
      throw Exception('$e');
    }
  }

  /// Fetch user groups from backend
  Future<List<String>> getUserGroups({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final response = await authenticatedGet(
        '/api/user/groups',
        sessionId: sessionId,
        queryParams: {'user_id': userId},
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200 || responseData['success'] != true) {
        debugPrint('Failed to fetch user groups: ${response.body}');
        return [];
      }

      final groups = List<String>.from(responseData['groups'] ?? []);
      debugPrint('Fetched user groups: $groups');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('groups', jsonEncode(groups));
      return groups;
    } catch (e) {
      debugPrint('Error fetching user groups: $e');
      return [];
    }
  }

  /// Save player_id (Push Notification token) to backend
  Future<void> savePlayerId({
    required String playerId,
    required String sessionId,
  }) async {
    try {
      final payload = {
        'player_id': playerId,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      };

      final response = await authenticatedPost(
        '/api/device/register',
        payload,
        sessionId: sessionId,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode != 200 || responseData['success'] != true) {
        debugPrint('Player ID registration failed: ${response.body}');
        throw Exception(
            responseData['error'] ?? 'Failed to register player ID');
      }

      debugPrint('Player ID registered successfully: $playerId');
    } catch (e) {
      debugPrint('Error registering player ID: $e');
      throw Exception('Failed to register player ID: $e');
    }
  }

  Future<bool> validateStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionId');

    if (sessionId == null || sessionId.isEmpty) {
      return false;
    }

    try {
      final response = await authenticatedGet(
        AppConstants.getProfileEndpoint,
        sessionId: sessionId,
      );
      if (response.statusCode == 200) {
        return true;
      }

      debugPrint(
        'Profile check returned ${response.statusCode}; keeping local session for now.',
      );
      return true;
    } on SessionExpiredException {
      return false;
    } catch (e) {
      debugPrint('Skipping forced logout; session validation failed: $e');
      return true;
    }
  }

  /// Get device ID (Android/iOS)
  Future<String> _getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedDeviceId = prefs.getString('device_id');
      if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
        debugPrint('Retrieved stored device ID: $storedDeviceId');
        return storedDeviceId;
      }

      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? '';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else {
        deviceId = '';
      }

      if (deviceId.isEmpty) {
        final random = DateTime.now().millisecondsSinceEpoch.toString();
        deviceId = 'device_$random${Platform.operatingSystem}';
      }

      await prefs.setString('device_id', deviceId);
      debugPrint('Generated and stored device ID: $deviceId');
      return deviceId;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      final random = DateTime.now().millisecondsSinceEpoch.toString();
      final fallbackId = 'device_$random${Platform.operatingSystem}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_id', fallbackId);
      debugPrint('Stored fallback device ID: $fallbackId');
      return fallbackId;
    }
  }

  /// Authenticated POST request
  Future<http.Response> authenticatedPost(
    String endpoint,
    dynamic body, {
    Map<String, String>? queryParams,
    required String sessionId,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint')
          .replace(queryParameters: queryParams);
      debugPrint('POST request to: $uri');
      debugPrint('POST body: $body');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': sessionId,
        },
        body: jsonEncode(body),
      );
      return await _handleAuthenticatedResponse(response, endpoint: endpoint);
    } catch (e) {
      if (e is SessionExpiredException) {
        rethrow;
      }
      debugPrint('POST request failed: $e');
      throw Exception('POST request failed: $e');
    }
  }

  /// Authenticated GET request
  Future<http.Response> authenticatedGet(
    String endpoint, {
    Map<String, String>? queryParams,
    required String sessionId,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint')
          .replace(queryParameters: queryParams);
      debugPrint('GET request to: $uri');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': sessionId,
        },
      );
      return await _handleAuthenticatedResponse(response, endpoint: endpoint);
    } catch (e) {
      if (e is SessionExpiredException) {
        rethrow;
      }
      debugPrint('GET request failed: $e');
      throw Exception('GET request failed: $e');
    }
  }

  Future<http.Response> _handleAuthenticatedResponse(
    http.Response response, {
    required String endpoint,
  }) async {
    if (_isSessionExpiredResponse(response)) {
      debugPrint(
        'Session expired while calling $endpoint: ${response.statusCode}',
      );
      await clearSessionData();
      throw SessionExpiredException();
    }

    return response;
  }

  bool _isSessionExpiredResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return true;
    }

    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    final body = response.body.trimLeft();
    final lowerBody = body.toLowerCase();

    if (contentType.contains('text/html')) {
      return true;
    }

    return lowerBody.startsWith('<!doctype html') ||
        lowerBody.startsWith('<html');
  }

  Map<String, dynamic> _decodeJsonMap(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final body = response.body.trimLeft();
    final lowerBody = body.toLowerCase();

    if (lowerBody.startsWith('<!doctype html') || lowerBody.startsWith('<html')) {
      throw Exception(
        'Server returned HTML instead of JSON. Check session expiry or backend routing.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception(fallbackMessage);
  }
}
