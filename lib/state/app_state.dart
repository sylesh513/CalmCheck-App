/// Everything the app remembers.
///
/// It lives on this device and nowhere else: no accounts, no servers, no
/// analytics, no crash reporter that ships card content. Settings sit in
/// preferences; care cards sit in their own versioned, atomically-written file
/// because they are the one thing here a person cannot recreate from memory in
/// a hurry.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/helplines.dart';
import '../data/sample_cards.dart';
import '../design/breath.dart';
import '../models/care_card.dart';
import '../models/personal_contact.dart';
import '../services/card_repository.dart';
import '../services/device_settings.dart';
import '../services/haptics.dart';
import '../services/purchases.dart';
import '../services/reminders.dart';

/// Only `free`, `subscribed` and `expired` are ever derived from real state.
/// `trial` exists because the design specifies the screen; the store owns
/// trials and this app has no server to ask about one.
enum ProStatus { free, trial, subscribed, expired }

enum OnboardingPath { myself, someoneElse, both }

/// PAY-01 ships as a three-way experiment. Assignment is made once per install
/// and then held, so the paywall never changes shape under someone.
enum PaywallVariant { annual, lifetime, giveback }

enum ThemeChoice { system, light, dark }

/// Reads an enum by index without trusting the stored value. Corrupt
/// preferences or a downgrade used to throw a RangeError inside `load()`,
/// which rejected the boot `Future.wait` and left a permanently blank screen.
T _enumAt<T>(List<T> values, int? index, T fallback) =>
    (index != null && index >= 0 && index < values.length)
    ? values[index]
    : fallback;

class AppState extends ChangeNotifier {
  AppState._(this._prefs, this._cardRepository, this.purchases);

  final SharedPreferences _prefs;
  final CardRepository _cardRepository;
  final PurchaseService purchases;

  /// Serialises card writes so two quick edits cannot interleave.
  Future<void> _writeChain = Future<void>.value();

