# Smart Census — Feature Log

> This file tracks every feature added to the project, phase by phase.  
> Updated automatically as features are implemented.

---

## Phase 1: Core Functionality

| # | Feature | Status | File(s) Changed |
|---|---------|--------|-----------------|
| 1.1 | **Blockchain Hash** — SHA-256 hash of survey JSON generated on submission | ✅ Done | `crypto_utils.dart`, `step3_documents.dart`, `survey_detail_screen.dart` |
| 1.2 | **AI Document Verification** — MLKit OCR called per-image on doc upload, live badge overlay on each thumbnail | ✅ Done | `ai_verification_service.dart`, `step3_documents.dart` |
| 1.3 | **Offline Sync Indicator** — Animated red banner + auto-syncs on reconnect via `connectivity_plus` | ✅ Done | `home_screen.dart` |
| 1.4 | **Duplicate Household Detection** — AlertDialog warning if householdId already exists in Hive | ✅ Done | `step1_household.dart`, `database_service.dart` |
| 1.5 | **Auto-Save Draft** — Prevents data loss by auto-persisting survey state to Hive on app restarts | ✅ Done | `database_service.dart`, `home_screen.dart`, `step1_household.dart`, `step2_members.dart` |

---

## Phase 2: Admin / Supervisor Portal

| # | Feature | Status | File(s) Changed |
|---|---------|--------|-----------------|
| 2.1 | **Admin Screen** — Role-gated admin tab to view all Firestore surveys | ⏳ Pending | `admin_screen.dart` [NEW] |
| 2.2 | **Approve / Reject Workflow** — Supervisor can change survey status in Firestore | ⏳ Pending | `admin_screen.dart`, `sync_service.dart` |
| 2.3 | **Status Workflow UI** — Visual status stepper: Draft → Pending → Verified / Rejected | ⏳ Pending | `survey_detail_screen.dart` |
| 2.4 | **Admin Filters** — Filter by area, status, date in admin view | ⏳ Pending | `admin_screen.dart` |

---

## Phase 3: Analytics & Reporting

| # | Feature | Status | File(s) Changed |
|---|---------|--------|-----------------|
| 3.1 | **Dashboard Charts** — Pie/bar charts of synced vs pending, surveys per day | ⏳ Pending | `home_screen.dart`, `pubspec.yaml` |
| 3.2 | **Export CSV/JSON** — Export all local surveys to a downloadable file | ⏳ Pending | `survey_list_screen.dart`, `database_service.dart` |
| 3.3 | **AI Verified Badge** — Show ✅ / ❌ badge on survey cards and detail screen | ⏳ Pending | `survey_list_screen.dart`, `survey_detail_screen.dart` |

---

## Phase 4: Polish & UX

| # | Feature | Status | File(s) Changed |
|---|---------|--------|-----------------|
| 4.1 | **Error Handling** — Replace all `print()` errors with SnackBar/Dialog feedback | ⏳ Pending | Multiple files |
| 4.2 | **Shimmer Loading** — Skeleton loaders while data fetches | ⏳ Pending | `home_screen.dart`, `survey_list_screen.dart` |
| 4.3 | **Connectivity Banner** — Offline mode notice shown at top of screens | ⏳ Pending | `home_screen.dart`, `survey_list_screen.dart` |
| 4.4 | **Form Validation** — Inline field-level error messages in all form steps | ⏳ Pending | `step1_household.dart`, `step2_members.dart` |

---

## Legend
- ✅ Done
- 🔄 In Progress
- ⏳ Pending
- ❌ Skipped / Deferred
