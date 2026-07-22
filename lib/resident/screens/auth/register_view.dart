// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : register_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Tuesday,05-May-2026
// Last Edited on  : Saturday,18-July-2026

library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/screens/legal/legal_document_view.dart';
import 'package:jirani/resident/screens/auth/resident_registration_ui.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:jirani/shared/services/community_service.dart';
import 'package:jirani/shared/widgets/jirani_logo.dart';
import 'package:jirani/shared/widgets/jirani_modal.dart';
import 'package:provider/provider.dart';

import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'login_view.dart';

part 'register/register_tokens.dart';
part 'register/register_form_fields.dart';
part 'register/register_community_widgets.dart';
part 'register/register_screen_widgets.dart';
part 'register/register_view_main.dart';
part 'register/register_view_state.dart';
