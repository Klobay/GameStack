# GAME STACK

Monochrome native Android game tracker: Kotlin • Jetpack Compose • RAWG • Supabase.

## What's included

- Email registration and login, Google OAuth with PKCE/deep-link callback, password recovery email
- Supabase cloud sync, private per-user collections with RLS
- RAWG discovery with game artwork, descriptions, release dates and genres
- Played / Currently playing / Want to play; All / Horror / Other categories
- Add/edit/remove games, optional personal rating, nickname and profile photo
- Smooth Compose screen transitions; black-and-white Material 3 UI
- Secure Android Keystore encryption for saved authentication tokens
- RAWG discovery called directly from the app

## Open in Android Studio

1. Extract `GameStack.zip`.
2. Open **Android Studio > Open > GameStack** (the folder containing `settings.gradle.kts`).
3. Install Android SDK **36** if Android Studio requests it. Use **JDK 17** or Android Studio's bundled JDK.
4. Wait for Gradle sync, then run the `app` configuration on a device/emulator with internet.

The package/application ID is `com.gamestack.app`. Supabase project URL and the **publishable** client key supplied in the conversation are already set in `app/build.gradle.kts`. Publishable keys are not privileged database credentials. The database is protected by RLS.

## Required Supabase steps (once)

### 1. Run the SQL

Dashboard -> **SQL Editor** -> run `supabase/migrations/001_game_stack.sql` (safe to re-run).

### 2. Google login

Dashboard -> **Authentication > Sign In / Providers > Google**: enable it and fill in both **Client ID** and **Client Secret** from a Google Cloud *Web application* OAuth client. The error `missing OAuth secret` means the secret field is empty.

In Google Cloud Console, add the callback shown in the Supabase Google panel (`https://tgiibweurmqxviapgfzx.supabase.co/auth/v1/callback`) to **Authorized redirect URIs**.

Dashboard -> **Authentication > URL Configuration > Redirect URLs** -> add exactly `gamestack://auth-callback`.

### 3. Game search

Search calls RAWG directly using `RAWG_API_KEY` in `app/build.gradle.kts`. No Edge Function is needed.

## Database privacy and security

`public.user_games` and `public.profiles` are protected by Row Level Security. `storage.objects` accepts writes only to the signed-in user's own `avatars/<user_id>/` path; the profile photo bucket is publicly readable so it can display in your profile. Tokens are encrypted using the Android Keystore. The app disables automatic backup. Never embed a Supabase secret/service-role key or the RAWG secret in the APK.

## Development status

This is a full **source project**, not a compiled APK. This environment does not have an Android SDK installation, so it could not run a device build or emulator test. Perform a Gradle sync and device run on your machine. Android Studio may need to download dependencies on first open. Report build errors with the exact error text.

## Source and APIs

- [Supabase Kotlin-independent Auth REST endpoints](https://supabase.com/docs/reference/self-hosting-auth/introduction)
- [Supabase OAuth PKCE flow](https://supabase.com/docs/guides/auth/sessions/pkce-flow)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [RAWG](https://rawg.io/apidocs) — game data and imagery

The app has no payment flow or data sharing beyond its described third-party services.

### Gradle bootstrap note

Because the official Gradle wrapper JAR could not be downloaded in the generation environment, this ZIP includes a **small custom Java Gradle bootstrapper** rather than the official wrapper JAR. It downloads Gradle 8.13 from `services.gradle.org` and checks its official SHA-256 digest (`20f1b1176237254a6fc204d8434196fa11a4cfb387567519c61556e8710aed78`) before running it. The bootstrapper source is included at `tools/GradleWrapperMain.java`; for production or shared repositories, replace it with the official Gradle wrapper using Android Studio or `gradle wrapper --gradle-version 8.13`.
