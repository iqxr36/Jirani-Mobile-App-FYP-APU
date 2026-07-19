// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : flutter_test_config.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,16-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestFirebaseCoreHostApi.setUp(_JiraniFirebaseCoreMock());
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test',
          appId: 'test',
          messagingSenderId: 'test',
          projectId: 'test',
          storageBucket: 'test.appspot.com',
        ),
      );
    } on FirebaseException catch (error) {
      if (error.code != 'duplicate-app') rethrow;
    }
  }
  await testMain();
}

class _JiraniFirebaseCoreMock implements TestFirebaseCoreHostApi {
  static CoreFirebaseOptions get _options => CoreFirebaseOptions(
    apiKey: 'test',
    projectId: 'test',
    appId: 'test',
    messagingSenderId: 'test',
    storageBucket: 'test.appspot.com',
  );

  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async {
    return CoreInitializeResponse(
      name: appName,
      options: _options,
      pluginConstants: const {},
    );
  }

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async {
    return [
      CoreInitializeResponse(
        name: defaultFirebaseAppName,
        options: _options,
        pluginConstants: const {},
      ),
    ];
  }

  @override
  Future<CoreFirebaseOptions> optionsFromResource() async => _options;
}
