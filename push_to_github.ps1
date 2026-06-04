# Push to GitHub Script for QuickBridge

Write-Host "Initializing Git Repository..." -ForegroundColor Green
& "C:\Program Files\Git\cmd\git.exe" init

Write-Host "Configuring local Git identity..." -ForegroundColor Green
& "C:\Program Files\Git\cmd\git.exe" config user.email "mysouss24-lab@github.com"
& "C:\Program Files\Git\cmd\git.exe" config user.name "mysoulss24-lab"

# Create standard .gitignore for Flutter
if (-not (Test-Path .gitignore)) {
    New-Item -ItemType File -Name .gitignore -Value @"
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/

# Android
.gradle/
local.properties
*.apk
*.ap_
*.aab

# Windows
build/
bin/
obj/

# Operating System
.DS_Store
Thumbs.db
"@
}

Write-Host "Staging files..." -ForegroundColor Green
& "C:\Program Files\Git\cmd\git.exe" add .

Write-Host "Creating initial commit..." -ForegroundColor Green
& "C:\Program Files\Git\cmd\git.exe" commit -m "Initial commit of QuickBridge file transfer system"

Write-Host "Setting main branch..." -ForegroundColor Green
& "C:\Program Files\Git\cmd\git.exe" branch -M main

Write-Host "Adding remote origin..." -ForegroundColor Green
# Remove remote if it already exists
try {
    & "C:\Program Files\Git\cmd\git.exe" remote remove origin
} catch {}

& "C:\Program Files\Git\cmd\git.exe" remote add origin https://github.com/mysoulss24-lab/quickbridge.git

Write-Host "Pushing to GitHub (A login popup might appear on your screen)..." -ForegroundColor Green
& "C:\Program Files\Git\cmd\git.exe" push -u origin main -f

Write-Host "Completed! Go to your GitHub page and check the Actions tab to monitor the build." -ForegroundColor Green
Read-Host "Press Enter to exit..."
