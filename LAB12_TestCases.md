# LAB 12 - Testing, Debugging & Quality Assurance
## Smart Census Mobile Application - Test Case Document

**Application:** Smart Census  
**Version:** 1.0  
**Testing Date:** April 7, 2026  
**Tester:** Student  

---

## TEST CASE DOCUMENT (8-10 Test Cases)

### TC01: User Authentication - Valid Login
| Field | Value |
|-------|-------|
| **Test Case ID** | TC01 |
| **Scenario** | Valid user authentication |
| **Steps** | 1. Launch app → 2. Enter valid email → 3. Enter valid password → 4. Click Login |
| **Expected Result** | User logged in successfully and navigated to Dashboard |
| **Actual Result** | ✓ Login successful, Dashboard displayed |
| **Status** | **PASS** |
| **Severity** | High |

### TC02: User Authentication - Invalid Password
| Field | Value |
|-------|-------|
| **Test Case ID** | TC02 |
| **Scenario** | Invalid password validation |
| **Steps** | 1. Launch app → 2. Enter valid email → 3. Enter wrong password → 4. Click Login |
| **Expected Result** | Error message displayed: "Invalid credentials" |
| **Actual Result** | ✓ Error message shown, user remains on login screen |
| **Status** | **PASS** |
| **Severity** | High |

### TC03: CRUD - Add New Survey
| Field | Value |
|-------|-------|
| **Test Case ID** | TC03 |
| **Scenario** | Add a new survey record |
| **Steps** | 1. Login → 2. Navigate to Surveys tab → 3. Click Add button → 4. Fill household info → 5. Click Next → 6. Add family members → 7. Upload documents → 8. Click Save |
| **Expected Result** | Survey saved to database and listed on Surveys screen |
| **Actual Result** | ✓ Survey created with all data, appears in list |
| **Status** | **PASS** |
| **Severity** | High |

### TC04: CRUD - Edit Existing Survey
| Field | Value |
|-------|-------|
| **Test Case ID** | TC04 |
| **Scenario** | Edit an existing survey record |
| **Steps** | 1. Login → 2. Navigate to Surveys → 3. Click Edit on survey card → 4. Modify household address → 5. Click Save |
| **Expected Result** | Survey updated with new data, changes reflected in list |
| **Actual Result** | ✓ Survey edited successfully, updated data persisted |
| **Status** | **PASS** |
| **Severity** | High |

### TC05: CRUD - Delete Survey with Confirmation
| Field | Value |
|-------|-------|
| **Test Case ID** | TC05 |
| **Scenario** | Delete survey with confirmation dialog |
| **Steps** | 1. Login → 2. Navigate to Surveys → 3. Click Delete on survey card → 4. View confirmation dialog → 5. Click Confirm Delete |
| **Expected Result** | Survey deleted, confirmation dialog shown, survey removed from list |
| **Actual Result** | ✓ Delete dialog appears, survey removed after confirmation |
| **Status** | **PASS** |
| **Severity** | High |

### TC06: Navigation - Tab Switching
| Field | Value |
|-------|-------|
| **Test Case ID** | TC06 |
| **Scenario** | Navigate between app tabs |
| **Steps** | 1. Login → 2. Click Dashboard tab → 3. Click Surveys tab → 4. Click Profile tab → 5. Verify each screen loads |
| **Expected Result** | All tabs accessible, content loads correctly on each screen |
| **Actual Result** | ✓ All tabs functional, navigation smooth |
| **Status** | **PASS** |
| **Severity** | Medium |

### TC07: Navigation - Drawer Menu
| Field | Value |
|-------|-------|
| **Test Case ID** | TC07 |
| **Scenario** | Access drawer menu and navigate |
| **Steps** | 1. Login → 2. Click hamburger menu → 3. Click "Lab Features" → 4. Verify navigation |
| **Expected Result** | Drawer opens, menu items clickable, navigation works |
| **Actual Result** | ✓ Drawer functions correctly, menu navigation works |
| **Status** | **PASS** |
| **Severity** | Medium |

### TC08: UI/UX - Splash Screen Display
| Field | Value |
|-------|-------|
| **Test Case ID** | TC08 |
| **Scenario** | Splash screen with logo and animations |
| **Steps** | 1. Launch app → 2. Observe splash screen for 2.6 seconds |
| **Expected Result** | Splash shows blue gradient logo with animated dots, transitions to login smoothly |
| **Actual Result** | ✓ Logo displays correctly, animations smooth, transition works |
| **Status** | **PASS** |
| **Severity** | Medium |

### TC09: UI/UX - Form Validation
| Field | Value |
|-------|-------|
| **Test Case ID** | TC09 |
| **Scenario** | Form field validation on add survey |
| **Steps** | 1. Login → 2. Go to Surveys → 3. Click Add → 4. Leave required fields empty → 5. Try to submit |
| **Expected Result** | Validation error shown, form prevents submission of empty fields |
| **Actual Result** | ✓ Validation works, empty fields blocked |
| **Status** | **PASS** |
| **Severity** | High |

### TC10: Session Management - State Persistence
| Field | Value |
|-------|-------|
| **Test Case ID** | TC10 |
| **Scenario** | Session data persists and loads correctly |
| **Steps** | 1. Login → 2. Add survey (partial) → 3. Navigate away → 4. Return to survey tab → 5. Check if data still visible |
| **Expected Result** | Survey data persisted in local storage, accessible after navigation |
| **Actual Result** | ✓ Data persists correctly using Hive database |
| **Status** | **PASS** |
| **Severity** | High |

---

## TEST SUMMARY
- **Total Test Cases:** 10
- **Passed:** 10 ✓
- **Failed:** 0
- **Pass Rate:** 100%

---
