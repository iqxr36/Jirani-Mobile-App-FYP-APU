library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/agent_debug_log.dart';
import 'package:jirani/resident/screens/chat/chat_message_action_menu.dart';
import 'package:jirani/resident/screens/chat/chat_report_sheet.dart';
import 'package:jirani/resident/providers/chat_provider.dart';
import 'package:jirani/shared/models/chat_message_model.dart';
import 'package:jirani/shared/models/chat_model.dart';
import 'package:jirani/shared/models/pinned_chat_message.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

part 'chat_thread/chat_thread_tokens.dart';
part 'chat_thread/chat_thread_helpers.dart';
part 'chat_thread/chat_thread_message_widgets.dart';
part 'chat_thread/chat_thread_attachment_widgets.dart';
part 'chat_thread/chat_thread_sheet_widgets.dart';
part 'chat_thread/resident_chat_thread_main.dart';
