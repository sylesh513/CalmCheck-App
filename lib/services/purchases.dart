/// Pro, bought from the App Store or Play Billing, validated by RevenueCat.
///
/// RevenueCat is the single network service this app talks to, and it only
/// ever sees anonymous purchase state — an install-scoped random id and the
/// store receipt. No account, no email, no card content, no usage data. The
/// promise on the privacy screen is that nothing about a *person* leaves the
/// device, and this keeps it.
///
/// Two rules this file exists to keep:
///
/// 1. **Pro never evaporates offline.** Entitlement is cached (by this file
///    and by the RevenueCat SDK's own on-device cache) and is only withdrawn
///    when the backend explicitly answers "nothing active" — never because a
///    query failed.
/// 2. **If the store has no products, Pro is not offered at all.** A build
///    published before the products exist shows no paywall rather than a
///    paywall that cannot charge.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'revenuecat_keys.dart';

/// The RevenueCat entitlement that gates every Pro feature. Must match the
/// entitlement identifier configured in the RevenueCat dashboard.
const String proEntitlementId = 'pro';

/// Must match the product identifiers configured in App Store Connect, the
/// Play Console, and attached to the RevenueCat offering. See
/// `docs/store-submission.md`.
class ProProductIds {
  const ProProductIds._();

  static const String annual = 'calmcheck_pro_annual';
  static const String monthly = 'calmcheck_pro_monthly';
  static const String lifetime = 'calmcheck_pro_lifetime';

  static const Set<String> all = {annual, monthly, lifetime};

  /// Lifetime is a one-off; the other two renew.
  static bool isSubscription(String id) => id != lifetime;
}

enum StoreAvailability {
  /// Not asked yet.
  unknown,

  /// The store answered and has nothing to sell here: no usable store, no
  /// RevenueCat key in the build, or the products are not configured yet. Pro
  /// is not offered, and the app opens up rather than shipping crippled.
  unavailable,

  /// The store could not be reached or the query threw. This is NOT the same
  /// as "nothing to sell" — treating it that way handed every Pro feature to
  /// anyone whose first launch happened to be offline.
  unreachable,

  /// Products came back. Pro can be sold.
  available,
}

enum PurchaseFlowState { idle, pending, restoring, error }

@immutable
class ProProduct {
  const ProProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    this.package,
  });

  final String id;
  final String title;

  /// Localised and formatted by the store. Never construct a price string.
  final String price;
  final double rawPrice;
  final String currencyCode;

  /// The RevenueCat package behind this row. Null only in tests.
  final Package? package;

  bool get isSubscription => ProProductIds.isSubscription(id);
}

/// What the app believes about entitlement, and when it last heard from the
/// store.
@immutable
class Entitlement {
  const Entitlement({
    required this.active,
    this.productId,
    this.lastVerified,
    this.everPurchased = false,
  });

  final bool active;
  final String? productId;
  final DateTime? lastVerified;

  /// True once a purchase has been seen, so an expired subscriber can be told
  /// what changed rather than shown a first-time paywall.
  final bool everPurchased;

  static const Entitlement none = Entitlement(active: false);

  Entitlement copyWith({
    bool? active,
    String? productId,
    DateTime? lastVerified,
    bool? everPurchased,
  }) => Entitlement(
    active: active ?? this.active,
    productId: productId ?? this.productId,
    lastVerified: lastVerified ?? this.lastVerified,
    everPurchased: everPurchased ?? this.everPurchased,
  );
}

class PurchaseService extends ChangeNotifier {
  PurchaseService()
    : _forcedAvailability = null,
      _forcedPro = false;

  /// A service that never touches a store. Tests run on a host where the
  /// billing plugin registers but cannot connect, and where an unhandled
  /// connection error would land in whichever test happens to be running.
  @visibleForTesting
  PurchaseService.forTest({
    StoreAvailability availability = StoreAvailability.unavailable,
    bool pro = false,
    this.products = const [],
  }) : _forcedAvailability = availability,
       _forcedPro = pro {
    // Applied at construction, not at init: a test asserts on gating before
    // any async work has had a chance to run.
    this.availability = availability;
    if (pro) entitlement = const Entitlement(active: true, everPurchased: true);
  }

  final StoreAvailability? _forcedAvailability;
  final bool _forcedPro;

  SharedPreferences? _prefs;
  bool _configured = false;
  bool _disposed = false;
  void Function(CustomerInfo)? _customerInfoListener;

