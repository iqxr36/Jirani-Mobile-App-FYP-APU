// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_viewmodel.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:async';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/verification_request.dart';
import 'package:jirani/shared/data/repositories/verification_repository.dart';

// Residency verification feature: manages upload state, latest request state, and verification form actions.
class VerificationViewModel extends ChangeNotifier {
  VerificationViewModel({VerificationRepository? repository})
    : _repository = repository ?? VerificationRepository();

  final VerificationRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  VerificationRequest? _currentRequest;
  double _uploadProgress = 0;
  String _selectedDocumentType = AppConstants.documentTypeUtilityBill;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VerificationRequest? get currentRequest => _currentRequest;
  double get uploadProgress => _uploadProgress;
  String get selectedDocumentType => _selectedDocumentType;

  // Residency verification feature: updates the document type selected by the resident upload form.
  set selectedDocumentType(String value) {
    _selectedDocumentType = value;
    _notifyIfActive();
  }

  // Residency verification feature: loads the resident's latest verification request for status screens.
  Future<void> loadCurrentRequest() async {
    _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

    try {
      _currentRequest = await _repository.getCurrentUserLatestRequest();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _notifyIfActive();
    }
  }

  // Residency verification feature: uploads a proof document and creates the Firestore request for admin review.
  Future<VerificationRequest?> submitVerificationRequest({
    required String documentType,
    required Uint8List fileBytes,
    required String originalFileName,
    String? localFilePath,
    required String communityName,
    required String unitNumber,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _uploadProgress = 0;
    _notifyIfActive();

    try {
      final result = await _repository.submitVerificationRequest(
        documentType: documentType,
        fileBytes: fileBytes,
        originalFileName: originalFileName,
        localFilePath: localFilePath,
        communityName: communityName,
        unitNumber: unitNumber,
        notes: notes,
        onUploadProgress: (p) {
          _uploadProgress = p.clamp(0.0, 1.0);
          _notifyIfActive();
        },
      );
      _currentRequest = result;
      return result;
    } catch (e, stackTrace) {
      debugPrint('[VerificationUpload] FAILED: $e');
      debugPrint('[VerificationUpload] $stackTrace');
      _errorMessage = _mapSubmitError(e);
      return null;
    } finally {
      _isLoading = false;
      _uploadProgress = 0;
      _notifyIfActive();
    }
  }

  // Residency verification feature: converts upload/storage failures into resident-friendly messages.
  String _mapSubmitError(Object e) {
    if (e is VerificationUnsupportedFileTypeException) {
      return e.message;
    }
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
        case 'unauthorized':
          return 'Upload blocked by Firebase Storage rules.';
        default:
          break;
      }
    }
    if (e is TimeoutException) {
      return 'Upload timed out. Check your connection and try again.';
    }

    final raw = e.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('unsupported operation') ||
        lower.contains('_namespace')) {
      return 'This file could not be read. Please choose another file.';
    }

    if (lower.contains('storage') &&
        (lower.contains('denied') || lower.contains('unauthorized'))) {
      return 'Upload blocked by Firebase Storage rules.';
    }

    return 'Upload failed. Please try again or pick a different file.';
  }

  // Residency verification feature: cancels the latest submitted request so the resident can resubmit documents.
  Future<bool> cancelLatestVerificationRequest() async {
    _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

    try {
      await _repository.cancelLatestVerificationRequest();
      _currentRequest = await _repository.getCurrentUserLatestRequest();
      return true;
    } catch (e, stackTrace) {
      debugPrint('[VerificationCancel] FAILED: $e');
      debugPrint('$stackTrace');
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _notifyIfActive();
    }
  }

  // Residency verification UI state: clears the latest upload/status error.
  void clearError() {
    _errorMessage = null;
    _notifyIfActive();
  }

  // Residency verification UI state: avoids notifying listeners after the upload screen is disposed.
  void _notifyIfActive() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
