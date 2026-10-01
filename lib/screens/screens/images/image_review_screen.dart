import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as image_package;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../services/database_service.dart';
import '../../../services/python_analysis_service.dart';
import '../analysis/screening_result_screen.dart';

enum AnnotationTool {
  circle,
  arrow,
  measure,
  label,
  undo,
}

enum AnnotationType {
  circle,
  arrow,
  measure,
  label,
}

/// Stores one annotation using coordinates relative to the displayed image.
class ImageAnnotation {
  final AnnotationType type;

  final double startX;
  final double startY;
  final double endX;
  final double endY;

  final String? label;
  final String? text;

  final Color colour;

  ImageAnnotation({
    required this.type,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.label,
    this.text,
    required this.colour,
  });
}

class ImageQualityResult {
  final double focusScore;
  final String exposure;
  final bool passed;

  const ImageQualityResult({
    required this.focusScore,
    required this.exposure,
    required this.passed,
  });
}

/// Screen used to review and annotate a microscopy image before
/// sending the original image to the computer analysis engine.
class ImageReviewScreen extends StatefulWidget {
  final String sampleId;
  final String specimenType;
  final String imagePath;
  final String imageId;

  const ImageReviewScreen({
    super.key,
    required this.sampleId,
    required this.specimenType,
    required this.imagePath,
    required this.imageId,
  });

  @override
  State<ImageReviewScreen> createState() =>
      _ImageReviewScreenState();
}

class _ImageReviewScreenState extends State<ImageReviewScreen> {
  static const Color teal = Color(0xFF087E78);
  static const Color secondaryText = Color(0xFF60747B);
  static const Color pageBackground = Color(0xFFEEF3F5);
  static const Color lightGreen = Color(0xFFE2F3F1);
  static const Color toolBackground = Color(0xFFF5F8F9);

  late String currentImagePath;
  late String currentImageId;

  final ImagePicker imagePicker = ImagePicker();

  double imageRotation = 0;

  final List<ImageAnnotation> annotations = [];

  AnnotationTool? selectedTool;

  Offset? dragStart;
  Offset? dragCurrent;

  int nextAnnotationNumber = 1;

  Color selectedAnnotationColour = teal;

  ImageQualityResult? imageQuality;

  bool calculatingQuality = true;
  bool isCalculating = false;

  double? pixelsPerMicrometre;

  final TransformationController transformationController =
      TransformationController();

  bool isZoomed = false;

  @override
  void initState() {
    super.initState();

    currentImagePath = widget.imagePath;
    currentImageId = widget.imageId;

    calculateImageQuality();
  }

