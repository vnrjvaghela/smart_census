@echo off
echo [1/2] Launching Android Emulator...
start /b flutter emulators --launch Medium_Phone_API_36.1

echo [2/2] Waiting for device and starting Smart Census...
flutter run -d emulator-5554
pause
