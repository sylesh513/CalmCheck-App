# Turning Pro on: RevenueCat, end to end

The app's purchase code is finished. `lib/services/purchases.dart` configures the
SDK, reads offerings, buys, restores, caches entitlement and gates every Pro
feature; `lib/screens/paywall/` renders the paywall on real store prices. Nothing
in `lib/` needs editing except two API keys.

What is left is console work: create the products in App Store Connect, give
RevenueCat the credentials to read Apple's side, wire up an entitlement and an
offering, put the public keys into the build, and prove a purchase in the
sandbox.

Work top to bottom. iOS first — Android is section 10 and needs a Play account.

---

## What is already configured

Created 2026-09-06 via the RevenueCat MCP. iOS only; Android is untouched.

| | |
|---|---|
| Project | `CalmCheck` — `projb8214278` |
| App | `CalmCheck iOS` — `appb2892c3ba5`, bundle `app.calmcheck` |
| Entitlement | `pro` — `entl20d4aa42d3`, all three products attached |
| Offering | `default` — `ofrngca73543b1f`, **current** |
| Packages | `$rc_annual`, `$rc_monthly`, `$rc_lifetime`, one product each |
| Public SDK key | `appl_AJqoiFxuRbllCOXZJazbiIAKasA`, baked into `revenuecat_keys.dart` |

Both Apple credential sets validate (`validate-app-credentials` → *valid* for
`app_store_subscriptions_key` and `app_store_connect_key`).

Products, created in **App Store Connect** through the MCP and all reporting
`READY_TO_SUBMIT`:

| Store identifier | RevenueCat id | Type | US price |
|---|---|---|---|
| `calmcheck_pro_annual` | `prodfad0186efb` | subscription, 1 year | $19.99 |
| `calmcheck_pro_monthly` | `prod3c0844b27c` | subscription, 1 month | $2.99 |
| `calmcheck_pro_lifetime` | `prod79ec1963cc` | non-consumable | $59.99 |

- Subscription group **CalmCheck Pro**, holding annual and monthly, so a person
  can move between them rather than ending up with two live subscriptions.
- **7-day free trial** on annual only (`trial_offer.duration = ONE_WEEK`), which
  is what `ProCopy.trialLine` is written for.
- **172 territories**, with every territory price filled by Apple's
  equalization from the USD base — £19.99 GB, €22.99 EU, ¥3000 JP, ₹1999 IN.
- Russia deliberately excluded from availability: Apple suspended App Store
  commerce there, and including it risks failing the whole write.
- IAP review notes on each product state that breathing, grounding, the first
  care card and the crisis helplines are never gated.

### Still outstanding on these products

- **Review screenshot is a placeholder.** All three carry an auto-supplied
  image (`filename: "SOURCE"`, 13,815 bytes, identical checksum across all
  three) rather than a picture of the paywall. Apple expects the real purchase
  UI; replace it with `upload-product-store-state-screenshot`.
- **`privacy_policy_url` is `null`** on all three. Apple asks for it on
  subscriptions — see section 4 of `store-submission.md`.
- **Paid Applications agreement** must read *Active* before any of this can
  transact, however green the products look.

---

## The one trap in this codebase

`AppState.isPro` returns **true** when the store says it has nothing to sell:

```dart
bool get isPro =>
    purchases.isPro ||
    purchases.availability == StoreAvailability.unavailable;
```

That is deliberate — it means a build shipped before the products exist is a
complete app rather than one with a paywall that cannot charge. It also means:

> **An empty `RC_APPLE_KEY`, or products RevenueCat cannot see, gives Pro away
> to everybody.**

So "no paywall appeared" is never proof that things work. The finish line for
this whole document is section 9: the paywall appears, with real prices on it.

---

## 1. App Store Connect — agreement and app record

### 1a. Paid Applications agreement (start this first)

Only the **Account Holder** can accept agreements. App Store Connect →
**Business** (older accounts label it *Agreements, Tax, and Banking*).

Under **Agreements**, find the **Paid Apps** row and accept the terms. Three
tasks then appear and all three must be finished:

