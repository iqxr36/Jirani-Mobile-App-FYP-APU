library;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/logic/verification_access.dart';
import 'package:jirani/resident/providers/chat_provider.dart';
import 'package:jirani/resident/providers/connection_provider.dart';
import 'package:jirani/resident/providers/notification_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/community_post_model.dart';
import 'package:jirani/shared/services/community_post_service.dart';
import 'package:jirani/resident/screens/chat/resident_messages_view.dart';
import 'package:jirani/resident/screens/connections/resident_connections_view.dart';
import 'package:jirani/resident/screens/home/community_post_detail_view.dart';
import 'package:jirani/resident/screens/home/resident_marketplace_view.dart';
import 'package:jirani/resident/screens/home/resident_services_view.dart';
import 'package:jirani/resident/screens/notifications/resident_notifications_view.dart';
import 'package:provider/provider.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';

part 'home/home_tokens.dart';
part 'home/resident_home_view_main.dart';
part 'home/home_header_widgets.dart';
part 'home/home_carousel_widgets.dart';
