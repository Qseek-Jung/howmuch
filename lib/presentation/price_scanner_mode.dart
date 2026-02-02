import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../core/design_system.dart';

class PriceScannerMode extends StatefulWidget {
  final String currencyCode;
  final Function(double) onPriceScanned;

  const PriceScannerMode({
    super.key,
    required this.currencyCode,
    required this.onPriceScanned,
  });

  @override
  State<PriceScannerMode> createState() => _PriceScannerModeState();
}

class _PriceScannerModeState extends State<PriceScannerMode>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isPaused = false;

  // Zoom
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  bool _isFlashOn = false;

  // OCR
  // Use Chinese script to support Hanzi/Kanji units (万, 億) along with Latin numbers.
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.chinese,
  );

  // Smoothing
  final List<double> _priceBuffer = [];
  static const int _bufferSize = 5;

  // Visual Feedback
  Rect? _targetRect; // Bounding box of the recognized price
  // We can't easily map this to screen coordinates without complex logic,
  // so we might just use this to trigger a "Detected" indicator for now.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-initialize camera on resume if needed
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      // Important: Update state to show loading indicator and prevent usage of disposed controller
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  // ... (Lines 80-324 omitted/unchanged in this replace, targeting _parsePrice and lifecycle) ...
  // Wait, I can't skip lines in replace_file_content like that if I want to target two separate blocks unless I use multi_replace.
  // I will use replace_file_content for _parsePrice ONLY first, then another call for lifecycle.
  // Actually, I'll use multi_replace.

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      print("No cameras available on this device.");
      return;
    }
    final firstCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);

      _minZoom = await _cameraController!.getMinZoomLevel();
      double nativeMax = await _cameraController!.getMaxZoomLevel();
      // Clamp Max Zoom to 5.0 for usability (OCR doesn't need 100x)
      _maxZoom = nativeMax > 5.0 ? 5.0 : nativeMax;

      // Set Default to Middle
      _currentZoom = (_minZoom + _maxZoom) / 2;

      await _cameraController!.setZoomLevel(_currentZoom);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });

        // Start Image Stream
        _cameraController!.startImageStream(_processImage);
      }
    } catch (e) {
      print("Camera init error: $e");
    }
  }

  void _processImage(CameraImage image) {
    if (_isProcessing || _isPaused) return;
    _isProcessing = true;
    _analyzeText(image);
  }

  Future<void> _analyzeText(CameraImage image) async {
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final recognizedText = await _textRecognizer.processImage(inputImage);

      _PriceCandidate? bestCandidate;
      TextLine? bestBlock;

      double bestDist = 1.0;

      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          // Spatial Filtering: Strictly check if center of line is within the center of the image.
          // We define a normalized "Safe Zone" in the center.
          final mediaSize = inputImage.metadata!.size;
          final lineCenter = line.boundingBox.center;

          // Adjust for rotation:
          // Android/iOS MLKit usually processes based on Metadata rotation.
          // However, the coordinates returned are in the coordinate system of the InputImage.
          // If we passed a rotation of 90/270, we must consider the swapped dimensions.
          final rotation =
              inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg;
          double dataWidth = mediaSize.width;
          double dataHeight = mediaSize.height;

          if (rotation == InputImageRotation.rotation90deg ||
              rotation == InputImageRotation.rotation270deg) {
            dataWidth = mediaSize.height;
            dataHeight = mediaSize.width;
          }

          // Normalize coordinates (0.0 to 1.0)
          final double nx = lineCenter.dx / dataWidth;
          final double ny = lineCenter.dy / dataHeight;

          // ROI definition (Approximation):
          // Horizontal: 0.2 to 0.8 (Central 60%)
          // Vertical: 0.45 to 0.55 (Strict central 10% to prevent reading above/below)
          if (nx < 0.2 || nx > 0.8) continue;
          if (ny < 0.45 || ny > 0.55) continue;

          final candidate = _parsePrice(line.text);
          if (candidate != null) {
            final dist = (ny - 0.5).abs();

            bool replace = false;
            if (bestCandidate == null) {
              replace = true;
            } else {
              // Priority: Center Proximity > Score (mostly)
              // If we have multiple lines, user aims the center line.
              // We prioritize the most 'central' line amongst valid numbers.
              if (candidate.score >= bestCandidate.score) {
                if (dist < bestDist) replace = true;
              } else {
                // If candidate is lower score but much more central?
                // Example: '500' (score 1) at center vs '12,000.00' (score 3) at edge.
                // User wants center. So if score is at least valid (>0), we take center.
                if (dist < bestDist && candidate.score > 0) replace = true;
              }
            }

            if (replace) {
              bestCandidate = candidate;
              bestBlock = line; // Assigned 'line' instead of 'block'
              bestDist = dist;
            }
          }
        }
      }

      if (bestCandidate != null) {
        _addPriceToBuffer(bestCandidate.value);
        final smoothedPrice = _getSmoothedPrice();

        if (smoothedPrice != null) {
          // Provide feedback
          // widget.onPriceScanned(smoothedPrice);
          // Only call if different to avoid spamming? parent setState logic is cheap enough for now.

          if (mounted) {
            widget.onPriceScanned(smoothedPrice);
            setState(() {
              _targetRect = bestBlock?.boundingBox;
            });
          }
        }
      } else {
        if (mounted && _targetRect != null) {
          setState(() {
            _targetRect = null;
          });
        }
      }
    } catch (e) {
      print("OCR Error: $e");
    } finally {
      // Small delay to prevent CPU choking, adjust as needed
      if (mounted) {
        Future.delayed(
          const Duration(milliseconds: 10),
          () => _isProcessing = false,
        );
      } else {
        _isProcessing = false;
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      print('Error Toggling Flash: $e');
    }
  }

  void _addPriceToBuffer(double price) {
    if (_priceBuffer.length >= _bufferSize) {
      _priceBuffer.removeAt(0);
    }
    _priceBuffer.add(price);
  }

  double? _getSmoothedPrice() {
    if (_priceBuffer.isEmpty) return null;

    // Simple mode (most frequent)
    final frequency = <double, int>{};
    for (var p in _priceBuffer) {
      frequency[p] = (frequency[p] ?? 0) + 1;
    }

    // Require at least N frames of consistency
    double? mode;
    int maxFreq = 0;
    frequency.forEach((k, v) {
      if (v > maxFreq) {
        maxFreq = v;
        mode = k;
      }
    });

    if (maxFreq >= 3) return mode;
    return null;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraController?.description;
    if (camera == null) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // Fix: Use raw value properly
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    final bytes = _concatenatePlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    if (Platform.isAndroid && planes.length == 3) {
      final allBytes = WriteBuffer();
      for (var plane in planes) {
        allBytes.putUint8List(plane.bytes);
      }
      return allBytes.done().buffer.asUint8List();
    } else {
      return planes.first.bytes;
    }
  }

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  _PriceCandidate? _parsePrice(String text) {
    // 1. Normalization
    // Replace full-width numbers and common variations of separators
    String clean = text
        .replaceAll('０', '0')
        .replaceAll('１', '1')
        .replaceAll('２', '2')
        .replaceAll('３', '3')
        .replaceAll('４', '4')
        .replaceAll('５', '5')
        .replaceAll('６', '6')
        .replaceAll('７', '7')
        .replaceAll('８', '8')
        .replaceAll('９', '9')
        .replaceAll('’', '\'')
        .replaceAll('‘', '\'') // Normalize apostrophes
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        ) // Normalize all whitespace (newlines, nbsp) to single space
        .trim();

    // 2. Extract potential number part with units
    // Regex matches: [optional sign] [digits/separators] [optional unit]
    // Units: k, m, b, 万, 萬, 千, 億, 亿
    final RegExp tokenRegex = RegExp(r'([-]?[\d.,\s\x27]+)\s?([kKmMbB万萬千億亿]?)');
    final match = tokenRegex.firstMatch(clean);

    if (match == null) return null;

    String rawNumber = match.group(1)?.trim() ?? "";
    String unit = match.group(2)?.toLowerCase() ?? "";

    if (rawNumber.isEmpty) return null;

    // Handle .99 or ,99 at start
    if (rawNumber.startsWith('.') || rawNumber.startsWith(',')) {
      rawNumber = '0$rawNumber';
    }

    // 3. Robust Number Parsing
    // Remove spaces (handle "55 000" -> "55000")
    String processing = rawNumber.replaceAll(' ', '');

    // Check for apostrophes (Swiss/others)
    if (processing.contains('\'')) {
      processing = processing.replaceAll('\'', '');
    }

    // Analyze separators left (comma/dot)
    bool hasComma = processing.contains(',');
    bool hasDot = processing.contains('.');

    if (hasComma && hasDot) {
      // Both present (e.g., 1,234.56 or 1.234,56)
      // The LAST one is the decimal separator.
      int lastComma = processing.lastIndexOf(',');
      int lastDot = processing.lastIndexOf('.');

      if (lastComma > lastDot) {
        // Euro style: 1.234,56 -> 1234.56
        processing = processing.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // US style: 1,234.56 -> 1234.56
        processing = processing.replaceAll(',', '');
      }
    } else if (hasComma) {
      // Only comma (e.g., 1,234 or 12,34)
      // Heuristic:
      // If comma appears multiple times -> Thousands separator (1,234,567)
      // If comma appears once:
      //   - If > 2 decimals (e.g. 1,000) -> Likely Thousands (unless currency is strictly Euro decimal, but 1,000 usually implies 1k)
      //   - If <= 2 decimals (e.g. 12,99 or 12,5) -> Likely Decimal

      // Check currency preference as baseline
      bool preferEuro = [
        'EUR',
        'VND',
        'IDR',
        'TRY',
        'BRL',
        'ARS',
        'CLP',
      ].contains(widget.currencyCode);

      int count = processing.split(',').length - 1;
      if (count > 1) {
        // Multiple commas -> Must be thousands
        processing = processing.replaceAll(',', '');
      } else {
        // Single comma
        int decimals = processing.length - processing.lastIndexOf(',') - 1;
        if (decimals == 3) {
          // "1,234" -> Ambiguous.
          // If Euro-preferring, likely 1.234 (1.2). But price tags usually show 2 decimals.
          // If US-preferring, likely 1234.
          // "1,000" is universally associated with 1k more than 1.0.
          if (preferEuro) {
            // In Euro, '.' is thousand. So if we see ',', it SHOULD be decimal.
            // But 1,234 (decimal) = 1.234.
            processing = processing.replaceAll(',', '.');
          } else {
            // US: Comma is thousand
            processing = processing.replaceAll(',', '');
          }
        } else {
          // 12,99 or 12,9 -> Decimal
          processing = processing.replaceAll(',', '.');
        }
      }
    } else if (hasDot) {
      // Only dot (e.g., 1.234 or 12.34)
      int count = processing.split('.').length - 1;
      if (count > 1) {
        // Multiple dots -> Thousands
        processing = processing.replaceAll('.', '');
      } else {
        // Single dot
        int decimals = processing.length - processing.lastIndexOf('.') - 1;
        if (decimals == 3) {
          // "1.234" -> Ambiguous.
          // If Euro (dot is thousand) -> 1234.
          // If US (dot is decimal) -> 1.234.
          bool preferEuro = [
            'EUR',
            'VND',
            'IDR',
            'TRY',
            'BRL',
            'ARS',
            'CLP',
          ].contains(widget.currencyCode);

          if (preferEuro) {
            processing = processing.replaceAll('.', '');
          } else {
            // US: dot is decimal
            // No change needed
          }
        } else {
          // 12.99 or 12.9 -> Decimal
          // No change needed
        }
      }
    }

    // 4. Apply Units
    double multiplier = 1.0;
    int score = 0;

    switch (unit) {
      case 'k':
      case 'K':
      case '千':
        multiplier = 1000.0;
        score += 2;
        break;
      case 'm':
      case 'M':
        multiplier = 1000000.0;
        score += 2;
        break;
      case 'b':
      case 'B':
        multiplier = 1000000000.0;
        score += 2;
        break;
      case '万':
      case '萬':
        multiplier = 10000.0;
        score += 2;
        break;
      case '億':
      case '亿':
        multiplier = 100000000.0;
        score += 2;
        break;
    }

    double value = 0.0;
    try {
      value = double.parse(processing);
    } catch (e) {
      return null;
    }

    // 5. Final Calculation
    value *= multiplier;

    // 6. Scoring
    if (value > 0) score += 1;
    if (rawNumber.contains('.') || rawNumber.contains(',')) score += 1;
    // Strong signal for Swiss/Currency
    if (processing.contains('\'') && widget.currencyCode == 'CHF') {
      score += 3;
    }

    return _PriceCandidate(value: value, score: score);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return GestureDetector(
      onScaleStart: (details) {
        _baseZoom = _currentZoom;
      },
      onScaleUpdate: (details) {
        double newZoom = _baseZoom * details.scale;
        if (newZoom < _minZoom) newZoom = _minZoom;
        if (newZoom > _maxZoom) newZoom = _maxZoom;

        // Update immediately for smooth UI
        if (newZoom != _currentZoom) {
          setState(() {
            _currentZoom = newZoom;
          });
          _cameraController!.setZoomLevel(newZoom);
        }
      },
      child: Stack(
        children: [
          // 1. Camera Preview
          SizedBox.expand(child: CameraPreview(_cameraController!)),

          // 2. ROI Overlay
          _buildROIOverlay(),

          // 3. Simple Indicator "Overlay on Number"
          if (_targetRect != null)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 250,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 3.5 Pause/Resume Control (Below ROI)
          // ROI is Centered, height 80.
          // We want button below it.

          // 4. Zoom Slider
          Align(
            alignment:
                Alignment.centerRight, // Reverted to Center Right as requested
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                height: 200,
                width: 40,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12.0, // Larger Grip
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 28.0, // Large Touch Area
                      ),
                      trackHeight: 6.0,
                    ),
                    child: Slider(
                      value: _currentZoom,
                      min: _minZoom,
                      max: _maxZoom,
                      onChanged: (val) {
                        setState(() => _currentZoom = val);
                        _cameraController!.setZoomLevel(val);
                      },
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.white30,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Control Bar (Apple Style)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 140,
              padding: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Distribute evenly
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Currency Indicator (Moved 5px Right)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 25,
                    ), // Increased to 25px
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.currencyCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Shutter / Pause Button (Center, Large)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPaused = !_isPaused;
                        if (!_isPaused) {
                          _targetRect = null;
                          _priceBuffer.clear();
                        }
                      });
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.transparent,
                      ),
                      padding: const EdgeInsets.all(
                        4,
                      ), // Spacing between ring and button
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isPaused ? Colors.white : Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: _isPaused ? Colors.black : Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),

                  // 3. Flash Toggle (Moved 5px Left)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 25,
                    ), // Increased to 25px
                    child: GestureDetector(
                      onTap: _toggleFlash,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white10, // Subtle glass effect
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: _isFlashOn
                              ? Colors.yellowAccent
                              : Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Removed Back Button as requested
        ],
      ),
    );
  }

  Widget _buildROIOverlay() {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 80, // Reduced from 120
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCandidate {
  final double value;
  final int score;
  _PriceCandidate({required this.value, required this.score});
}
