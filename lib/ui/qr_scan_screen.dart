// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
//
// /// Pops the raw String when a QR code is detected.
// class QRScanScreen extends StatefulWidget {
//   const QRScanScreen({Key? key}) : super(key: key);
//
//   @override
//   State<QRScanScreen> createState() => _QRScanScreenState();
// }
//
// class _QRScanScreenState extends State<QRScanScreen> {
//   bool _scanned = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Scan Activation QR')),
//       body: MobileScanner(
//         allowDuplicates: false,
//         onDetect: (barcode, args) {
//           if (_scanned) return;
//           final code = barcode.rawValue;
//           if (code == null) return;
//           _scanned = true;
//           Navigator.of(context).pop(code);
//         },
//       ),
//     );
//   }
// }
