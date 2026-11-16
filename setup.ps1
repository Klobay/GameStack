# One-time setup (Windows): generates android/, adds the OAuth deep link, installs packages.
Set-Location $PSScriptRoot
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "Flutter was not found. Install it from https://docs.flutter.dev/get-started/install and add flutter\bin to PATH, then reopen this window." -ForegroundColor Red
  Read-Host "Press Enter to close"; exit 1
}
Write-Host "Generating Android project..." -ForegroundColor Cyan
flutter create . --platforms=android --org com.gamestack --project-name gamestack
$f = "android/app/src/main/AndroidManifest.xml"
if (-not (Test-Path $f)) { Write-Host "android/ was not created. Check the errors above." -ForegroundColor Red; Read-Host "Press Enter to close"; exit 1 }
Copy-Item -Recurse -Force "branding\res\*" "android\app\src\main\res\"
$x = Get-Content $f -Raw
if ($x -notmatch 'auth-callback') {
  $filter = '<intent-filter><action android:name="android.intent.action.VIEW"/><category android:name="android.intent.category.DEFAULT"/><category android:name="android.intent.category.BROWSABLE"/><data android:scheme="gamestack" android:host="auth-callback"/></intent-filter></activity>'
  $x = ([regex]'</activity>').Replace($x, $filter, 1)
  if ($x -notmatch 'android.permission.INTERNET') { $x = $x.Replace('<application', '<uses-permission android:name="android.permission.INTERNET"/><application') }
  $x = $x -replace 'android:label="[^"]*"', 'android:label="Game Stack"'
  Set-Content $f $x
  Write-Host "Deep link added." -ForegroundColor Green
}
flutter pub get
flutter pub upgrade supabase_flutter
Write-Host "Done. Now connect a phone/emulator and run: flutter run" -ForegroundColor Green
Read-Host "Press Enter to close"
