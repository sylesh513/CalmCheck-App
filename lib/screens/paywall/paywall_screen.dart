/// PAY-01 — the paywall, in three variants, on real store prices.
///
/// One rule governs this whole area: nothing here may imply that safety
/// features are gated. The free-forever line is required, is never abbreviated
/// and is never a footnote. The paywall never appears in the panic flow, on the
/// first card, or near crisis resources.
///
/// Everything a store requires of a subscription screen is on it: what the plan
/// is called, how long it runs, the localised price the store itself reports,
/// what it includes, the auto-renew disclosure, restore, and working links to
/// the terms and the privacy policy.
library;

import 'package:flutter/material.dart';

import '../../data/copy.dart';
import '../../routes.dart';
import '../../services/purchases.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import 'lifecycle_screen.dart';

/// Only used by the design reference, which has no store to ask.
enum PayState { free, trial, subscribed, error, restoring }

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.entry, this.variant, this.forcedState});

  /// Where the person came from — a locked exercise, a second card, an export.
  final String? entry;

  /// Overrides the install's assigned variant. Used by the design reference.
  final PaywallVariant? variant;

  /// Renders a fixed state with sample prices. Design reference only.
  final PayState? forcedState;

  bool get isPreview => forcedState != null;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selected = ProProductIds.annual;
  bool _sawPurchase = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isPreview) {
      context.appRead.purchases.clearError();
    }
  }

  /// A completed purchase leaves the paywall for the confirmation, once.
  void _watchForPurchase(PurchaseService purchases) {
    if (widget.isPreview || _sawPurchase || !purchases.justPurchased) return;
    _sawPurchase = true;
    purchases.acknowledgePurchase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        Routes.lifecycle,
        arguments: LifecycleMoment.started,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final purchases = app.purchases;
    _watchForPurchase(purchases);

    final variant = widget.variant ?? app.paywallVariant;

    // ---- Design-reference rendering -------------------------------------
    if (widget.isPreview) {
      if (widget.forcedState == PayState.subscribed) {
        return const _AlreadyPro();
      }
      return _Paywall(
        variant: variant,
        prices: _samplePrices,
        selected: _selected,
        onSelect: (id) => setState(() => _selected = id),
        busy: widget.forcedState == PayState.restoring,
        busyLabel: 'Restoring your purchases…',
        errorMessage: widget.forcedState == PayState.error
            ? ProCopy.purchaseError
            : null,
        trialActive: widget.forcedState == PayState.trial,
        onBuy: () {},
        onRestore: () {},
      );
    }

    // ---- The real thing --------------------------------------------------
    if (purchases.entitlement.active) return const _AlreadyPro();

    if (!app.proOffered) return const _StoreUnavailable();

    final prices = [
      for (final p in purchases.products)
        (id: p.id, price: p.price, subscription: p.isSubscription),
    ];

    return _Paywall(
      variant: variant,
      prices: prices,
      selected: prices.any((p) => p.id == _selected)
          ? _selected
          : (prices.isNotEmpty ? prices.first.id : ProProductIds.annual),
      onSelect: (id) => setState(() => _selected = id),
      busy:
          purchases.flow == PurchaseFlowState.pending ||
          purchases.flow == PurchaseFlowState.restoring,
      busyLabel: purchases.flow == PurchaseFlowState.restoring
          ? 'Restoring your purchases…'
          : 'Talking to the store…',
      errorMessage: purchases.flow == PurchaseFlowState.error
          ? (purchases.errorMessage ?? ProCopy.purchaseError)
          : null,
      trialActive: false,
      onBuy: () => purchases.buy(_selected),
      onRestore: purchases.restore,
    );
  }

  static const List<({String id, String price, bool subscription})>
  _samplePrices = [
    (
      id: ProProductIds.annual,
      price: ProCopy.samplePriceAnnual,
      subscription: true,
    ),
    (
      id: ProProductIds.monthly,
      price: ProCopy.samplePriceMonthly,
      subscription: true,
    ),
    (
      id: ProProductIds.lifetime,
      price: ProCopy.samplePriceLifetime,
      subscription: false,
    ),
  ];
}

typedef _Price = ({String id, String price, bool subscription});

