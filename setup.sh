#!/usr/bin/env bash
set -e
flutter create . --platforms=android --org com.gamestack --project-name gamestack
cp -R branding/res/. android/app/src/main/res/
f=android/app/src/main/AndroidManifest.xml
if ! grep -q auth-callback "$f"; then
  python3 - "$f" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
flt='<intent-filter><action android:name="android.intent.action.VIEW"/><category android:name="android.intent.category.DEFAULT"/><category android:name="android.intent.category.BROWSABLE"/><data android:scheme="gamestack" android:host="auth-callback"/></intent-filter></activity>'
s=s.replace('</activity>',flt,1)
if 'permission.INTERNET' not in s: s=s.replace('<application','<uses-permission android:name="android.permission.INTERNET"/><application',1)
import re
s=re.sub(r'android:label="[^"]*"','android:label="Game Stack"',s,1)
open(p,'w').write(s)
PY
fi
flutter pub get
echo "Done. Run: flutter run --dart-define-from-file=env.json"
