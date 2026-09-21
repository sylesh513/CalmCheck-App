# Getting CalmCheck onto TestFlight — what was actually done

The record of moving CalmCheck from "finished app on a laptop" to "build 3
installed on a phone through TestFlight", written down because most of it was
not the part anyone expects to be hard. The app was done. Ten hours went into
the toolchain, the store metadata, and two bugs that only a real device found.

The generalized procedure extracted from this is the `ship-ios-testflight`
skill. This file is the specific history: what broke here, and why.

Nothing has been submitted for App Review. That is deliberate and still true at
the end of this document.

---

## 1. Store readiness, before a single build

### The three in-app purchases

Annual, monthly and lifetime existed in App Store Connect but were incomplete
in the way that gets a submission rejected rather than the way that fails a
build. Two things were missing on all three:

- **`privacy_policy_url`** — Apple wants a privacy policy on each IAP, not just
  on the listing. Set to `https://betterintegrations.org/calmcheck/privacy`,
  the same URL the listing uses and the same document as `lib/data/legal.dart`.
- **A current review screenshot** — the attached image was stale. Apple's IAP
  review screenshot has to show the actual purchase UI, with real prices.

Both were applied through the RevenueCat MCP and then **verified against live
App Store Connect state** rather than trusted from the write's return value.

The screenshot needed care. `test/render_shots_test.dart` renders design-review
images at 824×1830, a size App Store Connect rejects, and `PurchaseService
.forTest()` defaults to `unavailable` — so the paywall renders the "Pro is not
available on this device" screen instead of the paywall. Neither is any use to
a reviewer. `test/submission_shots_test.dart` exists for exactly this: 440×956
logical at pixelRatio 3 = **1284×2778**, Apple's 6.5" iPhone size, with a store
that has products in it at the real prices ($2.99 / $19.99 / $59.99).

```
flutter test test/submission_shots_test.dart   # build/submission/*.png
python3 tool/make_store_screenshots.py         # build/store/*.png, captioned
```

`07-paywall.png` is the IAP review shot. The other six are the listing frames.
The compositor flattens onto an opaque background because **App Store Connect
rejects PNGs with an alpha channel**.

### The legal text

Both pages were published on the parent company site over HTTPS. The invariant
worth preserving is in `docs/legal-for-publication.md`: the published pages and
`lib/data/legal.dart` are *the same document*, and the app tells people so.
Apple now links to the published copy from the listing and from three IAPs.
Editing one side without the other breaks a claim the app makes about itself.

---

## 2. The toolchain, which is where the day went

### `Application not configured for iOS`

`flutter build ipa --release` failed with that and nothing else. The message is
misleading — it suggests the Flutter project is missing iOS config, which it
wasn't. Running the build verbose gave the real error:

```
xcrun: error: unable to find utility "xcodebuild", not a developer tool or in PATH
```

`xcode-select -p` pointed at `/Library/Developer/CommandLineTools`. The only
Xcode on the machine was in `~/Downloads`. Command Line Tools are not Xcode:
they have no `xcodebuild`, so Flutter's iOS support silently isn't there.

**Lesson: when Flutter says the project isn't configured for iOS, check
`xcode-select -p` before touching a single project file.**

Fixed by moving Xcode to `/Applications` and running (needs sudo, so the user
ran it):

```sh
sudo xcode-select --switch /Applications/Xcode-beta.app
sudo xcodebuild -runFirstLaunch
```

It then broke *again* the same way, because installing the beta Command Line
Tools in between had silently re-pointed `xcode-select` back at CLT. Installing
CLT resets the developer directory. Re-check after any CLT install.

### The App Store wouldn't install a release Xcode

`sw_vers` showed macOS 27.0 build `26A5425a` — a beta seed. During a beta OS
cycle the App Store refuses to install the release Xcode, which is why it read
as "incompatible". That left three options: gamble the submission on a beta
Xcode, download the `.xip` manually, or **build somewhere else**.

We built somewhere else. See section 4.

### Eight `Target Integrity` errors

With `xcodebuild` finally reachable, the archive failed with eight deployment
target errors: pods declaring iOS 13.0/14.0 against Xcode 27's floor of 15.0.

Two fixes, both in the repo:

**`ios/Podfile`** — floor raised to 15.0, plus a `post_install` hook that
raises any pod below it. The hook only ever *raises*:

```ruby
ios_floor = Gem::Version.new('15.0')
bump = lambda do |config|
  current = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
  if current.nil? || Gem::Version.new(current.to_s) < ios_floor
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = ios_floor.to_s
  end
end
```

