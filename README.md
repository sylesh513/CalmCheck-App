# CalmCheck

An offline-first Flutter app for acute-moment readiness, built to the "Field
Card" design system. Two halves, one thesis: **someone is in distress right
now — tell me exactly what to do in the next 60 seconds.**

1. **Calm yourself.** A guided panic flow — paced breathing with synchronised
   haptics and voice, plus 5-4-3-2-1 sensory grounding. Works in airplane mode.
2. **Be ready for someone else.** Care cards — a structured, shareable profile
   for a person you look after, readable by any caregiver or stranger in
   seconds, fully offline.

---

## Running it

```bash
flutter pub get
flutter run                                # Android or iOS device / simulator
flutter test                               # 225 tests
flutter build appbundle --release          # the Play upload
flutter build apk --release --split-per-abi
flutter build ipa --release                # needs full Xcode, not just the CLTs
```

Release builds need an upload key. Copy `android/key.properties.example` to
`android/key.properties` and fill it in; without it the release build stops with
an explanation rather than quietly signing with debug keys. The whole
submission checklist is in **[docs/store-submission.md](docs/store-submission.md)**.

Requires Flutter 3.44+ / Dart 3.12+. Android `minSdk` 23+, **iOS 14+**. No NDK
is needed — every plugin here is Kotlin, Swift and Dart.

iOS 14 rather than 13 because `CLLocationManager.authorizationStatus` as an
instance property is 14+. Every device that can run iOS 13 can run iOS 14, so
the floor costs nobody a phone and saves the availability branching.

Verified on this machine: `flutter analyze` clean, all tests green, and the
Android debug, release (R8-minified, signed) and app-bundle builds all succeed.
Per-device release APKs come out at **24.2 MB** (armeabi-v7a) and **28.0 MB**
(arm64-v8a). A minified release build was installed on a Pixel 9 Pro emulator
and walked end to end, including the reminder toggle, which is the path R8 is
most likely to break.

**iOS builds too**, debug and release, and runs on an iPhone 17 Pro simulator.
`pod install` is clean and both hand-edited `project.pbxproj` entries — the
privacy manifest and the location plugin — load correctly; the built
`Runner.app` carries `PrivacyInfo.xcprivacy` and every usage string. The iOS
build is **not** verified here — this machine has the Command Line Tools but not
Xcode, so nothing iOS-side has been compiled. The Dart is platform-neutral, the
plugin set all supports iOS 13+, and `Info.plist` carries the camera and photo
usage strings, the portrait lock and the `tel:`/`https` query schemes.

`flutter test test/render_shots_test.dart` renders a dozen screens to PNGs in
`build/shots/` with the real bundled fonts, for looking at the build rather than
only asserting on it.

---

## What is on the device, and what isn't

There is no account, no server, and no analytics SDK. Care cards and settings
live in `SharedPreferences` on the phone; card photos are copied into the app's
own documents directory. `android.permission.INTERNET` is deliberately **not**
in the manifest.

Because of that there is no offline state anywhere in the app — offline is its
normal operating condition, not a failure to report. If any screen ever implies
a network dependency, that's a bug.

---

## Layout

```
lib/
  design/      tokens · theme · motion · breath      the system, in Dart
  models/      care_card.dart                        the shareable object
  data/        copy · exercises · helplines · …      every string, in one place
  state/       app_state.dart                        the whole of what is remembered
  services/    haptics · voice · dialer · pdf · …    the device-facing edges
  widgets/     the component library                 one import per screen
  screens/     one directory per flow
```

### The design layer

`design/tokens.dart` holds every spacing, radius, rule and colour value in the
product; nothing else in the app contains a literal. Three registers are
defined — CALM-light, CALM-dark and ACUTE — and `design/theme.dart` turns each
into a `ThemeData`. **ACUTE is a separate `ThemeData`, never a variant of
CALM**: its type is larger, its dividers are transparent, and it has no z-axis.

`design/breath.dart` is the single source of truth for the breath. `frameAt()`
is a pure function of elapsed seconds; the orb's geometry, the haptic pulse and
the voice cue all derive from it, driven by one `AnimationController`. The
easing is "Crest" — `1-(1-t)^2.4` up, `(1-t)^1.7` down — deliberately
asymmetric, because a symmetric ease-in-out reads as mechanical and you end up
leading the animation rather than being led by it.

### Screens, by the session that specified them

| Flow | Screens |
|---|---|
| Onboarding | ONB-01 (orb-forward and type-forward), ONB-02, ONB-03, ONB-04 |
| Home | HOME "Ground" layout, with the empty, one-card and many-card shelves |
| Panic (ACUTE) | PANIC-02 pacer, PANIC-03 grounding, PANIC-04 check-in, PANIC-05 rise |
| Care cards | CARD-VIEW, CARD-EDIT, CARD-EMPTY, CARD-SHARE, CARD-SCAN, CARD-PDF |
| Exercises | EX-01 library, EX-02 detail with the Pro cadence control |
| Crisis | CRISIS-01 |
| Pro | PAY-01 (three variants × five states), PAY-02, PAY-03, PAY-04 |
| Settings | SET-01, SET-02, SET-03, SET-04, breathing pace, helpline region |
| System states | permission denied ×2, purchase failure, three empty states, destructive confirm |

