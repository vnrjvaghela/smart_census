# Smart Census App

## Prerequisites
Before running the app, ensure you have the following installed:
1.  **Flutter SDK**: [Download here](https://docs.flutter.dev/get-started/install)
2.  **VS Code** with **Flutter** and **Dart** extensions.
3.  **Android Studio** (for Android Emulator) or an Android device with USB debugging enabled.

## Setup Instructions

### 1. Open the Project
Open the `smart_census` folder in VS Code.

### 2. Install Dependencies
Open the terminal in VS Code (Ctrl+`) and run:
```bash
flutter pub get
```

### 3. Firebase Setup (Crucial)
This app uses Firebase for Authentication and Storage. You must:
1.  Go to [Firebase Console](https://console.firebase.google.com/).
2.  Create a new project named "Smart Census".
3.  Add an Android App with package name `com.example.smart_census`.
4.  Download the `google-services.json` file.
5.  Place the file in: `smart_census/android/app/google-services.json`.
6.  Enable **Authentication** (Phone provider) in Firebase Console.
7.  Enable **Firestore Database** and **Storage**.

### 4. Run the App
Connect your device or start an emulator, then run:
```bash
flutter run
```

## Troubleshooting
- **"flutter command not found"**: Add the Flutter `bin` folder to your System PATH environment variable.
- **Hive Errors**: If you see errors about generated files, run:
  ```bash
  dart run build_runner build
  ```