  @override
  void dispose() {
    transformationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // IMAGE QUALITY
  // ---------------------------------------------------------------------------

  Future<void> calculateImageQuality() async {
    try {
      final imageFile = File(currentImagePath);

      if (!await imageFile.exists()) {
        throw Exception('The image file could not be found.');
      }

      final bytes = await imageFile.readAsBytes();

      final decodedImage = image_package.decodeImage(bytes);

      if (decodedImage == null) {
        throw Exception(
          'The selected image could not be decoded.',
        );
      }

      final focusScore = calculateFocusScore(decodedImage);
      final exposure = calculateExposure(decodedImage);

      final passed =
          focusScore >= 20 &&
          exposure != 'Too Dark' &&
          exposure != 'Too Bright';

      if (!mounted) {
        return;
      }

      setState(() {
        imageQuality = ImageQualityResult(
          focusScore: focusScore,
          exposure: exposure,
          passed: passed,
        );

        calculatingQuality = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        imageQuality = null;
        calculatingQuality = false;
      });
    }
  }

  double calculateFocusScore(
    image_package.Image image,
  ) {
    final width = image.width;
    final height = image.height;

    if (width < 2 || height < 2) {
      return 0;
    }

    double totalDifference = 0;
    double totalSquaredDifference = 0;
    int count = 0;

    final stepX = math.max(
      1,
      width ~/ 300,
    );

    final stepY = math.max(
      1,
      height ~/ 300,
    );

    for (
      int y = 0;
      y < height - 1;
      y += stepY
    ) {
      for (
        int x = 0;
        x < width - 1;
        x += stepX
      ) {
        final current = image.getPixel(
          x,
          y,
        );

        final right = image.getPixel(
          x + 1,
          y,
        );

        final currentBrightness =
            (current.r +
                    current.g +
                    current.b) /
                3;

        final rightBrightness =
            (right.r +
                    right.g +
                    right.b) /
                3;

        final difference =
            currentBrightness -
            rightBrightness;

        totalDifference += difference.abs();

        totalSquaredDifference +=
            difference * difference;

        count++;
      }
    }

    if (count == 0) {
      return 0;
    }

    final average =
        totalDifference / count;

    final variance =
        (totalSquaredDifference / count) -
        (average * average);

    final score = (variance / 500 * 100)
        .clamp(0.0, 100.0)
        .toDouble();

    return score;
  }

  String calculateExposure(
    image_package.Image image,
  ) {
    final width = image.width;
    final height = image.height;

    if (width == 0 || height == 0) {
      return 'Unknown';
    }

    double totalBrightness = 0;
    int pixelCount = 0;

    final stepX = math.max(
      1,
      width ~/ 300,
    );

    final stepY = math.max(
      1,
      height ~/ 300,
    );

    for (
      int y = 0;
      y < height;
      y += stepY
    ) {
      for (
        int x = 0;
        x < width;
        x += stepX
      ) {
        final pixel = image.getPixel(
          x,
          y,
        );

        final brightness =
            (0.299 * pixel.r) +
            (0.587 * pixel.g) +
            (0.114 * pixel.b);

        totalBrightness += brightness;
        pixelCount++;
      }
    }

    if (pixelCount == 0) {
      return 'Unknown';
    }

    final average =
        totalBrightness / pixelCount;

    if (average < 40) {
      return 'Too Dark';
    }

    if (average > 225) {
      return 'Too Bright';
    }

    return 'Good';
  }

  // ---------------------------------------------------------------------------
  // ANNOTATION TOOLS
  // ---------------------------------------------------------------------------

  void selectTool(AnnotationTool tool) {
    if (tool == AnnotationTool.undo) {
      undoLastAnnotation();
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      selectedTool = tool;
      dragStart = null;
      dragCurrent = null;
    });
  }