Every one of them is reachable in the running app. **Settings → About → Open the
design reference** also lists them all in one place, including the variants and
states that only occur under particular conditions, plus a specimen sheet with
the palette, contrast audit, type scale and spacing scale.

---

## The non-negotiables, and where they are enforced

1. **ACUTE is exclusive.** Entered only from the panic action. No navigation
   chrome, no counters, no progress, no monetization surface. `AcuteScaffold`
   strips the chrome; `test/flow_test.dart` walks the flow and fails if any of
   a list of monetization words appears in it.
2. **Breathing, grounding, the first care card and the helplines are free
   forever.** `AppState.canCreateCard` lets the first card through regardless of
   subscription; `exercises.dart` marks only the two free ones free, and a test
   asserts that list never changes. A lapsed subscription stops new cards and
   new exports and never removes a card someone already made.
3. **Contrast floors** of 7:1 body and 4.5:1 large/UI in all three modes. The
   measured ratios are printed on the specimen screen.
4. **Minimum target 48dp; crisis rows 88dp.** `CcStructure.targetMin` and
   `CcStructure.targetCrisis`, applied at every call site.
5. **Nothing leaves the device.** No `INTERNET` permission, no analytics, and
   the QR payload deliberately drops the card's photo path — that path means
   nothing on another phone.
6. **Nothing medical.** No crosses, ECG lines, pill icons or hospital blue, and
   `test/copy_test.dart` fails the build if `diagnose`, `treat`, `therapy`,
   `cure`, `prescribe`, `medical grade` or `clinically proven` appears in any
   user-facing string outside the disclaimer that disclaims them.
7. **No exclamation marks anywhere.** Also enforced by that test, along with
   the banned-word list from the voice rules.

---

## Accessibility

Accessibility is the product here, not a pass at the end.

- **Atkinson Hyperlegible** (Braille Institute, SIL OFL 1.1) for content, chosen
  for disambiguated letterforms — someone reading a medication name off a card
  in an emergency cannot afford to guess `1` for `l`. **IBM Plex Mono** (IBM,
  SIL OFL 1.1) for the micro-labels. Both are bundled in `assets/fonts/`; no
  font is fetched at runtime.
- **200% text scale** is a first-class layout, not an edge case.
  `test/screens_test.dart` renders every screen at 412×915 at 100% and 200%, in
  light and dark, and fails on any overflow. Where a layout can't hold it
  reflows — the type is never reduced. On CARD-VIEW, if `WHAT TO DO` grows tall
  enough to push `DO NOT` below the fold, the first do-not line pins itself to
  the bottom edge until the real block scrolls into view.
- **Reduced motion** holds the orb still at a fixed amplitude and changes the
  phase cue instead. The haptics keep running: reduced motion is a visual
  preference, not a request to stop pacing the breath.
- **Do / Do-not rows** are distinguished on four channels at once — colour, a
  painted marker shape (filled square vs open ring with a bar), the group's
  micro-label, and type weight — so they survive greyscale printing and every
  colour-vision simulation. The screen reader hears "Do:" or "Do not:".
- The orb carries one semantic label that refreshes on phase change, never on
  every frame.

---

## Tests

```
test/breath_test.dart      the breath timeline and the exhale >= inhale clamp
test/care_card_test.dart   the share payload round-trip, and what it must not carry
test/copy_test.dart        the voice rules and the policy word list
test/exercises_test.dart   what stays free
test/screens_test.dart     every screen × {100%, 200%} × {light, dark}
test/flow_test.dart        the flows, and the non-negotiables walked end to end
test/card_repository_test.dart  atomic writes, recovery, quarantine, migration
test/purchases_test.dart        what Pro is allowed to do to somebody
test/helplines_test.dart        the crisis dataset: coverage, order, honesty
test/reach_out_test.dart        the message somebody's person actually reads

integration_test/platform_channels_test.dart
    The Swift and Kotlin this app owns rather than imports. Unit tests cannot
    see any of it, and an unregistered channel fails *silently* — the Dart side
    catches MissingPluginException and answers null, which is indistinguishable
    from "no fix available". Runs on a real device or simulator:

        flutter test integration_test/platform_channels_test.dart -d <device>
```

---

## Pro

Billing goes straight to the App Store and Play Billing — `in_app_purchase`,
with no subscription service in between, because the promise on the privacy
screen is that nothing about a person leaves the device. The cost of that is
stated plainly: entitlement is whatever the store the phone is signed into
reports, and there is no receipt server behind it.

Two rules `lib/services/purchases.dart` exists to keep:

1. **Pro never evaporates offline.** The entitlement is cached and is withdrawn
   only when the store explicitly answers "nothing active" — never because a
   query failed.
