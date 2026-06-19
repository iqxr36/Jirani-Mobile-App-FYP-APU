import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/data/repositories/verification_repository.dart';
import 'package:jirani/shared/models/verification_request.dart';
import 'package:jirani/viewmodels/verification_viewmodel.dart';

void main() {
  group('VerificationViewModel', () {
    test(
      'updates loading, progress, and current request on submit success',
      () async {
        final request = _verificationRequest();
        final repository = _FakeVerificationRepository(
          submitHandler:
              ({
                required documentType,
                required fileBytes,
                required originalFileName,
                localFilePath,
                required communityName,
                required unitNumber,
                notes,
                onUploadProgress,
              }) async {
                onUploadProgress?.call(0.5);
                return request;
              },
        );
        final viewModel = VerificationViewModel(repository: repository);
        addTearDown(viewModel.dispose);

        var notificationCount = 0;
        viewModel.addListener(() => notificationCount += 1);

        final result = await viewModel.submitVerificationRequest(
          documentType: AppConstants.documentTypeUtilityBill,
          fileBytes: Uint8List.fromList([1, 2, 3]),
          originalFileName: 'bill.pdf',
          communityName: 'One South Residence',
          unitNumber: 'C-5-6',
        );

        expect(result, request);
        expect(viewModel.currentRequest, request);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.uploadProgress, 0);
        expect(viewModel.errorMessage, isNull);
        expect(notificationCount, greaterThanOrEqualTo(3));
      },
    );

    test('maps submit failures and resets loading state', () async {
      final repository = _FakeVerificationRepository(
        submitHandler:
            ({
              required documentType,
              required fileBytes,
              required originalFileName,
              localFilePath,
              required communityName,
              required unitNumber,
              notes,
              onUploadProgress,
            }) {
              throw VerificationUnsupportedFileTypeException('Only PDF files.');
            },
      );
      final viewModel = VerificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      final result = await viewModel.submitVerificationRequest(
        documentType: AppConstants.documentTypeUtilityBill,
        fileBytes: Uint8List.fromList([1, 2, 3]),
        originalFileName: 'bill.png',
        communityName: 'One South Residence',
        unitNumber: 'C-5-6',
      );

      expect(result, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.uploadProgress, 0);
      expect(viewModel.errorMessage, 'Only PDF files.');
    });

    test('does not notify listeners after disposal during upload', () async {
      final completion = Completer<VerificationRequest>();
      void Function(double progress)? progressCallback;
      final repository = _FakeVerificationRepository(
        submitHandler:
            ({
              required documentType,
              required fileBytes,
              required originalFileName,
              localFilePath,
              required communityName,
              required unitNumber,
              notes,
              onUploadProgress,
            }) {
              progressCallback = onUploadProgress;
              return completion.future;
            },
      );
      final viewModel = VerificationViewModel(repository: repository);

      final resultFuture = viewModel.submitVerificationRequest(
        documentType: AppConstants.documentTypeUtilityBill,
        fileBytes: Uint8List.fromList([1, 2, 3]),
        originalFileName: 'bill.pdf',
        communityName: 'One South Residence',
        unitNumber: 'C-5-6',
      );

      viewModel.dispose();

      expect(() => progressCallback?.call(0.75), returnsNormally);
      completion.complete(_verificationRequest());

      await expectLater(resultFuture, completes);
    });
  });
}

VerificationRequest _verificationRequest() {
  return VerificationRequest(
    id: 'request-1',
    userId: 'user-1',
    fullName: 'Om Khalil',
    email: 'omkhalil@gmail.com',
    phoneNumber: '+60197888597',
    documentType: AppConstants.documentTypeUtilityBill,
    documentUrl: 'https://example.com/bill.pdf',
    communityId: 'community-1',
    communityName: 'One South Residence',
    unitNumber: 'C-5-6',
    notes: '',
    status: AppConstants.verificationSubmitted,
    rejectionReason: null,
    submittedAt: DateTime(2026, 6, 18),
    reviewedAt: null,
    reviewedBy: null,
  );
}

typedef _SubmitHandler =
    FutureOr<VerificationRequest> Function({
      required String documentType,
      required Uint8List fileBytes,
      required String originalFileName,
      String? localFilePath,
      required String communityName,
      required String unitNumber,
      String? notes,
      void Function(double progress)? onUploadProgress,
    });

class _FakeVerificationRepository implements VerificationRepository {
  _FakeVerificationRepository({required _SubmitHandler submitHandler})
    : _submitHandler = submitHandler;

  final _SubmitHandler _submitHandler;

  @override
  User? get currentFirebaseUser => null;

  @override
  Future<void> cancelLatestVerificationRequest() async {}

  @override
  Future<void> cancelActiveVerificationRequestIfAny() async {}

  @override
  Future<VerificationRequest?> getCurrentUserLatestRequest() async => null;

  @override
  Future<VerificationRequest> submitVerificationRequest({
    required String documentType,
    required Uint8List fileBytes,
    required String originalFileName,
    String? localFilePath,
    required String communityName,
    required String unitNumber,
    String? notes,
    void Function(double progress)? onUploadProgress,
  }) async {
    return _submitHandler(
      documentType: documentType,
      fileBytes: fileBytes,
      originalFileName: originalFileName,
      localFilePath: localFilePath,
      communityName: communityName,
      unitNumber: unitNumber,
      notes: notes,
      onUploadProgress: onUploadProgress,
    );
  }
}
