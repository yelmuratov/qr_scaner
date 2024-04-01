import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QRScannerPage(),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isLoading = false;
  String? _resultMessage;
  IconData? _resultIcon;
  final player = AudioPlayer();
  DateTime? _lastScanTime;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> _scanQR(String qrText) async {
    // Check if a scan is already in progress or if the required wait time has not passed.
    if (_isLoading || !_canScanAgain()) {
      return; // Prevent scanning if the conditions are not met.
    }

    setState(() {
      _isLoading = true;
    });

    final encodedQRText = Uri.encodeComponent(qrText);
    final url = Uri.parse('https://pdp.diyarbek.ru/qr_code/$encodedQRText');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        _showResult(true);
      } else {
        _showResult(false);
      }
    } catch (e) {
      _showResult(false);
    } finally {
      setState(() {
        _isLoading = false;
        _lastScanTime = DateTime.now(); // Update the last scan time to now.
      });
    }
  }

  bool _canScanAgain() {
    if (_lastScanTime == null) {
      return true; // Allow scan if there's no previous scan.
    }
    final difference = DateTime.now().difference(_lastScanTime!).inSeconds;
    return difference >= 5; // Only allow a new scan if 10 seconds have passed.
  }

  void _showResult(bool isSuccess) {
    setState(() {
      _resultMessage = isSuccess ? "Success" : "Failure";
      _resultIcon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;
    });

    final soundToPlay = isSuccess ? 'success.mp3' : 'fail.mp3';
    player.play(AssetSource(soundToPlay));

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _resultMessage = null;
          _resultIcon = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white, // Set text color to white
            fontWeight: FontWeight.bold, // Set text to bold
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            allowDuplicates: false,
            onDetect: (barcode, args) {
              final String? qrText = barcode.rawValue;
              if (qrText != null && !_isLoading) {
                _scanQR(qrText);
              }
            },
          ),
          // QR Frame Overlay
          QRFrameOverlay(),
          // Loading and result messages
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_resultMessage != null && _resultIcon != null)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _resultIcon,
                      size: 100,
                      color: _resultMessage == "Success"
                          ? Colors.green
                          : Colors.red,
                    ),
                    Text(
                      _resultMessage!,
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QRFrameOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var squareSize = screenSize.width * 0.75; // Adjust the size of the square as needed

    return Center(
      child: Container(
        // This decoration is for the surrounding area outside the square
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                width: squareSize,
                height: squareSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                  // Creates a transparent square
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
