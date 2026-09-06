/// Terms and the privacy policy, written in the same voice as the rest of the
/// app: plain verbs, short lines, no clause a person cannot read once and
/// understand.
///
/// Both are also required by the stores. Apple wants a functional link to terms
/// and to a privacy policy from any screen that sells a subscription; Google
/// wants a privacy policy URL on the listing. `docs/store-submission.md` says
/// where to publish these.
library;

class LegalCopy {
  const LegalCopy._();

  static const String lastUpdated = 'Last updated 23 August 2026';
  /// The one address the app publishes, and the same one the published
  /// documents at betterintegrations.org/calmcheck carry.
  ///
  /// It is the company mailbox rather than a calmcheck.app address on purpose:
  /// the published policy and this text have to be the same document — both
  /// store consoles link to the published one, and a reviewer who finds them
  /// saying different things has grounds to reject — so the address has to be
  /// one that exists on both sides. calmcheck.app was never stood up.
  static const String contact = 'hello@betterintegrations.org';

  // ---- Terms of use --------------------------------------------------------

  static const List<({String heading, String body})> terms = [
    (
      heading: 'What you are agreeing to',
      body:
          'CalmCheck is a wellness app. By using it you agree to these terms. '
          'If you do not agree with them, delete the app; there is no account '
          'to close and nothing of yours is held anywhere else.',
    ),
    (
      heading: 'What CalmCheck is not',
      body:
          'CalmCheck is not a medical device. It does not diagnose or treat any '
          'condition, it cannot tell whether you are safe, and it is not a '
          'substitute for professional care. If you or someone else is in '
          'danger right now, call emergency services.',
    ),
    (
      heading: 'Care cards are yours, and they are your responsibility',
      body:
          'You decide what goes on a care card and who you share it with. '
          'Anyone holding the code or the file can read the card, so share it '
          'the way you would share a piece of paper with the same information '
          'on it. We never see a card and cannot recover one for you.',
    ),
    (
      heading: 'Crisis information',
      body:
          'The helpline numbers in the app are published by the organisations '
          'that run those lines. We check them before each release but we do '
          'not operate them and cannot guarantee they will answer. If a number '
          'in the app is wrong, write to us and we will correct it.',
    ),
    (
      heading: 'Pro',
      body:
          'Breathing, grounding, your first care card and the helplines are '
          'free forever and are never part of a paid plan. Pro adds more '
          'exercises, unlimited care cards, PDF export, a custom breathing '
          'pace and more guide voices. Pro is billed by the App Store or by '
          'Google Play, not by us; those stores handle payment, renewal, '
          'refunds and cancellation under their own terms.',
    ),
    (
      heading: 'If Pro ends',
      body:
          'Care cards you have already made stay on your device and stay '
          'readable, shareable and printable from a saved PDF. Making new '
          'cards, new exports and the Pro exercises pause until you renew. '
          'Nothing is deleted.',
    ),
    (
      heading: 'Reaching your person',
      body:
          'CalmCheck can place a call or open a pre-written message to the '
          'person you name, but it cannot reach anybody on your behalf and '
          'does not monitor whether you did. It is not an alarm system, a '
          'monitoring service, or a substitute for emergency services. If '
          'there is immediate danger to life, call your local emergency '
          'number.',
    ),
    (
      heading: 'What we promise, and what we do not',
      body:
          'We build this carefully and we test it. We cannot promise the app is '
          'free of faults, that a device will vibrate or speak when you expect '
          'it to, or that a reminder will arrive. To the extent the law allows, '
          'the app is provided as it is, and our liability is limited to what '
          'you paid for it.',
    ),
    (
      heading: 'Changes',
      body:
          'If these terms change, the new version ships with an app update and '
          'the date at the top changes with it.',
    ),
  ];

  // ---- Privacy policy ------------------------------------------------------

