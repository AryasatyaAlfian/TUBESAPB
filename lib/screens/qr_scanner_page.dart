import 'package:flutter/material.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presensi QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('QR Scanner (Placeholder)'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'QR Scanner will be enabled after fixing dependencies',
                    ),
                  ),
                );
              },
              child: const Text('Scan QR'),
            ),
          ],
        ),
      ),
    );
  }
}