  StoreAvailability availability = StoreAvailability.unknown;
  PurchaseFlowState flow = PurchaseFlowState.idle;
  String? errorMessage;

  List<ProProduct> products = const [];
  Entitlement entitlement = Entitlement.none;

  /// Set when a purchase completes, so the caller can show the confirmation.
  bool justPurchased = false;

  static const String _keyActive = 'proActive';
  static const String _keyProduct = 'proProductId';
  static const String _keyVerified = 'proVerifiedAt';
  static const String _keyEver = 'proEverPurchased';

  bool get isPro => entitlement.active;

  /// The only gate the UI should consult before showing anything about Pro.
  bool get canSellPro => availability == StoreAvailability.available;

  ProProduct? productFor(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// The per-platform RevenueCat public key. Empty means "not configured for
  /// this build", which reads as a store with nothing to sell.
  String get _apiKey => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => RevenueCatKeys.apple,
    TargetPlatform.android => RevenueCatKeys.google,
    _ => '',
  };

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _readCachedEntitlement(prefs);

    final forced = _forcedAvailability;
    if (forced != null) {
      availability = forced;
      if (_forcedPro) {
        entitlement = const Entitlement(active: true, everPurchased: true);
      }
      _notify();
      return;
    }

    if (kIsWeb || _apiKey.isEmpty) {
      availability = StoreAvailability.unavailable;
      _notify();
      return;
    }

    try {
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _configured = true;
    } catch (_) {
      // No plugin on this host (tests, desktop), or a malformed key. Either
      // way there is nothing to sell here; the app opens up.
      availability = StoreAvailability.unavailable;
      _notify();
      return;
    }

    // Every CustomerInfo the SDK hears about — purchase, renewal, refund,
    // restore on another screen — lands here. This is what both grants and
    // withdraws Pro, on every platform, with no timers involved.
    _customerInfoListener = _applyCustomerInfo;
    Purchases.addCustomerInfoUpdateListener(_customerInfoListener!);

