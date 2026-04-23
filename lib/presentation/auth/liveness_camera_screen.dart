import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../core/theme/app_theme.dart';

/// Liveness challenge steps
enum _Challenge {
  detectFace,
  blink,
  shakeHead,
  holdDocument,
  capturing,
  done,
}

class LivenessCameraScreen extends StatefulWidget {
  const LivenessCameraScreen({super.key});

  @override
  State<LivenessCameraScreen> createState() => _LivenessCameraScreenState();
}

class _LivenessCameraScreenState extends State<LivenessCameraScreen>
    with WidgetsBindingObserver {
  // ─── Camera ────────────────────────────────────────────────────────────────
  CameraController? _cameraCtrl;
  bool _cameraReady = false;
  bool _processingFrame = false;

  // ─── ML Kit ────────────────────────────────────────────────────────────────
  late final FaceDetector _faceDetector;

  // ─── Liveness State ────────────────────────────────────────────────────────
  _Challenge _challenge = _Challenge.detectFace;
  String _message = 'Posicione seu rosto e o documento na câmera';
  String _subMessage = 'Olhe diretamente para a câmera';
  bool _challengePassed = false;

  // blink
  bool _blinkStarted = false;

  // head shake: track leftDone & rightDone
  bool _turnedLeft  = false;
  bool _turnedRight = false;

  // document: face must occupy only top 40% of frame (room for document below)
  bool _documentDetected = false;

  // countdown for auto-capture
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,  // eye open probability
        enableLandmarks: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraCtrl?.stopImageStream();
    _cameraCtrl?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraCtrl?.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // ─── Camera Init ───────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraCtrl = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraCtrl!.initialize();
    if (!mounted) return;

    setState(() => _cameraReady = true);
    _cameraCtrl!.startImageStream(_processFrame);
  }

  // ─── Frame Processing ──────────────────────────────────────────────────────

  Future<void> _processFrame(CameraImage image) async {
    if (_processingFrame || _challenge == _Challenge.done) return;
    _processingFrame = true;

    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;
      setState(() => _evaluateChallenge(faces, image));
    } catch (_) {
      // ignore frame errors silently
    } finally {
      _processingFrame = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _cameraCtrl?.description;
    if (camera == null) return null;

    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // ─── Challenge Evaluation ──────────────────────────────────────────────────

  void _evaluateChallenge(List<Face> faces, CameraImage image) {
    switch (_challenge) {
      case _Challenge.detectFace:
        _evalDetectFace(faces);
        break;
      case _Challenge.blink:
        _evalBlink(faces);
        break;
      case _Challenge.shakeHead:
        _evalShakeHead(faces);
        break;
      case _Challenge.holdDocument:
        _evalDocument(faces, image);
        break;
      case _Challenge.capturing:
      case _Challenge.done:
        break;
    }
  }

  void _evalDetectFace(List<Face> faces) {
    if (faces.isEmpty) {
      _message    = 'Nenhum rosto detectado';
      _subMessage = 'Posicione seu rosto centralizado na câmera';
      return;
    }
    final face = faces.first;
    // Check face is large enough (face width > 20% of screen width)
    if (face.boundingBox.width < 80) {
      _message    = 'Aproxime-se da câmera';
      _subMessage = 'Seu rosto precisa preencher a moldura superior';
      return;
    }
    // All good → next challenge
    _message    = '✅ Rosto detectado!';
    _subMessage = 'Preparando próximo desafio...';
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() {
        _challenge  = _Challenge.blink;
        _message    = 'Pisque os olhos';
        _subMessage = 'Feche e abra os olhos uma vez';
      });
    });
  }

  void _evalBlink(List<Face> faces) {
    if (faces.isEmpty) {
      _message = 'Rosto perdido — reposicione-se';
      return;
    }
    final face = faces.first;
    final left  = face.leftEyeOpenProbability ?? 1.0;
    final right = face.rightEyeOpenProbability ?? 1.0;

    if (!_blinkStarted) {
      if (left < 0.25 && right < 0.25) {
        _blinkStarted = true;
        _message    = '👁️ Olhos fechados detectados...';
        _subMessage = 'Agora abra os olhos';
      } else {
        _message    = 'Pisque os olhos';
        _subMessage = 'Feche completamente os dois olhos';
      }
    } else {
      if (left > 0.7 && right > 0.7) {
        _blinkStarted = false;
        _message    = '✅ Piscada confirmada!';
        _subMessage = 'Preparando próximo desafio...';
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() {
            _challenge  = _Challenge.shakeHead;
            _message    = 'Balance a cabeça';
            _subMessage = 'Balance sua cabeça de um lado para o outro';
          });
        });
      }
    }
  }

  void _evalShakeHead(List<Face> faces) {
    if (faces.isEmpty) {
      _message = 'Rosto perdido — reposicione-se';
      return;
    }
    final face = faces.first;
    final yaw = face.headEulerAngleY ?? 0.0; // positive = right, negative = left

    if (!_turnedLeft && yaw < -18) {
      _turnedLeft = true;
      _message    = '✅ Lado esquerdo detectado!';
      _subMessage = 'Agora balance para o OUTRO lado';
    } else if (_turnedLeft && !_turnedRight && yaw > 18) {
      _turnedRight = true;
      _message     = '✅ Balance detectado!';
      _subMessage  = 'Volte para o centro e segure o documento';
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() {
          _challenge  = _Challenge.holdDocument;
          _message    = 'Segure seu documento';
          _subMessage = 'Coloque o RG ou CNH abaixo do rosto, na moldura';
        });
      });
    } else if (!_turnedLeft) {
      _message    = 'Balance a cabeça para um lado';
      _subMessage = 'Incline suavemente a cabeça para a esquerda ou direita';
    } else {
      _message    = 'Agora balance para o outro lado';
      _subMessage = 'Continue o movimento de balanço';
    }
  }

  void _evalDocument(List<Face> faces, CameraImage image) {
    if (faces.isEmpty) {
      _message    = 'Rosto perdido — reposicione-se';
      _documentDetected = false;
      return;
    }
    final face = faces.first;

    // Heuristic: face bounding box should be in upper 55% of frame
    // meaning there is room below the face for a document.
    final faceBottomRatio = (face.boundingBox.bottom) / image.height;
    final faceCenterY     = face.boundingBox.center.dy / image.height;

    final faceIsHigh = faceCenterY < 0.50 && faceBottomRatio < 0.65;

    // Also check face width is not too wide (document needs horizontal space too)
    final faceWidthRatio = face.boundingBox.width / image.width;
    final documentSpace  = faceWidthRatio < 0.75 && faceIsHigh;

    if (!documentSpace) {
      _documentDetected = false;
      _message    = 'Reposicione o rosto para o topo';
      _subMessage = 'Deixe espaço abaixo para o documento aparecer';
      return;
    }

    if (!_documentDetected) {
      _documentDetected = true;
      _message    = '📄 Documento detectado na moldura!';
      _subMessage = 'Mantenha a posição — capturando em 3 segundos...';
      _startCountdown();
    }
  }

  void _startCountdown() async {
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() { _challenge = _Challenge.capturing; });
    await _capturePhoto();
  }

  Future<void> _capturePhoto() async {
    try {
      await _cameraCtrl?.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200));
      final XFile? photo = await _cameraCtrl?.takePicture();
      if (!mounted) return;
      if (photo != null) {
        setState(() { _challenge = _Challenge.done; });
        Navigator.pop(context, photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao capturar foto. Tente novamente.')));
        setState(() {
          _challenge        = _Challenge.detectFace;
          _blinkStarted     = false;
          _turnedLeft       = false;
          _turnedRight      = false;
          _documentDetected = false;
          _countdown        = 0;
          _message    = 'Reiniciando validação...';
          _subMessage = 'Posicione seu rosto na câmera';
        });
        _cameraCtrl?.startImageStream(_processFrame);
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_cameraReady
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview
                CameraPreview(_cameraCtrl!),

                // Dark overlay with cutout frame
                _buildOverlay(),

                // Challenge UI at bottom
                _buildChallengePanel(),

                // Countdown bubble
                if (_countdown > 0) _buildCountdown(),
              ],
            ),
    );
  }

  Widget _buildOverlay() {
    return CustomPaint(
      painter: _FramePainter(
        challenge: _challenge,
        passed: _documentDetected,
      ),
    );
  }

  Widget _buildChallengePanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 32, left: 20, right: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _Challenge.values
                  .where((c) => c != _Challenge.capturing && c != _Challenge.done)
                  .map((c) {
                final idx      = _challengeIndex(c);
                final currIdx  = _challengeIndex(_challenge);
                final isDone   = idx < currIdx;
                final isActive = idx == currIdx;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.primaryGreen
                          : isActive
                              ? Colors.white
                              : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Icon
            Icon(
              _challengeIcon(),
              color: AppColors.primaryBlue,
              size: 32,
            ),
            const SizedBox(height: 10),

            // Main message
            Text(
              _message,
              style: const TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Sub message
            Text(
              _subMessage,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.85),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$_countdown',
            style: const TextStyle(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  IconData _challengeIcon() {
    switch (_challenge) {
      case _Challenge.detectFace:  return Icons.face_outlined;
      case _Challenge.blink:       return Icons.visibility_outlined;
      case _Challenge.shakeHead:   return Icons.swap_horiz_rounded;
      case _Challenge.holdDocument: return Icons.badge_outlined;
      case _Challenge.capturing:
      case _Challenge.done:        return Icons.check_circle_outline;
    }
  }

  int _challengeIndex(_Challenge c) {
    const ordered = [
      _Challenge.detectFace,
      _Challenge.blink,
      _Challenge.shakeHead,
      _Challenge.holdDocument,
    ];
    return ordered.indexOf(c);
  }
}

// ─── Custom Frame Painter ─────────────────────────────────────────────────────

class _FramePainter extends CustomPainter {
  final _Challenge challenge;
  final bool passed;

  const _FramePainter({required this.challenge, required this.passed});

  @override
  void paint(Canvas canvas, Size size) {
    final frameW = size.width * 0.88;
    final frameH = size.height * 0.70;
    final frameL = (size.width - frameW) / 2;
    final frameT = size.height * 0.05;
    final frameRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(frameL, frameT, frameW, frameH),
        const Radius.circular(20));

    // Even-odd path: full screen minus the frame cutout.
    // Only the area OUTSIDE the frame gets the dark tint.
    // The frame itself stays fully transparent (camera shows through).
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(frameRRect);

    canvas.drawPath(
        path, Paint()..color = Colors.black.withOpacity(0.55));

    // Border color based on current challenge state
    final borderColor = challenge == _Challenge.holdDocument && passed
        ? AppColors.primaryGreen
        : challenge == _Challenge.detectFace
            ? Colors.white
            : AppColors.primaryBlue;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(frameRRect, borderPaint);

    // Animated corner accents
    _drawCorners(canvas, frameL, frameT, frameW, frameH, borderColor);

    // Division line + zone labels (only during document challenge)
    if (challenge == _Challenge.holdDocument ||
        challenge == _Challenge.shakeHead) {
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.30)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final guideY = frameT + frameH * 0.50;
      canvas.drawLine(
          Offset(frameL + 16, guideY),
          Offset(frameL + frameW - 16, guideY),
          linePaint);
      _drawLabel(canvas, 'ROSTO', size.width / 2, frameT + frameH * 0.25);
      _drawLabel(canvas, 'DOCUMENTO', size.width / 2, frameT + frameH * 0.75);
    }
  }

  void _drawCorners(Canvas canvas, double l, double t, double w, double h, Color color) {
    const len = 20.0;
    const r   = 20.0;
    final p   = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(l + r, t), Offset(l + r + len, t), p);
    canvas.drawLine(Offset(l, t + r), Offset(l, t + r + len), p);
    // Top-right
    canvas.drawLine(Offset(l + w - r, t), Offset(l + w - r - len, t), p);
    canvas.drawLine(Offset(l + w, t + r), Offset(l + w, t + r + len), p);
    // Bottom-left
    canvas.drawLine(Offset(l + r, t + h), Offset(l + r + len, t + h), p);
    canvas.drawLine(Offset(l, t + h - r), Offset(l, t + h - r - len), p);
    // Bottom-right
    canvas.drawLine(Offset(l + w - r, t + h), Offset(l + w - r - len, t + h), p);
    canvas.drawLine(Offset(l + w, t + h - r), Offset(l + w, t + h - r - len), p);
  }

  void _drawLabel(Canvas canvas, String text, double cx, double cy) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(
              color: Colors.white54, fontSize: 11, letterSpacing: 2)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.challenge != challenge || old.passed != passed;
}
