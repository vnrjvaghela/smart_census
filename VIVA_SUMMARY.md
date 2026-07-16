# Smart Census Project - Viva Summary

## 1. Project Overview
**Smart Census** is a Flutter-based mobile application for census-style data collection and survey management. The app is designed with a focus on field survey operations, local persistence, offline-first capabilities, and optional cloud synchronization.

The main goal is to support enumerators and administrators in collecting household data, managing family member records, capturing document evidence, and syncing survey records with Firebase.

---

## 2. Technology Stack
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Firebase**:
  - `firebase_core` for initialization
  - `firebase_auth` for phone-based authentication
  - `cloud_firestore` for cloud survey storage
  - `firebase_storage` for document uploads
- **Hive**: Local lightweight database for offline storage
- **Provider**: State management for theme switching
- **Geolocator**: GPS location capture
- **Image Picker**: Camera/gallery document selection
- **Google Fonts**: Custom typography
- **Connectivity Plus**: Network status detection
- **Shared Preferences**: Storing user role and phone locally

---

## 3. App Architecture
### 3.1 `main.dart`
- Initializes Flutter bindings.
- Initializes Firebase using `firebase_options.dart`.
- Initializes `NotificationService()`.
- Initializes local database using `DatabaseService.init()`.
- Starts the app with `ChangeNotifierProvider` for theme management.
- Loads `SplashScreen` as the first page.

### 3.2 Theme Management
- `ThemeProvider` enables light/dark mode.
- The app defines both light and dark themes consistently across widgets.

### 3.3 Local Database Layer
- `DatabaseService` uses Hive to store:
  - `SurveyModel` records in `surveys` box
  - draft survey data in `draft_survey` box
- Handles save, update, delete, fetch, and clear operations.

---

## 4. User Flow
### 4.1 Splash Screen
- Animated splash screen with logo and loading dots.
- After a short delay, it routes the user based on stored role:
  - `admin` ➜ `AdminDashboardScreen`
  - `surveyor` ➜ `HomeScreen`
  - otherwise ➜ `LoginScreen`

### 4.2 Authentication
- `LoginScreen` supports phone OTP login.
- There are two roles:
  - **Surveyor**
  - **Admin**
- Test-mode credentials are hard-coded to support demo without Firebase SMS:
  - Surveyor: `9999999999`, OTP `123456`
  - Admin: `8888888888`, OTP `123456`
- After login, the app stores role and phone number in Shared Preferences.

### 4.3 Home Screen for Surveyors
- `HomeScreen` uses bottom navigation with 3 tabs:
  - `Dashboard`
  - `Surveys`
  - `Profile`
- The dashboard shows:
  - Total local surveys
  - Pending upload count
  - Active draft resume card
  - Cloud sync actions
  - Latest cloud survey summary
- Surveyors can start a new survey from a FAB.

### 4.4 Survey Screen
- `SurveyListScreen` lists saved surveys.
- Supports search by household ID/address.
- Supports filtering by status: `All`, `Pending`, `Uploaded`.
- Allows editing and deleting saved surveys.

---

## 5. Survey Workflow
### 5.1 Step 1 — Household Info
- `Step1Household` captures:
  - Auto-generated household ID
  - Full address
  - GPS location using Geolocator
- It saves a draft before moving to the next step.
- Duplicate household IDs are checked locally.

### 5.2 Step 2 — Family Members
- `Step2Members` lets the user enter multiple family members.
- Each member contains fields like:
  - Name
  - Age
  - Gender
  - Relation
  - Education
  - Occupation
  - Caste and sub-caste
- Members are saved as a list inside `SurveyModel`.

### 5.3 Step 3 — Document Submission
- `Step3Documents` allows capturing document photos from:
  - Camera
  - Gallery
- The app optionally performs AI verification of documents.
- It computes a SHA-256 hash to demonstrate a blockchain-style data fingerprint.
- Final survey data is saved locally in Hive and draft data is removed.

---

## 6. Data Model
### 6.1 `FamilyMember`
- Fields:
  - `id`
  - `name`
  - `age`
  - `gender`
  - `relation`
  - `education`
  - `occupation`
  - `caste`
  - `subCaste`
- Stored in Hive via `FamilyMemberAdapter`.