A pod asking for *more* than 15.0 knows something we don't; forcing it down
would break it. `Gem::Version` is used rather than string or float comparison
so `'9.0'` and `'10.0'` order correctly.

**`ios/Runner.xcodeproj/project.pbxproj`** — nine configurations pinned to
`IPHONEOS_DEPLOYMENT_TARGET = 15.0`. Six of them had been rewritten to
`$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)` by Xcode's own project upgrade
during the first failed build. That variable makes the minimum supported iOS a
function of *whichever Xcode happens to build the app* — a later Xcode would
have quietly dropped supported devices with no diff to show for it.

**Lesson: after Xcode "upgrades" a project, diff the pbxproj. It writes
`$(RECOMMENDED_*)` variables that turn pinned decisions into floating ones.**

### One warning correctly ignored

Flutter warned "Launch image is set to the default placeholder icon." The
launch assets are 68-byte 1×1 transparent PNGs against a storyboard background
of `#F4EFE6` — the app's `STOCK` colour. That is a deliberate solid-colour
launch screen, not a forgotten placeholder. The warning is a false positive and
chasing it would have wasted an hour.

---

## 3. What a real device found that no test did

Two bugs, both reported from TestFlight build 2, neither catchable in a
simulator or a widget test as the suite then stood.

### The first-card editor closed itself

Typing a name into the onboarding care-card editor threw the editor away and
dropped the user on HOME with only the name saved. It read as the form
submitting itself after one field.

The mechanism, which is worth understanding because the shape recurs:

1. The editor autosaves 450ms after a keystroke — `onChanged: (_) => _save()`.
2. `_save()` calls `upsertCard`, which notifies `AppState`.
3. `OnboardingFirstCardScreen` is **still mounted underneath** the editor and
   listens via `context.app`, so it rebuilds.
4. Its `build` asked "has a card appeared since I pushed the editor?" and, on
   the first autosave, ran `pushNamedAndRemoveUntil(Routes.home)` — removing
   the route the person was typing into.

The fix moves the check out of `build` and onto the return from the pushed
route:

```dart
Future<void> _create() async {
  final before = app.cards.length;
  await Navigator.of(context).pushNamed(route, arguments: ...);
  if (!mounted) return;
  if (context.appRead.cards.length > before) _toHome();
}
```

**The general rule: a screen must not make navigation decisions from global
state during `build` while another route sits on top of it.** A listener plus a
side effect in `build` is a trap whenever the thing it observes can change from
a screen the user is currently on.

The regression test walks onboarding to the editor, types, pumps past the
debounce, and asserts the field still holds the name. **It was run against the
previous commit first and confirmed to fail there** — a regression test that
passes on the broken code proves nothing.

### Reminders defaulted off and nobody found the toggle

Not a bug, a product decision that was wrong on contact with a real user. The
reminders toggle sat off waiting to be discovered, and a nudge to practise
while you're calm is the entire mechanism by which the app is useful *before* a
bad moment. ONB-03 now fires the notification request on arrival.

`setReminders` still owns the OS dialog and still only records `true` when
permission comes back granted — so a denial, or a revisit after a denial where
iOS never asks again, leaves the toggle honestly off. The copy changed with it:
it used to read "Off unless you want it," which would have become a lie the
moment the screen switched it on.

**Lesson: when behaviour changes, grep for copy that described the old
behaviour.** The screen would otherwise have been lying about its own state.

### One more thing a device would have found

Not hit this session, still unverified, and the reason a device test matters:

```dart
bool get isPro =>
    purchases.isPro || purchases.availability == StoreAvailability.unavailable;
```

If the store cannot be reached, Pro is given away to everyone. That is the
right call for a build published before the products exist, and a serious
revenue bug if it ever fires in production. **It can only be tested on a
physical device with a sandbox account.**

---

## 4. Building without a usable local Xcode

Because the Mac was on a beta OS with only a beta Xcode, the build was
delegated to the Lance App Manager — an operator with real ASC credentials on a
release-Xcode Mac. This removed the beta-Xcode risk from the submission
entirely instead of gambling an upload on it. Apple accepted every binary.

The operator **cannot see the local machine** — no working tree, no
uncommitted changes — and holds **no GitHub credentials by design**, so a
private GitHub URL always 404s. Source has to cross the boundary first.

### The flow, per build

```
stage_build(bundle_id, ref: "main")
  → git_remote_url  (credentialed, ~1h expiry, this app only)
  → next_build_number  (read live from ASC, authoritative)

git push <that url> main     → auto-triggers build + upload
poll check_app_manager_activity / read_app_manager_conversation
```

Three rules learned the hard way:

