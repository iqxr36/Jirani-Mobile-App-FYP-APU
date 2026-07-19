// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_profile_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/providers/theme_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/resident/screens/auth/email_verification_view.dart';
import 'package:jirani/resident/screens/home/resident_services_view.dart';
import 'package:jirani/resident/screens/marketplace/resident_item_listing_view.dart';
import 'package:jirani/resident/screens/profile/resident_edit_profile_view.dart';
import 'package:jirani/resident/screens/profile/payment_methods_view.dart';
import 'package:jirani/resident/screens/profile/resident_help_support_view.dart';
import 'package:jirani/resident/screens/profile/resident_privacy_safety_settings_view.dart';
import 'package:jirani/resident/screens/profile/resident_push_notifications_settings_view.dart';
import 'package:jirani/resident/screens/profile/resident_reviews_view.dart';
import 'package:jirani/resident/screens/profile/resident_settings_view.dart';
import 'package:jirani/resident/screens/verification/verification_process_view.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

part 'profile/profile_tokens.dart';
part 'profile/resident_profile_view_main.dart';
part 'profile/profile_stats_widgets.dart';
part 'profile/profile_card.dart';
part 'profile/profile_verification_widgets.dart';
part 'profile/profile_display_widgets.dart';
