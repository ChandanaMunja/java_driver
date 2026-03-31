// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/models/notification_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class SendNotification {
  static final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  static Future<void>? _settingsInFlight;
  static bool _settingsLoaded = false;
  static String _fcmProjectId = '';

  // OAuth access token cache (avoids rebuilding auth client for every send).
  static String? _cachedAccessToken;
  static DateTime? _cachedAccessTokenExpiry;
  static Future<String>? _accessTokenInFlight;

  // Refresh a bit early to avoid "token just expired" race conditions.
  static const Duration _tokenExpiryBuffer = Duration(seconds: 60);

  // Temporary fallback while backend/service JSON derivation is unstable.
  // Backend currently provides `notification_setting.projectId` as empty, but we
  // do have the correct Firebase project id.
  static const String _fallbackProjectId = 'jippymart-27c08';

  static Future<void> _ensureNotificationSettings() async {
    if (_settingsLoaded) return;
    if (_settingsInFlight != null) return _settingsInFlight!;

    final needs = Constant.senderId.isEmpty ||
        Constant.jsonNotificationFileURL.isEmpty;
    if (!needs) {
      _settingsLoaded = true;
      return;
    }

    _settingsInFlight = () async {
      try {
        debugPrint('[FCM] Loading notification settings (senderId/json)...');
        await FireStoreUtils.getSettings(forceRefresh: true);
      } catch (e) {
        debugPrint('[FCM] getSettings error: $e');
      }

      final ok = Constant.senderId.isNotEmpty &&
          Constant.jsonNotificationFileURL.isNotEmpty;
      _settingsLoaded = ok;

      if (!ok) {
        debugPrint('[FCM] Still missing config after getSettings. '
            'senderIdLen=${Constant.senderId.length} '
            'serviceJsonLen=${Constant.jsonNotificationFileURL.length}');
      } else {
        debugPrint('[FCM] Notification settings loaded.');
      }

      _settingsInFlight = null;
    }();

    await _settingsInFlight;
  }

  static Future getCharacters() {
    if (Constant.jsonNotificationFileURL.isEmpty) {
      throw ArgumentError('jsonNotificationFileURL is empty');
    }
    return http.get(Uri.parse(Constant.jsonNotificationFileURL.toString()));
  }

  static Future<String> getAccessToken() async {
    final now = DateTime.now();
    final expiry = _cachedAccessTokenExpiry;
    final token = _cachedAccessToken;

    if (token != null &&
        expiry != null &&
        now.isBefore(expiry.subtract(_tokenExpiryBuffer))) {
      return token;
    }

    // De-dupe concurrent refreshes.
    if (_accessTokenInFlight != null) {
      return _accessTokenInFlight!;
    }

    _accessTokenInFlight = () async {
      Map<String, dynamic> jsonData = {};

      await _ensureNotificationSettings();
      await getCharacters().then((response) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Failed to fetch service JSON. '
              'status=${response.statusCode} body=${response.body}');
        }
        final decoded = json.decode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw Exception('Invalid service JSON payload type.');
        }
        jsonData = decoded;
      });

      final String parsedProjectId =
          (jsonData['project_id'] ?? '').toString().trim();
      if (parsedProjectId.isNotEmpty) {
        _fcmProjectId = parsedProjectId;
      }

      if ((jsonData['private_key'] ?? '').toString().trim().isEmpty ||
          (jsonData['client_email'] ?? '').toString().trim().isEmpty ||
          (jsonData['token_uri'] ?? '').toString().trim().isEmpty) {
        throw Exception('Service account JSON missing required keys.');
      }

      final serviceAccountCredentials =
          ServiceAccountCredentials.fromJson(jsonData);

      final client = await clientViaServiceAccount(
          serviceAccountCredentials, _scopes);
      try {
        final accessToken = client.credentials.accessToken;
        _cachedAccessToken = accessToken.data;
        _cachedAccessTokenExpiry = accessToken.expiry;
        return accessToken.data;
      } finally {
        client.close();
      }
    }();

    try {
      return await _accessTokenInFlight!;
    } finally {
      _accessTokenInFlight = null;
    }
  }

  static String _resolveProjectForUrl() {
    // Prefer project_id derived from service account JSON.
    if (_fcmProjectId.isNotEmpty && !RegExp(r'^\d+$').hasMatch(_fcmProjectId)) {
      return _fcmProjectId.trim();
    }
    final fallback = Constant.senderId.trim();
    if (fallback.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fallback)) {
      return fallback;
    }
    debugPrint('[FCM] Using hardcoded fallback project id=$_fallbackProjectId');
    return _fallbackProjectId;
  }

  static Future<bool> sendFcmMessage(
      String type, String token, Map<String, dynamic>? payload) async {
    if (token.isEmpty) {
      debugPrint('[FCM] Token is null or empty. Skipping notification.');
      return false;
    }
    try {
      await _ensureNotificationSettings();
      final String accessToken = await getAccessToken();
      final String projectId = _resolveProjectForUrl();
      debugPrint("accessToken=======>");
      debugPrint(accessToken);
      NotificationModel? notificationModel =
          await FireStoreUtils.getNotificationContent(type);

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(
          <String, dynamic>{
            'message': {
              'token': token,
              'notification': {
                'body': notificationModel!.message ?? '',
                'title': notificationModel.subject ?? ''
              },
              'data': payload,
            }
          },
        ),
      );

      debugPrint("Notification=======>");
      debugPrint('FCM statusCode=${response.statusCode}');
      debugPrint(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      debugPrint('[FCM] sendFcmMessage failed: ${response.statusCode} '
          'body=${response.body}');
      return false;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  static sendOneNotification(
      {required String token,
      required String title,
      required String body,
      required Map<String, dynamic> payload}) async {
    if (token.isEmpty) {
      debugPrint('[FCM] Token is null or empty. Skipping notification.');
      return false;
    }
    try {
      await _ensureNotificationSettings();
      final String accessToken = await getAccessToken();
      final String projectId = _resolveProjectForUrl();
      debugPrint("accessToken=======>");
      debugPrint(accessToken);

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(
          <String, dynamic>{
            'message': {
              'token': token,
              'notification': {'body': body, 'title': title},
              'data': payload,
            }
          },
        ),
      );

      debugPrint("Notification=======>");
      debugPrint(response.statusCode.toString());
      debugPrint(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      debugPrint('[FCM] sendOneNotification failed: ${response.statusCode} '
          'body=${response.body}');
      return false;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  static Future<bool> sendChatFcmMessage(String title, String message,
      String token, Map<String, dynamic>? payload) async {
    try {
      await _ensureNotificationSettings();
      final String accessToken = await getAccessToken();
      final String projectId = _resolveProjectForUrl();
      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(
          <String, dynamic>{
            'message': {
              'token': token,
              'notification': {'body': message, 'title': title},
              'data': payload,
            }
          },
        ),
      );
      debugPrint("Notification=======>");
      debugPrint(response.statusCode.toString());
      debugPrint(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      debugPrint('[FCM] sendChatFcmMessage failed: ${response.statusCode} '
          'body=${response.body}');
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
