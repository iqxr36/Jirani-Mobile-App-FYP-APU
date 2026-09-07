<div align="center">

<img src="assets/In-app%20Jirani%20no%20background.png" alt="Jirani logo" width="220" />

# 🏡 Jirani — Community Trust Marketplace

**Borrow items. Share skills. Connect with neighbours.**

A Flutter and Firebase application for verified residents to share resources, discover local services, and build community trust.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11.4%2B-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Backend-DD2C00?logo=firebase&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-Cloud_Functions-3178C6?logo=typescript&logoColor=white)
![Project](https://img.shields.io/badge/Project-Final_Year-6750A4)

[Overview](#-overview) · [Features](#-key-features) · [Architecture](#-architecture)

</div>

---

## 🌍 Overview

Jirani is a **community trust marketplace for gated communities**, developed as a final-year academic project. It helps residents find items to borrow, offer services, communicate with neighbours, and build a reputation through their interactions.

The project combines a **resident mobile application** with a **web dashboard for community and system administrators**. Both experiences share a Firebase backend for authentication, community data, document storage, notifications, and transaction workflows.

### Why Jirani?

Sharing within a neighbourhood involves more than finding an available item. Residents need to know who they are interacting with, agree on a request, track its progress, and resolve issues when something goes wrong.

Jirani addresses these needs through:

- **Community access:** residency verification and location-based access checks.
- **Structured transactions:** borrowing and service request workflows with progress tracking.
- **Trust and accountability:** resident profiles, reviews, and server-managed reputation.
- **Connected communication:** neighbour connections, chat, community posts, and notifications.
- **Administrative oversight:** verification review, listing management, reports, and transaction monitoring.

## ✨ Key Features

### 📱 For Residents

| Area | Features |
| --- | --- |
| **Account and onboarding** | Email/password and Google sign-in flows, email verification, profile setup, and community selection. |
| **Residency verification** | Upload supporting documents, track verification status, and complete location permission and geofence checks. |
| **Item marketplace** | Browse listings, view item details, publish items, and send borrowing requests. |
| **Borrowing lifecycle** | Manage approvals, handover and return progress, completion, deposits, and disputes. |
| **Community services** | Offer services, browse providers, submit requests, and track service transactions. |
| **Payments** | Payment workflows for marketplace and service transactions, with backend handling for refunds and payouts. |
| **Neighbour connections** | Send and manage connection requests and explore public resident profiles. |
| **Messaging** | Chat with neighbours and share attachments within conversations. |
| **Reviews and reputation** | Submit transaction reviews and view resident reputation information. |
| **Community updates** | Read community posts and receive in-app and push notifications. |
| **Personalisation and support** | Light and dark themes, notification preferences, privacy settings, and community support information. |

### 🖥️ For Administrators

- **Dashboard:** view community statistics and transaction activity.
- **Resident management:** inspect resident accounts and manage account status.
- **Verification review:** review residency submissions and document extraction results.
- **Listing management:** oversee marketplace items and service listings.
- **Reports and disputes:** inspect reported content, supporting evidence, and transaction issues.
- **Payments and transactions:** monitor payment-related records and transaction progress.
- **Community news:** manage posts and announcements.
- **Settings:** manage administrative and community configuration, including support contacts.

Administrative access is separated into community and system administrator roles.

## 🔄 How It Works

1. **Join a community:** register, complete the resident profile, and follow the location and residency verification flow.
2. **Discover or contribute:** browse marketplace items and services, or create a listing.
3. **Make a request:** arrange a borrowing or service transaction and communicate through chat.
4. **Track progress:** follow the applicable approval, payment, fulfilment, and completion stages.
5. **Build trust:** leave a review after the transaction and build a community reputation.

## 🛡️ Trust and Verification

Trust-related behaviour is implemented across the app, Firebase rules, and Cloud Functions:

- **Document processing:** Google Cloud Document AI and Gemini support extraction and evaluation of residency documents, alongside an admin review workflow.
- **Server-managed reputation:** trust scores are written by the backend and protected by Firestore rules.
- **Public/private profile separation:** neighbour-facing profile data is stored separately from private user records.
- **Blind reviews:** reviews remain hidden until backend publication conditions are met, such as both parties submitting or the grace period ending.
- **Transaction rules:** borrowing and service workflows use explicit statuses and access checks.
- **App Check:** mobile builds configure debug providers during development and Play Integrity / Device Check for release builds.

Phone numbers are contact details with backend uniqueness checks. The app does not use SMS/OTP phone verification.

## 🧰 Technology Stack

| Layer | Technologies |
| --- | --- |
| Resident application | Flutter and Dart |
| Administrator dashboard | Flutter Web |
| State management | Provider, ChangeNotifier, and view models |
| Authentication | Firebase Authentication and Google Sign-In |
| Database and files | Cloud Firestore and Firebase Storage |
| Backend workflows | Cloud Functions written in TypeScript |
| Notifications | Firebase Cloud Messaging and local notifications |
| App attestation | Firebase App Check |
| Document processing | Google Cloud Document AI and Gemini |
| Payment integration | Xendit through backend functions |
| Location | Geolocator and native geofencing |
| Charts | fl_chart |
| Testing | Flutter tests, Node.js tests, and Firebase Emulator Suite |

## 🏗️ Architecture

Jirani separates resident and administrator interfaces while sharing models, repositories, and services. UI state is managed through providers and view models; repositories handle data access, and services coordinate application workflows. Cloud Functions handle backend operations such as reputation updates, review publication, notifications, and payment processing.

```text
lib/
├── resident/              Resident screens, providers, and view models
├── admin/                 Admin screens, providers, and services
├── shared/
│   ├── data/repositories/ Shared data access
│   ├── logic/             Authentication and session routing
│   ├── models/            Shared domain models
│   ├── services/          Application workflows and integrations
│   └── widgets/           Shared UI components
├── core/                  Theme, constants, and utilities
└── main.dart              Application bootstrap

functions/src/             TypeScript backend and OCR pipeline
firestore_rules/           Modular Firestore security rule sources
firestore.rules            Generated Firestore rules
storage.rules              Firebase Storage rules
test/                      Dart unit and widget tests
test/firestore/            Firestore and Storage rules tests
functions/test/            Backend tests
assets/                    Branding and application images
```

The web entry routes to the administrator portal. Mobile sessions route through resident onboarding and access checks to the resident app.

## 🧪 Testing

The repository includes tests for application logic and widgets, backend behaviour, and access rules covering areas such as verification uploads, user privacy, chat, listings, service requests, reviews, and trust scores. Rules tests use the Firebase Emulator Suite.

## 🎓 Project Status and Credits

Jirani is a final-year academic project. This private repository presents the application and backend implementation for authorised review.

**Developer:** Faisal Mohammed Ezzaddin Saif Ahmed, as credited in the source files.

## 🔒 Access and Usage

Access is limited to authorised reviewers. The source code is provided for review only. Running the application, using its connected APIs or billed services, copying, modifying, or redistributing the project requires the author's explicit permission.
