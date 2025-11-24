import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Reusable card scanning camera widget
class CardCameraWidget extends StatefulWidget {
  final String overlayText;
  final Function(Uint8List bytes) onCapture;

  const CardCameraWidget({
    Key? key,
    this.overlayText = 'Căn thẻ học sinh vào khung',
    required this.onCapture,
  }) : super(key: key);

  @override
  State<CardCameraWidget> createState() => _CardCameraWidgetState();
}

class _CardCameraWidgetState extends State<CardCameraWidget> {
  late List<CameraDescription> cameras;
  CameraController? controller;
  bool _isCameraInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
    });

    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ứng dụng cần quyền truy cập camera')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy camera')),
          );
        }
        return;
      }

      controller = CameraController(cameras[0], ResolutionPreset.high);
      await controller!.initialize();

      setState(() {
        _isCameraInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khởi tạo camera: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _takePicture() async {
    if (!controller!.value.isInitialized) {
      return;
    }

    try {
      final image = await controller!.takePicture();
      final imageBytes = await image.readAsBytes();

      if (mounted) {
        widget.onCapture(imageBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chụp ảnh: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        if (_isCameraInitialized)
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(controller!),
          )
        else
          const Center(child: Text('Không thể khởi tạo camera')),
        if (_isCameraInitialized)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'cardCaptureButton',
                  onPressed: _takePicture,
                  child: const Icon(Icons.camera_alt),
                ),
              ],
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: CardOverlayPainter()),
          ),
        ),
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.overlayText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CardOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    const double cardAspectRatio = 1.586;
    double cardWidth = size.width * 0.8;
    double cardHeight = cardWidth / cardAspectRatio;

    double left = (size.width - cardWidth) / 2;
    double top = (size.height - cardHeight) / 2;
    double right = left + cardWidth;
    double bottom = top + cardHeight;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTRB(left, top, right, bottom))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
