library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/verification_request.dart';
import 'package:jirani/shared/models/extracted_document_data.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/report_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:jirani/shared/models/service_model.dart';

part 'admin_service/admin_service_watchers.dart';
part 'admin_service/admin_service_verification.dart';
part 'admin_service/admin_service_reports.dart';
part 'admin_service/admin_service_stats.dart';
part 'admin_service/admin_service_residents.dart';

abstract class _AdminServiceBase {
  _AdminServiceBase({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
}

class AdminService extends _AdminServiceBase
    with
        _AdminServiceWatchersMixin,
        _AdminServiceVerificationMixin,
        _AdminServiceReportsMixin,
        _AdminServiceStatsMixin,
        _AdminServiceResidentsMixin {
  AdminService({super.auth, super.firestore});
}
