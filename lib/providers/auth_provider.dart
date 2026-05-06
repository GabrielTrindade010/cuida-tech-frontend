import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isCheckingSession = true;
  String? _errorMessage;
  int _registrationStep = 5; // Default to 5 (complete) to avoid flashing
  String _status = 'ACTIVE';
  String _role = 'PRESTADOR';

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isCheckingSession => _isCheckingSession;
  String? get errorMessage => _errorMessage;
  int get registrationStep => _registrationStep;
  String get status => _status;
  String get role => _role;

  Future<void> checkSession() async {
    _isCheckingSession = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      final decoded = JwtDecoder.decode(token);
      _registrationStep = decoded['registrationStep'] ?? 5;
      _role = decoded['role'] ?? 'PRESTADOR';
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
      await prefs.remove('jwt_token');
    }
    
    _isCheckingSession = false;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String document,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // O registro agora é apenas o Passo 1
      final response = await DioClient.instance.post('/users/register', data: {
        'name': name,
        'email': email,
        'document': document,
        'phone': phone,
        'password': password,
      });

      final token = response.data['token'];
      final user = response.data;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      
      _registrationStep = user['registrationStep'] ?? 1;
      _status = user['status'] ?? 'INCOMPLETE';
      _role = user['role'] ?? 'PRESTADOR';
      _isAuthenticated = true;
      
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Erro ao registrar conta.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRegistrationStep(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await DioClient.instance.patch('/users/update-registration', data: data);
      _registrationStep = response.data['registrationStep'] ?? _registrationStep;
      _status = response.data['status'] ?? _status;
      
      // Se o passo mudou, opcionalmente podemos atualizar o token se o backend emitir um novo,
      // mas aqui vamos apenas atualizar o estado local para navegação.
      
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Erro ao atualizar cadastro.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String document, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await DioClient.instance.post('/auth/login', data: {
        'document': document,
        'password': password,
      });

      final token = response.data['token'];
      final user = response.data['user'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      
      _registrationStep = user['registrationStep'] ?? 5;
      _status = user['status'] ?? 'ACTIVE';
      _role = user['role'] ?? 'PRESTADOR';
      _isAuthenticated = true;
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Credenciais inválidas.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    _isAuthenticated = false;
    _registrationStep = 1;
    _role = 'PRESTADOR';
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await DioClient.instance.get('/users/me');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadFile(String filePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fileName = filePath.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await DioClient.instance.post('/upload', data: formData);
      return response.data['url'];
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Erro no upload do arquivo.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptContract(String? signatureImagePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await DioClient.instance.post('/contracts/accept', data: {
        'signatureImagePath': signatureImagePath,
      });
      
      _registrationStep = 5;
      _status = 'PENDING';
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Erro ao aceitar contrato.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
