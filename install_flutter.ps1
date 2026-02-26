# Flutter Installation Script for Windows
# Run this script using PowerShell as Administrator

$FLUTTER_URL = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.0-stable.zip"
$INSTALL_DIR = "C:\src"
$FLUTTER_DIR = "$INSTALL_DIR\flutter"
$ZIP_PATH = "$env:TEMP\flutter.zip"

Write-Host "Starting Flutter Installation..." -ForegroundColor Green

# 1. Create Installation Directory
if (-not (Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
    Write-Host "Created directory: $INSTALL_DIR"
}

# 2. Download Flutter SDK
if (-not (Test-Path $FLUTTER_DIR)) {
    Write-Host "Downloading Flutter SDK... This may take a few minutes." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $FLUTTER_URL -OutFile $ZIP_PATH
    
    Write-Host "Extracting Flutter SDK to $INSTALL_DIR..." -ForegroundColor Cyan
    Expand-Archive -Path $ZIP_PATH -DestinationPath $INSTALL_DIR -Force
    
    Remove-Item $ZIP_PATH -Force
    Write-Host "Download and Extraction Complete." -ForegroundColor Green
} else {
    Write-Host "Flutter seems to be already installed at $FLUTTER_DIR" -ForegroundColor Yellow
}

# 3. Add to PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$FLUTTER_DIR\bin*") {
    Write-Host "Adding Flutter to User PATH environment variable..." -ForegroundColor Cyan
    $newPath = "$currentPath;$FLUTTER_DIR\bin"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Added to PATH. You may need to restart your terminal or computer." -ForegroundColor Green
} else {
    Write-Host "Flutter is already in your PATH." -ForegroundColor Green
}

# 4. Run Flutter Doctor
Write-Host "Running flutter doctor..." -ForegroundColor Cyan
& "$FLUTTER_DIR\bin\flutter.exe" doctor

Write-Host "Installation Script Finished." -ForegroundColor Green
Write-Host "Please restart your terminal (VS Code) to use the 'flutter' command." -ForegroundColor Yellow
