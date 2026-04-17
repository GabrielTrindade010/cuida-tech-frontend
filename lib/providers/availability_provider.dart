import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';

class AvailabilityProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Enviar a disponibilidade ao backend
  Future<bool> submitAvailability({
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, String>> shifts,
    Map<String, String>? substitute,
    required bool legalDisclaimerAccepted,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'startDate': startDate.toIso8601String().split('T').first,
        'endDate': endDate.toIso8601String().split('T').first,
        'shifts': shifts,
        'substitute': substitute,
        'legalDisclaimerAccepted': legalDisclaimerAccepted,
      };

      await DioClient.instance.post('/availability/submit', data: payload);
      
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Erro desconhecido ao enviar oferta de disponibilidade.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
