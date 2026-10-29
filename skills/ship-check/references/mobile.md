# Mobile checks (iOS, Android, React Native, Expo, Flutter)

Store rules change every year. Check the current Apple App Review Guidelines and Google Play policy pages before calling something a store Blocker.

## Performance

- Cold start: first useful screen in ≤ ~2 s on a mid-range device. Android vitals flag cold starts ≥ 5 s as slow.
- No heavy work on the main or JS thread during startup or scrolling. Splash screen hides only when content is ready.
- Long lists are virtualized (`FlatList`, `FlashList`, `ListView.builder`, `LazyColumn`, `List`).
- Images are sized for the screen and cached. No full-resolution photos in thumbnails.
- No leaks: listeners, timers, and subscriptions are cleaned up when screens unmount.
- App size: check the release build size. Large assets are downloaded on demand. Android uses App Bundles.
- Network: responses are cached where safe; the app does not refetch everything on every foreground.

## Security

- **No secrets in the app.** The binary and JS bundle are public. `EXPO_PUBLIC_` and similar values are public. Third-party secret keys belong on the server.
- Tokens and sensitive data are stored in Keychain or Keystore (`expo-secure-store`, `flutter_secure_storage`), not in `AsyncStorage`, `SharedPreferences`, or `UserDefaults`.
- TLS only: iOS App Transport Security has no broad exceptions; Android `usesCleartextTraffic` is false or limited by a network security config.
- Release build is a real release: debuggable off, dev menu off, no debug logging, Android code shrinking (R8) on.
- Deep links and universal links validate their parameters and do not skip auth.
- Permissions: only what the app uses, requested in context, with clear purpose strings (`NS*UsageDescription`).
- Sensitive screens are hidden from the app switcher snapshot where needed (banking, health).

## Best practices (release)

- Version and build number increased. Signing keys and certificates are backed up and not in the repo.
- Crash reporting in release builds (Crashlytics, Sentry) with source maps or dSYMs uploaded.
- **Old app versions stay in the wild.** The backend stays compatible with them, and there is a forced-update path for breaking changes.
- OTA updates (Expo Updates, CodePush): runtime version or channel is set so a JS update never lands on an incompatible native build.
- Store requirements (usually Needs confirmation):
  - Privacy policy URL. App Store privacy labels and Google Play Data safety form match what the app really collects, including SDKs.
  - In-app account deletion if the app lets users create an account.
  - Target API level meets Google Play's current requirement. iOS build uses an Xcode and SDK version Apple still accepts.
  - Sign in with Apple offered if other third-party logins are offered and the guidelines require it.
  - Screenshots, description, age rating, and review test account are ready.
- Staged or phased rollout planned, with someone watching crash rate.

## UX

- Tap targets ≥ 44×44 pt on iOS and ≥ 48×48 dp on Android.
- Layout respects safe areas, notches, and the home indicator. Works on the smallest and largest supported screens and on the oldest supported OS.
- Font scaling (Dynamic Type, Android font size) does not break layouts. Dark mode works or is clearly disabled.
- Screen reader: interactive elements have accessibility labels and roles (VoiceOver, TalkBack).
- Offline and slow network: clear message, cached content where possible, retry. No endless spinner.
- The keyboard does not cover the focused input. Android back button and gestures behave as expected.
- Permission denied is handled: the feature explains why it needs access and links to Settings.
- Loading, empty, and error states on every data screen.

## Maintainability

- End-to-end test (Maestro, Detox, integration_test) for the main flow on at least one platform.
- Native dependencies match the framework or SDK version (`npx expo-doctor`, `flutter doctor`, `pod outdated`).
- Build profiles (development, preview, production) have separate config and env values.