  static Future<AppState> load({
    CardRepository? cardRepository,
    PurchaseService? purchaseService,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final repository = cardRepository ?? CardRepository();
    final purchases = purchaseService ?? PurchaseService();

    final state = AppState._(prefs, repository, purchases);
    state._readSettings();
    await state._readCards();

    // The store connection is opened alongside the first frame. Nothing about
    // reaching the panic action depends on it.
    unawaited(purchases.init(prefs).then((_) => state.notifyListeners()));
    purchases.addListener(state.notifyListeners);

    return state;
  }

  // ---- Onboarding -------------------------------------------------------
  bool _onboarded = false;
  OnboardingPath? _path;

  bool get onboarded => _onboarded;
  OnboardingPath? get path => _path;

  void setPath(OnboardingPath value) {
    _path = value;
    _prefs.setInt('path', value.index);
    notifyListeners();
  }

  void completeOnboarding() {
    _onboarded = true;
    _prefs.setBool('onboarded', true);
    notifyListeners();
  }

  /// The first-cycle helper on PANIC-02 appears once, ever, then never again.
  bool _pacerHelperSeen = false;
  bool get pacerHelperSeen => _pacerHelperSeen;

  void markPacerHelperSeen() {
    if (_pacerHelperSeen) return;
    _pacerHelperSeen = true;
    _prefs.setBool('pacerHelperSeen', true);
    // No notify: this must not rebuild the pacer mid-breath.
  }

  // ---- Settings ---------------------------------------------------------
  bool _guideVoice = true;
  bool _vibration = true;
  bool _reminders = false;
  bool _reduceMotion = false;
  double _textScale = 1.0;

  /// Chosen by hand on CRISIS-01 or in Settings. Null means "follow the phone".
  String? _regionOverride;

  /// Where the phone says it is. Filled in at startup.
  String? _detectedRegion;
  ThemeChoice _themeChoice = ThemeChoice.system;
  BreathCadence _cadence = BreathCadence.standard;

  bool get guideVoice => _guideVoice;
  bool get vibration => _vibration;
  bool get reminders => _reminders;
  bool get reduceMotion => _reduceMotion;
  double get textScale => _textScale;
  ThemeChoice get themeChoice => _themeChoice;
  BreathCadence get cadence => _cadence;

  /// Null only when the phone's country is not in the dataset and nothing has
  /// been chosen by hand — the screen then offers findahelpline.com instead of
  /// a number nobody checked.
  HelplineRegion? get region =>
      Helplines.instance.forCode(_regionOverride ?? _detectedRegion);

  /// True when the region came from the phone rather than from a choice.
  bool get regionIsDetected => _regionOverride == null;

  String? get regionCode => _regionOverride ?? _detectedRegion;

  set guideVoice(bool v) => _setBool('guideVoice', v, (x) => _guideVoice = x);

  set vibration(bool v) {
    _setBool('vibration', v, (x) => _vibration = x);
    CcHaptics.instance.enabled = v;
  }

  /// Turning reminders on asks for the notification permission first. If the
  /// answer is no, the switch goes back to off rather than claiming a reminder
  /// that will never arrive.
  Future<bool> setReminders(bool value) async {
    if (!value) {
      _setBool('reminders', false, (x) => _reminders = x);
      await CcReminders.instance.cancel();
      return false;
    }
    final granted = await CcReminders.instance.requestPermission();
    _setBool('reminders', granted, (x) => _reminders = x);
    if (granted) await CcReminders.instance.schedule();
    return granted;
  }

  set reduceMotion(bool v) =>
      _setBool('reduceMotion', v, (x) => _reduceMotion = x);

  set textScale(double v) {
    _textScale = v.clamp(1.0, 2.0);
    _prefs.setDouble('textScale', _textScale);
    notifyListeners();
  }

  set themeChoice(ThemeChoice v) {
    _themeChoice = v;
    _prefs.setInt('themeChoice', v.index);
    notifyListeners();
  }

  void setRegion(String code) {
    _regionOverride = code;
    _prefs.setString('regionOverride', code);
    notifyListeners();
  }

  /// Back to following the phone.
  void clearRegionOverride() {
    _regionOverride = null;
    _prefs.remove('regionOverride');
    notifyListeners();
  }

  /// Asks the phone where it is. The network's country beats the SIM's, which
  /// beats the language locale.
  Future<void> refreshDetectedRegion() async {
    final fromNetwork = await deviceCountryCode();
    final next = fromNetwork ?? _localeCountry();
    if (next == _detectedRegion) return;
    _detectedRegion = next;
    notifyListeners();
  }

  /// Pro only. The setter clamps to `exhale >= inhale` — no preset can offer
  /// the reverse — and the screen prints the reason when it clamps.
  void setCadence(BreathCadence value) {
    _cadence = BreathCadence(
      inhale: value.inhale,
      hold: value.hold,
      exhale: value.exhale < value.inhale ? value.inhale : value.exhale,
      rest: value.rest,
    );
    _prefs.setString(
      'cadence',
      jsonEncode({
        'i': _cadence.inhale,
        'h': _cadence.hold,
        'e': _cadence.exhale,
        'r': _cadence.rest,
      }),
    );
    notifyListeners();
  }

  void _setBool(String key, bool value, void Function(bool) assign) {
    assign(value);
    _prefs.setBool(key, value);
    notifyListeners();
  }

  // ---- Your person ------------------------------------------------------
  PersonalContact? _person;

  /// The one contact that is yours rather than a care card's. Null until
  /// somebody sets it, and the panic flow shows nothing extra until then.
  PersonalContact? get person => _person;

  /// Optional. Used so a message can read "Sam is having a panic attack"
  /// rather than "I am", for anyone who would rather it did.
  String? _senderName;
  String? get senderName => _senderName;

  void setPerson(PersonalContact? contact) {
    _person = contact != null && contact.isUsable ? contact : null;
    if (_person == null) {
      _prefs.remove('person');
    } else {
      _prefs.setString('person', jsonEncode(_person!.toJson()));
    }
    notifyListeners();
  }

  void setSenderName(String? name) {
    final trimmed = (name ?? '').trim();
    _senderName = trimmed.isEmpty ? null : trimmed;
    if (_senderName == null) {
      _prefs.remove('senderName');
    } else {
      _prefs.setString('senderName', _senderName!);
    }
    notifyListeners();
  }

  /// Whether the message should offer to carry a location.
  bool _shareLocation = true;
  bool get shareLocation => _shareLocation;
  set shareLocation(bool v) =>
      _setBool('shareLocation', v, (x) => _shareLocation = x);

  // ---- Pro --------------------------------------------------------------
  PaywallVariant _paywallVariant = PaywallVariant.annual;
  PaywallVariant get paywallVariant => _paywallVariant;

  bool _sponsorApplicationSent = false;
  bool get sponsorApplicationSent => _sponsorApplicationSent;

  /// True only when the store has products to sell. A build published before
  /// the products exist shows no paywall at all.
  bool get proOffered => purchases.availability == StoreAvailability.available;

  /// Pro features are open only when the store positively reported that there
  /// is nothing to sell, so a build published before the products exist is a
  /// complete app rather than a crippled one. A store we could not reach, or
  /// one we have not asked yet, grants nothing — otherwise an offline first
  /// launch silently unlocked every paid feature.
  bool get isPro =>
      purchases.isPro ||
      purchases.availability == StoreAvailability.unavailable ||
      purchases.availability == StoreAvailability.unknown;

  ProStatus get proStatus {
    if (purchases.entitlement.active) return ProStatus.subscribed;
    if (purchases.entitlement.everPurchased) return ProStatus.expired;
    return ProStatus.free;
  }

  void submitSponsorApplication() {
    _sponsorApplicationSent = true;
    _prefs.setBool('sponsorApplication', true);
    notifyListeners();
  }

  void withdrawSponsorApplication() {
    _sponsorApplicationSent = false;
    _prefs.setBool('sponsorApplication', false);
    notifyListeners();
  }

  // ---- Care cards -------------------------------------------------------
  List<CareCardData> _cards = [];

  List<CareCardData> get cards => List.unmodifiable(_cards);

  /// The first care-card contact with a number on it. The panic flow falls back
  /// to this when nobody has named a personal contact, so somebody in the middle
  /// of an attack still has a person to reach rather than an empty screen.
  ({CareContact contact, String cardName})? get firstCareContact {
    for (final card in _cards) {
      for (final c in card.call) {
        if (c.hasNumber) return (contact: c, cardName: card.name);
      }
    }
    return null;
  }

  CardStoreHealth get cardStoreHealth => _cardRepository.health;
  String? get quarantinedCardFile => _cardRepository.quarantinedPath;

  /// The first card is free forever. Pro is what unlocks the rest — and an
  /// expired subscription never takes an existing card away.
  bool get canCreateCard => isPro || _cards.where((c) => !c.readOnly).isEmpty;

  /// PDF export is Pro. Reading, calling and sharing a card are not.
  bool get canExportPdf => isPro;

  CareCardData? cardById(String id) {
    for (final c in _cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  void upsertCard(CareCardData card) {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index >= 0) {
      _cards[index] = card;
    } else {
      _cards.add(card);
    }
    _persistCards();
    notifyListeners();
  }

  void deleteCard(String id) {
    _cards.removeWhere((c) => c.id == id);
    _persistCards();
    notifyListeners();
  }

  /// Set when a write fails, so Settings can say so rather than letting
  /// someone believe an edit was saved.
  Object? lastSaveError;

  void _persistCards() {
    final snapshot = List<CareCardData>.from(_cards);
    _writeChain = _writeChain
        .then((_) => _cardRepository.save(snapshot))
        .then(
          (_) {
            if (lastSaveError != null) {
              lastSaveError = null;
              notifyListeners();
            }
          },
          // A failed write must not poison the chain: the next edit still gets its
          // chance to land.
          onError: (Object e) {
            lastSaveError = e;
            notifyListeners();
          },
        );
  }

  /// Awaits every queued write. Called before the app is backgrounded so an
  /// edit is never lost to a process kill.
  Future<void> flush() => _writeChain;

  // ---- Load -------------------------------------------------------------
  void _readSettings() {
    _onboarded = _prefs.getBool('onboarded') ?? false;
    final pathIndex = _prefs.getInt('path');
    _path = pathIndex == null
        ? null
        : _enumAt(
            OnboardingPath.values,
            pathIndex,
            OnboardingPath.values.first,
          );
    _pacerHelperSeen = _prefs.getBool('pacerHelperSeen') ?? false;

    _guideVoice = _prefs.getBool('guideVoice') ?? true;
    _vibration = _prefs.getBool('vibration') ?? true;
    _reminders = _prefs.getBool('reminders') ?? false;
    _reduceMotion = _prefs.getBool('reduceMotion') ?? false;
    _textScale = _prefs.getDouble('textScale') ?? 1.0;
    _themeChoice = _enumAt(
      ThemeChoice.values,
      _prefs.getInt('themeChoice'),
      ThemeChoice.values.first,
    );
    _regionOverride = _prefs.getString('regionOverride');
    // The locale is the immediate answer; the network is asked a moment later.
    _detectedRegion = _localeCountry();
    _sponsorApplicationSent = _prefs.getBool('sponsorApplication') ?? false;
    _senderName = _prefs.getString('senderName');
    _shareLocation = _prefs.getBool('shareLocation') ?? true;

    final rawPerson = _prefs.getString('person');
    if (rawPerson != null) {
      try {
        final decoded = PersonalContact.fromJson(
          jsonDecode(rawPerson) as Map<String, dynamic>,
        );
        if (decoded.isUsable) _person = decoded;
      } catch (_) {
        _person = null;
      }
    }

    final rawCadence = _prefs.getString('cadence');
    if (rawCadence != null) {
      try {
        final m = jsonDecode(rawCadence) as Map<String, dynamic>;
        _cadence = BreathCadence(
          inhale: (m['i'] as num).toDouble(),
          hold: (m['h'] as num).toDouble(),
          exhale: (m['e'] as num).toDouble(),
          rest: (m['r'] as num).toDouble(),
        );
      } catch (_) {
        _cadence = BreathCadence.standard;
      }
    }

    final assigned = _prefs.getInt('paywallVariant');
    if (assigned == null) {
      _paywallVariant =
          PaywallVariant.values[DateTime.now().microsecondsSinceEpoch %
              PaywallVariant.values.length];
      _prefs.setInt('paywallVariant', _paywallVariant.index);
    } else {
      _paywallVariant = _enumAt(
        PaywallVariant.values,
        assigned,
        PaywallVariant.values.first,
      );
    }

    CcHaptics.instance.enabled = _vibration;
  }

  Future<void> _readCards() async {
    _cards = List<CareCardData>.from(await _cardRepository.load(_prefs));

    // A brand-new install starts with the two example cards, so the second
    // half of the app is legible before anyone has typed anything. A person
    // who deletes them is not given them back.
    final seeded = _prefs.getBool('seeded') ?? false;
    if (_cards.isEmpty && !seeded) {
      _cards = starterCards();
      _prefs.setBool('seeded', true);
      _persistCards();
    } else if (!seeded) {
      _prefs.setBool('seeded', true);
    }
  }

  /// The region the phone's own settings report, which on iOS is the closest
  /// thing available.
  String? _localeCountry() {
    for (final locale in PlatformDispatcher.instance.locales) {
      final code = locale.countryCode;
      if (code != null && code.length == 2) return code.toUpperCase();
    }
    return PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
  }

  @override
  void dispose() {
    purchases.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Reaches the single AppState from anywhere below [AppScope].
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this widget');
    return scope!.notifier!;
  }

  /// Reads without subscribing — for callbacks that only write.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this widget');
    return scope!.notifier!;
  }
}

extension AppStateAccess on BuildContext {
  AppState get app => AppScope.of(this);
  AppState get appRead => AppScope.read(this);
}
