/// RevenueCat public SDK keys — one per store.
///
/// These are *publishable* keys (they ship inside the binary and unlock
/// nothing by themselves), not secrets. They come from the RevenueCat
/// dashboard: Project settings → API keys → "Public app-specific API keys".
///
/// Fill in the defaults below before a release build, or inject them at build
/// time without touching source:
///
///   flutter build ipa --dart-define=RC_APPLE_KEY=appl_xxx
///   flutter build appbundle --dart-define=RC_GOOGLE_KEY=goog_xxx
///
/// While a key is empty the store is reported unavailable, which — by the
/// rule in `purchases.dart` — opens every Pro feature rather than shipping a
/// paywall that cannot charge. Release builds must therefore carry real keys.
library;

class RevenueCatKeys {
  const RevenueCatKeys._();

  static const String apple = String.fromEnvironment(
    'RC_APPLE_KEY',
    // CalmCheck iOS (bundle app.calmcheck) in the CalmCheck RevenueCat
    // project. Publishable: it unlocks nothing on its own, and baking it in
    // means no build can ship keyless and give Pro away.
    defaultValue: 'appl_AJqoiFxuRbllCOXZJazbiIAKasA',
  );

  static const String google = String.fromEnvironment(
    'RC_GOOGLE_KEY',
    // TODO(publisher): paste the goog_ key once the Play app exists. Empty
    // means Android reports the store unavailable, which opens Pro up — see
    // the warning in purchases.dart. Fill this in before any Play upload.
    defaultValue: '',
  );
}
