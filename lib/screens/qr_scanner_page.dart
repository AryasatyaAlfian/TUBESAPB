import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool isScanned = false; // Mencegah scan berulang kali

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presensi QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (!isScanned && barcode.rawValue != null) {
              setState(() {
                isScanned = true;
              });

              final String qrData = barcode.rawValue!;

              // Tampilkan hasil scan sementara
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('NIM/Data terdeteksi: $qrData')),
              );

              // TODO: Kirim qrData ini ke API Backend

              // Opsional: Kembali ke halaman sebelumnya setelah berhasil
              // Navigator.pop(context, qrData);
            }
          }
        },
      ),
    );
  }
}