class _Paywall extends StatelessWidget {
  const _Paywall({
    required this.variant,
    required this.prices,
    required this.selected,
    required this.onSelect,
    required this.busy,
    required this.busyLabel,
    required this.errorMessage,
    required this.trialActive,
    required this.onBuy,
    required this.onRestore,
  });

  final PaywallVariant variant;
  final List<_Price> prices;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool busy;
  final String busyLabel;
  final String? errorMessage;
  final bool trialActive;
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  String get _annualPrice {
    for (final p in prices) {
      if (p.id == ProProductIds.annual) return p.price;
    }
    return prices.isEmpty ? '' : prices.first.price;
  }

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        gap: CcGap.lg,
        children: [
          const CcBackBar(),
          CcStack(
            gap: CcGap.sm,
            children: [
              FieldLabel('Pro'),
              const CcHeadline('CalmCheck Pro'),
              if (trialActive) const CcSub('Your free trial is running.'),
            ],
          ),

          // Required, and never below the fold.
          const FreeForeverBlock(),

          if (variant == PaywallVariant.giveback) ...[
            const GiveBackBlock(lead: true),
            const CcRule(),
            const ProList(),
          ] else ...[
            const ProList(),
            const CcRule(),
          ],

          _Prices(
            variant: variant,
            prices: prices,
            selected: selected,
            enabled: !busy,
            onSelect: onSelect,
          ),

          if (errorMessage != null)
            NoticeBlock(label: 'Not charged', body: errorMessage!),

          if (_annualPrice.isNotEmpty)
            CcBody(ProCopy.plainPriceLine(_annualPrice), muted: true),

          CcStack(
            gap: CcGap.sm,
            children: [
              CcButton(
                trialActive ? 'Keep Pro after the trial' : 'Continue',
                size: CcButtonSize.lg,
                fullWidth: true,
                loading: busy,
                loadingLabel: busyLabel,
                onPressed: onBuy,
              ),
              CcButton(
                'Restore purchases',
                variant: CcButtonVariant.quiet,
                fullWidth: true,
                onPressed: busy ? null : onRestore,
              ),
            ],
          ),

          // The stores require this on the screen, not behind a link.
          CcCaption(ProCopy.autoRenewDisclosure),

          if (variant != PaywallVariant.giveback) const GiveBackBlock(),
          const LegalLinks(),
        ],
      ),
    );
  }
}

/// What a Pro subscriber sees if they land here. Nothing to buy.
class _AlreadyPro extends StatelessWidget {
  const _AlreadyPro();

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              FieldLabel('CalmCheck Pro'),
              const CcHeadline('You already have Pro.'),
              const CcSub(
                'Renewal and cancellation are handled by the store you bought '
                'it from. Nothing to buy here.',
              ),
              const CcRule(),
              const ProList(),
              const CcRule(),
              const GiveBackBlock(),
            ],
          ),
          CcStack(
            gap: CcGap.sm,
            children: [
              CcButton(
                'Manage subscription',
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.lg,
                fullWidth: true,
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.manageSubscription),
              ),
              const FreeForeverBlock(),
            ],
          ),
        ],
      ),
    );
  }
}

/// No store, or no products configured yet. Say so plainly and get out of the
/// way — nothing free is affected.
class _StoreUnavailable extends StatelessWidget {
  const _StoreUnavailable();

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              FieldLabel('Pro'),
              const CcHeadline('CalmCheck Pro'),
              const CcBody(ProCopy.storeUnavailable),
              const CcRule(),
              const FreeForeverBlock(),
            ],
          ),
          CcButton(
            'Back',
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.lg,
            fullWidth: true,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

/// The line that has to be on this screen. Body size, its own frame, above the
/// prices.
class FreeForeverBlock extends StatelessWidget {
  const FreeForeverBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CcSpace.lg,
        vertical: CcSpace.md,
      ),
      decoration: BoxDecoration(
        borderRadius: t.cardBorderRadius,
        border: Border.all(color: t.ink, width: 2),
      ),
      child: CcStack(
        gap: CcGap.xs,
        children: [
          FieldLabel('Free forever'),
          const CcBody(ProCopy.freeForever),
        ],
      ),
    );
  }
}

