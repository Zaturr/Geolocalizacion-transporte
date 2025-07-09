import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
    returnImage: false,
  );

  bool _isScanning = true;
  bool _torchEnabled = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    cameraController.start();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        actions: [
          // Torch button
          IconButton(
            color: Colors.white,
            icon: Icon(
              _torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: _torchEnabled ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _torchEnabled = !_torchEnabled;
              });
              cameraController.toggleTorch();
            },
          ),
          // Camera switch button
          IconButton(
            color: Colors.white,
            icon: Icon(
              _cameraFacing == CameraFacing.front
                  ? Icons.camera_front
                  : Icons.camera_rear,
            ),
            onPressed: () {
              setState(() {
                _cameraFacing = _cameraFacing == CameraFacing.front
                    ? CameraFacing.back
                    : CameraFacing.front;
              });
              cameraController.switchCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_isScanning) {
                _isScanning = false;
                final List<Barcode> barcodes = capture.barcodes;

                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  debugPrint('Codigo Encontrado! ${barcodes.first.rawValue}');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pop(context, barcodes.first.rawValue);
                  });
                } else {
                  debugPrint('No se encontro un Codigo.');
                  _isScanning = true;
                }
              }
            },
          ),
          if (!_isScanning)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black54,
                child: const Text(
                  "Escaneo Pausado...",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}