# Jirani — Code Map

## Top-level directory layout

```
lib/
├── main.dart                          # App entry, runApp, provider setup
├── core/                              # Cross-cutting infrastructure
│   ├── constants/app_constants.dart    # Firestore collections, status enums, role strings
│   ├── theme/app_theme.dart           # ThemeData, color schemes, text themes
│   └── utils/                         # Shared helpers
│       ├── validators.dart            # Form validation (email, password, phone, etc.)
│       ├── responsive.dart            # JiraniResponsive layout utilities
│       ├── auth_debug_log.dart        # Auth-flow debug logging
│       ├── agent_debug_log.dart       # Agent/automation debug logging
│       ├── community_change.dart      # Community change flow helpers
│       └── item_listing_form.dart     # Marketplace item form helpers
├── shared/                            # Shared across resident and admin apps
│   ├── models/                        # 19 Firestore-backed data models
│   │   ├── app_user.dart              # Users/admins collection model
│   │   ├── admin_user.dart            # Admin-specific model
│   │   ├── item_model.dart            # Marketplace item listing
│   │   ├── borrow_request.dart        # Borrow lifecycle state
│   │   ├── borrow_request_models.dart # Borrow sub-types (conditions, etc.)
│   │   ├── community_model.dart       # Community definition
│   │   ├── connection_model.dart      # Neighbor connection
│   │   ├── chat_model.dart            # Chat conversation
│   │   ├── chat_message_model.dart     # Individual message
│   │   ├── notification_model.dart    # In-app notification
│   │   ├── report_model.dart          # Disputes and misconduct
│   │   ├── review_model.dart          # Blind marketplace feedback
│   │   ├── service_model.dart         # Service listing
│   │   ├── service_request_model.dart # Service booking
│   │   ├── community_post_model.dart  # Admin announcements
│   │   ├── verification_request.dart  # Residency document submission
│   │   ├── extracted_document_data.dart # OCR-extracted fields
│   │   └── ...
│   ├── data/repositories/             # 11 repositories — Firestore/Storage I/O per entity
│   │   ├── auth_repository.dart       # Firebase Auth + admin doc CRUD
│   │   ├── user_repository.dart       # users & publicProfiles
│   │   ├── item_repository.dart       # items collection
│   │   ├── borrow_request_repository.dart
│   │   ├── community_repository.dart
│   │   ├── connection_repository.dart
│   │   ├── chat_repository.dart       # chats + messages + attachments
│   │   ├── notification_repository.dart
│   │   ├── report_repository.dart
│   │   ├── review_repository.dart
│   │   └── service_repository.dart
│   ├── services/                      # 30 service files — multi-step workflows
│   │   ├── firebase_auth_service.dart # Auth (sign in, register, reset, etc.)
│   │   ├── chat_service.dart          # 5-part split (core, queries, lifecycle, messages, reports)
│   │   ├── borrow_request_service.dart # 5-part split (queries, lifecycle, handover, return, disputes)
│   │   ├── ocr_parser_service.dart    # 6-part split (core, access, detection, labels, tenancy, utility)
│   │   ├── community_service.dart
│   │   ├── connection_service.dart
│   │   ├── notification_service.dart
│   │   ├── push_notification_service.dart
│   │   ├── report_service.dart
│   │   ├── storage_service.dart
│   │   ├── geofence_manager.dart      # Geofence + location verification
│   │   ├── internet_connectivity_checker.dart
│   │   ├── review_service.dart
│   │   ├── service_service.dart
│   │   └── community_post_service.dart
│   ├── logic/                         # Auth state management
│   │   ├── auth_viewmodel.dart        # Central ChangeNotifier + 6 mixins
│   │   ├── auth_wrapper.dart          # Role-based screen routing
│   │   └── auth_viewmodel/            # 6 mixin files: core, sign_in, registration, verification, profile, community
│   ├── providers/                     # Provider aliases (auth_provider.dart, etc.)
│   └── widgets/                       # 13 reusable widgets
│       ├── auth_feedback_banner.dart
│       ├── jirani_logo.dart
│       ├── jirani_modal.dart
│       ├── jirani_background.dart
│       ├── network_status_overlay.dart
│       ├── verification_locked_overlay.dart
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       ├── empty_state_widget.dart
│       ├── error_state_widget.dart
│       ├── loading_widget.dart
│       ├── community_change_warning_dialog.dart
│       └── auth_widget_placeholder.dart
├── resident/                          # Resident mobile app
│   ├── screens/
│   │   ├── auth/                      # Login, register, forgot password, email/phone verify, account created
│   │   ├── onboarding/               # First-launch onboarding carousel
│   │   ├── permissions/              # Photo/document permission grant
│   │   ├── location/                 # Geofence gate, community confirmation, outside boundary
│   │   ├── verification/             # Residency document upload + admin review status
│   │   ├── home/                     # Main shell + dashboard + community posts + marketplace + services
│   │   ├── marketplace/              # Item listing detail
│   │   ├── profile/                  # Own profile, edit, settings, reviews, public profile
│   │   ├── chat/                     # Chat list, thread (6-part split), new chat, message actions, report
│   │   ├── connections/              # Neighbor connections, requests
│   │   ├── notifications/            # In-app notification feed
│   │   └── camera/                   # Camera permission grant
│   ├── logic/                        # Resident-specific view models and helpers
│   │   ├── item_viewmodel.dart       # Marketplace item CRUD + state
│   │   ├── verification_viewmodel.dart # Verification document flow state
│   │   ├── marketplace_borrow_flow.dart # Borrow request screen orchestration
│   │   ├── chat_access.dart          # Chat feature access helpers
│   │   ├── notification_navigation.dart
│   │   ├── verification_access.dart
│   │   ├── resident_onboarding_prefs.dart
│   │   └── resident_surface_tokens.dart # Theme extension getters
│   └── providers/                    # 11 provider wrappers (ChangeNotifier/typedef)
│       ├── borrow_request_provider.dart
│       ├── chat_provider.dart
│       ├── connection_provider.dart
│       ├── item_provider.dart        # Typedef → ItemViewModel
│       ├── network_status_provider.dart
│       ├── notification_provider.dart
│       ├── report_provider.dart
│       ├── review_provider.dart
│       ├── service_provider.dart
│       ├── theme_provider.dart
│       └── verification_provider.dart # Typedef → VerificationViewModel
├── admin/                            # Admin web app
│   ├── screens/
│   │   ├── auth/admin_login_screen.dart
│   │   ├── admin_dashboard_screen.dart # Section-based dashboard shell
│   │   ├── dashboard/                # Overview stats + transactions
│   │   ├── verification/             # Residency document review
│   │   ├── users/                    # Resident management
│   │   ├── listings/                 # Item/service listing oversight
│   │   ├── news/                     # Community post management
│   │   ├── reports/                  # 5-part split: inbox, case widgets, evidence, tokens
│   │   └── settings/                 # Admin preferences
│   ├── services/admin_service.dart   # Admin-only Firestore queries + moderation actions
│   ├── providers/admin_provider.dart # Dashboard state, scoped collections, moderation
│   └── logic/widgets/                # 5 admin-specific widget files
│       ├── admin_layout_widgets.dart  # Scaffold, nav rail, app bar
│       ├── admin_listing_widgets.dart # Listing display cards
│       ├── admin_ocr_widgets.dart     # OCR review fields
│       ├── admin_status_widgets.dart  # Status badges, metadata
│       └── ocr_review_dialog.dart     # OCR edit dialog
└── features/                         # Feature modules (if any)
```

