library;

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/item_listing_form.dart';
import 'package:jirani/resident/logic/marketplace_borrow_flow.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/resident/providers/borrow_request_provider.dart';
import 'package:jirani/resident/providers/chat_provider.dart';
import 'package:jirani/resident/providers/item_provider.dart';
import 'package:jirani/resident/providers/review_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/services/device_permission_access.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/utils/display_labels.dart';
import 'package:jirani/resident/screens/chat/resident_chat_thread_view.dart';
import 'package:jirani/resident/screens/profile/public_resident_profile_view.dart';
import 'package:provider/provider.dart';

part 'item_listing/item_listing_tokens.dart';
part 'item_listing/item_listing_options.dart';
part 'item_listing/item_listing_helpers.dart';
part 'item_listing/item_listing_shared_widgets.dart';
part 'item_listing/resident_my_items_view.dart';
part 'item_listing/resident_lender_request_detail_view.dart';
part 'item_listing/resident_item_listing_form_view.dart';
