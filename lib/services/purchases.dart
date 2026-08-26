/// Pro, bought from the App Store or Play Billing directly.
///
/// There is no subscription service in front of this and no receipt server
/// behind it, because the promise on the privacy screen is that nothing about a
/// person leaves the device. The cost of that is stated plainly in
/// `docs/store-submission.md`: entitlement is verified against the store the
/// device is already signed in to, and nowhere else.
///
/// Two rules this file exists to keep:
///
/// 1. **Pro never evaporates offline.** Entitlement is cached and is only
///    withdrawn when the store explicitly answers "nothing active" — never
///    because a query failed.
/// 2. **If the store has no products, Pro is not offered at all.** A build
///    published before the products exist shows no paywall rather than a
///    paywall that cannot charge.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Must match the product identifiers configured in App Store Connect and the
/// Play Console. See `docs/store-submission.md`.
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

  /// The store answered and has nothing to sell here: no usable store, or the
  /// products are not configured yet. Pro is not offered, and the app opens up
  /// rather than shipping crippled.
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
    required this.details,
  });

  final String id;
  final String title;

  /// Localised and formatted by the store. Never construct a price string.
  final String price;
  final double rawPrice;
  final String currencyCode;
  final ProductDetails details;

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
  PurchaseService({InAppPurchase? iap})
    : _injected = iap,
      _forcedAvailability = null,
      _forcedPro = false;

  /// A service that never touches a store. Tests run on a host where the
  /// billing plugin registers but cannot connect, and where an unhandled
  /// connection error would land in whichever test happens to be running.
  @visibleForTesting
  PurchaseService.forTest({
    StoreAvailability availability = StoreAvailability.unavailable,
    bool pro = false,
    this.products = const [],
  }) : _injected = null,
       _forcedAvailability = availability,
       _forcedPro = pro {
    // Applied at construction, not at init: a test asserts on gating before
    // any async work has had a chance to run.
    this.availability = availability;
    if (pro) entitlement = const Entitlement(active: true, everPurchased: true);
  }

  final InAppPurchase? _injected;
  final StoreAvailability? _forcedAvailability;
  final bool _forcedPro;

  /// Resolved lazily: on a host without the plugin registered — a test, a
  /// desktop build — reaching for the instance throws, and that must leave the
  /// app running with Pro simply not for sale.
  InAppPurchase? _resolved;

  InAppPurchase? get _store {
    if (_injected != null) return _injected;
    if (_resolved != null) return _resolved;
    try {
      return _resolved = InAppPurchase.instance;
    } catch (_) {
      return null;
    }
  }

  StreamSubscription<List<PurchaseDetails>>? _sub;
  SharedPreferences? _prefs;

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

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _readCachedEntitlement(prefs);

    final forced = _forcedAvailability;
    if (forced != null) {
      availability = forced;
      if (_forcedPro) {
        entitlement = const Entitlement(active: true, everPurchased: true);
      }
      notifyListeners();
      return;
    }

    final iap = _store;
    if (iap == null) {
      availability = StoreAvailability.unavailable;
      notifyListeners();
      return;
    }

    // Listen before querying: a pending purchase from a previous launch can
    // arrive the moment the connection opens.
    _sub = iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        flow = PurchaseFlowState.error;
        errorMessage = _friendlyError(e);
        notifyListeners();
      },
    );

    bool storeReady = false;
    try {
      storeReady = await iap.isAvailable();
    } catch (_) {
      storeReady = false;
    }
    if (!storeReady) {
      availability = StoreAvailability.unavailable;
      notifyListeners();
      return;
    }

    await _loadProducts();

    // Re-check entitlement against the store. Failures here are silent: the
    // cached entitlement stands.
    //
    // iOS is excluded on purpose. StoreKit's restore can present an Apple-ID
    // sign-in sheet, and a sign-in prompt on a cold start of a wellness app is
    // both bad UX and a known App Store review snag. On iOS the entitlement is
    // refreshed by the purchase stream and by the explicit "Restore purchases"
    // button instead. Android's queryPurchasesAsync never prompts.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_silentRestore());
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _store!.queryProductDetails(ProProductIds.all);
      final found =
          response.productDetails
              .map(
                (d) => ProProduct(
                  id: d.id,
                  title: d.title,
                  price: d.price,
                  rawPrice: d.rawPrice,
                  currencyCode: d.currencyCode,
                  details: d,
                ),
              )
              .toList()
            // Annual first, then monthly, then lifetime — the paywall reorders for
            // the lifetime-anchor variant.
            ..sort((a, b) => _rank(a.id).compareTo(_rank(b.id)));

      products = found;
      availability = found.isEmpty
          ? StoreAvailability.unavailable
          : StoreAvailability.available;
    } catch (_) {
      products = const [];
      // A failed query is not evidence that there is nothing to sell.
      availability = StoreAvailability.unreachable;
    }
    notifyListeners();
  }

  static int _rank(String id) => switch (id) {
    ProProductIds.annual => 0,
    ProProductIds.monthly => 1,
    _ => 2,
  };

  Future<void> buy(String productId) async {
    final product = productFor(productId);
    if (product == null) return;

    flow = PurchaseFlowState.pending;
    errorMessage = null;
    notifyListeners();

    try {
      final param = PurchaseParam(productDetails: product.details);
      // Subscriptions and lifetime are both non-consumable: neither is bought
      // twice.
      await _store!.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      flow = PurchaseFlowState.error;
      errorMessage = _friendlyError(e);
      notifyListeners();
    }
  }

  Future<void> restore() async {
    if (_store == null) return;
    flow = PurchaseFlowState.restoring;
    errorMessage = null;
    notifyListeners();
    try {
      await _store!.restorePurchases();
      // The stream delivers the results; give it a beat, then settle so the
      // button cannot spin forever if there is nothing to restore.
      Timer(const Duration(seconds: 4), () {
        if (flow == PurchaseFlowState.restoring) {
          flow = PurchaseFlowState.idle;
          notifyListeners();
        }
      });
    } catch (e) {
      flow = PurchaseFlowState.error;
      errorMessage = _friendlyError(e);
      notifyListeners();
    }
  }

  /// A restore nobody asked for, run at launch to keep the cached entitlement
  /// honest. It never surfaces an error and never revokes on failure.
  Future<void> _silentRestore() async {
    try {
      _sawAnyActive = false;
      _restoreWindowOpen = true;
      await _store!.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 3));
      _restoreWindowOpen = false;

      // The store answered and named nothing active: the subscription has
      // lapsed or was refunded. This is the only path that withdraws Pro.
      if (!_sawAnyActive && entitlement.active) {
        _persistEntitlement(
          entitlement.copyWith(active: false, lastVerified: DateTime.now()),
        );
      }
    } catch (_) {
      _restoreWindowOpen = false;
    }
  }

  bool _sawAnyActive = false;
  bool _restoreWindowOpen = false;

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          flow = PurchaseFlowState.pending;
          notifyListeners();

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (ProProductIds.all.contains(purchase.productID)) {
            _sawAnyActive = true;
            _persistEntitlement(
              Entitlement(
                active: true,
                productId: purchase.productID,
                lastVerified: DateTime.now(),
                everPurchased: true,
              ),
            );
            if (purchase.status == PurchaseStatus.purchased) {
              justPurchased = true;
            }
          }
          flow = PurchaseFlowState.idle;

        case PurchaseStatus.error:
          if (!_restoreWindowOpen) {
            flow = PurchaseFlowState.error;
            errorMessage = _friendlyError(purchase.error);
          }

        case PurchaseStatus.canceled:
          // Backing out is not a failure and gets no error copy.
          flow = PurchaseFlowState.idle;
      }

      // Every delivered purchase must be completed or the store will keep
      // re-delivering it, and Play will refund it after three days.
      if (purchase.pendingCompletePurchase) {
        try {
          await _store?.completePurchase(purchase);
        } catch (_) {
          // Retried on the next delivery.
        }
      }
    }
    notifyListeners();
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
      prefs.setBool(_keyActive, next.active);
      prefs.setBool(_keyEver, next.everPurchased);
      if (next.productId != null) prefs.setString(_keyProduct, next.productId!);
      if (next.lastVerified != null) {
        prefs.setString(_keyVerified, next.lastVerified!.toIso8601String());
      }
    }
    notifyListeners();
  }

  /// Errors say what happened and never apologise. "Nothing has been charged"
  /// is the part that matters to somebody staring at a failed purchase.
  String _friendlyError(Object? error) {
    final raw = error is IAPError ? '${error.code} ${error.message}' : '$error';
    if (raw.toLowerCase().contains('network') ||
        raw.toLowerCase().contains('timeout')) {
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
    notifyListeners();
  }

  void acknowledgePurchase() {
    justPurchased = false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
