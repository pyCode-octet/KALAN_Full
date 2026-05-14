import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/ocr_service.dart';
import 'generating_screen.dart';

class CameraOCRScreen extends StatefulWidget {
  const CameraOCRScreen({super.key});

  @override
  State<CameraOCRScreen> createState() => _CameraOCRScreenState();
}

class _CameraOCRScreenState extends State<CameraOCRScreen> {
  CameraController? _controller;
  List<XFile> _capturedImages = [];
  bool _isInitializing = true;
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImages.add(image);
      });
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<void> _processOCR() async {
    if (_capturedImages.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    StringBuffer fullText = StringBuffer();
    for (var image in _capturedImages) {
      final text = await _ocrService.extractText(image.path);
      fullText.writeln(text);
    }

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GeneratingScreen(ocrText: fullText.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Real camera viewfinder
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          
          // Scanning overlay guides
          _buildScanningOverlay(),

          // Top bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Scanner un cours',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    _controller!.value.flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    final newMode = _controller!.value.flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
                    _controller!.setFlashMode(newMode);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          // Captured images preview grid (bottom left)
          if (_capturedImages.isNotEmpty)
            Positioned(
              bottom: 140,
              left: 16,
              right: 16,
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_capturedImages[index].path),
                              width: 60,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0, right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _capturedImages.removeAt(index)),
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_capturedImages.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: ElevatedButton(
                      onPressed: _processOCR,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text('Valider (${_capturedImages.length} photos)'),
                    ),
                  )
                else
                  Text(
                    'Place ton cours dans le cadre',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                      onPressed: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() => _capturedImages.add(image));
                        }
                      },
                    ),
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 56, height: 56,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                      onPressed: () async {
                        final cameras = await availableCameras();
                        if (cameras.length < 2) return;
                        final newCamera = _controller!.description == cameras.first ? cameras.last : cameras.first;
                        await _controller!.dispose();
                        _controller = CameraController(newCamera, ResolutionPreset.high, enableAudio: false);
                        await _controller!.initialize();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Center(
      child: Container(
        width: 300, height: 450,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            _cornerGuide(top: 0, left: 0, rotation: 0),
            _cornerGuide(top: 0, right: 0, rotation: 1.5708),
            _cornerGuide(bottom: 0, left: 0, rotation: -1.5708),
            _cornerGuide(bottom: 0, right: 0, rotation: 3.14159),
          ],
        ),
      ),
    );
  }

  Widget _cornerGuide({double? top, double? bottom, double? left, double? right, required double rotation}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 4),
              left: BorderSide(color: AppColors.primary, width: 4),
            ),
          ),
        ),
      ),
    );
  }
}
