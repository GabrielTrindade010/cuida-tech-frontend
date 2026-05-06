import 'package:flutter/material.dart';
import '../core/api/dio_client.dart';

class OfferProvider with ChangeNotifier {
  List<dynamic> _availableOffers = [];
  List<dynamic> _myOffers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get availableOffers => _availableOffers;
  List<dynamic> get myOffers => _myOffers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAvailableOffers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await DioClient.instance.get('/offers');
      _availableOffers = response.data;
    } catch (e) {
      _errorMessage = 'Erro ao carregar ofertas disponíveis.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyAcceptedOffers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Reusing availability endpoint or creating a new one?
      // I'll use /offers/my-accepted for clarity
      final response = await DioClient.instance.get('/offers/my-accepted');
      _myOffers = response.data;
    } catch (e) {
      _errorMessage = 'Erro ao carregar seus serviços.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptOffer(int offerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DioClient.instance.post('/offers/$offerId/accept');
      _availableOffers.removeWhere((o) => o['id'] == offerId);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao aceitar oferta.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refuseOffer(int offerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DioClient.instance.post('/offers/$offerId/refuse');
      _availableOffers.removeWhere((o) => o['id'] == offerId);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao recusar oferta.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkIn(int offerId, double lat, double lng) async {
    _isLoading = true;
    notifyListeners();
    try {
      await DioClient.instance.post('/treated-days/check-in', data: {
        'offerId': offerId,
        'lat': lat,
        'lng': lng
      });
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao realizar check-in.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkOut(int offerId, double lat, double lng, String report) async {
    _isLoading = true;
    notifyListeners();
    try {
      await DioClient.instance.post('/treated-days/check-out', data: {
        'offerId': offerId,
        'lat': lat,
        'lng': lng,
        'report': report
      });
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao realizar check-out.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> indicateSubstitute(int offerId, String name, String document) async {
    _isLoading = true;
    notifyListeners();
    try {
      await DioClient.instance.post('/offers/$offerId/substitute', data: {
        'name': name,
        'document': document
      });
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao indicar substituto.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
