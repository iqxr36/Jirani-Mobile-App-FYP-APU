# Jirani

Community trust marketplace for verified residents — borrow items, offer services, connect with neighbors, and build reputation within a gated community.

Built with **Flutter** (resident mobile app + admin web dashboard) and **Firebase** (Auth, Firestore, Storage, Cloud Functions, App Check, FCM).

## Roles

| Role | Platform | Entry |
|------|----------|-------|
| Resident | Android / iOS | `AuthWrapper` → onboarding → `ResidentMainShell` |
| Community / system admin | Web | `AuthWrapper` → `AdminLoginScreen` → `AdminDashboardScreen` |

Residents must pass **residency verification** (document upload + admin review) before listing marketplace items.

## Project layout

```
lib/
  resident/          Resident UI, providers, and view models
  admin/             Admin web dashboard and services
  shared/
    data/repositories/   Firestore/Storage access (SSOT for entities)
    services/            Orchestration (borrow lifecycle, chat, reviews, OCR)
    logic/               AuthViewModel, AuthWrapper routing
  core/              Constants, theme, validators
firestore_rules/     Modular Firestore rules source (build → firestore.rules)
functions/src/       Cloud Functions (trust score, review publish, notifications)
test/                Dart unit/widget tests
test/firestore/      Firestore + Storage rules tests (emulator)
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for collections, borrow/review flows, and the security model.

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (SDK ^3.11).
2. Clone the repo and run `flutter pub get`.
3. Configure Firebase: `firebase_options.dart` is generated via FlutterFire CLI.
4. For local rules work:
   ```bash
   npm run build:firestore-rules
   ```

## Running

```bash
flutter run              # resident app (device/emulator)
flutter run -d chrome    # admin web dashboard
```

## Testing

**Dart tests** (validators, borrow flow, services, view models):

```bash
flutter test
```

**Firestore rules** (requires JDK 21+):

```bash
cd test/firestore
npm install
npm test
```

Rules tests cover chat, trust score, user privacy, items, services, reviews, borrow completion, verification storage, and notifications.

## Deploy (Firebase)

```powershell
cd functions; npm install; npm run build; cd ..
npm run build:firestore-rules
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

Phone profile updates need these callables (included in a full functions deploy):

```powershell
firebase deploy --only functions:updateResidentPhoneNumber,functions:checkResidentPhoneAvailability,functions:adminUpdateResidentPhoneNumber,functions:backfillResidentPhoneRegistry
```

Community post expiry (notification deep links) needs the lifecycle function plus updated rules:

```powershell
firebase deploy --only functions:reconcileCommunityPostLifecycle,firestore:rules
```

App Check uses debug providers in `kDebugMode` and Play Integrity / Device Check in release builds.

## Phone number (contact only)

Residents enter a phone number at registration and can change it in Edit Profile. Uniqueness is enforced by the `updateResidentPhoneNumber` Cloud Function and the `residentPhoneNumbers` registry. **SMS / OTP phone verification was removed** — there is no Verify phone screen and Firebase Phone Auth is not used.

To change phone: Edit Profile → save. Ensure `updateResidentPhoneNumber` is deployed.

## Security highlights

- **Trust scores and reputation** — server-written only (Cloud Functions + locked Firestore rules).
- **User privacy** — neighbor-facing reads use `publicProfiles`; private fields stay in `users`.
- **Blind reviews** — submitted hidden; published by Cloud Function after grace period or dual submission.
- **Borrow lifecycle** — status transitions validated in rules; client services mirror allowed paths.

## License

FYP academic project — not licensed for public distribution unless stated otherwise by the authors.
