import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static String get _localBaseUrl {
    if (kIsWeb) return 'https://cuida-tech-backend.onrender.com/api';
    if (Platform.isAndroid) return 'https://cuida-tech-backend.onrender.com/api'; // Android Emulator
    return 'https://cuida-tech-backend.onrender.com/api'; // Windows / iOS Simulator
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
