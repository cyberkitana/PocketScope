import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../services/database_service.dart';
import '../../../utils/id_generator.dart';
import 'image_review_screen.dart';

/// Screen used to upload images for a sample.
class UploadImagesScreen extends StatefulWidget {
  final String sampleId;
  final String specimenType;

  const UploadImagesScreen({
    super.key,
    required this.sampleId,
    required this.specimenType,
  });

  @override
  State<UploadImagesScreen> createState() => _UploadImagesScreenState();
}

class _UploadImagesScreenState extends State<UploadImagesScreen> {
  final ImagePicker imagePicker = ImagePicker();

  List<String> uploadedImagePaths = [];

  bool isUploading = false;

  @override
  void initState() {
    super.initState();

    loadImages();
  }

  /// Loads the images currently stored for this sample.
  Future<void> loadImages() async {
    try {
      final storedImages =
          await DatabaseService.getImagesForSample(widget.sampleId);

      if (!mounted) {
        return;
      }

      setState(() {
        uploadedImagePaths = storedImages
            .map(
              (image) => image['file_path'] as String,
            )
            .toList();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load images: $error',
          ),
        ),
      );
    }
  }

  /// Opens the device gallery and allows multiple images to be selected.
  Future<void> uploadImages() async {
    try {
      final selectedImages = await imagePicker.pickMultiImage(
        imageQuality: 100,
      );

      if (selectedImages.isEmpty) {
        return;
      }

      setState(() {
        isUploading = true;
      });

      final applicationDirectory =
          await getApplicationDocumentsDirectory();

      final imageDirectory = Directory(
        '${applicationDirectory.path}/sample_images',
      );

      if (!await imageDirectory.exists()) {
        await imageDirectory.create(
          recursive: true,
        );
      }

      for (final selectedImage in selectedImages) {
        final imageId = await IdGenerator.generateImageId(
          widget.specimenType,
        );

        final fileExtension = selectedImage.path.contains('.')
            ? selectedImage.path.split('.').last
            : 'jpg';

        final savedImagePath =
            '${imageDirectory.path}/$imageId.$fileExtension';

        final savedImage = await File(
          selectedImage.path,
        ).copy(savedImagePath);

        await DatabaseService.saveImage({
          'id': imageId,
          'sample_id': widget.sampleId,
          'file_path': savedImage.path,
          'captured_at': DateTime.now().toIso8601String(),
          'status': 'Uploaded',
        });
      }

      await loadImages();

      if (!mounted) {
        return;
      }

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selectedImages.length} image(s) uploaded successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to upload images: $error',
          ),
        ),
      );
    }
  }

  /// Removes an image from both SQLite and local storage.
  Future<void> removeImage(int index) async {
    if (index < 0 || index >= uploadedImagePaths.length) {
      return;
    }

    final imagePath = uploadedImagePaths[index];

    try {
      final storedImages =
          await DatabaseService.getImagesForSample(widget.sampleId);

      final matchingImage =
          storedImages.cast<Map<String, dynamic>?>().firstWhere(
                (image) => image?['file_path'] == imagePath,
                orElse: () => null,
              );

      if (matchingImage != null) {
        final imageId = matchingImage['id'] as String;

        await DatabaseService.deleteImageRecord(imageId);
      }

      final imageFile = File(imagePath);

      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        uploadedImagePaths.removeAt(index);
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

  /// Opens the image review screen.
  Future<void> reviewImages() async {
    if (uploadedImagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload at least one image.',
          ),
        ),
      );
      return;
    }

    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => ImageReviewScreen(
          sampleId: widget.sampleId,
          specimenType: widget.specimenType,
          images: uploadedImagePaths,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        uploadedImagePaths = List<String>.from(result);
      });
    }

    await loadImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Images'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sample Images',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.specimenType} sample • ${widget.sampleId}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isUploading
                      ? null
                      : uploadImages,
                  icon: const Icon(
                    Icons.upload_file,
                  ),
                  label: Text(
                    isUploading
                        ? 'Uploading Images...'
                        : 'Upload Images',
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (uploadedImagePaths.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No images uploaded yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Upload microscope images of the sample '
                            'to continue.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    for (
                      int index = 0;
                      index < uploadedImagePaths.length;
                      index++
                    )
                      Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: Image.file(
                                  File(
                                    uploadedImagePaths[index],
                                  ),
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Image ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                ),
                                onPressed: isUploading
                                    ? null
                                    : () {
                                        removeImage(index);
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : reviewImages,
                  child: const Text(
                    'Review Images',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}