    await refresh();
  }

  /// (Re)ask RevenueCat for products and entitlement. Called at init, and
  /// again from the paywall when a previous attempt left the store
  /// unreachable — a launch without network must not disable buying Pro for
  /// the whole session.
  Future<void> refresh() async {
    if (!_configured) return;

    try {
      final offerings = await Purchases.getOfferings();
      final packages = <Package>[
        ...?offerings.current?.availablePackages,
        for (final o in offerings.all.values)
          if (o.identifier != offerings.current?.identifier)
            ...o.availablePackages,
      ];

      final found = <ProProduct>[];
      final seen = <String>{};
      for (final pkg in packages) {
        final sp = pkg.storeProduct;
        final id = _baseProductId(sp.identifier);
        if (!ProProductIds.all.contains(id) || !seen.add(id)) continue;
        found.add(
          ProProduct(
            id: id,
            title: sp.title,
            price: sp.priceString,
            rawPrice: sp.price,
            currencyCode: sp.currencyCode,
            package: pkg,
          ),
        );
      }
      // Annual first, then monthly, then lifetime — the paywall reorders for
      // the lifetime-anchor variant.
      found.sort((a, b) => _rank(a.id).compareTo(_rank(b.id)));

      products = found;
      availability = found.isEmpty
          ? StoreAvailability.unavailable
          : StoreAvailability.available;
    } catch (_) {
      products = const [];
      // A failed query is not evidence that there is nothing to sell.
      availability = StoreAvailability.unreachable;
    }
    _notify();

    // Refresh entitlement from RevenueCat's cache (and network when it can).
    // Failure is silent: the cached entitlement stands — rule 1.
    try {
      _applyCustomerInfo(await Purchases.getCustomerInfo());
    } catch (_) {}
  }

  /// Play's product ids arrive as `productId:basePlanId` on Android. The app
  /// keys everything off the plain product id.
  static String _baseProductId(String id) => id.split(':').first;

  static int _rank(String id) => switch (id) {
    ProProductIds.annual => 0,
    ProProductIds.monthly => 1,
    _ => 2,
  };

  Future<void> buy(String productId) async {
    final product = productFor(productId);
    final package = product?.package;
    if (product == null || package == null) return;

    flow = PurchaseFlowState.pending;
    errorMessage = null;
    _notify();

    try {
      // On Android, switching between subscription plans must be a plan
      // change, not a second parallel subscription — otherwise a monthly
      // subscriber who taps annual is double-billed.
      StoreProductChangeInfo? change;
      final currentId = entitlement.productId;
      if (defaultTargetPlatform == TargetPlatform.android &&
          entitlement.active &&
          currentId != null &&
          currentId != productId &&
          ProProductIds.isSubscription(currentId) &&
          product.isSubscription) {
        change = StoreProductChangeInfo(_baseProductId(currentId));
      }

      final result = await Purchases.purchase(
        PurchaseParams.package(package, productChangeInfo: change),
      );
      _applyCustomerInfo(result.customerInfo, fromPurchase: true);
      flow = PurchaseFlowState.idle;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        // Backing out is not a failure and gets no error copy.
        flow = PurchaseFlowState.idle;
      } else {
        flow = PurchaseFlowState.error;
        errorMessage = _friendlyError(code);
      }
    } catch (e) {
      flow = PurchaseFlowState.error;
      errorMessage = _friendlyError(null);
    }
    _notify();
  }

  Future<void> restore() async {
    if (!_configured) return;
    flow = PurchaseFlowState.restoring;
    errorMessage = null;
    _notify();
    try {
      // Answers directly — no stream to wait on, no settle timer to race.
      final info = await Purchases.restorePurchases();
      _applyCustomerInfo(info);
      flow = PurchaseFlowState.idle;
    } on PlatformException catch (e) {
      flow = PurchaseFlowState.error;
      errorMessage = _friendlyError(PurchasesErrorHelper.getErrorCode(e));
    } catch (_) {
      flow = PurchaseFlowState.error;
      errorMessage = _friendlyError(null);
    }
    _notify();
  }

  /// The single writer of entitlement. Called only with a definitive answer
  /// from RevenueCat, so withdrawing here never happens because of a failed
  /// query — on any platform.
  void _applyCustomerInfo(CustomerInfo info, {bool fromPurchase = false}) {
    final active = info.entitlements.active[proEntitlementId];
    final everHeld =
        entitlement.everPurchased ||
        info.entitlements.all.containsKey(proEntitlementId);

    final next = Entitlement(
      active: active != null,
      productId: active != null
          ? _baseProductId(active.productIdentifier)
          : entitlement.productId,
      lastVerified: DateTime.now(),
      everPurchased: everHeld || active != null,
    );

    final becamePro = !entitlement.active && next.active;
    _persistEntitlement(next);
    if (fromPurchase && becamePro) {
      justPurchased = true;
      _notify();
    }
  }

  void _readCachedEntitlement(SharedPreferences prefs) {
    entitlement = Entitlement(
      active: prefs.getBool(_keyActive) ?? false,
      productId: prefs.getString(_keyProduct),
      lastVerified: DateTime.tryParse(prefs.getString(_keyVerified) ?? ''),
      everPurchased: prefs.getBool(_keyEver) ?? false,
    );
  }

  void _persistEntitlement(Entitlement next) {
    entitlement = next;
    final prefs = _prefs;
    if (prefs != null) {
      // Awaited as a unit so a failed write is at least visible in the zone
      // log rather than silently dropped mid-sequence.
      unawaited(
        Future.wait<bool>([
          prefs.setBool(_keyActive, next.active),
          prefs.setBool(_keyEver, next.everPurchased),
          if (next.productId != null)
            prefs.setString(_keyProduct, next.productId!),
          if (next.lastVerified != null)
            prefs.setString(
              _keyVerified,
              next.lastVerified!.toIso8601String(),
            ),
        ]),
      );
    }
    _notify();
  }

  /// Errors say what happened and never apologise. "Nothing has been charged"
  /// is the part that matters to somebody staring at a failed purchase.
  String _friendlyError(PurchasesErrorCode? code) {
    if (code == PurchasesErrorCode.networkError ||
        code == PurchasesErrorCode.offlineConnectionError) {
      return 'The store could not be reached. Nothing has been charged. '
          'Everything free keeps working without it.';
    }
    return "That purchase didn't go through. Nothing has been charged. Try "
        'again, or restore a previous purchase.';
  }

  void clearError() {
    if (flow != PurchaseFlowState.error) return;
    flow = PurchaseFlowState.idle;
    errorMessage = null;
    _notify();
  }

  void acknowledgePurchase() {
    justPurchased = false;
  }

  /// Listeners can outlive an async gap; a notification after dispose is an
  /// assertion in debug and a wasted call in release.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    final listener = _customerInfoListener;
    if (listener != null) {
      Purchases.removeCustomerInfoUpdateListener(listener);
    }
    super.dispose();
  }
}
