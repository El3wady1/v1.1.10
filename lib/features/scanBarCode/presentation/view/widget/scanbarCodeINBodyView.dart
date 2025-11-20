import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saladafactory/core/app_router.dart';
import 'package:saladafactory/features/home/data/repo/ReturnLastloginRepo.dart';
import 'package:saladafactory/features/in/data/services/getAllSupplierINServices.dart';
import 'package:saladafactory/features/in/data/services/getAllunitService.dart';
import 'package:saladafactory/features/in/data/services/getProductByBarcodeINService.dart';
import 'package:saladafactory/features/mainProduct/presentation/view/mainProductView.dart';
import 'package:saladafactory/features/scanBarCode/presentation/view/widget/cornerPainterBarCode.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class ScanbarcodeINbodyview extends StatefulWidget {
  var mainProduct;

  @override
  ScanbarcodeINbodyview(this.mainProduct);
  State<ScanbarcodeINbodyview> createState() => _ScanbarcodeINbodyviewState();
}

class _ScanbarcodeINbodyviewState extends State<ScanbarcodeINbodyview>
    with TickerProviderStateMixin {
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
      await _audioPlayer.play(AssetSource('audio/beep.mp3'));
    }
  }

  void _handleBarcode(String barcode) async {
    if (isScanned) return;
    setState(() => isScanned = true);
    _borderAnimationController.stop();
    _redLineAnimationController.stop();

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 10);
    }

    await _playScanSound();

    setState(() {
      _borderColorAnimation = ColorTween(
        begin: Colors.blueAccent,
        end: Colors.blueAccent,
      ).animate(_borderAnimationController);
    });
    var productdata;
    var supplierData;
    var unitData;

    await getAllUnitINServices().then((v) => unitData = v);
    await getAllSupplierINServices().then((v) => supplierData = v);
    await getProductByBarcodeINService(barbracode: barcode, context: context)
        .then((v) => productdata = v);
         var data = await ReturnLastloginRepo.featchData();
var canadd =data["canaddProductIN"];
Routting.pushreplaced(context, MainCategorySelectionPage(barcode: barcode, isexitsProduct: productdata!=null?true:false, ));
    // Routting.pushreplaced(
    //   context,
    //   Inview(
    //     initialBarcode: barcode,
    //     isExist: productdata != null ? true : false,
    //     SupplierData: supplierData,
    //     unitData: unitData,
    //     mainProduct: widget.mainProduct, canAddPernew:data["canaddProductIN"] ,
    //   ),
    // );
  
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
          
          title: Text('مسح الباركود',
              style: GoogleFonts.cairo(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.black87,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
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
                final barcode = capture.barcodes.first.rawValue;
                if (barcode != null) {
                  _handleBarcode(barcode);
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
                    decoration: BoxDecoration(
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
                  top: size.height * 0.5 -
                      scanArea / 2 +
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
                    padding: EdgeInsets.all(12),
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
                  SizedBox(height: 20),
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.white.withOpacity(0.7),
                    size: 40,
                  ),
              ElevatedButton(
  onPressed: () {
    Routting.pushreplaced(
      context,
      MainCategorySelectionPage(
        barcode: "",
        isexitsProduct: false,
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Text(
    "ليس لدي باركود للمنتج جديد",
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