## Layer architecture

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Model** | `shared/models/` | Data classes with `fromJson`/`toJson`, Firestore mapping |
| **Repository** | `shared/data/repositories/` | Single-entity Firestore/Storage I/O |
| **Service** | `shared/services/` | Cross-entity orchestration, business workflows |
| **ViewModel / Provider** | `resident/logic/`, `resident/providers/`, `shared/logic/` | UI state management (ChangeNotifier) |
| **View** | `resident/screens/`, `admin/screens/` | Widget tree, no direct Firebase calls |

## Authentication flow

```
App start → AuthWrapper
  ├─ Not logged in → ResidentPreAuthGate
  │   ├─ First launch → OnboardingScreen → LoginView
  │   └─ Returning    → LoginView
  │       ├─ Login (email/Google/Apple) → AuthViewModel
  │       ├─ Register → AuthViewModel.register → AccountCreatedView
  │       └─ Forgot password → ForgotPasswordView
  └─ Logged in → Load profile
      ├─ Needs email verify → EmailVerificationView
      ├─ Needs phone verify → PhoneVerificationView
      ├─ Needs verification → AccountCreatedView
      └─ Verified
          ├─ role=resident → ResidentGeofenceGate → ResidentMainShell
          └─ role=admin    → AdminDashboardScreen
```

