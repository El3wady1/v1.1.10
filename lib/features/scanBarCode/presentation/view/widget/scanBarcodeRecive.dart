import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saladafactory/features/scanBarCode/presentation/view/widget/cornerPainterBarCode.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class ScanBarcodeReceive extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  
  const ScanBarcodeReceive({Key? key, required this.onBarcodeScanned}) : super(key: key);

  @override
  State<ScanBarcodeReceive> createState() => _ScanBarcodeReceiveState();
}

class _ScanBarcodeReceiveState extends State<ScanBarcodeReceive> with TickerProviderStateMixin {
  bool isScanned = false;
  late MobileScannerController controller;
  late AnimationController _borderAnimationController;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _borderWidthAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setVolume(1.0)
    ..setReleaseMode(ReleaseMode.release);

  late AnimationController _redLineAnimationController;
  late Animation<double> _redLineAnimation;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() {
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _borderColorAnimation = ColorTween(
      begin: Colors.greenAccent,
      end: Colors.lightGreenAccent,
    ).animate(_borderAnimationController);

    _borderWidthAnimation = Tween<double>(
      begin: 2.0,
      end: 4.0,
    ).animate(_borderAnimationController);

    _redLineAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _redLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _redLineAnimationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    controller.dispose();
    _borderAnimationController.dispose();
    _redLineAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    controller.toggleTorch();
  }

  Future<void> _playScanSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/beep.mp3'));
    } catch (e) {
      debugPrint('Error playing scan sound: $e');
    }
  }

  void _handleBarcode(String barcode) async {
    if (isScanned) return;
    
    setState(() => isScanned = true);
    _borderAnimationController.stop();
    _redLineAnimationController.stop();

    // Provide feedback
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 10);
    }
    await _playScanSound();

    // Send barcode back to parent
    widget.onBarcodeScanned(barcode);

    // Reset scanner after short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => isScanned = false);
        _borderAnimationController.repeat(reverse: true);
        _redLineAnimationController.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = size.width * 0.7;
    final cornerSize = scanArea * 0.1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('مسح باركود الاستلام', style: GoogleFonts.cairo(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.black87,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.flashlight_on, color: Colors.white),
              onPressed: _toggleTorch,
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: controller,
              fit: BoxFit.cover,
              onDetect: (capture) {
                if (isScanned) return;
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first.rawValue;
                  if (barcode != null) {
                    _handleBarcode(barcode);
                  }
                }
              },
            ),
            // Scanner overlay UI
            _buildScannerOverlay(size, scanArea, cornerSize),
            // Instructions
            _buildInstructions(size),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay(Size size, double scanArea, double cornerSize) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(decoration: const BoxDecoration(color: Colors.black)),
              Center(
                child: Container(
                  width: scanArea,
                  height: scanArea,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _borderAnimationController,
            builder: (context, child) {
              return Container(
                width: scanArea,
                height: scanArea,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _borderColorAnimation.value ?? Colors.green,
                    width: _borderWidthAnimation.value,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  painter: CornerPainter(
                    color: _borderColorAnimation.value ?? Colors.green,
                    cornerSize: cornerSize,
                  ),
                ),
              );
            },
          ),
        ),
        AnimatedBuilder(
          animation: _redLineAnimation,
          builder: (context, child) {
            return Positioned(
              top: size.height * 0.5 - scanArea / 2 + _redLineAnimation.value * scanArea,
              left: size.width * 0.5 - scanArea / 2,
              child: Container(
                width: scanArea,
                height: 2,
                color: Colors.redAccent,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInstructions(Size size) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'وجّه الكود داخل الإطار للمسح',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Icon(
            Icons.keyboard_arrow_up,
            color: Colors.white.withOpacity(0.7),
            size: 40,
          ),
        ],
      ),
    );
  }
}

// Usage example:
// In your receiving screen, you would use it like this:
/*
ScanBarcodeReceive(
  onBarcodeScanned: (barcode) {
    // Handle the scanned barcode
    // This will be called each time a barcode is scanned
    print('Scanned barcode: $barcode');
    // You can then add it to your received items list
    setState(() {
      receivedItems.add({
        'barcode': barcode,
        'name': 'Item from barcode',
        'quantity': 1,
      });
    });
  },
)
*/