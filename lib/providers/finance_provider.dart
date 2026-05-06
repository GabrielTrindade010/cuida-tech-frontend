import 'package:flutter/material.dart';
import '../core/api/dio_client.dart';

class FinanceProvider with ChangeNotifier {
  double _totalGains = 0;
  List<dynamic> _transactions = [];
  String? _pixKey;
  bool _isLoading = false;
  String? _errorMessage;

  double get totalGains => _totalGains;
  List<dynamic> get transactions => _transactions;
  String? get pixKey => _pixKey;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchFinanceData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Mocking finance data for now as backend logic for payments is complex
      // In a real app, this would fetch from a /finance endpoint
      _totalGains = 1250.00;
      _transactions = [
        {'title': 'Plantão Moema', 'date': '2026-04-20', 'value': 180.00, 'status': 'PAID'},
        {'title': 'Home Care Jardins', 'date': '2026-04-21', 'value': 250.00, 'status': 'PAID'},
        {'title': 'Plantão Itaim', 'date': '2026-04-22', 'value': 200.00, 'status': 'PENDING'},
      ];
      
      final profile = await DioClient.instance.get('/users/me');
      _pixKey = profile.data['pixKey'];
      
    } catch (e) {
      _errorMessage = 'Erro ao carregar dados financeiros.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePixKey(String key) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DioClient.instance.put('/users/profile', data: {'pixKey': key});
      _pixKey = key;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar chave PIX.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
