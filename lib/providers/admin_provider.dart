import 'package:flutter/material.dart';
import '../core/api/dio_client.dart';

class AdminProvider with ChangeNotifier {
  List<dynamic> _users = [];
  List<dynamic> _offers = [];
  List<dynamic> _financeReports = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get users => _users;
  List<dynamic> get offers => _offers;
  List<dynamic> get financeReports => _financeReports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        fetchUsers(),
        fetchOffers(),
        fetchFinanceReports(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsers() async {
    try {
      final response = await DioClient.instance.get('/admin/users');
      _users = response.data;
    } catch (e) {
      _errorMessage = 'Erro ao carregar usuários.';
    }
    notifyListeners();
  }

  Future<void> fetchOffers() async {
    try {
      final response = await DioClient.instance.get('/admin/offers');
      _offers = response.data;
    } catch (e) {
      _errorMessage = 'Erro ao carregar ofertas.';
    }
    notifyListeners();
  }

  Future<void> fetchFinanceReports() async {
    try {
      final response = await DioClient.instance.get('/admin/finance/reports');
      _financeReports = response.data;
    } catch (e) {
      _errorMessage = 'Erro ao carregar relatórios financeiros.';
    }
    notifyListeners();
  }

  Future<bool> updateUserStatus(int userId, String action) async {
    try {
      await DioClient.instance.post('/admin/users/$userId/$action');
      await fetchUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createOffer(Map<String, dynamic> data) async {
    try {
      await DioClient.instance.post('/admin/offers', data: data);
      await fetchOffers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteOffer(int offerId) async {
    try {
      await DioClient.instance.delete('/admin/offers/$offerId');
      await fetchOffers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> downloadReport(int providerId) async {
    try {
      final response = await DioClient.instance.get('/admin/finance/reports/$providerId/download');
      return response.data['downloadUrl'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> uploadReceipt(int providerId, String receiptUrl) async {
    try {
      await DioClient.instance.post('/admin/finance/reports/$providerId/receipt', data: {
        'receiptUrl': receiptUrl
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