### AuthViewModel mixins

| Mixin | File | Responsibility |
|-------|------|----------------|
| Core | `auth_viewmodel_core.dart` | Base state, lifecycle, error handling |
| Sign-in | `auth_viewmodel_sign_in.dart` | Email/Google/Apple sign-in, password reset |
| Registration | `auth_viewmodel_registration.dart` | Resident registration + post-registration steps |
| Verification | `auth_viewmodel_verification.dart` | Phone link, email verify, phone credential |
| Profile | `auth_viewmodel_profile.dart` | Profile save/update, image upload |
| Community | `auth_viewmodel_community.dart` | Community change, location verification marking |

## Firestore collections

See `docs/ARCHITECTURE.md` for the complete list of 18+ collections and their purposes.

## Key workflows

### Marketplace borrow
1. Item listed in `items` collection by verified resident
2. Borrower creates `borrowRequest` (pending)
3. Owner approves → borrower completes `manual_v1` payment
4. Owner marks pickup-ready → borrower confirms handover (active)
5. Borrower submits return → owner confirms (completed)
6. Both parties submit blind reviews (published after 3-day grace)

### Residency verification
1. Resident uploads document → `verificationRequests` (submitted)
2. OCR Cloud Function extracts fields (name, address, expiry)
3. Admin reviews in dashboard → approve/reject
4. Cloud Functions syncs `verificationStatus` to `users`

### Connections (neighbor network)
1. Resident sends request via `connections` collection
2. Recipient accepts → status changes to `accepted`
3. Connections enable direct chat and marketplace transactions

## Borrow request state machine

```
pending → approved (owner approves)
       → rejected (owner rejects)
       → cancelled (borrower cancels)
approved → pickupReady (owner marks ready)
pickupReady → active (borrower confirms pickup)
active → returnSubmitted (borrower submits return)
returnSubmitted → completed (owner confirms)
               → minorIssuePending (damage reported)
               → disputed (major damage/lost)
minorIssuePending → completed (borrower accepts deduction)
                  → disputed (borrower disputes)
disputed → resolvedByAdmin (admin intervenes)
```

## Geofence / location

`GeofenceManager` (`lib/shared/services/geofence_manager.dart`) wraps platform geofencing APIs.
`ResidentGeofenceGate` (`lib/resident/screens/location/resident_geofence_gate.dart`) blocks app
access until the resident confirms their community location.

## Security notes

- UI checks are UX-only; Firestore Security Rules and Cloud Functions are the authority
- Reviews start `hidden` + `visible: false`; only `review_publish` CF makes them visible
- Trust/completion counters are CF-write only
- App Check enforces platform identity on release builds
- Storage paths: `item_images/`, `verification_documents/`, `borrow_request_proofs/`, `chat_attachments/`, `profile_images/`

## See also

- `docs/ARCHITECTURE.md` — Detailed architecture, borrow state machine, review flow, Cloud Functions
- `firestore_rules/` — Modular Firestore security rules
- `functions/` — Cloud Functions source
- `test/` — Unit, widget, and firestore rules tests