### 6.2 `SurveyModel`
- Fields:
  - `id`
  - `householdId`
  - `address`
  - `latitude`, `longitude`
  - `members`
  - `documentPaths`
  - `documentUrls`
  - `isSynced`
  - `status`
  - `timestamp`
  - `aiVerified`
  - `blockchainHash`
- Supports JSON serialization and deserialization.

---

## 7. Sync and Cloud Integration
### 7.1 Sync Service
- `SyncService` uploads unsynced surveys to Firestore.
- It also uploads images using a platform-specific service:
  - `sync_service_io.dart` on mobile/desktop
  - `sync_service_web.dart` on web
- After upload, local records are marked `isSynced = true`.
- Survey metadata is written to Firestore with extra fields:
  - `surveyorPhone`
  - `surveyorName`

### 7.2 Dashboard Cloud Fetch
- The dashboard fetches cloud records from Firestore.
- It computes cloud statistics like total families and total members.
- This provides a live snapshot of remote survey data.

---

## 8. Admin Features
- The admin flow includes an admin dashboard.
- Admin screens connect to Firestore collections like:
  - `surveys`
  - `enumerators`
- Admin functionality includes:
  - viewing survey analytics
  - fetching latest survey data from Firebase
  - adding enumerators and managing remote records
- This separates field surveyor usage from higher-level admin controls.

---

## 9. Additional Capabilities
- **Offline support**: Local Hive storage ensures surveys are retained without network access.
- **Draft resume**: unfinished survey drafts are kept separately and can be resumed.
- **GPS location capture**: necessary for field census accuracy.
- **Theming**: light/dark mode support with modern Material styling.
- **Notifications**: initialized at app startup for future push support.
- **AI verification and blockchain hash generation**: experimental features for document validation and tamper-proof record tracking.

---

## 10. Project Demonstration Points for Viva
### What to show
1. Launch the app from `main.dart`.
2. Explain the splash screen and role-based routing.
3. Show `LoginScreen` with phone role selection and test OTP mode.
4. Open `HomeScreen` and describe the dashboard counts and offline banner.
5. Create a new survey:
   - Household data
   - GPS capture
   - Add family members
   - Attach documents
   - Submit and save locally
6. Open `SurveyListScreen` to show saved records, search, filter, and delete.
7. Trigger cloud sync and explain how `SyncService` uploads data to Firebase.
8. Mention `AdminDashboardScreen` as the admin monitoring panel.

### Why this app is useful
- Supports enumerators with offline-first census data collection.
- Preserves local survey data before cloud sync.
- Helps manage both field and admin workflows in one application.
- Uses modern mobile UI patterns and local persistence.

---

## 11. Running the App
### Required setup
- Flutter SDK installed
- Android Studio/emulator or physical Android device
- Firebase project with:
  - Authentication enabled
  - Firestore database
  - Storage bucket
- `google-services.json` placed in `android/app`

### Commands
```bash
flutter pub get
flutter run
```

---

## 12. Notes on Current Status
- The app successfully builds and runs on Android emulator.
- Core features are implemented and can be demonstrated end-to-end.
- The project also includes useful debugging and QA documentation in `LAB12_QA_Summary.md`, `LAB12_TestCases.md`, and `LAB12_BugReport.md`.

---

## 13. Key Code Locations
- `lib/main.dart` — app startup and theme initialization
- `lib/services/database_service.dart` — local Hive storage
- `lib/services/sync_service.dart` — cloud sync logic
- `lib/screens/auth/login_screen.dart` — login and role selection
- `lib/screens/home/home_screen.dart` — main dashboard and navigation
- `lib/screens/survey/household_info_screen.dart` — step 1 data entry
- `lib/screens/survey/family_members_screen.dart` — step 2 family member management
- `lib/screens/survey/document_submission_screen.dart` — final document capture and submission
- `lib/models/survey_model.dart` — survey schema
- `lib/models/family_member_model.dart` — family member schema

---

## 14. Final Summary
Smart Census is a mobile-first field data collection system that balances offline data capture with cloud sync and administrative oversight. It is built to support real-world census workflows with GPS capture, structured household and member data, document evidence collection, local draft recovery, and optional Firebase-based synchronization.

This summary is ready to use during your viva to explain the project architecture, user flow, database design, and key features.
