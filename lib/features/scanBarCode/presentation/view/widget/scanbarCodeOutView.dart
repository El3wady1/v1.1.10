import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saladafactory/core/utils/assets.dart';
import 'package:saladafactory/features/scanBarCode/data/services/getProductByBarCodeOUT.dart';
import 'package:saladafactory/features/scanBarCode/presentation/view/widget/cornerPainterBarCode.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class ScanbarcodeOutbodyview extends StatefulWidget {
  @override
  State<ScanbarcodeOutbodyview> createState() => _ScanbarcodeOutbodyviewState();
}

class _ScanbarcodeOutbodyviewState extends State<ScanbarcodeOutbodyview>
    with TickerProviderStateMixin {
  bool isScanned = false;
  late MobileScannerController controller;
  late AnimationController _borderAnimationController;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _borderWidthAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _redLineAnimationController;
  late Animation<double> _redLineAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
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

  Future<void> _handleBarcode(String barcode) async {
    if (isScanned || !mounted) return;

    setState(() => isScanned = true);
    _borderAnimationController.stop();
    _redLineAnimationController.stop();

    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 10);
      }

      await _audioPlayer.play(AssetSource(AssetAudio.scanned));

      setState(() {
        _borderColorAnimation = ColorTween(
          begin: Colors.blueAccent,
          end: Colors.blueAccent,
        ).animate(_borderAnimationController);
      });

      // استدعاء مباشر دون عرض نافذة حوار
      _navigateToOutView(barcode);
    } catch (e) {
      debugPrint('Error handling barcode: $e');
      _resetScanState();
    }
  }

  void _navigateToOutView(String barcode) async {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await getProductByBarCodeOUT(barbracode: barcode, context: context);
      } catch (e) {
        debugPrint('Navigation error: $e');
        _resetScanState();
      }
    });
  }

  void _resetScanState() {
    if (mounted) {
      setState(() => isScanned = false);
      _borderAnimationController.repeat(reverse: true);
      _redLineAnimationController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = size.width * 0.7;
    final cornerSize = scanArea * 0.1;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('مسح الباركود', style:GoogleFonts.cairo(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.black87,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                if (isScanned || !mounted) return;
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first.rawValue;
                  if (barcode != null) {
                    _handleBarcode(barcode);
                  }
                }
              },
            ),
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
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
                  top: size.height * 0.5 - scanArea / 2 +
                      _redLineAnimation.value * scanArea,
                  left: size.width * 0.5 - scanArea / 2,
                  child: Container(
                    width: scanArea,
                    height: 2,
                    color: Colors.redAccent,
                  ),
                );
              },
            ),
            Positioned(
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
            ),
          ],
        ),
      ),
    );
  }
}
