library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/agent_debug_log.dart';
import 'package:jirani/resident/logic/chat_access.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/chat_message_model.dart';
import 'package:jirani/shared/models/chat_model.dart';
import 'package:jirani/shared/models/pinned_chat_message.dart';
import 'package:jirani/shared/models/reported_chat_message_snapshot.dart';
import 'package:jirani/shared/utils/chat_report_formatters.dart';

part 'chat_service/chat_service_core.dart';
part 'chat_service/chat_service_queries.dart';
part 'chat_service/chat_service_lifecycle.dart';
part 'chat_service/chat_service_messages.dart';
part 'chat_service/chat_service_reports.dart';

class ChatService extends _ChatServiceBase
    with
        _ChatServiceQueriesMixin,
        _ChatServiceLifecycleMixin,
        _ChatServiceMessagesMixin,
        _ChatServiceReportsMixin {
  ChatService({super.firestore, super.storage});
}
