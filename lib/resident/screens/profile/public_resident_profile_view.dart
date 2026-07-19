// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : public_resident_profile_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/providers/review_provider.dart';
import 'package:jirani/shared/data/repositories/public_profile_repository.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/public_resident_profile.dart';
import 'package:jirani/shared/models/review_model.dart';
import 'package:jirani/shared/models/service_model.dart';
import 'package:jirani/shared/utils/public_profile_metrics.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/shared/widgets/resolved_profile_avatar.dart';
import 'package:provider/provider.dart';


part 'public_profile/public_profile_tokens.dart';
part 'public_profile/public_resident_profile_view_main.dart';
part 'public_profile/public_profile_content.dart';
part 'public_profile/public_profile_sections.dart';
part 'public_profile/public_profile_previews.dart';
part 'public_profile/public_profile_widgets.dart';
part 'public_profile/public_profile_helpers.dart';
