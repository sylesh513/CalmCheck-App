# CalmCheck — legal text for publication

**These are now published.** Both pages are live on the parent company site:

- <https://betterintegrations.org/calmcheck/privacy>
- <https://betterintegrations.org/calmcheck/terms>

Paste those URLs into App Store Connect (and, later, Play Console). The rest of
this file is kept as the record of what had to be decided to publish them, and
of the invariant that keeps the two copies in step.

**The wording below is transcribed verbatim from `lib/data/legal.dart`.** Do not
edit it here without editing there. The app tells people the in-app text and the
published text are the same document, both consoles link to the published one,
and a reviewer who finds them saying different things has grounds to reject.

The URLs, and where each one has to go:

| Page | Goes into |
|---|---|
| `/calmcheck/privacy` | App Store Connect → App Privacy → Privacy Policy URL, **and** the `privacy_policy_url` on all three in-app purchases |
| `/calmcheck/terms` | App Store Connect → App Information → Licence Agreement / EULA link, and the paywall link |

## The five things only the publisher could fill in — and what they became

The in-app version omits these because a phone screen does not need them. A
published policy on a company site does. All five are now settled:

1. **Legal entity.** Better Integrations, named at the top of both published
   pages as the data controller and the contracting party.
2. **Registered address.** Kokapet, Hyderabad, Telangana 500075, India. On both
   pages, for GDPR/UK-GDPR transparency.
3. **Governing law and jurisdiction.** India, courts at Hyderabad, Telangana —
   the same law and venue as every other agreement the company publishes. It is
   section 11 of the published Terms and has no in-app counterpart.
4. **Contact address.** Changed on both sides to `hello@betterintegrations.org`,
   which exists. `calmcheck.app` resolves but serves nothing, so the old address
   would have put a dead mailbox in a published policy. `LegalCopy.contact` is
   now the single source of truth in the app — `about_screen.dart` and
   `dialer.dart` read it rather than repeating the string.
5. **Effective date.** *Last updated 23 August 2026*, unchanged, on both sides.
   The wording did not change, so the date did not either.

The published pages add exactly two sections that are not in the app: the
publisher's details at the top of each document, and — on the Privacy Policy
only — a closing section about the website hosting it, which states that the
site sets no cookies, runs no analytics and fetches nothing from a third party.
That last one is a live constraint on the website, not a description of it:
adding a tag manager to betterintegrations.org would falsify a published privacy
policy for a shipped app.

I am not a lawyer and this is not legal advice. The privacy statements below are
strong claims — no analytics, no servers, nothing collected — and they happen to
be true of the code as written, which I have read. If the parent company adds a
tag manager, a crash reporter, or a marketing pixel to the pages hosting this
policy, the policy stops being accurate.

**Keeping the two copies in step.** The published pages live in the website repo
at `src/routes/calmcheck/privacy.tsx` and `src/routes/calmcheck/terms.tsx`. Edit
a sentence in `lib/data/legal.dart` and you must edit it there in the same
change, and bump the date on both. The app tells people the two are the same
document; two versions of a privacy policy is two policies, and only one of them
can be the one somebody agreed to.

---
---

# CalmCheck — Privacy Policy

*Last updated 23 August 2026*

> Published as section 1, "Who we are": the legal entity name and registered
> address, plus a closing section 15 about the website hosting the page.

## The short version

CalmCheck has no accounts and no servers of ours. Your care cards, your settings
and everything you do in the app are stored on this device only. Nothing about
you is uploaded and nothing is tracked. The one thing that ever uses the network
is checking a Pro purchase with the store — and that carries no personal
information.

## What is stored, and where

Care cards, any photo you attach to one, your settings and whether you have Pro
are written to this app's own storage on this device. The app makes no network
requests of its own except purchase validation, described under Payments below.

## What we collect

Nothing about you. There is no analytics SDK, no advertising identifier, no
crash reporter and no telemetry of ours. We do not know how many times you
opened the app, which exercises you used, or whether you ever opened the
helplines screen. Two system-level exceptions are described under Payments and
The camera.

## The camera

The camera is used only to read a care card's QR code, and only while the
scanning screen is open. No image is saved and no image leaves the device. The
code reader is Google's ML Kit barcode library, which runs entirely on the device
but may report anonymous diagnostic counters to Google; it never sees card
content as text or anything about you. If you would rather not grant the camera,
you can open a card file instead.

## Photos

