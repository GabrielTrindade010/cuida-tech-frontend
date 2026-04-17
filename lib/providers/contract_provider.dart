import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';

class ContractProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _latestContract;
  bool _alreadyAccepted = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get latestContract => _latestContract;
  bool get alreadyAccepted => _alreadyAccepted;

  Future<bool> checkIfAlreadyAccepted() async {
    try {
      final response = await DioClient.instance.get('/contracts/status');
      _alreadyAccepted = response.data['accepted'] == true;
      return _alreadyAccepted;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchLatestContract() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await DioClient.instance.get('/contracts/latest');
      _latestContract = response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _errorMessage = 'Nenhum contrato ativo de parcerias encontrado.';
      } else {
        _errorMessage = e.response?.data['message'] ?? 'Erro ao buscar termo legal.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptContract(String? base64Signature) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await DioClient.instance.post('/contracts/accept', data: {
        'signatureImagePath': base64Signature, // Poderia ser url S3, por mock mandaremos BASE64
      });
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Falha ao registrar aceite do contrato.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