2. **If the store has no products, Pro is not offered at all.** Every Pro
   feature stays open and no paywall appears, so a build published before the
   products are configured is a complete app rather than one with a paywall
   that cannot charge.

Product identifiers, the store-side setup and the review notes are in
[docs/store-submission.md](docs/store-submission.md).

---

## Where care cards live

Not in preferences. `lib/services/card_repository.dart` writes them to their own
versioned JSON file, atomically, keeping the previous contents as a backup:

- a write goes to a temp file and is renamed into place, so a crash mid-write
  cannot leave a half-file;
- a primary file that will not parse falls back to the backup;
- if neither parses, the unreadable file is **kept** — renamed, not deleted —
  and Settings says so. Somebody's care cards are not ours to discard because
  we could not read them;
- one malformed card does not cost the others;
- a file written by a newer build is refused rather than rewritten with fields
  this build does not understand;
- the pre-1.0 preferences blob is migrated once, then cleared;
- queued writes are flushed when the app leaves the foreground.

---

## Your person

One contact that is yours, separate from any care card — those belong to
whoever the card is about. Set it in **Settings → Your person** and the panic
flow gains one loud control, **Call &lt;name&gt;**, above the two quiet ways out.
Until it is set the flow looks exactly as designed, with two elements.

The design holds PANIC-02 to two interactive elements. Reaching a person is the
one thing worth a third, and it is only ever drawn when somebody has actually
named theirs.

Texting them opens the system messaging app with the message already written
and **unsent** — that is not a compromise, it is the only thing either platform
allows, and it is the right behaviour anyway. iOS has no API to send on
somebody's behalf, and Play's SMS policy forbids a non-messaging app from even
declaring the permission, so CalmCheck holds none.

If "include where you are" is on, the app asks for a fix at the moment the
button is tapped, tries every enabled provider, falls back to a cached fix, and
gives up after eight seconds — the message goes without a link rather than
making somebody wait. Foreground only; there is no background location
permission. The whole message is previewed in Settings before it can ever be
sent.

---

## Crisis numbers

`assets/helplines/helplines.json` is a bundled dataset, built by
`tool/build_helplines.py`. It holds two very different kinds of number:

- **Emergency services for 237 territories**, derived from Google's
  [libphonenumber short-number metadata](https://github.com/google/libphonenumber)
  (Apache-2.0, ITU-sourced — the same data Android uses for emergency
  dialling). The number a person in that country would actually reach for is
  listed first: 911 across the Americas, 999 in the UK, 000 in Australia, 112
  across the EU and India, 110 in Japan.
- **Crisis helplines**, hand-verified against the operator's own publication and
  stamped with the date. Ten countries so far. Where a country has none, the
  screen says so plainly and routes to findahelpline.com rather than showing a
  number nobody checked — a wrong number on a fire exit is worse than no number.

Which country is decided by the network the phone is registered to, then the
SIM, then the phone's own region — because somebody having a panic attack
abroad needs the numbers for where they are standing, not for the language they
read in. There is a manual override on the screen itself and in Settings.

Refreshing it is a data change and a release, never a network call. Re-run the
generator after a libphonenumber update, and re-check the crisis lines before
each release:

```bash
python3 tool/build_helplines.py \
  --metadata tool/ShortNumberMetadata.xml --iso tool/iso3166.json
```

---

## Two deliberate trade-offs

**The barcode model is bundled, not downloaded.** `mobile_scanner` can use
Google Play Services' unbundled ML Kit and save about 5 MB per ABI, but the
model is then fetched over the network on first use. In an app whose thesis is
that it works with no signal, a scanner that quietly needs the internet the
first time is a broken promise, so the model ships inside the APK.

**Cloud backup is off.** Android's automatic backup would copy card content
into the user's Google account, which would make the privacy screen untrue, so
both cloud backup and device-to-device transfer are excluded. It is why the app
says: if you delete it, that data is gone — save a PDF of any card you want to
keep.

**"Open Settings" is our own method channel, not a plugin.** The obvious package
for it compiles against an SDK too old for the current Android Gradle Plugin and
fails the build. `lib/services/device_settings.dart` plus twenty lines of Kotlin
in `MainActivity` does the same job on Android, and `app-settings:` through
`url_launcher` does it on iOS.

---

## Not included

- **The store-side product setup.** The code is done; creating
  `calmcheck_pro_annual`, `calmcheck_pro_monthly` and `calmcheck_pro_lifetime`
  in App Store Connect and the Play Console is an account task, not a code one.
  Until they exist the app hides Pro and unlocks everything.
- **A hosted privacy policy and terms.** Both are complete and readable in the
  app; both consoles also want a URL to publish them at.
- **The upload keystore.** Generated and owned by whoever publishes.
- **iOS verification.** See above — the project is configured for iOS but has
  not been compiled on this machine.
- **Store listing assets.** `store/icon-1024.png` and `store/icon-48.png` (the
  legibility test) are generated by `tool/make_icons.py`, which also writes the
  Android adaptive layers — foreground, background and monochrome — and the iOS
  icon set. Screenshots and the feature graphic are not generated here.
