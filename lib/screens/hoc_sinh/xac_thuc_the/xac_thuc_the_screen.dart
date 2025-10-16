import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class XacThucTheScreen extends StatefulWidget {
  const XacThucTheScreen({Key? key}) : super(key: key);

  @override
  State<XacThucTheScreen> createState() => _XacThucTheScreenState();
}

class _XacThucTheScreenState extends State<XacThucTheScreen> {
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

    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ứng dụng cần quyền truy cập camera')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy camera')),
        );
        return;
      }

      controller = CameraController(cameras[0], ResolutionPreset.high);
      await controller!.initialize();

      setState(() {
        _isCameraInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khởi tạo camera: $e')),
      );
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
        _showImagePreviewDialog(imageBytes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chụp ảnh: $e')),
      );
    }
  }

  void _showImagePreviewDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ImagePreviewDialog(
        imageBytes: imageBytes,
        onRetake: () {
          Navigator.of(context).pop();
        },
        onConfirm: (Uint8List confirmedImageBytes) {
          Navigator.of(context).pop();
          _uploadImage(confirmedImageBytes);
        },
      ),
    );
  }

  Future<void> _uploadImage(Uint8List imageBytes) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      // Upload to server - Replace with your actual API call
      // await YourApiService.uploadCardImage(base64Image);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tải ảnh lên thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải ảnh lên: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực thẻ học sinh'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                if (_isCameraInitialized)
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CameraPreview(controller!),
                  )
                else
                  const Center(
                    child: Text('Không thể khởi tạo camera'),
                  ),
                if (_isCameraInitialized)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: 'takePictureButton',
                          onPressed: _takePicture,
                          child: const Icon(Icons.camera_alt),
                        ),
                      ],
                    ),
                  ),
                // Overlay guide for card placement
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CardOverlayPainter(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Dialog to display captured image
class ImagePreviewDialog extends StatelessWidget {
  final Uint8List imageBytes;
  final VoidCallback onRetake;
  final Function(Uint8List) onConfirm;

  const ImagePreviewDialog({
    Key? key,
    required this.imageBytes,
    required this.onRetake,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Xác nhận ảnh thẻ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Chụp lại'),
                ),
                ElevatedButton.icon(
                  onPressed: () => onConfirm(imageBytes),
                  icon: const Icon(Icons.check),
                  label: const Text('Xác nhận'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter to display a card-shaped overlay
class CardOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    const double cardAspectRatio = 1.586; // Standard ID card aspect ratio
    double cardWidth = size.width * 0.8;
    double cardHeight = cardWidth / cardAspectRatio;

    double left = (size.width - cardWidth) / 2;
    double top = (size.height - cardHeight) / 2;
    double right = left + cardWidth;
    double bottom = top + cardHeight;

    // Draw background overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTRB(left, top, right, bottom))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw card border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), borderPaint);

    // Add helper text
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: 'Căn thẻ học sinh vào khung',
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, bottom + 24),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}