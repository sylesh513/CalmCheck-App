/// Canonical copy. One string, one place — so the same words appear on every
/// surface that hits the same condition.
///
/// Voice rules: plain verbs, sentence case, second person, short lines. No
/// exclamation marks anywhere in the app. Errors say what happened and never
/// apologise. Banned: journey, mindful, tribe, warrior, oops, sorry. Banned for
/// policy: diagnose, treat, therapy, cure, prescribe, medical grade.
library;

class StateCopy {
  const StateCopy._();

  // ---- Permission denied ----
  static const cameraLabel = 'Camera off';
  static const cameraHeadline = "CalmCheck can't see the code";
  static const cameraDirection =
      'CalmCheck needs the camera to scan a code. You can turn this on in '
      'Settings, or open a card file instead.';
  static const cameraPrimary = 'Open Settings';
  static const cameraSecondary = 'Open a card file';

  static const notificationsLabel = 'Notifications off';
  static const notificationsHeadline = "Reminders won't arrive";
  static const notificationsDirection =
      'CalmCheck needs notifications to send a practice reminder. You can turn '
      'this on in Settings, or practise without reminders.';
  static const notificationsPrimary = 'Open Settings';
  static const notificationsSecondary = 'Carry on without reminders';

  // ---- Purchase failure ----
  static const purchaseLabel = 'Purchase';
  static const purchaseHeadline = "Purchase didn't complete";
  static const purchaseDirection =
      "That purchase didn't go through. Nothing has been charged. Try again, "
      'or restore a previous purchase.';
  static const purchasePrimary = 'Try again';
  static const purchaseSecondary = 'Restore purchase';

  // ---- Empty states: a ghosted form of the missing thing, one line of
  // direction, one action. Never an apology, never a shrug. ----
  static const emptyCardsLabel = 'Care cards';
  static const emptyCardsHeadline = 'No care cards yet.';
  static const emptyCardsDirection =
      'A care card holds everything someone would need to help a person you '
      'look after — what to do, what to avoid, who to call. It works offline '
      'and you can share it with a QR code.';
  static const emptyCardsPrimary = 'Create your first card';

  static const emptyExercisesLabel = 'Exercises';
  static const emptyExercisesHeadline = 'Nothing unlocked yet';
  static const emptyExercisesDirection =
      'Every exercise is included with Pro. Breathing and grounding stay free.';
  static const emptyExercisesPrimary = 'See what Pro includes';

  static const emptyScanLabel = 'Scan';
  static const emptyScanHeadline = 'Not a CalmCheck card';
  static const emptyScanDirection =
      "That code isn't a CalmCheck card. Point the camera at a CalmCheck QR code.";
  static const emptyScanPrimary = 'Scan again';

  static const noCameraLabel = 'No camera';
  static const noCameraDirection =
      "This device doesn't have a camera CalmCheck can use. You can open a "
      'card file instead.';

  // ---- Destructive confirmation ----
  static const deleteCardTitle = 'Delete this card?';
  static const deleteCardBody =
      "This can't be undone. Nothing is stored anywhere else.";
  static const deleteCardConfirm = 'Delete card';
  static const deleteCardCancel = 'Keep card';

  // ---- The wellness scope, stated as respect rather than legal cover ----
  static const disclaimerBody =
      'CalmCheck offers breathing and grounding exercises and a place to keep '
      'care information. It is not a medical device. It does not diagnose or '
      'treat any condition, and it is not a substitute for professional care.';
  static const disclaimerDanger =
      'If you or someone else is in danger right now, call emergency services.';
}

/// PAY-01..04. Nothing on any of these screens may imply that safety features
/// are gated; the free-forever line is required on the paywall.
class ProCopy {
  const ProCopy._();

  static const int sponsorEvery = 12;
  static const int sponsoredSoFar = 37;
  static const int licencesAvailable = 4;

  /// Shown only in the design reference, where there is no store to ask.
  /// Every price a person can actually be charged comes from the store, in
  /// their own currency — never from a constant in this file.
  static const String samplePriceAnnual = '\$19.99';
  static const String samplePriceMonthly = '\$2.99';
  static const String samplePriceLifetime = '\$59.99';

  static const freeForever =
      'Breathing, grounding, your first care card, and the helplines are free '
      'forever. Pro adds more of everything else.';

  static const List<String> proList = [
    'Every exercise',
    'Unlimited care cards',
    'Save and print cards as PDF',
    'Set your own breathing pace',
    'More guide voices',
  ];

  /// The store owns the trial. This line is shown only for a product the store
  /// reports an introductory offer on.
  static String trialLine(String price) =>
      '7 days free, then $price a year. Cancel any time.';

  static String plainPriceLine(String price) =>
      '$price a year. Cancel any time.';

  /// Required on any screen selling an auto-renewing subscription.
  static const autoRenewDisclosure =
      'CalmCheck Pro renews automatically. Payment is charged to your store '
      'account when you confirm the purchase, and again each period unless you '
      'cancel at least 24 hours before it ends. Manage or cancel it in your '
      'store account settings at any time. Lifetime is a single payment and '
      'does not renew.';

  static const storeUnavailable =
      'Pro is not available on this device right now. Everything free — '
      'breathing, grounding, your care cards and the helplines — keeps working '
      'exactly as it does.';

  static const giveBack =
      'Every $sponsorEvery subscriptions pays for a free year of Pro for '
      "someone who can't afford it. $sponsoredSoFar sponsored so far.";

  static const purchaseError = StateCopy.purchaseDirection;

  static const sponsoredBody =
      'Pro costs money to build, and the people who most need a care card '
      'often have the least to spend. Every $sponsorEvery subscriptions funds '
      'a free year for someone who asks.';

  static const sponsoredLimit =
      'The pool is small and it runs out. When it does, this page says so.';
}
