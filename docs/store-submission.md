# Submitting CalmCheck

Everything the two stores need that is not in the code, and everything in the
code they will ask about. Work top to bottom the first time.

---

## 1. Identifiers

| | |
|---|---|
| Android application id | `app.calmcheck` (debug builds install as `app.calmcheck.debug`) |
| iOS bundle id | set in Xcode; use `app.calmcheck` to match |
| Display name | CalmCheck |
| Version | `pubspec.yaml` `version: 1.0.0+1` — the part before `+` is the public version, after it the build number |
| Minimum OS | Android 6.0 (API 23), iOS 14.0 |

Bump the build number on every upload, even a rejected one.

---

## 2. The upload key (Android)

A release build is refused unless a key is configured, so nothing can be
published signed with debug keys by accident.

```bash
keytool -genkey -v -keystore ~/calmcheck-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy `android/key.properties.example` to `android/key.properties` and fill in
`storeFile`, `storePassword`, `keyAlias`, `keyPassword`. That file and any
`.jks` are gitignored.

**Back the `.jks` up somewhere that is not this machine.** Losing it means
losing the ability to ship an update to the same listing. Enrolling in Play App
Signing at first upload is strongly recommended, so this key is only the upload
key and Google holds the signing key.

---

## 3. In-app products

The app reads prices from the store and never displays a hardcoded one. Create
these exact identifiers in both consoles:

| Identifier | Type | Notes |
|---|---|---|
| `calmcheck_pro_annual` | Auto-renewing subscription, 1 year | The default selection |
| `calmcheck_pro_monthly` | Auto-renewing subscription, 1 month | |
| `calmcheck_pro_lifetime` | Non-consumable / one-time product | Does not renew |

On Play, the two subscriptions each need a base plan; on App Store Connect they
belong to one subscription group so a person can move between them. If you want
the free trial the design describes, add a 7-day introductory offer to the
annual plan — the app does not fabricate one.

**Until these exist, the app hides Pro entirely** and unlocks every Pro feature,
so a build submitted before the products are live is a complete app rather than
one with a paywall that cannot charge. That is deliberate: it means you can ship
1.0 without monetisation and turn it on later with no code change.

There is no receipt server. Entitlement is whatever the store the device is
signed into reports, cached locally so that Pro never disappears when the phone
is offline, and withdrawn only when the store explicitly answers "nothing
active". This is a deliberate trade for the app's no-server promise; it is
weaker against a determined jailbroken device and stronger against everything
else.

---

## 4. Privacy policy and terms

Both exist in the app: **Settings → Privacy policy** and **Settings → Terms of
use**, and both are linked from the paywall because Apple requires it there.

Both consoles also want a **URL**. Publish the text of
`lib/data/legal.dart` at, for example, `https://calmcheck.app/privacy` and
`https://calmcheck.app/terms`, and paste those URLs into the listings. Keep the
two copies in step; the in-app version is the one people actually read.

---

## 5. Data safety / privacy nutrition label

The honest answers, which are also the short ones.

**Google Play — Data safety**

- Does your app collect or share any of the required user data types? **No.**
  - *Location:* the app reads a coarse fix only while somebody is tapping "text
    my person", puts a map link into a message they compose, and keeps nothing.
    It is not transmitted to the developer and not stored, so it is neither
    collected nor shared under Play's definitions. Prominent disclosure is on
    the setting itself and on the screen that uses it.
- Is all of the user data encrypted in transit? *Not applicable — no data is
  transmitted.*
- Do you provide a way for users to request that their data is deleted?
  *Not applicable — data never leaves the device; deleting the app deletes it.*

**Apple — App Privacy**

- Data used to track you: **None.**
- Data linked to you: **None.**
- Data not linked to you: **None.**
  - *Precise location* is used but not collected: it goes into a message the
    person composes in their own Messages app and is not retained. This is
    reflected in `ios/Runner/PrivacyInfo.xcprivacy`.

If the console insists on a purchase category: purchases are processed by the
store, and the app receives only a yes/no entitlement. It never sees a name, an
email or a payment detail.

**Advertising ID:** not used. The app declares no `AD_ID` permission.

---

## 6. Content ratings and category