**The build number comes from ASC, never from the repo.** `stage_build` returns
`next_build_number` read live seconds earlier. `pubspec.yaml` is usually stale.
Builds 2 and 3 both took their number this way.

**Never paste the credentialed URL into a message.** It carries a working
credential and would land in the transcript. It was written into a shell script
in a scratchpad directory and executed from there, which also keeps it out of
`.git/config` — pushing by URL rather than `git remote add` means re-staging
just swaps the URL and nothing credentialed is ever committed.

**Do not trust the operator's receipt.** Build 1's receipt said "Distributed to
internal testers via pilot." A read-only API audit hours later found **zero beta
groups and zero testers** — the claim was a no-op, and the user had already
acted on it by opening TestFlight and finding a redeem-code prompt. Every later
receipt was verified with an explicit read-only audit quoting API totals. Build
2's identical line turned out to be true, but only because it was checked.

### `await_reply` doesn't work here

It timed out at 600000ms, 240000ms and 100000ms — the client tool timeout is
shorter than the tool's own wait. Background `sleep` plus polling
`check_app_manager_activity` worked reliably every time. Builds took 15–47
minutes; step count rising with `error: null` is the sign it's healthy, and the
rate slowing usually means it's polling ASC for processing rather than still
compiling.

---

## 5. Why TestFlight showed a redeem code

The user opened TestFlight and was asked for a redeem code instead of being
offered the build. Build 1 was `VALID`, processing was done, export compliance
wasn't blocking, and the user is the Account Holder.

None of that matters. **Internal TestFlight distribution needs three separate
things**, and the build had only the first:

1. A build in state `VALID` — yes.
2. An internal **beta group** — there were none.
3. The tester in that group, **and the build assigned to the group** — neither.

Account Holder status grants no TestFlight access by itself. The user created
the group (`ToTheTop`) in App Store Connect directly; because it has
`hasAccessToAllBuilds = true`, builds 2 and 3 reached them automatically.

The later audit is the model for checking this:

```
GET /v1/betaGroups?filter[app]={id}            → total, and internal flag
GET /v1/betaTesters?filter[apps]={id}          → email + state per tester
GET /v1/betaGroups/{group}/builds              → which builds the group has
GET /v1/builds/{build}/individualTesters       → direct assignments
```

`GET /v1/builds/{id}/betaGroups` returns 403 — use group→builds instead.

---

## 6. The builds

| Build | Commit | State | What was in it |
|---|---|---|---|
| 1 | `78b4d34` | VALID | iOS 15 floor; give-back counters removed |
| 2 | `025365a` | VALID | Empty card library; sample content moved to tests |
| 3 | `03df01f` | VALID | Reminders on arrival; editor no longer closes itself |

Marketing version is `1.0.0` throughout. One detail cost a round trip: ASC's
`versionString` was `1.0` while `CFBundleShortVersionString` resolves through
`$(FLUTTER_BUILD_NAME)` to `1.0.0` from `pubspec.yaml`. **A build will not
attach to a version whose string doesn't match exactly.** Corrected to `1.0.0`.

### What build 2 changed, and why it mattered

A new install used to arrive with two fictional care cards already in it —
detailed medical descriptions of people the user has never met, sitting where
their own family is meant to be. The onboarding copy explained them, which was
the tell that something was off. The library now starts empty; the sample
content moved to `test/fixtures/`, which is what it always was.

Anyone upgrading has those two cleared once on load, matched strictly on the
old `sample-` id prefix so nothing a person made or was sent is touched.
`canCreateCard` dropped its `isSample` exemption with them; the `readOnly`
exemption stays, and gained a test of its own — a card someone shared with you
is not a card you made, and must not consume the free slot.

---

## 7. Still outstanding

Needs the user, not an agent:

- **Sandbox purchase and restore on a physical device.** The single most
  important unverified thing, for the `isPro` reason in section 3. Check: three
  real prices on the paywall (not the store-unavailable screen), a sandbox
  purchase unlocks Pro, Restore works after delete-and-reinstall, and the
  free-forever features stay free.
- **The App Privacy questionnaire.** Apple-ID-gated, and the item actually
  blocking submission.

Can be delegated whenever wanted:

- **Listing metadata** — description, subtitle, keywords, category, age rating,
  the six frames in `build/store/`, review notes. All drafted in
  `docs/store-submission.md` §5 and §7.

Not done, on purpose:

- **Nothing has been submitted for review.** The operator was explicitly told
  not to, every time.

Also open: `RevenueCatKeys.google` is still empty and must be filled before any
Play upload.

---

## 8. App Store Connect listing — state as of 9 Sep 2026

