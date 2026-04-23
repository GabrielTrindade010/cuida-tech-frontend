import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/theme/app_theme.dart';

class TakePictureScreen extends StatefulWidget {
  final String documentType; // 'RG_FRENTE', 'RG_VERSO', 'SELFIE'
  const TakePictureScreen({super.key, required this.documentType});

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Se for selfie, usa a camera frontal, senão traseira
    final cameraConfig = widget.documentType == 'SELFIE' 
        ? _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => _cameras.first)
        : _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => _cameras.first);

    _controller = CameraController(cameraConfig, ResolutionPreset.high, enableAudio: false);

    await _controller!.initialize();
    if (mounted) setState(() => _isInit = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final XFile picture = await _controller!.takePicture();
      if (!mounted) return;
      
      // Retorna a imagem tirada (caminho do arquivo)
      Navigator.pop(context, picture.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao capturar foto.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _controller == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.documentType == 'SELFIE' ? 'Centralize seu rosto' : 'Enquadre o documento'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          
          // Overlay de Máscara (RG/CNH - Horizontal ou Selfie - Circular)
          if (widget.documentType != 'SELFIE')
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.25,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryGreen, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          if (widget.documentType == 'SELFIE')
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryBlue, width: 3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
          // Botão Tirar Foto
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGreen, width: 4),
                  ),
                  child: const Center(child: Icon(Icons.camera_alt, size: 36, color: Colors.black87)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
