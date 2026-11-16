GameStack launcher icon pack
============================

This pack fixes the launcher icon being cropped/zoomed on Android launchers.

Contents:
- android/app/src/main/res/ : ready-to-copy Android launcher resources
- branding/res/             : matching backup/branding resources
- GameStack_app_icon_fixed_1024.png : 1024x1024 master app icon
- GameStack_logo_transparent.png    : transparent logo artwork

How to install:
1. Close your IDE/build process.
2. In your Flutter project, open android/app/src/main/.
3. Replace its existing res/mipmap-* folders and res/mipmap-anydpi-v26 folder
   with the matching folders from android/app/src/main/res/ in this pack.
4. Optionally replace your project's branding/res folders with branding/res
   from this pack so the backup copy stays in sync.
5. From the Flutter project root, run:
     flutter clean
     flutter pub get
     flutter build apk --release
6. Uninstall the old app from your phone before installing the new APK, so
   Android refreshes the launcher icon cache.

The adaptive-icon foreground has deliberate transparent padding so the
Android launcher mask does not cut off the stacked-diamond mark. The legacy
density icons are also centered with comfortable margins.

Do not copy these folders into Flutter's lib/ or assets/ directory.
