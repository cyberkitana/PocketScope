import 'dart:io';

import 'package:flutter/material.dart';

import '../../../services/database_service.dart';
import '../analysis/analysis_screen.dart';

/// Screen used to review images before analysis.
class ImageReviewScreen extends StatefulWidget {
  final String sampleId;
  final String specimenType;
  final List<String> images;

  const ImageReviewScreen({
    super.key,
    required this.sampleId,
    required this.specimenType,
    required this.images,
  });

  @override
  State<ImageReviewScreen> createState() =>
      _ImageReviewScreenState();
}

class _ImageReviewScreenState
    extends State<ImageReviewScreen> {
  late List<String> images;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    images = List<String>.from(widget.images);
  }

  Future<void> removeCurrentImage() async {
    if (images.isEmpty) {
      return;
    }

    final imageToRemove = images[currentIndex];

    try {
      final storedImages =
          await DatabaseService.getImagesForSample(
        widget.sampleId,
      );

      final matchingImage = storedImages.where(
        (image) => image['file_path'] == imageToRemove,
      );

      if (matchingImage.isNotEmpty) {
        final imageId =
            matchingImage.first['id'] as String;

        await DatabaseService.deleteImageRecord(
          imageId,
        );
      }

      final file = File(imageToRemove);

      if (await file.exists()) {
        await file.delete();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        images.removeAt(currentIndex);

        if (images.isEmpty) {
          currentIndex = 0;
        } else if (currentIndex >= images.length) {
          currentIndex = images.length - 1;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image removed.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to remove image: $error',
          ),
        ),
      );
    }
  }

  void goToPreviousImage() {
    if (images.isEmpty) {
      return;
    }

    setState(() {
      currentIndex =
          (currentIndex - 1 + images.length) %
              images.length;
    });
  }

  void goToNextImage() {
    if (images.isEmpty) {
      return;
    }

    setState(() {
      currentIndex =
          (currentIndex + 1) % images.length;
    });
  }

  void retakeImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Camera capture will be available later.',
        ),
      ),
    );
  }

  void returnToUpload() {
    Navigator.pop(
      context,
      images,
    );
  }

  void analyseImages() {
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least one image before analysis.',
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisScreen(
          sampleId: widget.sampleId,
          specimenType: widget.specimenType,
          imageCount: images.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Images'),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.image_not_supported_outlined,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No images available.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Return to the upload screen to add an image.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: returnToUpload,
                    child: const Text('Back to Upload'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentImage = images[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Images'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: returnToUpload,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black12,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(
                    File(currentImage),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Text(
                'Image ${currentIndex + 1} of ${images.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: images.length > 1
                      ? goToPreviousImage
                      : null,
                  icon: const Icon(
                    Icons.chevron_left,
                  ),
                  tooltip: 'Previous image',
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: images.length > 1
                      ? goToNextImage
                      : null,
                  icon: const Icon(
                    Icons.chevron_right,
                  ),
                  tooltip: 'Next image',
                ),
              ],
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: retakeImage,
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                      ),
                      label: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: removeCurrentImage,
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      label: const Text('Remove'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: analyseImages,
                  child: const Text('Analyse Images'),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}