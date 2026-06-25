library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/widgets/auth_feedback_banner.dart';
import 'package:provider/provider.dart';

part 'phone_verification/phone_verification_tokens.dart';
part 'phone_verification/phone_verification_view_main.dart';
part 'phone_verification/phone_verification_view_state.dart';
part 'phone_verification/phone_verification_otp_widgets.dart';
part 'phone_verification/phone_verification_screen_widgets.dart';