class ProList extends StatelessWidget {
  const ProList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return CcStack(
      gap: CcGap.sm,
      children: [
        FieldLabel('What Pro adds'),
        for (final item in ProCopy.proList)
          Container(
            padding: const EdgeInsets.symmetric(vertical: CcSpace.sm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: t.rule,
                  width: CcStructure.ruleWeight,
                ),
              ),
            ),
            child: Text(item, style: context.ccText.bodyLarge),
          ),
      ],
    );
  }
}

/// Credibility comes from a specific number and an honest limit, not from
/// illustration.
class GiveBackBlock extends StatelessWidget {
  const GiveBackBlock({super.key, this.lead = false});

  final bool lead;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final content = CcStack(
      gap: CcGap.xs,
      children: [
        FieldLabel('Give-back'),
        if (lead) ...[
          Text(
            '${ProCopy.sponsoredSoFar}',
            style: TextStyle(
              fontFamily: ccLabelFace,
              fontSize: t.displaySize * 1.6,
              height: 1,
              fontWeight: FontWeight.w700,
              color: t.ink,
            ),
          ),
          FieldLabel('years of Pro sponsored so far'),
        ],
        CcBody(ProCopy.giveBack, muted: true),
      ],
    );

    if (lead) {
      return Container(
        padding: const EdgeInsets.all(CcSpace.lg),
        decoration: BoxDecoration(
          color: t.stockRaised,
          borderRadius: t.cardBorderRadius,
          border: Border.all(color: t.rule, width: CcStructure.cardEdge),
        ),
        child: content,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: CcSpace.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: t.rule, width: CcStructure.ruleWeight),
        ),
      ),
      child: content,
    );
  }
}

class _Prices extends StatelessWidget {
  const _Prices({
    required this.variant,
    required this.prices,
    required this.selected,
    required this.enabled,
    required this.onSelect,
  });

  final PaywallVariant variant;
  final List<_Price> prices;
  final String selected;
  final bool enabled;
  final ValueChanged<String> onSelect;

  static const Map<String, ({String term, String equivalent, String? savings})>
  _labels = {
    ProProductIds.annual: (
      term: 'Annual',
      equivalent: 'Billed once a year',
      savings: 'Best value',
    ),
    ProProductIds.monthly: (
      term: 'Monthly',
      equivalent: 'Billed every month',
      savings: null,
    ),
    ProProductIds.lifetime: (
      term: 'Lifetime',
      equivalent: 'One payment, no renewal',
      savings: null,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final ordered = [...prices];
    if (variant == PaywallVariant.lifetime) {
      ordered.sort(
        (a, b) => _lifetimeFirst(a.id).compareTo(_lifetimeFirst(b.id)),
      );
    }

    return CcStack(
      gap: CcGap.sm,
      children: [
        if (variant == PaywallVariant.lifetime && ordered.length > 1)
          CcCaption(
            "Most people choose annual. Lifetime is here if you'd rather pay "
            'once.',
          ),
        for (final price in ordered)
          PriceOption(
            key: ValueKey(price.id),
            term: _labels[price.id]?.term ?? price.id,
            price: price.price,
            equivalent: _labels[price.id]?.equivalent ?? '',
            savings: _labels[price.id]?.savings,
            selected: selected == price.id,
            enabled: enabled,
            onTap: () => onSelect(price.id),
          ),
      ],
    );
  }

  static int _lifetimeFirst(String id) => id == ProProductIds.lifetime ? 0 : 1;
}

/// Terms and the privacy policy, reachable from the screen that sells the
/// subscription. Both are real pages, not dead links.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.only(top: CcSpace.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: t.rule, width: CcStructure.ruleWeight),
        ),
      ),
      child: Wrap(
        spacing: CcSpace.md,
        children: [
          CcButton(
            'Terms of use',
            variant: CcButtonVariant.quiet,
            haptic: null,
            onPressed: () => Navigator.of(context).pushNamed(Routes.terms),
          ),
          CcButton(
            'Privacy policy',
            variant: CcButtonVariant.quiet,
            haptic: null,
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.privacyPolicy),
          ),
        ],
      ),
    );
  }
}
