library;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/models/admin_display_rows.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/reported_chat_message_snapshot.dart';
import 'package:jirani/shared/models/report_model.dart';
import 'package:jirani/shared/utils/chat_report_formatters.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

part 'admin_reports/admin_reports_tokens.dart';
part 'admin_reports/admin_reports_screen_main.dart';
part 'admin_reports/admin_report_inbox_tile.dart';
part 'admin_reports/admin_report_case_widgets.dart';
part 'admin_reports/admin_report_evidence_widgets.dart';
