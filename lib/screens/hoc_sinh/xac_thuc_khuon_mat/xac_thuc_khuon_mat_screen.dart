import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quan_ly_hoc_sinh/models/xin_ra_vao.dart';
import 'package:quan_ly_hoc_sinh/services/image_service.dart';
import 'package:quan_ly_hoc_sinh/services/local_data_service.dart';
import 'package:quan_ly_hoc_sinh/services/xin_ra_vao_service.dart';


class XacThucKhuonMatScreen extends StatefulWidget {
  final bool isUploadFace;
  final String idRaVao;
  const XacThucKhuonMatScreen({Key? key, this.isUploadFace = false, this.idRaVao = ""}) : super(key: key);

  @override
  State<XacThucKhuonMatScreen> createState() => _XacThucKhuonMatScreenState();
}

class _XacThucKhuonMatScreenState extends State<XacThucKhuonMatScreen> {
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
    final status = await Permission.camera.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cần cấp quyền camera để xác thực khuôn mặt'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      cameras = await availableCameras();

      // Use front camera if available
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khởi tạo camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _takePicture() async {
    if (controller == null || !controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final XFile image = await controller!.takePicture();
      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showImagePreviewDialog(bytes);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chụp ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImagePreviewDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ImagePreviewDialog(
        imageBytes: imageBytes,
        onRetake: () => Navigator.pop(context),
        onConfirm: (bytes) {
          Navigator.pop(context);
          _uploadImage(bytes);
        },
      ),
    );
  }

  Future<void> _uploadImage(Uint8List imageBytes) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert image to Base64
      final String base64Image = uint8ListToBase64(imageBytes);

      final response = await ImageService.uploadFaceImage(imageData: imageBytes, studentId: LocalDataService.instance.getId()!, isUpload: widget.isUploadFace);
      String message = "";
      if (widget.isUploadFace) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật khuôn mặt thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cập nhật khuôn mặt thất bại: ${response['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (response['is_match'] == true) {
          _updateRaVao();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xác thực khuôn mặt thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xác thực khuôn mặt thất bại!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      // Show success message
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi ảnh lên server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _updateRaVao() async {
    if (widget.idRaVao.isEmpty) return;
    final record = await XinRaVaoService.getXinRaVaoById(widget.idRaVao);
    if (record == null) return;
    final updatedRecord = record.copyWith(
      trangThai: TrangThaiXin.daVao,
      thoiGianVaoThucTe: DateTime.now(),
    );

    await XinRaVaoService.updateXinRaVao(record.id!, updatedRecord);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã check-in thành công')),
    );

  }

  String uint8ListToBase64(Uint8List bytes) {
    return base64Encode(bytes);
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
        title: Text(widget.isUploadFace ? 'Cập nhật khuôn mặt' : 'Xác thực khuôn mặt'),
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
                  Positioned.fill(
                    child: CustomPaint(
                      painter: FaceOverlayPainter(),
                    ),
                  ),
                if (_isCameraInitialized)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _takePicture,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.white,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 36,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Đặt khuôn mặt vào khung và nhấn chụp',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Xác nhận ảnh khuôn mặt',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Container(
            width: double.infinity,
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Chụp lại'),
                ),
                ElevatedButton.icon(
                  onPressed: () => onConfirm(imageBytes),
                  icon: const Icon(Icons.check),
                  label: const Text('Xác nhận'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter to display a face-shaped overlay
class FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2.5;
    final double radius = size.width * 0.4;

    // Create a path for the entire screen
    final Path backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create a path for the oval face cutout
    final Path ovalPath = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: radius * 1.3,
          height: radius * 1.6
      ));

    // Combine paths using difference operation to create a cutout
    final Path finalPath = Path.combine(
        PathOperation.difference,
        backgroundPath,
        ovalPath
    );

    // Fill the combined path with semi-transparent black
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(finalPath, overlayPaint);

    // Draw white outline around the face area
    final Paint outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: radius * 1.3,
          height: radius * 1.6
      ),
      outlinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
