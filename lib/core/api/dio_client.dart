import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static String get _localBaseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://192.168.0.14:3000/api'; // Android Emulator MUST use 10.0.2.2
    return 'http://localhost:3000/api'; // Windows / iOS Simulator
  }

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _localBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static Dio get instance => _dio;

  static void setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Redirecionamento global se 401 ou 403 (falta de contrato) pode ser injetado aqui via Contexto (NavigationService global)
        return handler.next(e);
      },
    ));
  }
}
