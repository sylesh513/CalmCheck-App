/// Route names. The panic flow is exclusive: once you are in it there is no
/// navigation chrome, and every route out of it is deliberate.
class Routes {
  const Routes._();

  static const boot = '/';
  static const onboardingPromise = '/onboarding/promise';
  static const onboardingPaths = '/onboarding/paths';
  static const onboardingPermissions = '/onboarding/permissions';
  static const onboardingScope = '/onboarding/scope';
  static const onboardingFirstCard = '/onboarding/first-card';

  static const home = '/home';

  static const panicPacer = '/panic';
  static const panicGrounding = '/panic/grounding';
  static const panicCheckIn = '/panic/check-in';
  static const panicRise = '/panic/rise';

  static const cardView = '/card';
  static const cardEdit = '/card/edit';
  static const cardShare = '/card/share';
  static const cardScan = '/card/scan';
  static const cardEmpty = '/card/empty';

  static const exercises = '/exercises';
  static const exerciseDetail = '/exercises/detail';

  static const crisis = '/crisis';

  static const paywall = '/pro';
  static const sponsored = '/pro/sponsored';
  static const manageSubscription = '/pro/manage';
  static const lifecycle = '/pro/lifecycle';

  static const settings = '/settings';
  static const privacy = '/settings/privacy';
  static const about = '/settings/about';
  static const display = '/settings/display';
  static const breathingPace = '/settings/pace';
  static const helplineRegion = '/settings/region';
  static const yourPerson = '/settings/your-person';

  static const terms = '/legal/terms';
  static const privacyPolicy = '/legal/privacy';

  static const gallery = '/design';
}