  void undoLastAnnotation() {
    if (annotations.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      annotations.removeLast();

      if (nextAnnotationNumber > 1) {
        nextAnnotationNumber--;
      }
    });
  }

  void handleImagePointerDown(
    Offset position,
    BoxConstraints constraints,
  ) {
    if (selectedTool == null ||
        selectedTool == AnnotationTool.label ||
        selectedTool == AnnotationTool.undo) {
      return;
    }

    final normalisedPosition =
        normalisePosition(
      position,
      constraints,
    );

    setState(() {
      dragStart = normalisedPosition;
      dragCurrent = normalisedPosition;
    });
  }

  void handleImagePointerMove(
    Offset position,
    BoxConstraints constraints,
  ) {
    if (dragStart == null) {
      return;
    }

    final normalisedPosition =
        normalisePosition(
      position,
      constraints,
    );

    setState(() {
      dragCurrent = normalisedPosition;
    });
  }

  void handleImagePointerUp() {
    if (dragStart == null ||
        dragCurrent == null ||
        selectedTool == null) {
      return;
    }

    final start = dragStart!;
    final end = dragCurrent!;

    if (selectedTool == AnnotationTool.circle) {
      createCircleAnnotation(
        start,
        end,
      );
    } else if (selectedTool == AnnotationTool.arrow) {
      createArrowAnnotation(
        start,
        end,
      );
    } else if (selectedTool == AnnotationTool.measure) {
      createMeasureAnnotation(
        start,
        end,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      dragStart = null;
      dragCurrent = null;
    });
  }

  Offset normalisePosition(
    Offset position,
    BoxConstraints constraints,
  ) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    if (width <= 0 || height <= 0) {
      return Offset.zero;
    }

    final x = (position.dx / width)
        .clamp(0.0, 1.0)
        .toDouble();

    final y = (position.dy / height)
        .clamp(0.0, 1.0)
        .toDouble();

    return Offset(
      x,
      y,
    );
  }

  void createCircleAnnotation(
    Offset start,
    Offset end,
  ) {
    final left = math.min(
      start.dx,
      end.dx,
    );

    final top = math.min(
      start.dy,
      end.dy,
    );

    final right = math.max(
      start.dx,
      end.dx,
    );

    final bottom = math.max(
      start.dy,
      end.dy,
    );

    if ((right - left) < 0.02 ||
        (bottom - top) < 0.02) {
      return;
    }

    setState(() {
      annotations.add(
        ImageAnnotation(
          type: AnnotationType.circle,
          startX: left,
          startY: top,
          endX: right,
          endY: bottom,
          label: 'A$nextAnnotationNumber',
          colour: selectedAnnotationColour,
        ),
      );

      nextAnnotationNumber++;
      selectedTool = null;
    });
  }

  void createArrowAnnotation(
    Offset start,
    Offset end,
  ) {
    setState(() {
      annotations.add(
        ImageAnnotation(
          type: AnnotationType.arrow,
          startX: start.dx,
          startY: start.dy,
          endX: end.dx,
          endY: end.dy,
          colour: selectedAnnotationColour,
        ),
      );

      selectedTool = null;
    });
  }

  void createMeasureAnnotation(
    Offset start,
    Offset end,
  ) {
    setState(() {
      annotations.add(
        ImageAnnotation(
          type: AnnotationType.measure,
          startX: start.dx,
          startY: start.dy,
          endX: end.dx,
          endY: end.dy,
          colour: selectedAnnotationColour,
        ),
      );

      selectedTool = null;
    });

    final distance =
        calculateRelativeDistance(
      start,
      end,
    );

    final message =
        pixelsPerMicrometre == null
            ? 'Measurement: ${distance.toStringAsFixed(2)} relative image units'
            : 'Measurement: ${(distance / pixelsPerMicrometre!).toStringAsFixed(2)} µm';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  /// Opens the label dialog and places the entered text on the image.
  ///
  /// This intentionally does not use a TextEditingController.
  /// The previous implementation disposed a controller while Flutter
  /// was still rebuilding the TextField, which caused:
  ///
  /// A TextEditingController was used after being disposed.
  Future<void> placeTextLabel(
    Offset position,
  ) async {
    String enteredText = '';

    final labelText = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Add Label',
          ),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
              enteredText = value;
            },
            decoration: const InputDecoration(
              hintText: 'Enter label',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                final text =
                    enteredText.trim();

                if (text.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  text,
                );
              },
              child: const Text(
                'Place',
              ),
            ),
          ],
        );
      },
    );

    if (labelText == null ||
        labelText.trim().isEmpty ||
        !mounted) {
      return;
    }

    setState(() {
      annotations.add(
        ImageAnnotation(
          type: AnnotationType.label,
          startX: position.dx,
          startY: position.dy,
          endX: position.dx,
          endY: position.dy,
          text: labelText.trim(),
          colour: selectedAnnotationColour,
        ),
      );

      selectedTool = null;
    });
  }

  Future<void> showColourPicker() async {
    final colours = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      teal,
      Colors.blue,
      Colors.purple,
      Colors.white,
    ];

    final selectedColour =
        await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Annotation Colour',
          ),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final colour in colours)
                InkWell(
                  onTap: () {
                    Navigator.pop(
                      dialogContext,
                      colour,
                    );
                  },
                  borderRadius:
                      BorderRadius.circular(24),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colour,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black26,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (selectedColour == null ||
        !mounted) {
      return;
    }

    setState(() {
      selectedAnnotationColour =
          selectedColour;
    });
  }

  void handleImageTap(
    TapUpDetails details,
    BoxConstraints constraints,
  ) {
    if (selectedTool != AnnotationTool.label) {
      return;
    }

    final position =
        normalisePosition(
      details.localPosition,
      constraints,
    );

    placeTextLabel(position);
  }

  double calculateRelativeDistance(
    Offset start,
    Offset end,
  ) {
    final dx =
        end.dx - start.dx;

    final dy =
        end.dy - start.dy;

    return math.sqrt(
      (dx * dx) + (dy * dy),
    );
  }

  // ---------------------------------------------------------------------------
  // IMAGE CONTROLS
  // ---------------------------------------------------------------------------

  void rotateImage() {
    setState(() {
      imageRotation += math.pi / 2;

      if (imageRotation >= math.pi * 2) {
        imageRotation = 0;
      }
    });
  }

  void toggleZoom() {
    if (isZoomed) {
      resetZoom();
      return;
    }

    transformationController.value =
        Matrix4.identity()
          ..scaleByDouble(
            2.0,
            2.0,
            1.0,
            1.0,
          );

    setState(() {
      isZoomed = true;
    });
  }

  void resetZoom() {
    transformationController.value =
        Matrix4.identity();

    if (mounted) {
      setState(() {
        isZoomed = false;
      });
    }
  }

  Future<void> replaceImage() async {
    try {
      final selectedImage =
          await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (selectedImage == null) {
        return;
      }

      final applicationDirectory =
          await getApplicationDocumentsDirectory();

      final imageDirectory =
          Directory(
        '${applicationDirectory.path}/sample_images',
      );

      if (!await imageDirectory.exists()) {
        await imageDirectory.create(
          recursive: true,
        );
      }

      final newImageId =
          'IMG_${DateTime.now().millisecondsSinceEpoch}';

      final fileExtension =
          selectedImage.path.contains('.')
              ? selectedImage.path
                  .split('.')
                  .last
                  .toLowerCase()
              : 'jpg';

      final newPath =
          '${imageDirectory.path}/'
          '$newImageId.$fileExtension';

      final copiedFile =
          await File(
        selectedImage.path,
      ).copy(newPath);

      try {
        await DatabaseService.deleteImageRecord(
          currentImageId,
        );
      } catch (_) {}

      final previousFile =
          File(currentImagePath);

      if (await previousFile.exists()) {
        try {
          await previousFile.delete();
        } catch (_) {}
      }

      try {
        await DatabaseService.saveImage({
          'id': newImageId,
          'sample_id': widget.sampleId,
          'file_path': copiedFile.path,
          'captured_at':
              DateTime.now().toIso8601String(),
          'status': 'Uploaded',
        });
      } catch (_) {}

      if (!mounted) {
        return;
      }

      setState(() {
        currentImageId = newImageId;
        currentImagePath = copiedFile.path;

        annotations.clear();
        nextAnnotationNumber = 1;
        imageRotation = 0;
        selectedTool = null;
        calculatingQuality = true;
        imageQuality = null;
      });

      resetZoom();

      await calculateImageQuality();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to replace image: $error',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // COMPUTER ANALYSIS
  // ---------------------------------------------------------------------------

  Future<void> finishAnnotation() async {
    if (currentImagePath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No image is available for analysis.',
          ),
        ),
      );
      return;
    }

    final imageFile =
        File(currentImagePath);

    if (!await imageFile.exists()) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The image file could not be found.',
          ),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isCalculating = true;
    });

    try {
      debugPrint(
        'Starting computer analysis...',
      );

      debugPrint(
        'Image path: $currentImagePath',
      );

      debugPrint(
        'Sample ID: ${widget.sampleId}',
      );

      final analysisResult =
          await PythonAnalysisService.analyzeBloodSmear(
        imagePath: currentImagePath,
      );

      debugPrint(
        'Computer analysis completed successfully.',
      );

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ScreeningResultScreen(
            patientName: 'Patient',
            patientId: 'Not recorded',
            specimen: widget.specimenType,
            collectedDate: 'Not recorded',
            doctorName: 'Not recorded',
            registrationNumber: 'Not recorded',
            sampleId: widget.sampleId,
            facilityName: 'PocketScope',
            analysis: analysisResult,
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        'COMPUTER ANALYSIS ERROR: $error',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration:
              const Duration(seconds: 8),
          content: Text(
            'Computer analysis failed:\n$error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCalculating = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // IMAGE AREA
  // ---------------------------------------------------------------------------

  Widget buildImageArea() {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        return ClipRRect(
          borderRadius:
              BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InteractiveViewer(
                  transformationController:
                      transformationController,
                  minScale: 1,
                  maxScale: 5,
                  boundaryMargin:
                      const EdgeInsets.all(80),
                  panEnabled:
                      selectedTool == null,
                  scaleEnabled:
                      selectedTool == null,
                  child: Transform.rotate(
                    angle: imageRotation,
                    child: Image.file(
                      File(currentImagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                if (selectedTool != null &&
                    selectedTool !=
                        AnnotationTool.undo)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior:
                          HitTestBehavior.translucent,
                      onTapUp: (details) {
                        handleImageTap(
                          details,
                          constraints,
                        );
                      },
                      onPanStart: (details) {
                        handleImagePointerDown(
                          details.localPosition,
                          constraints,
                        );
                      },
                      onPanUpdate: (details) {
                        handleImagePointerMove(
                          details.localPosition,
                          constraints,
                        );
                      },
                      onPanEnd: (details) {
                        handleImagePointerUp();
                      },
                    ),
                  ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter:
                          AnnotationPainter(
                        annotations:
                            annotations,
                        previewTool:
                            selectedTool,
                        previewStart:
                            dragStart,
                        previewEnd:
                            dragCurrent,
                        previewColour:
                            selectedAnnotationColour,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.65,
                      ),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${File(currentImagePath).uri.pathSegments.last}  •  ${formatCurrentTime()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color:
                        Colors.black.withValues(
                      alpha: 0.65,
                    ),
                    borderRadius:
                        BorderRadius.circular(8),
                    child: InkWell(
                      onTap: toggleZoom,
                      borderRadius:
                          BorderRadius.circular(8),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/maximize-2.svg',
                            width: 18,
                            height: 18,
                            colorFilter:
                                const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (pixelsPerMicrometre != null)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: buildScaleBar(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildScaleBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.65,
        ),
        borderRadius:
            BorderRadius.circular(6),
      ),
      child: const Text(
        'Calibrated scale',
        style: TextStyle(
          fontSize: 9,
          color: Colors.white,
        ),
      ),
    );
  }

  String formatCurrentTime() {
    final now = DateTime.now();

    final hour =
        now.hour.toString().padLeft(
              2,
              '0',
            );

    final minute =
        now.minute.toString().padLeft(
              2,
              '0',
            );

    return '$hour:$minute';
  }

  // ---------------------------------------------------------------------------
  // ANNOTATION BAR
  // ---------------------------------------------------------------------------

  Widget buildAnnotationBar() {
    return Container(
      width: double.infinity,
      height: 72,
      color: Colors.white,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
        children: [
          buildAnnotationTool(
            tool: AnnotationTool.circle,
            icon: 'assets/images/circle.svg',
            label: 'Circle',
          ),
          buildAnnotationTool(
            tool: AnnotationTool.arrow,
            icon: 'assets/images/arrow-up-right.svg',
            label: 'Arrow',
          ),
          buildAnnotationTool(
            tool: AnnotationTool.measure,
            icon: 'assets/images/ruler.svg',
            label: 'Measure',
          ),
          buildAnnotationTool(
            tool: AnnotationTool.label,
            icon: 'assets/images/type.svg',
            label: 'Label',
          ),
          buildAnnotationTool(
            tool: AnnotationTool.undo,
            icon: 'assets/images/undo-2.svg',
            label: 'Undo',
          ),
        ],
      ),
    );
  }

  Widget buildAnnotationTool({
    required AnnotationTool tool,
    required String icon,
    required String label,
  }) {
    final selected =
        selectedTool == tool;

    return InkWell(
      onTap: () {
        selectTool(tool);
      },
      borderRadius:
          BorderRadius.circular(8),
      child: SizedBox(
        width: 58,
        height: 64,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? lightGreen
                    : toolBackground,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  width: 19,
                  height: 19,
                  colorFilter:
                      ColorFilter.mode(
                    selected
                        ? teal
                        : secondaryText,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 12,
              child: Text(
                label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  height: 1,
                  color: selected
                      ? teal
                      : secondaryText,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // IMAGE QUALITY CARD
  // ---------------------------------------------------------------------------

  Widget buildImageQualityCard() {
    final quality = imageQuality;

    final passed =
        quality?.passed ?? false;

    return Container(
      width: 358,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Image Quality',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: calculatingQuality
                      ? Colors.grey.shade100
                      : passed
                          ? const Color(
                              0xFFE4F3EA,
                            )
                          : const Color(
                              0xFFFCE8E8,
                            ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Text(
                  calculatingQuality
                      ? 'Checking'
                      : passed
                          ? 'Passed'
                          : 'Review',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                    color: calculatingQuality
                        ? secondaryText
                        : passed
                            ? const Color(
                                0xFF2D7D5B,
                              )
                            : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              buildQualityMetric(
                value: calculatingQuality
                    ? '...'
                    : quality == null
                        ? 'N/A'
                        : '${quality.focusScore.toStringAsFixed(0)}%',
                label: 'Focus',
              ),

              const SizedBox(width: 8),

              buildQualityMetric(
                value: calculatingQuality
                    ? '...'
                    : quality?.exposure ?? 'N/A',
                label: 'Exposure',
              ),

              const SizedBox(width: 8),

              buildQualityMetric(
                value: 'Not assessed',
                label: 'Debris',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildQualityMetric({
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        height: 42,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: lightGreen,
          borderRadius:
              BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.1,
                fontWeight:
                    FontWeight.bold,
                color: teal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                height: 1.1,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 62,
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                    ),
                    tooltip: 'Back',
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Annotate Image',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${widget.specimenType} • Image review',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Material(
                    color: Colors.white,
                    child: InkWell(
                      onTap: rotateImage,
                      borderRadius:
                          BorderRadius.circular(8),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/rotate-cw.svg',
                            width: 20,
                            height: 20,
                            colorFilter:
                                const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 620,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 420,
                          child:
                              buildImageArea(),
                        ),

                        const SizedBox(height: 10),

                        buildAnnotationBar(),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child:
                                  OutlinedButton.icon(
                                onPressed:
                                    showColourPicker,
                                icon: const Icon(
                                  Icons.palette_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Colour',
                                ),
                                style:
                                    OutlinedButton.styleFrom(
                                  foregroundColor:
                                      teal,
                                  side:
                                      const BorderSide(
                                    color: teal,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child:
                                  OutlinedButton.icon(
                                onPressed:
                                    replaceImage,
                                icon: const Icon(
                                  Icons.refresh,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Reupload',
                                ),
                                style:
                                    OutlinedButton.styleFrom(
                                  foregroundColor:
                                      teal,
                                  side:
                                      const BorderSide(
                                    color: teal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        buildImageQualityCard(),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child:
                              FilledButton.icon(
                            onPressed:
                                isCalculating
                                    ? null
                                    : finishAnnotation,
                            icon: isCalculating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : SvgPicture.asset(
                                    'assets/images/check.svg',
                                    width: 18,
                                    height: 18,
                                    colorFilter:
                                        const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                            label: Text(
                              isCalculating
                                  ? 'Running Computer Analysis...'
                                  : 'Run Computer Analysis',
                            ),
                            style:
                                FilledButton.styleFrom(
                              backgroundColor:
                                  teal,
                              foregroundColor:
                                  Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ANNOTATION PAINTER
// -----------------------------------------------------------------------------

class AnnotationPainter
    extends CustomPainter {
  final List<ImageAnnotation> annotations;

  final AnnotationTool? previewTool;

  final Offset? previewStart;
  final Offset? previewEnd;

  final Color previewColour;

  AnnotationPainter({
    required this.annotations,
    required this.previewTool,
    required this.previewStart,
    required this.previewEnd,
    required this.previewColour,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    for (final annotation in annotations) {
      paintAnnotation(
        canvas,
        size,
        annotation,
      );
    }

    if (previewStart != null &&
        previewEnd != null &&
        previewTool != null) {
      paintPreview(
        canvas,
        size,
      );
    }
  }

  void paintAnnotation(
    Canvas canvas,
    Size size,
    ImageAnnotation annotation,
  ) {
    final start = Offset(
      annotation.startX * size.width,
      annotation.startY * size.height,
    );

    final end = Offset(
      annotation.endX * size.width,
      annotation.endY * size.height,
    );

    final paint = Paint()
      ..color = annotation.colour
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    switch (annotation.type) {
      case AnnotationType.circle:
        final rectangle =
            Rect.fromPoints(
          start,
          end,
        );

        canvas.drawOval(
          rectangle,
          paint,
        );

        if (annotation.label != null) {
          paintLabel(
            canvas,
            annotation.label!,
            start,
            annotation.colour,
          );
        }

        break;

      case AnnotationType.arrow:
        paintArrow(
          canvas,
          start,
          end,
          paint,
        );

        break;

      case AnnotationType.measure:
        canvas.drawLine(
          start,
          end,
          paint,
        );

        paintMeasurementText(
          canvas,
          start,
          end,
          annotation.colour,
        );

        break;

      case AnnotationType.label:
        if (annotation.text != null) {
          paintLabel(
            canvas,
            annotation.text!,
            start,
            annotation.colour,
          );
        }

        break;
    }
  }

  void paintPreview(
    Canvas canvas,
    Size size,
  ) {
    final start = Offset(
      previewStart!.dx * size.width,
      previewStart!.dy * size.height,
    );

    final end = Offset(
      previewEnd!.dx * size.width,
      previewEnd!.dy * size.height,
    );

    final paint = Paint()
      ..color = previewColour
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    switch (previewTool) {
      case AnnotationTool.circle:
        canvas.drawOval(
          Rect.fromPoints(
            start,
            end,
          ),
          paint,
        );
        break;

      case AnnotationTool.arrow:
        paintArrow(
          canvas,
          start,
          end,
          paint,
        );
        break;

      case AnnotationTool.measure:
        canvas.drawLine(
          start,
          end,
          paint,
        );
        break;

      default:
        break;
    }
  }

  void paintArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    canvas.drawLine(
      start,
      end,
      paint,
    );

    final direction =
        end - start;

    if (direction.distance == 0) {
      return;
    }

    final angle = math.atan2(
      direction.dy,
      direction.dx,
    );

    const arrowLength = 12.0;
    const arrowAngle = 0.5;

    final firstPoint = Offset(
      end.dx -
          arrowLength *
              math.cos(
                angle - arrowAngle,
              ),
      end.dy -
          arrowLength *
              math.sin(
                angle - arrowAngle,
              ),
    );

    final secondPoint = Offset(
      end.dx -
          arrowLength *
              math.cos(
                angle + arrowAngle,
              ),
      end.dy -
          arrowLength *
              math.sin(
                angle + arrowAngle,
              ),
    );

    canvas.drawLine(
      end,
      firstPoint,
      paint,
    );

    canvas.drawLine(
      end,
      secondPoint,
      paint,
    );
  }

  void paintLabel(
    Canvas canvas,
    String text,
    Offset position,
    Color colour,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: colour,
          fontSize: 12,
          fontWeight:
              FontWeight.bold,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    );

    textPainter.layout();

    final background =
        Paint()
          ..color = Colors.black.withValues(
        alpha: 0.35,
      );

    final rectangle =
        RRect.fromRectAndRadius(
      Rect.fromLTWH(
        position.dx,
        position.dy,
        textPainter.width + 10,
        textPainter.height + 6,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      rectangle,
      background,
    );

    textPainter.paint(
      canvas,
      Offset(
        position.dx + 5,
        position.dy + 3,
      ),
    );
  }

  void paintMeasurementText(
    Canvas canvas,
    Offset start,
    Offset end,
    Color colour,
  ) {
    final distance =
        (end - start).distance;

    final midpoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    paintLabel(
      canvas,
      '${distance.toStringAsFixed(1)} px',
      midpoint,
      colour,
    );
  }

  @override
  bool shouldRepaint(
    covariant AnnotationPainter oldDelegate,
  ) {
    return true;
  }
}