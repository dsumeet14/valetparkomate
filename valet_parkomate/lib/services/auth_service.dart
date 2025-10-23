import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valet_parkomate/models/user.dart';
import 'package:valet_parkomate/services/api_service.dart';

class AuthService with ChangeNotifier {
  UserSession? _session;
  bool _isLoading = true;

  UserSession? get userSession => _session;
  bool get isLoggedIn => _session != null;
  bool get isLoading => _isLoading;

  static const _kStorageKey = 'valet_user_session';
  static const _kTokenKey = 'valet_auth_token';

  Future<void> loadFromStorage() async {
    final sp = await SharedPreferences.getInstance();
    final jsonStr = sp.getString(_kStorageKey);
    final token = sp.getString(_kTokenKey);

    if (jsonStr != null && token != null) {
      try {
        final map = jsonDecode(jsonStr);
        _session = UserSession.fromJson(Map<String, dynamic>.from(map));
        _session!.token = token; // Restore token
      } catch (e) {
        // Clear corrupt data
        await sp.remove(_kStorageKey);
        await sp.remove(_kTokenKey);
        _session = null;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> persistSession() async {
    final sp = await SharedPreferences.getInstance();
    if (_session == null) {
      await sp.remove(_kStorageKey);
      await sp.remove(_kTokenKey);
    } else {
      await sp.setString(_kStorageKey, jsonEncode(_session!.toJson()));
      if (_session!.token != null) {
        await sp.setString(_kTokenKey, _session!.token!);
      }
    }
  }

  Future<String?> getToken() async {
    if (_session == null) {
      // Attempt to load from storage if not in memory
      await loadFromStorage();
    }
    return _session?.token;
  }

  Future<void> logout() async {
    _session = null;
    await persistSession();
    notifyListeners();
  }

  Future<UserSession> login(String siteNoStr, String id, String password) async {
    try {
      final siteNo = int.tryParse(siteNoStr) ?? 0;
      final body = {'site_no': siteNo, 'id': id, 'password': password};
      final res = await ApiService().post('api/login', body);

      final rRole = res['role']?.toString();
      final rId = res['id']?.toString();
      final rSite = (res['site_no'] is int) ? res['site_no'] as int : int.parse(res['site_no'].toString());
      final rToken = res['token']?.toString(); // Get token from response

      if (rToken == null) {
        throw Exception('Login failed: no token returned.');
      }

      final session = UserSession(
        id: rId!,
        role: rRole ?? 'operator',
        siteNo: rSite,
        token: rToken, // Store the token in the session
      );

      _session = session;
      await persistSession();
      notifyListeners();
      return session;
    } catch (e) {
      _session = null;
      notifyListeners();
      rethrow;
    }
  }
}