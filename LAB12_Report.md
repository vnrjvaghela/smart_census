# LAB 12: Testing & Debugging Report

## 1. Test Cases (Functional Testing)

| Test Case ID | Feature / Module | Test Scenario                  | Expected Result                                     | Actual Result   | Status |
| ------------ | ---------------- | ------------------------------ | --------------------------------------------------- | --------------- | ------ |
| TC01         | Authentication   | Login with valid credentials   | User is logged in and redirected to Dashboard       | As expected     | Pass   |
| TC02         | Authentication   | Login with invalid credentials | "Invalid credentials" error is shown                | As expected     | Pass   |
| TC03         | Survey           | Add new survey                 | Local draft is created and saved successfully       | As expected     | Pass   |
| TC04         | Syncing          | Tap sync while offline         | Show "Offline" banner and prevent sync              | As expected     | Pass   |
| TC05         | OCR (Lab 11)     | Pick image for OCR text        | Texts are successfully extracted and displayed      | As expected     | Pass   |
| TC06         | API (Lab 9)      | Load Posts API                 | List of JSON posts is parsed and shown dynamically  | As expected     | Pass   |
| TC07         | API (Lab 9)      | Refresh on API failure         | Error UI is displayed with a functioning Retry btn  | As expected     | Pass   |
| TC08         | Notifications    | Fire Local Notification        | Immediate notification appears on the device drawer | As expected     | Pass   |
| TC09         | Survey Draft     | Resume drafted survey          | Form is pre-filled with unsaved draft data          | As expected     | Pass   |
| TC10         | Profile          | Logout user                    | User session ends and redirects to splash/login    | As expected     | Pass   |

## 2. Bug Report

| Bug ID | Issue Description                                      | Module         | Priority | Fix Implemented                                               |
| ------ | ------------------------------------------------------ | -------------- | -------- | ------------------------------------------------------------- |
| B01    | Crash on empty numeric input during survey creation    | Survey Form    | High     | Added input text validation to default to 0 if empty          |
| B02    | API list throws exception when no internet connected   | API Intercept  | Medium   | Added Connectivity checking and Exception UI fallback         |
| B03    | OCR Image Upload fails without camera permissions      | AI/OCR         | High     | Used permission_handler to gracefully request system perm     |
| B04    | Notifications not appearing after app restart          | Notifications  | Low      | Adjusted AndroidManifest permissions and setup delayed queues |
| B05    | Dark mode colors unreadable on API list cards          | Design / Theme | Medium   | Specified conditional `isDark` color variants for the Cards   |

## 3. Screenshots Checklist
> _Please attach the Before/After screenshots in this section before submitting your Lab._

- [ ] B01 - Empty input crash (Before)
- [ ] B01 - Form successfully alerting user (After)
- [ ] B02 - Red error widget loaded for API (Before)
- [ ] B02 - Correct list load upon retry (After)
- [ ] OCR Screen demonstration
- [ ] Actionable Notification drawer captured
