# Submitting CalmCheck

Everything the two stores need that is not in the code, and everything in the
code they will ask about. Work top to bottom the first time.

---

## 1. Identifiers

| | |
|---|---|
| Android application id | `app.calmcheck` (debug builds install as `app.calmcheck.debug`) |
| iOS bundle id | `app.calmcheck` (set in the Xcode project; matches Android) |
| Display name | CalmCheck |
| Version | `pubspec.yaml` `version: 1.0.0+3` — the part before `+` is the public version, after it the build number |
| Minimum OS | Android 7.0 (API 24 — Flutter's floor wins over the Gradle `minSdk 23` line), iOS 15.0 |

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

**RevenueCat.** Purchases are validated by RevenueCat (`purchases_flutter`).
The full click-by-click setup — App Store Connect products, the In-App Purchase
key StoreKit 2 requires, the entitlement and offering, and sandbox testing — is
in `docs/revenuecat-setup.md`. In summary:

1. Create a project with an iOS app (bundle id `app.calmcheck`) and an Android
   app (package `app.calmcheck`), attaching the App Store Connect API key and
   the Play service credentials it asks for.
2. Add the three products above and attach all of them to a single
   entitlement whose identifier is exactly **`pro`**
   (`proEntitlementId` in `lib/services/purchases.dart`).
3. Create an offering (the default one is fine) containing an annual, a
   monthly, and a lifetime package pointing at those products.
4. Put the two **public** SDK keys into `lib/services/revenuecat_keys.dart`,
   or pass them at build time:
   `--dart-define=RC_APPLE_KEY=appl_… --dart-define=RC_GOOGLE_KEY=goog_…`

RevenueCat sees an anonymous install id and receipts — never a name, an email,
or card content. It is the app's only network dependency, and the privacy
policy says so in matching words.

**Until the keys and products exist, the app hides Pro entirely** and unlocks
every Pro feature, so a build submitted before the products are live is a
complete app rather than one with a paywall that cannot charge. That is
deliberate: it means you can ship 1.0 without monetisation and turn it on later
with no code change — but it also means **a release build with an empty key
gives Pro away**; check the keys before every upload.

Entitlement is cached locally so that Pro never disappears when the phone is
offline, and is withdrawn only when RevenueCat definitively answers "nothing
active" — never because a query failed.

---

## 4. Privacy policy and terms

Both exist in the app: **Settings → Privacy policy** and **Settings → Terms of
use**, and both are linked from the paywall because Apple requires it there.

Both consoles also want a **URL**. Both are published on the parent company
site and are the ones to paste into the listings:

- `https://betterintegrations.org/calmcheck/privacy`
- `https://betterintegrations.org/calmcheck/terms`

The published pages carry the same wording as `lib/data/legal.dart`, plus the
publisher's registered details and a governing-law clause the phone screen does
not need. Keep the two copies in step — edit one and you edit the other in the
same change; the in-app version is the one people actually read. Details in
`docs/legal-for-publication.md`.

---

## 5. Data safety / privacy nutrition label

The honest answers, which are also the short ones.

**Google Play — Data safety**

- Does your app collect or share any of the required user data types?
  - **Purchase history: collected** (not shared, not linked to identity, not
    used for tracking) — RevenueCat processes store receipts to validate Pro.
    Encrypted in transit: **yes**. Deletion: covered by the RevenueCat data
    deletion process; nothing else exists to delete.
  - Everything else: **No.**
  - *Location:* the app reads a coarse fix only while somebody is tapping "text
    my person", puts a map link into a message they compose, and keeps nothing.
    It is not transmitted to the developer and not stored, so it is neither
    collected nor shared under Play's definitions. Prominent disclosure is on
    the setting itself and on the screen that uses it.
  - *Diagnostics:* the bundled ML Kit barcode library (the QR scanner) may
    send anonymous diagnostic counters to Google; declare **Diagnostics —
    collected, optional, not linked** if the reviewer asks about it.

**Apple — App Privacy**

- Data used to track you: **None.**
- Data linked to you: **None.**
- Data not linked to you: **Purchase history** (app functionality only) —
  RevenueCat validates receipts against an anonymous install id. RevenueCat's
  own privacy manifest ships in its pod and App Store Connect aggregates it
  automatically.
  - *Precise location* is used but not collected: it goes into a message the
    person composes in their own Messages app and is not retained. This is
    reflected in `ios/Runner/PrivacyInfo.xcprivacy`.

Purchases are processed by the store and validated by RevenueCat; the app
receives a yes/no entitlement. It never sees a name, an email or a payment
detail.

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

## 7. Listing copy

Written for the App Store fields. The number after each field is Apple's character
limit; every value below is within it.

**Name** (30) — `CalmCheck`

**Subtitle** (30) — `Panic help that works offline`

**Promotional text** (170, editable without a new version)

> Everything a panicking person needs is one tap from the home screen, and none
> of it needs a signal. Your cards and contacts never leave the phone.

**Keywords** (100, comma-separated, no spaces after commas)

`panic,anxiety,breathing,grounding,calm,offline,crisis,helpline,care card,attack,relief,coping`

**Description** (4000)

> CalmCheck is for the minutes when thinking clearly is hard.
>
> One tap from the home screen starts a paced breathing exercise you can feel
> rather than read — the rhythm is drawn and haptic, so it works with the screen
> at arm's length and your eyes half closed. Grounding exercises sit beside it.
> Crisis helplines are one tap away, chosen for where you are, and you can
> override the region by hand.
>
> CARE CARDS
>
> A care card is a page about one person: what helps them, what does not, who to
> call. Make one for yourself so somebody else knows what to do, or make one
> with a person you look after. Cards can be shared by QR code or file — phone
> to phone, no account, no server in between.
>
> NOTHING LEAVES YOUR PHONE
>
> There is no account and no sign-in. Your cards, your contacts and how often
> you open the app stay on the device. The only network traffic the app makes is
> validating an in-app purchase. Breathing, grounding, the crisis helplines and
> your first care card are free forever, and are never put behind the paywall.
>
> CALMCHECK PRO
>
> Pro adds unlimited care cards, photos on cards, PDF export and reminders.
> Available monthly, annually, or as a one-time purchase.
>
> NOT A MEDICAL DEVICE
>
> CalmCheck does not diagnose or treat anything, and it is not a substitute for
> professional care. If you are in danger, contact your local emergency number.

**Privacy policy URL** — `https://betterintegrations.org/calmcheck/privacy` (published)

**Support URL** — required by Apple, and the one field here that is not yet
confirmed to exist. It must resolve to a real page with a way to reach you;
`https://betterintegrations.org/calmcheck` works if that page carries the
support mailbox, otherwise publish `/calmcheck/support` before submitting.

---

## 8. Review notes

Paste something like this into both review forms.

> CalmCheck is an offline-first wellness app. It has no account and no
> analytics. The only network use is validating the Pro in-app purchase
> (RevenueCat); everything a person puts into the app stays on the device.
>
> No sign-in is needed to review it. The card library starts empty by design —
> tap "Make a card" on Home to create one in about twenty seconds, which is the
> flow every card screen depends on.
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

## 9. Assets

| Asset | Size | Where |
|---|---|---|
| App icon | 1024×1024, no alpha, no rounded corners | `store/icon-1024.png` |
| Android adaptive icon | foreground, background, monochrome | `android/app/src/main/res/mipmap-*` |
| iOS icon set | all sizes | `ios/Runner/Assets.xcassets/AppIcon.appiconset` |
| Screenshots | 1284×2778 portrait (6.5"), six of them | `build/store/` — rendered, see below |
| IAP review screenshot | same render, the paywall frame | `build/submission/07-paywall.png` |
| Play feature graphic | 1024×500 | not generated |

The listing frames are generated, not captured by hand:

```bash
flutter test test/submission_shots_test.dart   # build/submission/*.png
python3 tool/make_store_screenshots.py         # build/store/*.png, captioned
```

**Size is not negotiable and is not 6.9".** This app's App Store Connect record
offers a single iPhone slot — 6.5" — and accepts only 1242×2688 or 1284×2778;
a 6.9" frame (1320×2868) is refused with "the dimensions of one or more
screenshots are wrong" rather than scaled down. Apple then reuses that one set
for every other display size. The pipeline renders 428×926 logical at 3x, which
is 1284×2778, and flattens the output because App Store Connect also rejects an
alpha channel. Do not use `test/render_shots_test.dart` for this: it renders
824×1830 design-review images, which the console rejects, from a paywall with
no store behind it.

### Marketing images for LinkedIn

The same shots feed the social frames, which are not store assets and are not
submitted anywhere:

```bash
python3 tool/make_social_images.py             # build/social/<ratio>/*.png
python3 tool/make_social_images.py square      # just the one ratio
```

Four slots, all of them LinkedIn's: `landscape` 1200×627 (link preview and the
classic feed image), `square` 1200×1200 (feed, and one slide of a document
carousel), `portrait` 1080×1350 (the tallest the feed shows uncropped), and
`banner` 1584×396 (profile cover, laid out so the avatar never lands on type).
Seven posts in the same order as the listing frames, so a carousel and the
store tell the story the same way.

The copy lives in `POSTS` at the top of the script and claims nothing that has
not shipped — the footer is a URL, not "download on the App Store", because the
app is on TestFlight and has not been through review. `CTA` is the line to edit
when that changes.

`build/store/` comes out numbered in the order the design specifies, because
the order is the pitch — and only the first three reach the install sheets:

1. `01-home` — *Calm in one tap.*
2. `02-panic` — *Breathing you can feel, not just watch.*
3. `03-crisis` — *No signal needed. Ever.*
4. `04-card-view`, the Ravi card — *What to do. What not to do.*
5. `05-share`, the QR — *Share it with anyone.*
6. `06-privacy` — *Nothing leaves your phone.*

Upload them **one file at a time**, confirming each before the next. A six-file
drag lands asynchronously and arrives shuffled.

---

## 10. Building

```bash
flutter test                                  # 226 tests
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

## 11. Before every upload

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