- **Contact Info** — Senior Management, Financial, Technical and Legal
  contacts. All four can be the same person.
- **Bank Account** — add one and wait for it to reach **Clear** status. This is
  the slow part; budget days, not hours.
- **Tax Forms** — the US forms (W-8BEN from outside the US, W-9 inside) plus any
  local ones requested.

Done when the row reads **Active**. Until then `getProducts` returns empty,
RevenueCat shows no products, and — per the trap above — this app silently
unlocks Pro. This is the single most common cause of "my products don't load".

### 1b. Register the App ID

[developer.apple.com/account](https://developer.apple.com/account) →
**Certificates, Identifiers & Profiles** → **Identifiers** → **+** → **App
IDs** → **App**.

- Description: `CalmCheck`
- Bundle ID: **Explicit**, exactly `app.calmcheck`
- Capabilities: leave the defaults

There is no In-App Purchase capability to tick and no entitlements file to add —
it is on for every App ID automatically. That is why this project has no
`ios/Runner/Runner.entitlements` and needs none.

### 1c. Create the app record

App Store Connect → **Apps** → **+** → **New App**.

- Platform: **iOS**
- Name: `CalmCheck` — globally unique across the App Store, so have a fallback
- Primary Language: your choice
- Bundle ID: pick `app.calmcheck` — **it only appears if 1b is done**
- SKU: `calmcheck` (internal, never shown to anyone)
- User Access: Full Access

---

## 2. Create the three products

The identifiers are hardcoded in `ProProductIds` (`lib/services/purchases.dart`)
and must match exactly. Anything the store returns that is not one of these
three is ignored by `PurchaseService.refresh()`.

### The two subscriptions

App Store Connect → your app → **Monetization → Subscriptions** → create a
subscription group first (call it `CalmCheck Pro`). One group matters: it is
what lets somebody move between monthly and annual instead of ending up with
two live subscriptions.

Inside the group, create both:

| Product ID | Duration | Reference name |
|---|---|---|
| `calmcheck_pro_annual` | 1 year | CalmCheck Pro Annual |
| `calmcheck_pro_monthly` | 1 month | CalmCheck Pro Monthly |

Each one needs, before it will leave *Missing Metadata*:

- **Subscription price** for your home territory (App Store Connect fills the
  rest of the world from Apple's price matrix)
- **Localization** — display name and description, at minimum in your primary
  language
- A **review screenshot** and review notes — only required when you submit,
  but fill them in now so the product reaches *Ready to Submit*

The subscription **group** also needs its own localized display name (Apple
shows it on the Manage Subscriptions screen), and an **App Store promotion**
image is optional.

If you want the free trial the paywall copy is written around, add an
**introductory offer** to the annual plan: Subscription → Introductory Offers →
Free trial, 7 days, new subscribers. The app never fabricates a trial — it only
shows one if the store reports one.

### The lifetime purchase

App Store Connect → **Monetization → In-App Purchases** → **+** →
**Non-Consumable**:

| Product ID | Type |
|---|---|
| `calmcheck_pro_lifetime` | Non-consumable |

Same requirements: price, localization, review screenshot.

**Wait for all three to read *Ready to Submit*.** Products stuck in *Missing
Metadata* are not fetchable, even in the sandbox.

---

## 3. In-App Purchase key — the StoreKit 2 blocker

**Where:** App Store Connect → **Users and Access** → **Integrations** tab →
**In-App Purchase** in the left sidebar.

> This page also carries the App Store Connect API section (section 4). They are
> **different key types**, and generating the wrong one is the most common
> mistake in this whole document. This one validates transactions.

1. **Generate In-App Purchase Key**, name it `RevenueCat`.
2. **Download the `.p8`** — one download only; Apple never serves it again. Lose
   it and you revoke and regenerate.
3. Copy the **Key ID** from the key's row — it is also the `XXXXXXXXXX` portion
   of the filename.
4. Copy the **Issuer ID** shown above the table.

**Check the filename before uploading.** This key downloads as
`SubscriptionKey_XXXXXXXXXX.p8`. If yours starts `AuthKey_`, you generated a
section 4 key by mistake and RevenueCat will reject it. **Do not rename it to
get past the check** — the two are different keys for different Apple APIs, a
renamed one uploads cleanly and then silently fails to validate transactions.

**Into RevenueCat:** project `CalmCheck` (`projb8214278`) → Apps →
`CalmCheck iOS` → **In-app purchase key configuration** tab.

| From App Store Connect | Into RevenueCat |
|---|---|
| the `.p8` file | Upload / paste contents |
| Key ID | Key ID |
| Issuer ID | Issuer ID |

Save, then **confirm it reads "Valid credentials".** Without this, purchases
complete on the device and never grant the entitlement — silently, with no error
anywhere in the app.

---

## 4. App Store Connect API key — required to manage products

Not optional if you want products created from here rather than typed by hand.

**Where:** same page — **Users and Access** → **Integrations** → **App Store
Connect API** → **Team Keys**.

1. **+** → name it `RevenueCat` → access role **App Manager** (the minimum
   RevenueCat accepts).
2. **Download the `.p8`** — again one download, and a *different file* from
   section 3's. This one downloads as `AuthKey_XXXXXXXXXX.p8`.
3. Copy the **Key ID** and the **Issuer ID** above the table.
4. Get the **Vendor Number**: App Store Connect → **Payments and Financial
   Reports** → top-left corner. Eight or nine digits.

**Into RevenueCat:** same app → **App Store Connect API** tab.

| From App Store Connect | Into RevenueCat |
|---|---|
| the `.p8` file | Upload |
| Key ID | Key ID |
| Issuer ID | Issuer ID |
| Vendor Number | Vendor number |

### Telling the two keys apart

| | Section 3 key | Section 4 key |
|---|---|---|
| Sidebar section | In-App Purchase | App Store Connect API → Team Keys |
| Role setting | none | App Manager |
| Extra field | — | Vendor number |
| Missing it breaks | entitlements never granted (StoreKit 2) | reading/writing store products |
| RevenueCat tab | In-app purchase key configuration | App Store Connect API |

Keep both `.p8` files out of this repository.

### App Store Server Notifications (recommended)

Without them RevenueCat only learns about a cancellation or renewal the next
time the app asks. RevenueCat shows a URL under the app's settings; paste it
into App Store Connect → your app → **General → App Information → App Store
Server Notifications**, into both the Production and Sandbox fields, version
**2**.
---

## 5. RevenueCat — project and app

> **Already done** — see *What is already configured* above. Kept as a record
> of how it was set up. The one part still outstanding is uploading the two
> `.p8` keys from sections 3 and 4 into the app's credential tabs.

At [app.revenuecat.com](https://app.revenuecat.com):

1. **Create a project**, `CalmCheck`.
2. **Apps → + New → App Store.** App name `CalmCheck`, bundle id
   **`app.calmcheck`** — it must match `PRODUCT_BUNDLE_IDENTIFIER` in
   `ios/Runner.xcodeproj/project.pbxproj` exactly.
3. Open the app's **In-app purchase key configuration** tab, upload the `.p8`
   from section 3, paste the Issuer ID, save. **Confirm it reads "Valid
   credentials" before going further.** If it does not, nothing downstream will
   work and the failure mode is silent.
4. If you made an App Store Connect API key in section 4, upload it under the
   App Store Connect API tab.

---

## 6. RevenueCat — products, entitlement, offering

> **Already done** — see *What is already configured* above. Kept as a record.

Three layers, and the app depends on the middle one by name.

**Products.** Products → **+ New**. Either import from App Store Connect (if
you added the API key) or add the three identifiers by hand:
`calmcheck_pro_annual`, `calmcheck_pro_monthly`, `calmcheck_pro_lifetime`.

**Entitlement.** Entitlements → **+ New** → identifier exactly **`pro`**. This
string is `proEntitlementId` in `lib/services/purchases.dart`; a typo here means
purchases complete and unlock nothing. Attach **all three** products to it.

**Offering.** Offerings → use the `default` offering → **+ Add Package** three
times:

| Package | Attach |
|---|---|
| Annual (`$rc_annual`) | `calmcheck_pro_annual` |
| Monthly (`$rc_monthly`) | `calmcheck_pro_monthly` |
| Lifetime (`$rc_lifetime`) | `calmcheck_pro_lifetime` |

Mark the offering **Current**. (This app is forgiving about package identifiers
— `refresh()` reads the current offering *and* every other one, then matches on
product id — but use the standard `$rc_*` names anyway; RevenueCat's own tooling
assumes them.)

**Get the public key.** Project settings → **API keys** → the **public
app-specific** key for the App Store app. It starts `appl_`. This is a
publishable key that ships in the binary; it is not a secret, and it is not the
`sk_` secret key — never put an `sk_` key in the app.

---

## 7. Put the keys into the build

**Done for iOS.** The Apple key is the `defaultValue:` of `RevenueCatKeys.apple`
in `lib/services/revenuecat_keys.dart`, so every build carries it with no flag
to remember.

That is a deliberate trade. The key is publishable — it ships in the binary and
unlocks nothing on its own — so the only cost of committing it is that a fork
could report purchases into this project. The cost of *not* committing it is
much worse: one `flutter build ipa` without the flag ships an app that hands Pro
to everyone, silently, per the rule at the top of this document. Removing the
footgun is worth more than hiding a publishable string.

`String.fromEnvironment` still wins over the default, so a build can override:

```bash
flutter build ipa --dart-define=RC_APPLE_KEY=appl_other_key
```

**Android is still empty**, and an empty key means Pro is given away on that
platform. Fill in `RevenueCatKeys.google` before any Play upload — section 10.

---

## 8. Test the purchase in the sandbox

**Make a sandbox account.** App Store Connect → **Users and Access → Sandbox →
Test Accounts** → **+**. Use an email address you control that is *not* already
an Apple ID. Set the App Store region to match the pricing you want to see.

**Sign in on the device.** Settings → **Developer → Sandbox Apple Account**
(iOS 18 and later; on older iOS it is Settings → App Store → Sandbox Account).
The Developer menu appears once the device has run a build from Xcode. Do not
sign the sandbox account into the normal App Store — it belongs only here.

**Run a debug build on a real iPhone**, not the simulator:

```bash
flutter run --dart-define-from-file=revenuecat.json -d <your-iphone>
```

The simulator does not talk to the real StoreKit sandbox; purchases there are
either impossible or local-only and never reach RevenueCat.

**Then, in the app:** Settings, or any locked exercise, or a second care card →
the paywall → buy the annual plan. What to expect:

- A sandbox purchase can take 15+ seconds. That is normal, not a hang.
- Sandbox prices sometimes ignore what you set in App Store Connect. Also
  normal.
- Sandbox subscriptions renew on an accelerated clock — a month is 5 minutes, a
  year is an hour — and stop after several cycles. That makes expiry easy to
  test: buy, wait, and watch Pro withdraw and `ProStatus.expired` show the
  "what changed" copy rather than a first-time paywall.

**Confirm it landed.** In the RevenueCat dashboard, turn on **View sandbox
data**, find the customer, and check that the `pro` entitlement is active. If
the purchase succeeded on the phone but no customer appears here, the In-App
Purchase key from section 3 is missing or invalid — go back to step 5.3.

---

## 9. Verify against this app's own rules

The point of these four is that each one is a way the integration can be broken
while looking fine.

- [ ] **The paywall appears at all, with real prices.** If Pro features are open
      and no paywall shows, `availability` is `unavailable` — the key is empty,
      or RevenueCat sees no products. Do not ship this build.
- [ ] **Restore works.** Delete the app, reinstall, Settings → Restore
      purchases → Pro comes back.
- [ ] **Pro survives airplane mode.** Buy, kill the app, go offline, relaunch.
      Entitlement is read from the on-device cache before the first frame and
      must not flicker off.
- [ ] **Nothing safety-related is ever gated.** Breathing, grounding, the first
      care card and the crisis helplines stay free with the paywall live. This
      is a store-review requirement as much as a design one.

And the test suite still has to be green — it asserts both rules above:

```bash
flutter test test/purchases_test.dart
```

---

## 10. Android, when you get to it

Needs a Google Play developer account ($25, one time). The Play side is slower
than Apple's, mostly because of credential propagation.

1. **Upload a build first.** Play will not let you create in-app products until
   an app bundle containing the billing library has been uploaded to a track —
   internal testing is enough.
2. **Create the products** under Monetize: two subscriptions
   (`calmcheck_pro_annual`, `calmcheck_pro_monthly`), each needing a **base
   plan** (the code strips Play's `productId:basePlanId` form in
   `_baseProductId`, so base plan naming is free), and one one-time product
   `calmcheck_pro_lifetime`.
3. **Service credentials.** RevenueCat needs a Google Cloud service account with
   the Android Publisher, Developer Reporting and Pub/Sub APIs enabled, granted
   these Play Console permissions: view app information, view financial data,
   manage orders and subscriptions, manage store presence. RevenueCat publishes
   a Cloud Shell script that does most of it. **Allow up to 36 hours for the
   credentials to start working** — this is normal and not something you have
   misconfigured.
4. **RevenueCat:** add a Play Store app with package `app.calmcheck`, upload the
   service account JSON, add the three products to the **same `pro`
   entitlement** and the **same offering** as the Apple ones, and take the
   `goog_` public key.
5. **Test** with a licence tester (Play Console → Setup → License testing),
   installing from the internal testing track — not a sideloaded APK.

The manifest is already correct: `INTERNET` is declared and `MainActivity` uses
`launchMode="singleTop"`, which is what Play Billing needs so a purchase is not
cancelled when the payment sheet returns.

---

## 11. When it does not work

| Symptom | Cause |
|---|---|
| No paywall, everything unlocked | Empty API key, or RevenueCat returned no products. Check `RC_APPLE_KEY` reached the build, then the offering. |
| Paywall says the store is unavailable, with a retry | `StoreAvailability.unreachable` — the query threw. Network, or a malformed key. |
| Products empty, key valid | Paid Applications agreement not Active, or products not yet *Ready to Submit*. |
| Purchase succeeds, Pro never activates | In-App Purchase key (section 3) missing or invalid — the StoreKit 2 failure mode. Or the entitlement is not literally `pro`. |
| Purchase succeeds, Pro activates, dashboard empty | Looking at production data. Toggle **View sandbox data**. |
| Android: credentials rejected | Propagation. Wait; up to 36 hours. |

---

## 12. Doing most of this with the RevenueCat MCP

RevenueCat ships an AI Toolkit plugin (MCP server + skills), installed on this
machine as `revenuecat@RevenueCat`. Authorize it once with `/mcp` in an
interactive `claude` terminal (OAuth, no API key to manage), and an agent can
drive most of sections 2, 5, 6 and 7 directly.

**What it can do**

- `create-project`, `create-app` — section 5, steps 1 and 2
- `create-product`, `set-product-store-state`, `create-product-prices`,
  `equalize-subscription-prices`, `upload-product-store-state-screenshot`,
  `submit-products-to-store` — section 2, including writing the product
  metadata into App Store Connect rather than typing it there
- `create-entitlement`, `attach-products-to-entitlement`, `create-offering`,
  `create-packages`, `attach-products-to-package` — all of section 6
- `list-app-public-api-keys` — fetches the `appl_` key for section 7
- `validate-app-credentials` — confirms the section 3 key actually works

**What it cannot do, and why**

- The **Paid Applications agreement** and the App Store Connect **app record**
  (section 1) — account-level, browser only.
- The **In-App Purchase `.p8` key** (section 3) — generating a credential and
  uploading it is dashboard work by design. This is the blocking dependency:
  `set-product-store-state` cannot write to App Store Connect until RevenueCat
  holds valid Apple credentials.
- **Sandbox testers and on-device testing** (section 8) — a real purchase on a
  real iPhone is the only thing that proves the chain works.

So the order is unchanged: do sections 1, 3 and 4 by hand, then hand the rest to
the MCP.

---

See also `docs/store-submission.md` for the rest of the submission — privacy
labels, review notes, screenshots and the pre-upload checklist.
