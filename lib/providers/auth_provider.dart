import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
      await prefs.remove('jwt_token');
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String document,
    required String professionalRegister,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await DioClient.instance.post('/users/register', data: {
        'name': name,
        'email': email,
        'document': document,
        'professionalRegister': professionalRegister,
        'password': password,
      });
      // Importante: No nosso backend Clean Arch, o register não loga automaticamente.
      // Retornamos true para a tela avisar "Conta criada com sucesso" e o usuário fazer o login normal.
      return true;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
        _errorMessage = 'Servidor indisponível. O Backend está rodando?';
      } else {
        _errorMessage = e.response?.data['message'] ?? 'Erro desconhecido ao registrar nova conta.';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await DioClient.instance.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
         _errorMessage = 'Servidor indisponível. O Backend está rodando?';
      } else {
         _errorMessage = e.response?.data['message'] ?? 'Erro desconhecido na autenticação.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    _isAuthenticated = false;
    notifyListeners();
  }
}
