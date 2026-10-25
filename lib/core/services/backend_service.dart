import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../errors/failure.dart';
import '../utils/json_utils.dart';
import 'firebase_providers.dart';

/// Thin client for the EcoPoint backend (`firebase/functions`, run as a Node
/// server). Every operation that changes an EP balance goes through here — the
/// client never writes balances. The server verifies the caller's Firebase ID
/// token, validates input and applies changes atomically.
///
/// Free hosts put idle servers to sleep, so the first call after a quiet period
/// can take a while; [warmUp] is called at app start and the timeout is long.
class BackendService {
  BackendService(this._auth, {http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConstants.backendUrl).replaceAll(RegExp(r'/+$'), '');

  final FirebaseAuth _auth;
  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 75);

  /// Fire-and-forget request that wakes a sleeping server.
  Future<void> warmUp() async {
    try {
      await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 90));
    } catch (_) {
      // Best effort only.
    }
  }

  Future<Map<String, Object?>> call(
    String name, [
    Map<String, Object?> data = const {},
  ]) async {
    final user = _auth.currentUser;
    if (user == null) throw const Failure(Failure.unauthenticated);

    try {
      final token = await user.getIdToken();
      final res = await _client
          .post(
            Uri.parse('$_baseUrl/api/$name'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      Object? decoded;
      try {
        decoded = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        decoded = null;
      }
      final body = asMap(decoded);
      if (res.statusCode == 200) return asMap(body['result']);
      throw Failure.fromBackend(res.statusCode, body['error']);
    } on Failure {
      rethrow;
    } on TimeoutException {
      throw const Failure(Failure.network, 'timeout');
    } on SocketException catch (e) {
      throw Failure(Failure.network, e.message);
    } on http.ClientException catch (e) {
      throw Failure(Failure.network, e.message);
    } catch (e) {
      throw Failure.from(e);
    }
  }
}

final backendServiceProvider = Provider<BackendService>(
  (ref) => BackendService(ref.watch(firebaseAuthProvider)),
);
