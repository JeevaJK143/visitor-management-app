import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gradient_app_bar.dart';
import '../../visitor_details/pages/visitor_details_page.dart';
import '../../visitors/bloc/visitor_bloc.dart';
import '../../visitors/bloc/visitor_event.dart';
import '../../visitors/bloc/visitor_state.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  late final MobileScannerController _scannerController;

  bool _isHandlingScan = false;
  bool _awaitingLookup = false;
  String? _scannedId;
  String? _lastInvalidValue;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isHandlingScan) return;

    String? value;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();

      if (raw != null && raw.isNotEmpty) {
        value = raw;
        break;
      }
    }

    if (value == null || !_looksLikeVisitorId(value)) {
      if (value != _lastInvalidValue) {
        _lastInvalidValue = value;
        _showMessage('Invalid visitor QR code.');
      }
      return;
    }

    _lastInvalidValue = null;
    _scannedId = value;
    _awaitingLookup = true;
    setState(() => _isHandlingScan = true);
    _scannerController.stop();

    context.read<VisitorBloc>().add(LoadVisitorDetails(value));
  }

  bool _looksLikeVisitorId(String value) {
    return !value.contains('/') &&
        !value.contains('\n') &&
        !value.contains('\r') &&
        value.length <= 100;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onLookupFinished(VisitorState state) async {
    _awaitingLookup = false;
    final visitor = state.selectedVisitor;

    if (state.status == VisitorStatus.detailsLoaded &&
        visitor != null &&
        visitor.id == _scannedId) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisitorDetailsPage(visitorId: visitor.id),
        ),
      );

      _resumeScanning();
      return;
    }

    _resumeScanning(
      message: state.errorMessage ?? 'Visitor not found. Try again.',
    );
  }

  void _resumeScanning({String? message}) {
    if (!mounted) return;

    setState(() => _isHandlingScan = false);
    _scannedId = null;
    if (message != null) _showMessage(message);
    _scannerController.start();
  }

  Widget _cameraError(BuildContext context, MobileScannerException error) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                denied ? Icons.no_photography_outlined : Icons.error_outline,
                color: Colors.white,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                denied
                    ? 'Camera permission was denied. Allow camera access for '
                        'this app in Settings > Apps > Permissions, then try again.'
                    : (error.errorDetails?.message ??
                        'Camera unavailable. Please try again.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(140, 46),
                ),
                onPressed: () => _scannerController.start(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisitorBloc, VisitorState>(
      listenWhen: (previous, current) =>
          _awaitingLookup &&
          previous.status != current.status &&
          (current.status == VisitorStatus.detailsLoaded ||
              current.status == VisitorStatus.detailsFailure),
      listener: (context, state) => _onLookupFinished(state),
      child: Scaffold(
        appBar: const GradientAppBar(
          icon: Icons.qr_code_scanner,
          title: 'Scan Visitor QR',
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Scan the visitor QR code',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Position the visitor code inside the scanning area.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primary, width: 3),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                        errorBuilder: _cameraError,
                      ),
                      IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 230,
                            height: 230,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      if (_isHandlingScan)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  'Looking up visitor...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: OutlinedButton.icon(
                  onPressed: _isHandlingScan
                      ? null
                      : () => _scannerController.toggleTorch(),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Toggle Flash'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
