library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
part 'admin_service/admin_service_payments.dart';
part 'admin_service/admin_service_listings.dart';

// Admin service base: shares Firebase Auth, Firestore, and Functions clients across admin service mixins.
abstract class _AdminServiceBase {
  _AdminServiceBase({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
}

// Admin service facade: combines watcher, verification, report, resident, stats, and payment operations for the portal.
class AdminService extends _AdminServiceBase
    with
        _AdminServiceWatchersMixin,
        _AdminServiceVerificationMixin,
        _AdminServicePaymentsMixin,
        _AdminServiceReportsMixin,
        _AdminServiceStatsMixin,
        _AdminServiceResidentsMixin,
        _AdminServiceListingsMixin {
  AdminService({super.auth, super.firestore, super.functions});
}
