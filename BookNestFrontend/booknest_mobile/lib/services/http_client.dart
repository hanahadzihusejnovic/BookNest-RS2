import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../screens/auth_wrapper.dart';

class HttpClient {
  static const _tokenKey = 'auth_token';
  static const _rememberMeKey = 'remember_me';
  static const _savedUsernameKey = 'saved_username';
  static const _secureStorage = FlutterSecureStorage();

  static Future<void> _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final savedUsername = prefs.getString(_savedUsernameKey);

    await _secureStorage.delete(key: _tokenKey);
    await prefs.clear();

    if (rememberMe && savedUsername != null) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_savedUsernameKey, savedUsername);
    }

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (route) => false,
    );
  }

  static Future<Map<String, String>> _authHeaders([Map<String, String>? extra]) async {
    final token = await _secureStorage.read(key: _tokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (extra != null) ...extra,
    };
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final response = await http.get(url, headers: await _authHeaders(headers));
    if (response.statusCode == 401) await _handleUnauthorized();
    return response;
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await http.post(url, headers: await _authHeaders(headers), body: body, encoding: encoding);
    if (response.statusCode == 401) await _handleUnauthorized();
    return response;
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await http.put(url, headers: await _authHeaders(headers), body: body, encoding: encoding);
    if (response.statusCode == 401) await _handleUnauthorized();
    return response;
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await http.delete(url, headers: await _authHeaders(headers), body: body, encoding: encoding);
    if (response.statusCode == 401) await _handleUnauthorized();
    return response;
  }
}