- Category: **Health & Fitness** on both stores.
- Play content rating questionnaire: no violence, no sexual content, no
  gambling. There is **user-generated content** in the sense that a person types
  care-card text — but it is stored only on their own device and cannot be
  shared to any service, so there is no moderation surface.
- Apple age rating: 4+ is defensible; **12+** is the safer answer because the
  app surfaces crisis and self-harm helplines.

---

## 7. Review notes

Paste something like this into both review forms.

> CalmCheck is an offline wellness app. It has no account, no server and no
> analytics, and on Android it does not request the INTERNET permission at all.
>
> No sign-in is needed to review it. Two example care cards are present on first
> launch so every screen has content.
>
> The app is explicitly **not** a medical device. The disclaimer appears during
> onboarding, in Settings → About, and in the terms: it does not diagnose or
> treat, and it is not a substitute for professional care.
>
> The app shows crisis helpline numbers, chosen by device locale with a manual
> override. It does not place calls automatically; a person has to tap a number,
> which hands off to the dialler.
>
> Camera: used only to read a care card's QR code. There is a "open a card file
> instead" path for reviewers who would rather not grant it.
>
> Location: only used when a person taps "text my person" on the breathing
> screen, to put a map link into a message they compose and send themselves.
> Foreground only — there is no background location permission. Set a contact
> in Settings → Your person to see it.
>
> The app holds no SMS permission and cannot send a message. Texting opens the
> system messaging app with the text pre-filled and unsent.
>
> In-app purchase: CalmCheck Pro (`calmcheck_pro_annual`,
> `calmcheck_pro_monthly`, `calmcheck_pro_lifetime`). Breathing, grounding, the
> first care card and the crisis helplines are free forever and are never gated.

---

## 8. Assets

| Asset | Size | Where |
|---|---|---|
| App icon | 1024×1024, no alpha, no rounded corners | `store/icon-1024.png` |
| Android adaptive icon | foreground, background, monochrome | `android/app/src/main/res/mipmap-*` |
| iOS icon set | all sizes | `ios/Runner/Assets.xcassets/AppIcon.appiconset` |
| Screenshots | 1179×2556 portrait, six of them | not generated — see the shot order below |
| Play feature graphic | 1024×500 | not generated |

`flutter test test/render_shots_test.dart` renders screens to `build/shots/`
with the real bundled fonts, which is a good starting point for the
screenshots. The order the design specifies, because the order is the pitch:

1. HOME — *Calm in one tap.*
2. PANIC-02 mid-exhale — *Paced breathing you can feel, not just watch.*
3. PANIC-02 or HOME — *No signal needed. Ever.*
4. CARD-VIEW, the Ravi card — *What to do. What not to do. In seconds.*
5. CARD-SHARE, the QR — *Share it with anyone. No account needed.*
6. SET-02, privacy — *Nothing leaves your phone.*

---

## 9. Building

```bash
flutter test                                  # 225 tests
flutter build appbundle --release             # the Play upload
flutter build apk --release --split-per-abi   # sideloadable, for testers
flutter build ipa --release                   # needs full Xcode
```

Release builds run R8 with `android/app/proguard-rules.pro`. After any plugin
change, install a release build and exercise the scanner, the reminder toggle,
PDF export and a purchase before uploading — shrinking is the step most likely
to break something that debug builds hide.

Play requires an app bundle. Per-device download from the bundle is around
23 MB on arm64; roughly 5 MB of that is the bundled ML Kit barcode model, kept
in the binary on purpose so scanning works with no signal.

---

## 10. Before every upload

- [ ] Build number incremented
- [ ] `flutter analyze` clean and `flutter test` green
- [ ] Release build installed on a real device, not just an emulator
- [ ] `flutter test integration_test/platform_channels_test.dart -d <device>`
      green on both an Android device and an iPhone — it is the only thing that
      checks the platform code this app owns
- [ ] Scanner, reminder toggle, PDF export, tap-to-call and "text my person"
      exercised in that release build
- [ ] A purchase and a restore exercised against a sandbox account
- [ ] Helpline numbers re-checked against the operators' own pages, and
      `CRISIS_VERIFIED_ON` in `tool/build_helplines.py` bumped with the dataset
      regenerated (the date is printed on the crisis screen)
- [ ] Privacy policy and terms URLs live and matching the in-app text
