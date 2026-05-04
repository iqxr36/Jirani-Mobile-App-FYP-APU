import 'package:flutter/foundation.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/data/models/verification_request.dart';
import 'package:fyp_flutter_application/data/repositories/verification_repository.dart';

class VerificationViewModel extends ChangeNotifier {
  VerificationViewModel({VerificationRepository? repository})
      : _repository = repository ?? VerificationRepository();

  final VerificationRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  VerificationRequest? _currentRequest;
  double _uploadProgress = 0;
  String _selectedDocumentType = AppConstants.documentTypeUtilityBill;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VerificationRequest? get currentRequest => _currentRequest;
  double get uploadProgress => _uploadProgress;
  String get selectedDocumentType => _selectedDocumentType;

  set selectedDocumentType(String value) {
    _selectedDocumentType = value;
    notifyListeners();
  }

  Future<void> loadCurrentRequest() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentRequest = await _repository.getCurrentUserLatestRequest();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VerificationRequest?> submitVerificationRequest({
    required String documentType,
    required String filePath,
    required String communityName,
    required String unitNumber,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _uploadProgress = 0;
    notifyListeners();

    try {
      final result = await _repository.submitVerificationRequest(
        documentType: documentType,
        filePath: filePath,
        communityName: communityName,
        unitNumber: unitNumber,
        notes: notes,
        onUploadProgress: (p) {
          _uploadProgress = p.clamp(0.0, 1.0);
          notifyListeners();
        },
      );
      _currentRequest = result;
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      _uploadProgress = 0;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
