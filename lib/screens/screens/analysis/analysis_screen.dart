import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as image_package;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../services/database_service.dart';
import '../../../services/python_analysis_service.dart';
import '../../../utils/id_generator.dart';
import 'screening_result_screen.dart';

/// Tools available for manually reviewing a microscope image.
enum AnnotationTool {
  circle,
  arrow,
  measure,
  label,
  undo,
}

/// Types of annotations that can be placed on the image.
enum AnnotationType {
  circle,
  arrow,
  measure,
  label,
}

/// Stores one manual observation made by the user during image review.
///
/// These annotations are human observations only. They are not passed
/// to the Python computer-analysis pipeline.
class ImageAnnotation {
  final AnnotationType type;
  final Offset start;
  final Offset end;
  final String? label;
  final int number;

  ImageAnnotation({
    required this.type,
    required this.start,
    required this.end,
    this.label,
    required this.number,
  });
}

/// Stores the basic image-quality measurements.
class ImageQualityResult {
  final double focusScore;
  final double exposure;
  final bool passed;

  ImageQualityResult({
    required this.focusScore,
    required this.exposure,
    required this.passed,
  });
}

/// Allows the user to review and manually annotate a microscope image
/// before sending the original image to the computer-analysis pipeline.
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
  String currentImagePath = '';
  String currentImageId = '';

  final ImagePicker _imagePicker = ImagePicker();

  double imageRotation = 0;

  final List<ImageAnnotation> annotations = [];

  AnnotationTool selectedTool = AnnotationTool.circle;

  Offset? _dragStart;
  Offset? _dragCurrent;

  int _annotationNumber = 0;

  Color annotationColour = const Color(0xFF0D8B83);

  ImageQualityResult? imageQuality;

  bool calculatingImageQuality = true;

  double pixelsPerMicrometre = 0;

  final TransformationController _transformationController =
      TransformationController();

  double currentZoom = 1.0;

  /// Prevents multiple Python analyses from being started at once.
  bool runningComputerAnalysis = false;

  @override
  void initState() {
    super.initState();

    currentImagePath = widget.imagePath;
    currentImageId = widget.imageId;

    calculateImageQuality();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // IMAGE QUALITY
  // ---------------------------------------------------------------------------

  /// Calculates basic focus and exposure information for the image.
  Future<void> calculateImageQuality() async {
    if (!mounted) {
      return;
    }

    setState(() {
      calculatingImageQuality = true;
    });

    try {
      final imageFile = File(currentImagePath);

      if (!imageFile.existsSync()) {
        throw Exception(
          'The microscope image could not be found.',
        );
      }

      final imageBytes = await imageFile.readAsBytes();

      final decodedImage = image_package.decodeImage(
        imageBytes,
      );

      if (decodedImage == null) {
        throw Exception(
          'The microscope image could not be read.',
        );
      }

      double brightnessTotal = 0.0;
      double brightnessDifferenceTotal = 0.0;

      int pixelCount = 0;
      int differenceCount = 0;

      for (int y = 0; y < decodedImage.height; y += 4) {
        for (int x = 0; x < decodedImage.width; x += 4) {
          final pixel = decodedImage.getPixel(x, y);

          final double red = pixel.r.toDouble();
          final double green = pixel.g.toDouble();
          final double blue = pixel.b.toDouble();

          final double brightness =
              (red + green + blue) / 3.0;

          brightnessTotal += brightness;
          pixelCount++;

          if (x + 4 < decodedImage.width) {
            final nextPixel =
                decodedImage.getPixel(x + 4, y);

            final double nextRed =
                nextPixel.r.toDouble();

            final double nextGreen =
                nextPixel.g.toDouble();

            final double nextBlue =
                nextPixel.b.toDouble();

            final double nextBrightness =
                (nextRed + nextGreen + nextBlue) / 3.0;

            brightnessDifferenceTotal +=
                (brightness - nextBrightness).abs();

            differenceCount++;
          }
        }
      }

      final double exposure =
          pixelCount > 0
              ? brightnessTotal / pixelCount
              : 0.0;

      final double focusScore =
          differenceCount > 0
              ? brightnessDifferenceTotal /
                  differenceCount
              : 0.0;

      final bool exposurePassed =
          exposure >= 35.0 &&
          exposure <= 220.0;

      final bool focusPassed =
          focusScore >= 20.0;

      final qualityResult = ImageQualityResult(
        focusScore: focusScore,
        exposure: exposure,
        passed: exposurePassed && focusPassed,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        imageQuality = qualityResult;
        calculatingImageQuality = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        imageQuality = ImageQualityResult(
          focusScore: 0.0,
          exposure: 0.0,
          passed: false,
        );

        calculatingImageQuality = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to check image quality: $error',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ANNOTATION TOOLS
  // ---------------------------------------------------------------------------

  /// Selects one of the manual annotation tools.
  void selectTool(AnnotationTool tool) {
    if (!mounted) {
      return;
    }

    setState(() {
      selectedTool = tool;
    });

    if (tool == AnnotationTool.undo) {
      undoLastAnnotation();
    }
  }

  /// Removes the most recent manual annotation.
  void undoLastAnnotation() {
    if (annotations.isEmpty) {
      return;
    }

    setState(() {
      annotations.removeLast();

      if (_annotationNumber > 0) {
        _annotationNumber--;
      }
    });
  }

  /// Records the start of a manual annotation.
  void handlePointerDown(
    PointerDownEvent event,
    BoxConstraints constraints,
  ) {
    if (selectedTool == AnnotationTool.undo) {
      undoLastAnnotation();
      return;
    }

    final position = normalisePosition(
      event.localPosition,
      constraints,
    );

    setState(() {
      _dragStart = position;
      _dragCurrent = position;
    });
  }

  /// Updates the current manual annotation while dragging.
  void handlePointerMove(
    PointerMoveEvent event,
    BoxConstraints constraints,
  ) {
    if (_dragStart == null) {
      return;
    }

    final position = normalisePosition(
      event.localPosition,
      constraints,
    );

    setState(() {
      _dragCurrent = position;
    });
  }

  /// Completes a manual annotation.
  Future<void> handlePointerUp(
    PointerUpEvent event,
    BoxConstraints constraints,
  ) async {
    if (_dragStart == null) {
      return;
    }

    final endPosition = normalisePosition(
      event.localPosition,
      constraints,
    );

    final startPosition = _dragStart!;

    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });

    if (selectedTool == AnnotationTool.circle) {
      _annotationNumber++;

      setState(() {
        annotations.add(
          ImageAnnotation(
            type: AnnotationType.circle,
            start: startPosition,
            end: endPosition,
            number: _annotationNumber,
          ),
        );
      });

      return;
    }

    if (selectedTool == AnnotationTool.arrow) {
      _annotationNumber++;

      setState(() {
        annotations.add(
          ImageAnnotation(
            type: AnnotationType.arrow,
            start: startPosition,
            end: endPosition,
            number: _annotationNumber,
          ),
        );
      });

      return;
    }

    if (selectedTool == AnnotationTool.measure) {
      _annotationNumber++;

      setState(() {
        annotations.add(
          ImageAnnotation(
            type: AnnotationType.measure,
            start: startPosition,
            end: endPosition,
            number: _annotationNumber,
          ),
        );
      });

      return;
    }

    if (selectedTool == AnnotationTool.label) {
      await addLabelAnnotation(
        startPosition,
      );
    }
  }

  /// Converts a screen position into a normalized image position.
  Offset normalisePosition(
    Offset position,
    BoxConstraints constraints,
  ) {
    final double width =
        constraints.maxWidth <= 0
            ? 1.0
            : constraints.maxWidth;

    final double height =
        constraints.maxHeight <= 0
            ? 1.0
            : constraints.maxHeight;

    return Offset(
      (position.dx / width).clamp(0.0, 1.0),
      (position.dy / height).clamp(0.0, 1.0),
    );
  }

  /// Opens the label dialog and stores the entered text.
  Future<void> addLabelAnnotation(
    Offset position,
  ) async {
    final controller =
        TextEditingController();

    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Add label',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter label',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (label == null ||
        label.trim().isEmpty ||
        !mounted) {
      return;
    }

    _annotationNumber++;

    setState(() {
      annotations.add(
        ImageAnnotation(
          type: AnnotationType.label,
          start: position,
          end: position,
          label: label.trim(),
          number: _annotationNumber,
        ),
      );
    });
  }

  /// Opens a colour selector for manual annotations.
  Future<void> showColourPicker() async {
    final colours = [
      const Color(0xFF0D8B83),
      const Color(0xFFE5484D),
      const Color(0xFF3366CC),
      const Color(0xFFFFA000),
      const Color(0xFF7B61FF),
      Colors.white,
    ];

    final selectedColour =
        await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Annotation colour',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colours.map(
              (colour) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(
                      dialogContext,
                      colour,
                    );
                  },
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
                );
              },
            ).toList(),
          ),
        );
      },
    );

    if (selectedColour == null ||
        !mounted) {
      return;
    }

    setState(() {
      annotationColour = selectedColour;
    });
  }

  // ---------------------------------------------------------------------------
  // IMAGE OPERATIONS
  // ---------------------------------------------------------------------------

  /// Replaces the current microscope image with another gallery image.
  Future<void> replaceImage() async {
    try {
      final pickedImage =
          await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedImage == null) {
        return;
      }

      final applicationDirectory =
          await getApplicationDocumentsDirectory();

      final imageDirectory = Directory(
        '${applicationDirectory.path}${Platform.pathSeparator}sample_images',
      );

      if (!imageDirectory.existsSync()) {
        await imageDirectory.create(
          recursive: true,
        );
      }

      final newImageId = await IdGenerator.generateImageId(
        widget.specimenType,
      );

      final extension =
          pickedImage.path.contains('.')
              ? pickedImage.path.substring(
                  pickedImage.path.lastIndexOf('.'),
                )
              : '.jpg';

      final newImagePath =
          '${imageDirectory.path}${Platform.pathSeparator}$newImageId$extension';

      final copiedFile =
          await File(pickedImage.path).copy(
        newImagePath,
      );

      try {
        await DatabaseService.deleteImage(
          currentImageId,
        );
      } catch (_) {
        // Continue if the old database record does not exist.
      }

      final oldFile =
          File(currentImagePath);

      if (oldFile.existsSync()) {
        try {
          await oldFile.delete();
        } catch (_) {
          // Continue if the old image cannot be deleted.
        }
      }

      await DatabaseService.saveImage({
        'id': newImageId,
        'sample_id': widget.sampleId,
        'file_path': copiedFile.path,
        'captured_date_time':
            DateTime.now().toIso8601String(),
      });

      if (!mounted) {
        return;
      }

      setState(() {
        currentImagePath = copiedFile.path;
        currentImageId = newImageId;

        annotations.clear();
        _annotationNumber = 0;

        imageRotation = 0;

        _transformationController.value =
            Matrix4.identity();

        currentZoom = 1.0;
      });

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

  /// Rotates the microscope image by 90 degrees.
  void rotateImage() {
    setState(() {
      imageRotation += math.pi / 2;

      if (imageRotation >= math.pi * 2) {
        imageRotation = 0;
      }
    });
  }

  /// Zooms the image in.
  void zoomIn() {
    final double newZoom =
        (currentZoom + 0.25).clamp(
      1.0,
      4.0,
    );

    setState(() {
      currentZoom = newZoom;

      _transformationController.value =
          Matrix4.identity()
            ..scaleByDouble(
              currentZoom,
              currentZoom,
              currentZoom,
              1.0,
            );
    });
  }

  /// Resets the image zoom.
  void resetZoom() {
    setState(() {
      currentZoom = 1.0;

      _transformationController.value =
          Matrix4.identity();
    });
  }

  // ---------------------------------------------------------------------------
  // COMPUTER ANALYSIS
  // ---------------------------------------------------------------------------

  /// Runs the actual Python computer analysis.
  ///
  /// The original microscope image is passed to Python.
  /// Manual annotations are deliberately not passed to Python.
  Future<void> finishAnnotation() async {
    if (runningComputerAnalysis) {
      return;
    }

    final imageFile =
        File(currentImagePath);

    if (!imageFile.existsSync()) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The microscope image could not be found.',
          ),
        ),
      );

      return;
    }

    setState(() {
      runningComputerAnalysis = true;
    });

    try {
      final analysisResult =
          await PythonAnalysisService.analyzeBloodSmear(
        imagePath: currentImagePath,
      );

      if (!mounted) {
        return;
      }

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ScreeningResultScreen(
            patientName: 'Patient',
            patientId: widget.sampleId,
            specimen: widget.specimenType,
            collectedDate: 'Not recorded',
            doctorName: 'Not recorded',
            registrationNumber: 'Not recorded',
            sampleId: widget.sampleId,
            facilityName: 'PocketScope',
            analysis: analysisResult,
            clinicianNote: '',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Computer analysis failed: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          runningComputerAnalysis = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // IMAGE AREA
  // ---------------------------------------------------------------------------

  /// Builds the microscope image and manual annotation overlay.
  Widget buildImageArea() {
    return Container(
      width: double.infinity,
      height: 390,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius:
            BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              InteractiveViewer(
                transformationController:
                    _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                panEnabled: true,
                scaleEnabled: true,
                child: Center(
                  child: Transform.rotate(
                    angle: imageRotation,
                    child: Image.file(
                      File(currentImagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: Listener(
                  onPointerDown: (event) {
                    handlePointerDown(
                      event,
                      constraints,
                    );
                  },
                  onPointerMove: (event) {
                    handlePointerMove(
                      event,
                      constraints,
                    );
                  },
                  onPointerUp: (event) {
                    handlePointerUp(
                      event,
                      constraints,
                    );
                  },
                  child: CustomPaint(
                    painter: AnnotationPainter(
                      annotations: annotations,
                      currentStart: _dragStart,
                      currentEnd: _dragCurrent,
                      selectedTool: selectedTool,
                      annotationColour:
                          annotationColour,
                      pixelsPerMicrometre:
                          pixelsPerMicrometre,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius:
                        BorderRadius.circular(6),
                  ),
                  child: Text(
                    File(currentImagePath)
                        .uri
                        .pathSegments
                        .last,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),

              Positioned(
                right: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: zoomIn,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius:
                          BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 12,
                left: 12,
                child:
                    _buildImageQualityBadge(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Displays the current image-quality status.
  Widget _buildImageQualityBadge() {
    if (calculatingImageQuality) {
      return Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius:
              BorderRadius.circular(6),
        ),
        child: const Text(
          'Checking image...',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      );
    }

    final passed =
        imageQuality?.passed ?? false;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius:
            BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            passed
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded,
            color: passed
                ? Colors.greenAccent
                : Colors.orangeAccent,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            passed
                ? 'Image quality OK'
                : 'Check image quality',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ANNOTATION TOOLBAR
  // ---------------------------------------------------------------------------

  /// Builds the manual annotation controls.
  Widget buildAnnotationToolbar() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildToolButton(
            icon: Icons.circle_outlined,
            label: 'Circle',
            tool: AnnotationTool.circle,
          ),
          _buildToolButton(
            icon: Icons.arrow_outward,
            label: 'Arrow',
            tool: AnnotationTool.arrow,
          ),
          _buildToolButton(
            icon: Icons.straighten,
            label: 'Measure',
            tool: AnnotationTool.measure,
          ),
          _buildToolButton(
            icon: Icons.label_outline,
            label: 'Label',
            tool: AnnotationTool.label,
          ),
          _buildToolButton(
            icon: Icons.undo,
            label: 'Undo',
            tool: AnnotationTool.undo,
          ),
        ],
      ),
    );
  }

  /// Builds one annotation tool button.
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required AnnotationTool tool,
  }) {
    final selected =
        selectedTool == tool;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          selectTool(tool);
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE5F5F3)
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(7),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? const Color(0xFF0D8B83)
                    : const Color(0xFF6D7979),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: selected
                      ? const Color(0xFF0D8B83)
                      : const Color(0xFF6D7979),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // IMAGE CONTROLS
  // ---------------------------------------------------------------------------

  /// Builds image control buttons.
  Widget buildImageControls() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                showColourPicker,
            icon: Icon(
              Icons.palette_outlined,
              size: 17,
              color: annotationColour,
            ),
            label: const Text(
              'Colour',
            ),
            style:
                OutlinedButton.styleFrom(
              minimumSize:
                  const Size(
                double.infinity,
                42,
              ),
              side: const BorderSide(
                color: Color(0xFFB9C3C3),
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: OutlinedButton.icon(
            onPressed: rotateImage,
            icon: const Icon(
              Icons.rotate_right,
              size: 17,
            ),
            label: const Text(
              'Rotate',
            ),
            style:
                OutlinedButton.styleFrom(
              minimumSize:
                  const Size(
                double.infinity,
                42,
              ),
              side: const BorderSide(
                color: Color(0xFFB9C3C3),
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: OutlinedButton.icon(
            onPressed: resetZoom,
            icon: const Icon(
              Icons.zoom_out_map,
              size: 17,
            ),
            label: const Text(
              'Reset zoom',
            ),
            style:
                OutlinedButton.styleFrom(
              minimumSize:
                  const Size(
                double.infinity,
                42,
              ),
              side: const BorderSide(
                color: Color(0xFFB9C3C3),
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: OutlinedButton.icon(
            onPressed: replaceImage,
            icon: const Icon(
              Icons.upload_outlined,
              size: 17,
            ),
            label: const Text(
              'Reupload',
            ),
            style:
                OutlinedButton.styleFrom(
              minimumSize:
                  const Size(
                double.infinity,
                42,
              ),
              side: const BorderSide(
                color: Color(0xFFB9C3C3),
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // IMAGE QUALITY CARD
  // ---------------------------------------------------------------------------

  /// Builds the image quality information card.
  Widget buildImageQualityCard() {
    final quality = imageQuality;

    if (calculatingImageQuality) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 9),
            Text(
              'Checking image quality...',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF6D7979),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    if (quality == null) {
      return const SizedBox.shrink();
    }

    final passed = quality.passed;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: passed
            ? const Color(0xFFEAF7F4)
            : const Color(0xFFFFF4D6),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passed
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                size: 18,
                color: passed
                    ? const Color(0xFF087A59)
                    : const Color(0xFF8A6500),
              ),
              const SizedBox(width: 7),
              Text(
                passed
                    ? 'Image quality acceptable'
                    : 'Image quality needs review',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: passed
                      ? const Color(0xFF087A59)
                      : const Color(0xFF8A6500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Focus score: ${quality.focusScore.toStringAsFixed(1)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF4F5A5A),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Exposure: ${quality.exposure.toStringAsFixed(1)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF4F5A5A),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    buildImageArea(),

                    const SizedBox(height: 12),

                    buildAnnotationToolbar(),

                    const SizedBox(height: 10),

                    buildImageControls(),

                    const SizedBox(height: 12),

                    buildImageQualityCard(),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            runningComputerAnalysis
                                ? null
                                : finishAnnotation,
                        icon:
                            runningComputerAnalysis
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .biotech_outlined,
                                    size: 18,
                                  ),
                        label: Text(
                          runningComputerAnalysis
                              ? 'Running Computer Analysis...'
                              : 'Run Computer Analysis',
                          style:
                              const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          minimumSize:
                              const Size(
                            double.infinity,
                            48,
                          ),
                          backgroundColor:
                              const Color(
                            0xFF0D8B83,
                          ),
                          foregroundColor:
                              Colors.white,
                          disabledBackgroundColor:
                              const Color(
                            0xFF9AB9B6,
                          ),
                          disabledForegroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              9,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Manual annotations are recorded as human observations and are not used by the computer analysis.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color:
                            Color(0xFF7A8585),
                        fontSize: 9,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP BAR
  // ---------------------------------------------------------------------------

  /// Builds the page header.
  Widget _buildTopBar() {
    return SizedBox(
      height: 62,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                alignment:
                    Alignment.center,
                child: SvgPicture.asset(
                  'assets/images/chevron-left.svg',
                  width: 20,
                  height: 20,
                  colorFilter:
                      const ColorFilter.mode(
                    Color(0xFF172121),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Image review',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF172121),
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Review and annotate microscope image',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF6D7979),
                      fontSize: 11,
                    ),
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

/// Paints manual image-review annotations.
class AnnotationPainter
    extends CustomPainter {
  final List<ImageAnnotation> annotations;
  final Offset? currentStart;
  final Offset? currentEnd;
  final AnnotationTool selectedTool;
  final Color annotationColour;
  final double pixelsPerMicrometre;

  AnnotationPainter({
    required this.annotations,
    required this.currentStart,
    required this.currentEnd,
    required this.selectedTool,
    required this.annotationColour,
    required this.pixelsPerMicrometre,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint =
        Paint()
          ..color = annotationColour
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;

    for (final annotation in annotations) {
      final start = Offset(
        annotation.start.dx *
            size.width,
        annotation.start.dy *
            size.height,
      );

      final end = Offset(
        annotation.end.dx *
            size.width,
        annotation.end.dy *
            size.height,
      );

      if (annotation.type ==
          AnnotationType.circle) {
        final centre = Offset(
          (start.dx + end.dx) / 2,
          (start.dy + end.dy) / 2,
        );

        final radius = math.sqrt(
              math.pow(
                end.dx - start.dx,
                2,
              ) +
                  math.pow(
                    end.dy - start.dy,
                    2,
                  ),
            ) /
            2;

        canvas.drawCircle(
          centre,
          radius,
          paint,
        );

        _drawNumber(
          canvas,
          centre,
          annotation.number,
        );
      }

      if (annotation.type ==
          AnnotationType.arrow) {
        _drawArrow(
          canvas,
          start,
          end,
          paint,
        );

        _drawNumber(
          canvas,
          end,
          annotation.number,
        );
      }

      if (annotation.type ==
          AnnotationType.measure) {
        canvas.drawLine(
          start,
          end,
          paint,
        );

        _drawMeasurementText(
          canvas,
          start,
          end,
          annotation,
        );
      }

      if (annotation.type ==
          AnnotationType.label) {
        _drawLabel(
          canvas,
          start,
          annotation.label ?? '',
        );

        _drawNumber(
          canvas,
          start,
          annotation.number,
        );
      }
    }

    if (currentStart != null &&
        currentEnd != null) {
      final start = Offset(
        currentStart!.dx *
            size.width,
        currentStart!.dy *
            size.height,
      );

      final end = Offset(
        currentEnd!.dx *
            size.width,
        currentEnd!.dy *
            size.height,
      );

      final previewPaint =
          Paint()
            ..color = annotationColour
            ..style =
                PaintingStyle.stroke
            ..strokeWidth = 2.0;

      if (selectedTool ==
          AnnotationTool.circle) {
        final centre = Offset(
          (start.dx + end.dx) / 2,
          (start.dy + end.dy) / 2,
        );

        final radius = math.sqrt(
              math.pow(
                end.dx - start.dx,
                2,
              ) +
                  math.pow(
                    end.dy - start.dy,
                    2,
                  ),
            ) /
            2;

        canvas.drawCircle(
          centre,
          radius,
          previewPaint,
        );
      }

      if (selectedTool ==
          AnnotationTool.arrow) {
        _drawArrow(
          canvas,
          start,
          end,
          previewPaint,
        );
      }

      if (selectedTool ==
          AnnotationTool.measure) {
        canvas.drawLine(
          start,
          end,
          previewPaint,
        );
      }
    }
  }

  /// Draws an annotation number.
  void _drawNumber(
    Canvas canvas,
    Offset position,
    int number,
  ) {
    final textPainter =
        TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    );

    textPainter.layout();

    final backgroundPaint =
        Paint()
          ..color = annotationColour
          ..style =
              PaintingStyle.fill;

    final rect =
        Rect.fromCenter(
      center: position,
      width:
          textPainter.width + 10,
      height:
          textPainter.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(4),
      ),
      backgroundPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        rect.left + 5,
        rect.top + 3,
      ),
    );
  }

  /// Draws an arrow with a triangular arrowhead.
  void _drawArrow(
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

    final angle =
        math.atan2(
      end.dy - start.dy,
      end.dx - start.dx,
    );

    const arrowLength = 12.0;
    const arrowAngle =
        math.pi / 6;

    final pointOne =
        Offset(
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

    final pointTwo =
        Offset(
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

    final path =
        Path()
          ..moveTo(
            end.dx,
            end.dy,
          )
          ..lineTo(
            pointOne.dx,
            pointOne.dy,
          )
          ..lineTo(
            pointTwo.dx,
            pointTwo.dy,
          )
          ..close();

    final fillPaint =
        Paint()
          ..color = annotationColour
          ..style =
              PaintingStyle.fill;

    canvas.drawPath(
      path,
      fillPaint,
    );
  }

  /// Draws a measurement label.
  void _drawMeasurementText(
    Canvas canvas,
    Offset start,
    Offset end,
    ImageAnnotation annotation,
  ) {
    final centre =
        Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final dx =
        end.dx - start.dx;

    final dy =
        end.dy - start.dy;

    final distance =
        math.sqrt(
      (dx * dx) +
          (dy * dy),
    );

    final String text =
        pixelsPerMicrometre > 0
            ? '${(distance / pixelsPerMicrometre).toStringAsFixed(1)} µm'
            : '${(distance * 100).toStringAsFixed(1)}% image width';

    final textPainter =
        TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight:
              FontWeight.w600,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    );

    textPainter.layout();

    final backgroundPaint =
        Paint()
          ..color = annotationColour
          ..style =
              PaintingStyle.fill;

    final rect =
        Rect.fromCenter(
      center: centre,
      width:
          textPainter.width + 10,
      height:
          textPainter.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(4),
      ),
      backgroundPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        rect.left + 5,
        rect.top + 3,
      ),
    );
  }

  /// Draws a manual text label.
  void _drawLabel(
    Canvas canvas,
    Offset position,
    String label,
  ) {
    final textPainter =
        TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight:
              FontWeight.w600,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    );

    textPainter.layout(
      maxWidth: 150,
    );

    final backgroundPaint =
        Paint()
          ..color = annotationColour
          ..style =
              PaintingStyle.fill;

    final rect =
        Rect.fromLTWH(
      position.dx,
      position.dy,
      textPainter.width + 10,
      textPainter.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(4),
      ),
      backgroundPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        rect.left + 5,
        rect.top + 3,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant AnnotationPainter oldDelegate,
  ) {
    return oldDelegate.annotations !=
            annotations ||
        oldDelegate.currentStart !=
            currentStart ||
        oldDelegate.currentEnd !=
            currentEnd ||
        oldDelegate.selectedTool !=
            selectedTool ||
        oldDelegate.annotationColour !=
            annotationColour;
  }
}