If you attach a photo to a care card, the file you pick is copied into the app's
own storage. The original is untouched and the copy is never uploaded. A photo is
deliberately left out of the QR code, because a code has to be small enough to
scan.

## Your person, and where you are

You can name one person to reach from the breathing screen. Their name and number
are stored on this device like everything else. Calling them hands the number to
your dialler. Texting them opens your own messaging app with the message already
written — CalmCheck cannot send a message by itself, on any phone.

If you leave "include where you are" on, CalmCheck asks your phone for your
location at the moment you tap to text, adds a map link to that message, and
forgets it. It is never asked for in the background, never stored, and never sent
to us. Turn it off and the message goes without it.

## When you share a card

A QR code or a card file carries the whole card. Once you share it, whoever holds
it can read it. That exchange happens between the two devices — by camera, by
file, or on paper — and not through us.

## Payments

If you buy Pro, the App Store or Google Play handles the payment. The purchase is
validated by RevenueCat, a service that checks store receipts; it sees a random
identifier for this install and the purchase itself — never your name, your
email, your payment details, or anything you put in the app. This is the only
network connection the app makes.

## Reminders

If you turn reminders on, the reminder is scheduled by your phone and delivered
by your phone. There is no push server and no message is sent from anywhere.

## Backups

CalmCheck opts out of automatic cloud backup on Android so that card content is
not copied off the device by the system. That is why deleting the app deletes the
data: save a PDF of any card you want to keep.

## Children

A care card is often about a child, and is written by the adult who looks after
them. The app is intended for that adult. We do not knowingly collect anything
from anyone, of any age, because we do not collect anything at all.

## Your rights

Because nothing is collected, there is nothing for us to show you, correct or
erase. Everything the app holds is on your device, where you can read it, change
it, export it or delete it yourself.

## Getting in touch

Write to hello@betterintegrations.org. An email you send us is an email we hold; we keep
it only as long as it takes to answer you.

---
---

# CalmCheck — Terms of Use

*Last updated 23 August 2026*

> Published as section 1, "Who you are agreeing with", and section 11,
> "Governing law" — the entity, its address, and the jurisdiction.

## What you are agreeing to

CalmCheck is a wellness app. By using it you agree to these terms. If you do not
agree with them, delete the app; there is no account to close and nothing of
yours is held anywhere else.

## What CalmCheck is not

CalmCheck is not a medical device. It does not diagnose or treat any condition,
it cannot tell whether you are safe, and it is not a substitute for professional
care. If you or someone else is in danger right now, call emergency services.

## Care cards are yours, and they are your responsibility

You decide what goes on a care card and who you share it with. Anyone holding the
code or the file can read the card, so share it the way you would share a piece
of paper with the same information on it. We never see a card and cannot recover
one for you.

## Crisis information

The helpline numbers in the app are published by the organisations that run those
lines. We check them before each release but we do not operate them and cannot
guarantee they will answer. If a number in the app is wrong, write to us and we
will correct it.

## Pro

Breathing, grounding, your first care card and the helplines are free forever and
are never part of a paid plan. Pro adds more exercises, unlimited care cards, PDF
export, a custom breathing pace and more guide voices. Pro is billed by the App
Store or by Google Play, not by us; those stores handle payment, renewal, refunds
and cancellation under their own terms.

## If Pro ends

Care cards you have already made stay on your device and stay readable,
shareable and printable from a saved PDF. Making new cards, new exports and the
Pro exercises pause until you renew. Nothing is deleted.

## Reaching your person

CalmCheck can place a call or open a pre-written message to the person you name,
but it cannot reach anybody on your behalf and does not monitor whether you did.
It is not an alarm system, a monitoring service, or a substitute for emergency
services. If there is immediate danger to life, call your local emergency number.

## What we promise, and what we do not

We build this carefully and we test it. We cannot promise the app is free of
faults, that a device will vibrate or speak when you expect it to, or that a
reminder will arrive. To the extent the law allows, the app is provided as it is,
and our liability is limited to what you paid for it.

## Changes

If these terms change, the new version ships with an app update and the date at
the top changes with it.

---
---

## After publishing

Both pages are live over HTTPS. The privacy URL —
`https://betterintegrations.org/calmcheck/privacy` — still has to reach three
places besides the listing: the `privacy_policy_url` field on each of the three
in-app purchases, which is `null` on all of them. That is a RevenueCat change,
not a code one, and it is the last outstanding item on this document.
