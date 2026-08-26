import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import '../widgets/barcode_scanner_overlay.dart';

/// Full-screen barcode / QR entry: camera when supported, otherwise manual input.
class ProductBarcodeScannerPage extends StatefulWidget {
  const ProductBarcodeScannerPage({super.key});

  /// Platforms where `mobile_scanner` registers a native/web implementation.
  static bool get isCameraPlatformSupported {
    if (kIsWeb) {
      return true;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  /// Opens the scanner and returns the scanned/entered value, or null if cancelled.
  static Future<String?> open(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ProductBarcodeScannerPage()),
    );
  }

  @override
  State<ProductBarcodeScannerPage> createState() =>
      _ProductBarcodeScannerPageState();
}

class _ProductBarcodeScannerPageState extends State<ProductBarcodeScannerPage> {
  final _manualController = TextEditingController();
  MobileScannerController? _controller;
  FlutterExceptionHandler? _previousFlutterOnError;
  var _handled = false;
  var _useCamera = false;
  var _cameraFailed = false;
  String? _cameraErrorKind;
  var _overlayStatus = ScannerOverlayStatus.scanning;
  Timer? _resultDelay;

  @override
  void initState() {
    super.initState();
    _useCamera = ProductBarcodeScannerPage.isCameraPlatformSupported;
    if (!_useCamera) {
      return;
    }
    _installMissingPluginGuard();
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      // Explicitly accept 1D barcodes and QR / 2D codes.
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.pdf417,
        BarcodeFormat.aztec,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.itf14,
        BarcodeFormat.codabar,
      ],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startCamera());
    });
  }

  void _installMissingPluginGuard() {
    _previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (_isMobileScannerPluginError(details.exception)) {
        unawaited(_failCamera('unavailable'));
        return;
      }
      _previousFlutterOnError?.call(details);
    };
  }

  void _restoreFlutterOnError() {
    if (_previousFlutterOnError != null) {
      FlutterError.onError = _previousFlutterOnError;
      _previousFlutterOnError = null;
    }
  }

  bool _isMobileScannerPluginError(Object exception) {
    if (exception is! MissingPluginException) {
      return false;
    }
    final message = exception.message ?? '';
    return message.contains('mobile_scanner');
  }

  Future<void> _failCamera(String kind) async {
    if (!mounted || _cameraFailed) {
      return;
    }
    setState(() {
      _cameraFailed = true;
      _cameraErrorKind = kind;
    });
    await _disposeController();
  }

  Future<void> _startCamera() async {
    final controller = _controller;
    if (!mounted || controller == null || _handled) {
      return;
    }
    try {
      await controller.start();
    } on MobileScannerException catch (error) {
      await _failCamera(
        error.errorCode == MobileScannerErrorCode.permissionDenied
            ? 'permission'
            : 'unavailable',
      );
    } on MissingPluginException {
      await _failCamera('unavailable');
    } catch (_) {
      await _failCamera('unavailable');
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) {
      return;
    }
    try {
      await controller.stop();
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    _resultDelay?.cancel();
    _restoreFlutterOnError();
    _manualController.dispose();
    unawaited(_disposeController());
    super.dispose();
  }

  void _submitCode(String raw, {bool fromCamera = false}) {
    final code = raw.trim();
    if (_handled || code.isEmpty) {
      return;
    }
    _handled = true;

    if (!fromCamera) {
      Navigator.of(context).pop(code);
      return;
    }

    setState(() => _overlayStatus = ScannerOverlayStatus.success);
    unawaited(_controller?.stop());

    _resultDelay?.cancel();
    _resultDelay = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(code);
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        _submitCode(raw, fromCamera: true);
        return;
      }
    }
  }

  String _cameraMessage(AppLocalizations l10n) {
    return switch (_cameraErrorKind) {
      'permission' => l10n.productsCameraPermissionDenied,
      _ => l10n.productsCameraUnavailable,
    };
  }

  Widget _manualEntry(AppLocalizations l10n, {required String? banner}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (banner != null) ...[
            Text(banner, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            l10n.productsEnterBarcodeHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _manualController,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.barcode),
            textInputAction: TextInputAction.done,
            onSubmitted: _submitCode,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.confirm,
            icon: Icons.check_outlined,
            expand: true,
            onPressed: () => _submitCode(_manualController.text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showManual = !_useCamera || _cameraFailed || _controller == null;

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.productsScanBarcode,
        showBackButton: true,
      ),
      body: showManual
          ? _manualEntry(
              l10n,
              banner: !_useCamera || _cameraFailed
                  ? _cameraMessage(l10n)
                  : null,
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      unawaited(
                        _failCamera(
                          error.errorCode ==
                                  MobileScannerErrorCode.permissionDenied
                              ? 'permission'
                              : 'unavailable',
                        ),
                      );
                    });
                    return const SizedBox.shrink();
                  },
                ),
                BarcodeScannerOverlay(
                  status: _overlayStatus,
                  alignHint: l10n.productsScannerAlignHint,
                  scanningLabel: l10n.productsScannerScanning,
                  detectedLabel: l10n.productsScannerDetected,
                  processingLabel: l10n.productsScannerProcessing,
                  errorLabel: l10n.productsScannerInvalid,
                ),
              ],
            ),
    );
  }
}