  static const List<({String heading, String body})> privacy = [
    (
      heading: 'The short version',
      body:
          'CalmCheck has no accounts and no servers of ours. Your care cards, '
          'your settings and everything you do in the app are stored on this '
          'device only. Nothing about you is uploaded and nothing is tracked. '
          'The one thing that ever uses the network is checking a Pro '
          'purchase with the store — and that carries no personal '
          'information.',
    ),
    (
      heading: 'What is stored, and where',
      body:
          'Care cards, any photo you attach to one, your settings and whether '
          'you have Pro are written to this app\'s own storage on this device. '
          'The app makes no network requests of its own except purchase '
          'validation, described under Payments below.',
    ),
    (
      heading: 'What we collect',
      body:
          'Nothing about you. There is no analytics SDK, no advertising '
          'identifier, no crash reporter and no telemetry of ours. We do not '
          'know how many times you opened the app, which exercises you used, '
          'or whether you ever opened the helplines screen. Two system-level '
          'exceptions are described under Payments and The camera.',
    ),
    (
      heading: 'The camera',
      body:
          'The camera is used only to read a care card\'s QR code, and only '
          'while the scanning screen is open. No image is saved and no image '
          'leaves the device. The code reader is Google\'s ML Kit barcode '
          'library, which runs entirely on the device but may report '
          'anonymous diagnostic counters to Google; it never sees card '
          'content as text or anything about you. If you would rather not '
          'grant the camera, you can open a card file instead.',
    ),
    (
      heading: 'Photos',
      body:
          'If you attach a photo to a care card, the file you pick is copied '
          'into the app\'s own storage. The original is untouched and the copy '
          'is never uploaded. A photo is deliberately left out of the QR code, '
          'because a code has to be small enough to scan.',
    ),
    (
      heading: 'Your person, and where you are',
      body:
          'You can name one person to reach from the breathing screen. Their '
          'name and number are stored on this device like everything else. '
          'Calling them hands the number to your dialler. Texting them opens '
          'your own messaging app with the message already written — CalmCheck '
          'cannot send a message by itself, on any phone.\n\nIf you leave '
          '"include where you are" on, CalmCheck asks your phone for your '
          'location at the moment you tap to text, adds a map link to that '
          'message, and forgets it. It is never asked for in the background, '
          'never stored, and never sent to us. Turn it off and the message '
          'goes without it.',
    ),
    (
      heading: 'When you share a card',
      body:
          'A QR code or a card file carries the whole card. Once you share it, '
          'whoever holds it can read it. That exchange happens between the two '
          'devices — by camera, by file, or on paper — and not through us.',
    ),
    (
      heading: 'Payments',
      body:
          'If you buy Pro, the App Store or Google Play handles the payment. '
          'The purchase is validated by RevenueCat, a service that checks '
          'store receipts; it sees a random identifier for this install and '
          'the purchase itself — never your name, your email, your payment '
          'details, or anything you put in the app. This is the only network '
          'connection the app makes.',
    ),
    (
      heading: 'Reminders',
      body:
          'If you turn reminders on, the reminder is scheduled by your phone '
          'and delivered by your phone. There is no push server and no message '
          'is sent from anywhere.',
    ),
    (
      heading: 'Backups',
      body:
          'CalmCheck opts out of automatic cloud backup on Android so that card '
          'content is not copied off the device by the system. That is why '
          'deleting the app deletes the data: save a PDF of any card you want '
          'to keep.',
    ),
    (
      heading: 'Children',
      body:
          'A care card is often about a child, and is written by the adult who '
          'looks after them. The app is intended for that adult. We do not '
          'knowingly collect anything from anyone, of any age, because we do '
          'not collect anything at all.',
    ),
    (
      heading: 'Your rights',
      body:
          'Because nothing is collected, there is nothing for us to show you, '
          'correct or erase. Everything the app holds is on your device, where '
          'you can read it, change it, export it or delete it yourself.',
    ),
    (
      heading: 'Getting in touch',
      body:
          'Write to $contact. An email you send us is an email we hold; we keep '
          'it only as long as it takes to answer you.',
    ),
  ];
}
