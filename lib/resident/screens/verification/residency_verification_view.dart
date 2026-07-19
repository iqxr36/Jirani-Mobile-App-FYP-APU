// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : residency_verification_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/resident/logic/verification_viewmodel.dart';
import 'package:jirani/resident/screens/verification/verification_status_view.dart';
import 'package:jirani/shared/widgets/jirani_modal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

part 'residency/residency_tokens.dart';
part 'residency/residency_document_options.dart';
part 'residency/residency_verification_form.dart';
part 'residency/residency_form_fields.dart';
part 'residency/residency_upload_widgets.dart';
