/// CARD-SCAN — receive a card.
///
/// Every state here has one thing to do about it, and none of them is a dead
/// end: a blocked camera still offers the card file, and a code that isn't a
/// CalmCheck card says so plainly rather than failing silently.
library;

import 'package:flutter/material.dart';

import '../../services/device_settings.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/copy.dart';
import '../../models/care_card.dart';
import '../../routes.dart';
import '../../services/card_file.dart';
import '../../services/haptics.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

enum ScanState { scanning, found, invalid, denied, noCamera }

class CardScanScreen extends StatefulWidget {
  const CardScanScreen({super.key});

  @override
  State<CardScanScreen> createState() => _CardScanScreenState();
}

class _CardScanScreenState extends State<CardScanScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  ScanState _state = ScanState.scanning;
  CareCardData? _found;

  @override
  void initState() {
    super.initState();
    // Since mobile_scanner 5.x the widget no longer watches the app
    // lifecycle itself: without this, backgrounding the app — or the
    // expected round-trip through system settings to grant the camera —
    // comes back to a frozen preview.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    switch (lifecycle) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _controller.stop();
      case AppLifecycleState.resumed:
        if (_state == ScanState.scanning) {
          _controller.start();
        } else if (_state == ScanState.denied ||
            _state == ScanState.noCamera) {
          // Coming back from settings: the permission may have just been
          // granted. Try again; a still-blocked camera re-raises the same
          // state through the error builder.
          setState(() => _state = ScanState.scanning);
          _controller.start();
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_state == ScanState.found) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final card = CareCardData.tryParseShareString(raw);
      if (card != null) {
        CcHaptics.instance.fire(CcHaptic.pressFirm);
        setState(() {
          _found = card;
          _state = ScanState.found;
        });
        _controller.stop();
        return;
      }
      // The MobileScanner widget unmounts on this state, but the controller
      // owns the camera and keeps it hot until told otherwise. The retry path
      // already calls `start()`, so this is the missing half of that pair.
      _controller.stop();
      setState(() => _state = ScanState.invalid);
    }
  }

  void _save(CareCardData card) {
    final app = context.appRead;
    // A received card is read-only until its holder decides to keep it.
    var received = card.copyWith(
      readOnly: true,
      sharedBy: card.call.isNotEmpty ? card.call.first.name : null,
    );

    // A shared card carries the id it was created under, so scanning your own
    // printed card — or an older copy of one you already hold — used to
    // overwrite the original in place: an editable card silently became
    // read-only, and a newer version was replaced by an older one. Neither is
    // recoverable, because the photo never travels in the payload.
    final existing = app.cardById(received.id);
    if (existing != null &&
        (!existing.readOnly || existing.version >= received.version)) {
      received = received.copyWith(
        id: 'card-${DateTime.now().microsecondsSinceEpoch}',
      );
    }

    app.upsertCard(received);
    Navigator.of(
      context,
    ).pushReplacementNamed(Routes.cardView, arguments: received.id);
  }

  Future<void> _openFile() async {
    final card = await openCardFile();
    if (!mounted) return;
    if (card == null) {
      setState(() => _state = ScanState.invalid);
      return;
    }
    _save(card);
  }

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
              const CcHeadline('Scan a care card'),
              const CcBody('Point the camera at the QR code.'),
              _body(),
              if (_state == ScanState.found && _found != null)
                CareTile(
                  name: _found!.name,
                  signal: _found!.relation.isEmpty
                      ? 'Shared with you'
                      : '${_found!.relation} · shared with you',
                  initial: _found!.initial,
                ),
            ],
          ),
          CcStack(
            gap: CcGap.sm,
            children: [
              if (_state == ScanState.found && _found != null)
                CcButton(
                  "Open ${_found!.name}'s card",
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: () => _save(_found!),
                ),
              if (_state == ScanState.invalid)
                CcButton(
                  StateCopy.emptyScanPrimary,
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: () {
                    setState(() => _state = ScanState.scanning);
                    _controller.start();
                  },
                ),
              if (_state == ScanState.denied)
                CcButton(
                  StateCopy.cameraPrimary,
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: openAppSettings,
                ),
              CcButton(
                'Open a card file instead',
                variant: CcButtonVariant.quiet,
                fullWidth: true,
                onPressed: _openFile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_state) {
      case ScanState.denied:
        return SystemState(
          label: StateCopy.cameraLabel,
          headline: StateCopy.cameraHeadline,
          direction: StateCopy.cameraDirection,
          ghost: const _GhostViewfinder(),
        );
      case ScanState.noCamera:
        return SystemState(
          label: StateCopy.noCameraLabel,
          headline: 'No camera CalmCheck can use',
          direction: StateCopy.noCameraDirection,
          ghost: const _GhostViewfinder(),
        );
      case ScanState.invalid:
        return SystemState(
          label: StateCopy.emptyScanLabel,
          headline: StateCopy.emptyScanHeadline,
          direction: StateCopy.emptyScanDirection,
          ghost: const _GhostViewfinder(),
        );
      case ScanState.scanning:
      case ScanState.found:
        return _Viewfinder(
          controller: _controller,
          onDetect: _onDetect,
          note: _state == ScanState.found
              ? 'Card found — ${_found?.name ?? ''}'
              : 'Looking for a code…',
          onError: (exception) {
            final next =
                exception.errorCode == MobileScannerErrorCode.permissionDenied
                ? ScanState.denied
                : ScanState.noCamera;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _state != next) setState(() => _state = next);
            });
          },
        );
    }
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    required this.controller,
    required this.onDetect,
    required this.note,
    required this.onError,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;
  final String note;
  final void Function(MobileScannerException) onError;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return CcStack(
      gap: CcGap.sm,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: t.cardBorderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: onDetect,
                  errorBuilder: (context, exception) {
                    onError(exception);
                    return const _GhostViewfinder();
                  },
                  placeholderBuilder: (context) => const _GhostViewfinder(),
                ),
                IgnorePointer(
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.7,
                      heightFactor: 0.7,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: t.signal, width: 3),
                          borderRadius: t.cardBorderRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        CcCaption(note),
      ],
    );
  }
}

class _GhostViewfinder extends StatelessWidget {
  const _GhostViewfinder();

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return AspectRatio(
      aspectRatio: 1,
      child: DottedFrame(
        color: t.rule,
        radius: t.radiusCard,
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.55,
            heightFactor: 0.55,
            child: DottedFrame(
              color: t.rule,
              radius: t.radiusCard,
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }
}