Entered through the web console. `1.0.0` is still `PREPARE_FOR_SUBMISSION` and
nothing has been submitted.

**Saved and confirmed on the version page:**

- Promotional text, description, keywords (93/100), Support URL, Marketing URL,
  Copyright — the values in `store-submission.md` §7.
- Support URL is `https://betterintegrations.org/calmcheck`, chosen because that
  page carries a CONTACT section with the mailbox. Verified live, as was
  `/calmcheck/privacy`. The doc previously listed a `/calmcheck/support` path
  that does not exist — do not use it.

**Screenshots: uploaded**, but only after two separate failures.

First, a six-file upload in one call lands asynchronously and **arrives in
scrambled order**: the result was panic, crisis, share, privacy, card, home.
Order is not cosmetic — Apple uses only the first three on install sheets. They
were deleted, and the slot is empty again. **Upload them one file at a time**,
in the §9 order, confirming each before the next.

Second, and only visible once the slot was empty: **the size was wrong.** This
app's record offers exactly one iPhone slot — **6.5"** — which takes 1242×2688
or 1284×2778 and nothing else, and Apple reuses that one set for every other
display size. The 6.9" frames the pipeline had been rendering (1320×2868) are
refused with "the dimensions of one or more screenshots are wrong"; they are
not scaled down. `test/submission_shots_test.dart` now renders 428×926 at 3x
and `tool/make_store_screenshots.py` composes at 1284×2778, with the screen
inset re-centred for the narrower frame. Re-run both; `build/store/` is already
regenerated at the right size.

The IAP review screenshot attached to the three products was uploaded at
1320×2868 and **was accepted** — that field has a much looser floor than the
listing slot, so it does not need replacing.

Both slots are now filled, one file at a time, in the §9 order: six 6.5"
iPhone frames and six 13" iPad frames.

**The iPad slot is not optional.** `TARGETED_DEVICE_FAMILY = "1,2"` means the
binary claims iPad support, so "You must upload a screenshot for 13-inch iPad
displays" is a hard blocker on Add for Review, and that slot takes only
2064×2752 or 2048×2732. `test/submission_shots_test.dart` now takes
`--dart-define=SHOT_DEVICE=ipad13` (1032×1376 at 2x) and the compositor takes a
device argument; caption type scales by the square root of the width ratio,
because scaling it by width alone eats the squarer iPad frame. Dropping to
device family 1 would remove the requirement, at the cost of a new build.

Rendering at iPad size exposed one real layout fact: the card view's action bar
sits inside the scroll view, and at 1376 points it lands half below the fold —
a marketing frame with a button sliced in two. The shot helper now jumps a
screen to the end of its scroll when the overflow is under 240px, which is the
difference between "there is more below" and "this looks broken". It changes
none of the six iPhone frames; only the paywall shot moved.

**Then the rest of the version, in one pass through the console.** The Add for
Review validation listed seven blockers; six are now cleared:

- **Primary category** Health & Fitness. **Subtitle** was empty and is now the
  §7 line, 29 of 30 characters.
- **Content rights**: does not contain, show, or access third-party content.
- **Age ratings** (Apple's seven-step 2025 questionnaire): every feature and
  capability No; Mature Themes, Sexuality, Violence and Chance-Based all None.
  Medical or Wellness is the only place this app has to think: **Medical or
  Treatment Information = Infrequent, Health or Wellness Topics = Yes.** None
  would contradict the medication field and the helplines; Frequent reads as a
  treatment app and costs several years of age rating. Calculated: **13+**
  (12+ on systems earlier than version 26 — the §6 target).
- **App Privacy**: one data type, Purchases → used for App Functionality, not
  linked to identity, not used for tracking. Published. ML Kit diagnostics
  stayed undeclared, per §5 — the position to defend if a reviewer asks.
- **Pricing**: $0.00 in all 175 countries, availability set to all of them.
- **App Review information**: contact name and `hello@betterintegrations.org`,
  **"Sign-in required" unchecked** (it defaults to checked, which would have
  demanded credentials for an app that has no account), and the §8 notes
  pasted in full. Version release left on "Automatically release".

**Blocked on one field:** App Review → Contact Information → phone number is
required, and the page will not save without it. Everything above is entered
but unsaved until it is filled.

**Still untouched:** the three IAP products, which for a first version must be
submitted alongside the app from the version page's In-App Purchases section.

One inconsistency found while verifying: the public page at
`betterintegrations.org/calmcheck` still says **"iOS 14 and later"** in two
places. The floor was raised to iOS 15 in `78b4d34`. The published page is now
wrong and should be corrected before the listing points at it.
