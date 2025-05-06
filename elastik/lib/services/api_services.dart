import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart' show debugPrint;

// class ApiService {
//   final Dio _dio;
//   final FlutterSecureStorage _storage = const FlutterSecureStorage();

//   ApiService() : _dio = Dio() {
//     // Initialize without baseUrl first
//     // Set platform-specific base URL
//     final baseUrl =
//         kIsWeb ? 'https://localhost:7221/api/' : 'https://10.0.2.2:7221/api/';

//     _dio.options = BaseOptions(baseUrl: baseUrl);

//     // Platform-specific HTTP client configuration
//     if (kIsWeb) {
//       _dio.httpClientAdapter = BrowserHttpClientAdapter();
//     } else {
//       _dio.httpClientAdapter = IOHttpClientAdapter(
//         createHttpClient: () {
//           final HttpClient client = HttpClient();
//           // Bypass SSL verification for development (mobile/desktop only)
//           client.badCertificateCallback =
//               (X509Certificate cert, String host, int port) => true;
//           return client;
//         },
//       );
//     }

//     // Add interceptors
//     _dio.interceptors.add(
//       InterceptorsWrapper(
//         onRequest: (options, handler) async {
//           debugPrint('Making request to ${options.uri}');
//           final token = await _storage.read(key: 'token');
//           if (token != null) {
//             options.headers['Authorization'] = 'Bearer $token';
//           }
//           return handler.next(options);
//         },
//         onError: (error, handler) {
//           debugPrint('Dio error: ${error.toString()}');
//           return handler.next(error);
//         },
//       ),
//     );
//   }

//   Dio get client => _dio;

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() : _dio = Dio() {
    // Use Android emulator local address
    final baseUrl = 'https://10.0.2.2:7221/api/';
    _dio.options = BaseOptions(baseUrl: baseUrl);

    // Configure for native platforms only
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final HttpClient client = HttpClient();
        // Accept self-signed certs for development
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('Making request to ${options.uri}');
          final token = await _storage.read(key: 'token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('Dio error: ${error.toString()}');
          return handler.next(error);
        },
      ),
    );
  }

  Dio get client => _dio;

  Future<Response> testConnection() async {
    return _dio.get('test/connectivity');
  }

  // 🔐 Auth Endpoints
  Future<Response> login(String email, String password) {
    return _dio.post(
      'auth/login',
      data: {'email': email, 'password': password},
    );
  }

  // 👥 User Endpoints
  Future<Response> createUser({
    required String fullName,
    required String email,
    required String passwordHash,
    required String role,
  }) {
    return _dio.post(
      'user',
      data: {
        'fullName': fullName,
        'email': email,
        'passwordHash': passwordHash,
        'role': role,
      },
    );
  }

  Future<Response> getAllUsers() {
    return _dio.get('user');
  }

  Future<Response> getUserById(String userId) {
    return _dio.get('user/$userId');
  }
  
  // Gets the current user's ID from the JWT token
  Future<String> getCurrentUserId() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['sub']; // This gets the user ID from "sub" claim
    } catch (e) {
      throw Exception('Failed to decode token: $e');
    }
  }

  /// Gets the full current user details from the API
  Future<Response> getCurrentUser() async {
    try {
      final userId = await getCurrentUserId();
      return await getUserById(userId);
    } on DioException catch (e) {
      throw Exception('Failed to fetch user: ${e.message}');
    }
  }

  // 🎟️ Event Endpoints (Admin)
  Future<Response> createEvent({
    required String title,
    required String description,
    required String location,
    List<String>? customFieldIds,
  }) {
    return _dio.post(
      'admin/events/create',
      data: {
        'title': title,
        'description': description,
        'location': location,
        'customFieldIds': customFieldIds ?? [],
      },
    );
  }

  Future<Response> createCustomField({
    required String fieldName,
    required String fieldType,
    required List<Map<String, dynamic>> questions,
    required bool isRequired,
  }) {
    return _dio.post(
      'admin/events/custom-field',
      data: {
        'fieldName': fieldName,
        'fieldType': fieldType,
        'questions': questions,
        'isRequired': isRequired,
      },
    );
  }

  Future<Response> assignFieldsToEvent({
    required String eventId,
    required List<String> fieldIds,
  }) {
    return _dio.post(
      'admin/events/assign-fields',
      data: {'eventId': eventId, 'fieldIds': fieldIds},
    );
  }

  Future<Response> getAllCustomFields() {
    return _dio.get('admin/events/custom-fields');
  }

  // 🎟️ Registration Endpoints
  Future<Response> submitRegistration({
    required String eventCustomFieldId,
    required List<Map<String, dynamic>> answers,
  }) {
    return _dio.post(
      'registration',
      data: {
        'eventCustomFieldId': eventCustomFieldId,
        'answers': answers,
      },
    );
  }

  Future<Response> getUserRegistrationForEvent({
    required String userId,
    required String eventCustomFieldId,
  }) {
    return _dio.get(
      'registration/$userId/$eventCustomFieldId',
    );
  }

  Future<Response> getAllAdminEvents() {
    return _dio.get('admin/events/all');
  }

  // 🎟️ Event Endpoints (Participant)
  Future<Response> getAllEventsForParticipants() {
    return _dio.get('event');
  }

  Future<Response> getEventById(String eventId) {
    return _dio.get('event/$eventId');
  }

  // 👥 Participant Endpoints
  Future<Response> getEventParticipants(String eventId) {
    return _dio.get('participant/$eventId/participants');
  }

  Future<Response> updateParticipantAvailability({
    required String participantId,
    required bool isAvailable,
  }) {
    return _dio.post(
      'participant/update-availability',
      data: {
        'participantId': participantId,
        'isAvailable': isAvailable,
      },
    );
  }

  Future<Response> addComment({
    required String userId,
    required String eventId,
    required String content,
  }) {
    return _dio.post(
      'participant/add-comment',
      data: {
        'userId': userId,
        'eventId': eventId,
        'content': content,
      },
    );
  }

  Future<Response> getEventComments(String eventId) {
    return _dio.get('participant/$eventId/comments');
  }

  Future<Response> deleteEvent(String eventId) {
    return _dio.delete('admin/events/delete/$eventId');
  }

  // 🚪 Logout
  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'role');
  }
}
