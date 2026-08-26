/// PAY-03 — the row that opens the store's own billing screen, and the context
/// around it.
///
/// The billing screen belongs to the store, not to this app, and so do the
/// renewal date, the price you are actually paying and the cancel button. This
/// app deliberately cannot see any of them: there is no receipt server to ask.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../services/dialer.dart';
import '../../services/purchases.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

/// Where each store keeps a person's own subscriptions.
Future<void> openStoreSubscriptions({String? productId}) async {
  if (kIsWeb) return;
  if (Platform.isIOS) {
    await openWeb('https://apps.apple.com/account/subscriptions');
    return;
  }
  final suffix = productId == null
      ? ''
      : '?sku=$productId&package=app.calmcheck';
  await openWeb('https://play.google.com/store/account/subscriptions$suffix');
}

class ManageSubscriptionScreen extends StatelessWidget {
  const ManageSubscriptionScreen({super.key, this.forcedStatus});

  final ProStatus? forcedStatus;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final purchases = app.purchases;
    final status = forcedStatus ?? app.proStatus;
    final productId = purchases.entitlement.productId;
    final lifetime = productId == ProProductIds.lifetime;

    final row = switch (status) {
      ProStatus.free => (
        label: 'Restore purchases',
        explanation:
            'Already paid on another device? Bring Pro back on this one.',
        value: null,
      ),
      ProStatus.trial => (
        label: 'Manage subscription',
        explanation:
            'Your trial is running. Cancel before it ends in the store and '
            "you're not charged.",
        value: 'Trial',
      ),
      ProStatus.subscribed => (
        label: lifetime ? 'Your purchase' : 'Manage subscription',
        explanation: lifetime
            ? 'Lifetime. A single payment, nothing to renew or cancel.'
            : 'Renewal, price and cancellation are handled by the store. '
                  'This opens your subscriptions there.',
        value: lifetime ? 'Lifetime' : 'Active',
      ),
      ProStatus.expired => (
        label: 'Manage subscription',
        explanation:
            'Pro has ended. Your care cards are still here and still '
            'readable.',
        value: 'Ended',
      ),
    };

    return CalmScaffold(
      child: CcScreen(
        children: [
          const CcBackBar(),
          CcStack(
            gap: CcGap.sm,
            children: [
              FieldLabel('Subscription'),
              const CcSub(
                "Billing lives in the store you bought Pro from. This app "
                'never sees your payment details.',
              ),
            ],
          ),
          const CcRule(),
          NavRow(
            label: row.label,
            explanation: row.explanation,
            value: row.value,
            onTap: status == ProStatus.free
                ? purchases.restore
                : lifetime
                ? null
                : () => openStoreSubscriptions(productId: productId),
          ),
          const CcRule(),
          if (status != ProStatus.free) ...[
            NavRow(
              label: 'Restore purchases',
              explanation:
                  'Already paid on another device? Bring Pro back on this one.',
              onTap: purchases.restore,
            ),
            const CcRule(),
          ],
          if (purchases.flow == PurchaseFlowState.restoring)
            const NoticeBlock(
              label: 'Restoring',
              body: 'Asking the store what you already own.',
            ),
          if (purchases.flow == PurchaseFlowState.error &&
              purchases.errorMessage != null)
            NoticeBlock(label: 'Not charged', body: purchases.errorMessage!),
          NavRow(
            label: 'Terms of use',
            explanation: 'What you agree to, and what this app is not.',
            onTap: () => Navigator.of(context).pushNamed(Routes.terms),
          ),
          const CcRule(),
          NavRow(
            label: 'Privacy policy',
            explanation: 'What is stored, where it lives, and what we collect.',
            onTap: () => Navigator.of(context).pushNamed(Routes.privacyPolicy),
          ),
        ],
      ),
    );
  }
}
