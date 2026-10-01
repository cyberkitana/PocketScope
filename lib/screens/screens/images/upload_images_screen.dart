import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../services/database_service.dart';
import 'image_review_screen.dart';

class UploadImagesScreen extends StatefulWidget {
  final String sampleId;
  final String specimenType;

  const UploadImagesScreen({
    super.key,
    required this.sampleId,
    required this.specimenType,
  });

  @override
  State<UploadImagesScreen> createState() =>
      _UploadImagesScreenState();
}

class _UploadImagesScreenState extends State<UploadImagesScreen> {
  static const Color teal = Color(0xFF087E78);
  static const Color secondaryText = Color(0xFF60747B);
  static const Color pageBackground = Color(0xFFEEF3F5);
  static const Color lightGreen = Color(0xFFE2F3F1);
  static const Color borderColor = Color(0xFFD0D7DA);

  final ImagePicker imagePicker = ImagePicker();

  XFile? selectedImage;

  bool isSelectingImage = false;
  bool isSavingImage = false;

  // ---------------------------------------------------------------------------
  // IMAGE SELECTION
  // ---------------------------------------------------------------------------

  Future<void> selectImage(ImageSource source) async {
    if (isSelectingImage || isSavingImage) {
      return;
    }

    setState(() {
      isSelectingImage = true;
    });

    try {
      final image = await imagePicker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          isSelectingImage = false;
        });

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        selectedImage = image;
        isSelectingImage = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSelectingImage = false;
      });

      showMessage(
        'Unable to select image: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // IMAGE SAVING
  // ---------------------------------------------------------------------------

  Future<String> saveImageToApplicationDirectory(
    XFile image,
  ) async {
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

    final imageId =
        'IMG_${DateTime.now().millisecondsSinceEpoch}';

    final originalPath = image.path;

    String extension = 'jpg';

    if (originalPath.contains('.')) {
      extension = originalPath
          .split('.')
          .last
          .toLowerCase();

      if (extension.isEmpty) {
        extension = 'jpg';
      }
    }

    final newPath =
        '${imageDirectory.path}/$imageId.$extension';

    final copiedFile = await File(
      originalPath,
    ).copy(newPath);

    try {
      await DatabaseService.saveImage({
        'id': imageId,
        'sample_id': widget.sampleId,
        'file_path': copiedFile.path,
        'captured_at':
            DateTime.now().toIso8601String(),
        'status': 'Uploaded',
      });
    } catch (_) {
      // The local image is still available even if
      // the database record cannot be saved.
    }

    return imageId;
  }

  // ---------------------------------------------------------------------------
  // CONTINUE TO IMAGE REVIEW
  // ---------------------------------------------------------------------------

  Future<void> continueToReview() async {
    if (selectedImage == null) {
      showMessage('Please upload an image first.');
      return;
    }

    if (isSavingImage) {
      return;
    }

    setState(() {
      isSavingImage = true;
    });

    try {
      final image = selectedImage!;

      final imageId =
          await saveImageToApplicationDirectory(
        image,
      );

      final applicationDirectory =
          await getApplicationDocumentsDirectory();

      final imageDirectory = Directory(
        '${applicationDirectory.path}/sample_images',
      );

      final files = await imageDirectory
          .list()
          .where(
            (entity) =>
                entity is File &&
                entity.path.contains(imageId),
          )
          .toList();

      if (files.isEmpty) {
        throw Exception(
          'The uploaded image could not be saved.',
        );
      }

      final savedImagePath =
          (files.first as File).path;

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageReviewScreen(
            sampleId: widget.sampleId,
            specimenType: widget.specimenType,
            imagePath: savedImagePath,
            imageId: imageId,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSavingImage = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSavingImage = false;
      });

      showMessage(
        'Unable to upload image: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CAMERA
  // ---------------------------------------------------------------------------

  void cameraNotAvailable() {
    showMessage(
      'Camera capture will be available in a later version.',
    );
  }

  // ---------------------------------------------------------------------------
  // GENERAL HELPERS
  // ---------------------------------------------------------------------------

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String getFileName() {
    if (selectedImage == null) {
      return '';
    }

    return selectedImage!.path
        .split(Platform.pathSeparator)
        .last;
  }

  // ---------------------------------------------------------------------------
  // UPLOAD OPTION
  // ---------------------------------------------------------------------------

  Widget buildUploadOption({
    required String iconPath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: isSelectingImage || isSavingImage || !enabled
            ? null
            : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white
                : Colors.grey.shade100,
            border: Border.all(
              color: enabled
                  ? borderColor
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                      ? lightGreen
                      : Colors.grey.shade200,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  colorFilter:
                      ColorFilter.mode(
                    enabled
                        ? teal
                        : Colors.grey.shade500,
                    BlendMode.srcIn,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? Colors.black
                      : secondaryText,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SELECTED IMAGE
  // ---------------------------------------------------------------------------

  Widget buildSelectedImage() {
    if (selectedImage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: teal,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Image.file(
              File(selectedImage!.path),
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) {
                return const Icon(
                  Icons.image_outlined,
                  color: secondaryText,
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Image selected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  getFileName(),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: isSavingImage
                ? null
                : () {
                    setState(() {
                      selectedImage = null;
                    });
                  },
            icon: const Icon(
              Icons.close,
              size: 19,
            ),
            color: secondaryText,
            tooltip: 'Remove image',
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
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 620,
                          minWidth: 0,
                        ),
                        child: _buildContent(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      height: 62,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isSavingImage
                ? null
                : () {
                    Navigator.pop(context);
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
                  'Upload Image',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '${widget.specimenType} • Sample ${widget.sampleId}',
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildContent() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Add microscopy image',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Upload an image captured through the microscope adapter, then review it before computer analysis.',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: secondaryText,
          ),
        ),

        const SizedBox(height: 20),

        if (selectedImage == null)
          _buildEmptyImageCard()
        else
          buildSelectedImage(),

        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow =
                constraints.maxWidth < 450;

            if (isNarrow) {
              return Column(
                children: [
                  buildUploadOption(
                    iconPath:
                        'assets/images/upload.svg',
                    title: 'Upload Image',
                    subtitle:
                        'Choose an image from your device',
                    onTap: () {
                      selectImage(
                        ImageSource.gallery,
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  buildUploadOption(
                    iconPath:
                        'assets/images/camera.svg',
                    title: 'Use Camera',
                    subtitle:
                        'Camera capture is not available yet',
                    onTap: cameraNotAvailable,
                    enabled: false,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: buildUploadOption(
                    iconPath:
                        'assets/images/upload.svg',
                    title: 'Upload Image',
                    subtitle:
                        'Choose an image from your device',
                    onTap: () {
                      selectImage(
                        ImageSource.gallery,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: buildUploadOption(
                    iconPath:
                        'assets/images/camera.svg',
                    title: 'Use Camera',
                    subtitle:
                        'Camera capture is not available yet',
                    onTap: cameraNotAvailable,
                    enabled: false,
                  ),
                ),
              ],
            );
          },
        ),

        if (isSelectingImage)
          const Padding(
            padding: EdgeInsets.only(
              top: 14,
            ),
            child: LinearProgressIndicator(
              color: teal,
            ),
          ),

        const SizedBox(height: 20),

        _buildInformationCard(),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed:
                selectedImage == null ||
                        isSavingImage
                    ? null
                    : continueToReview,
            icon: isSavingImage
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : SvgPicture.asset(
                    'assets/images/arrow-right.svg',
                    width: 18,
                    height: 18,
                    colorFilter:
                        const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
            label: Text(
              isSavingImage
                  ? 'Opening Review...'
                  : 'Continue to Image Review',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: teal,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  Colors.grey.shade300,
              disabledForegroundColor:
                  Colors.grey.shade600,
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
  // EMPTY IMAGE CARD
  // ---------------------------------------------------------------------------

  Widget _buildEmptyImageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/images/image.svg',
              width: 30,
              height: 30,
              colorFilter:
                  const ColorFilter.mode(
                teal,
                BlendMode.srcIn,
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'No image selected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Choose an existing image from your device. Camera capture will be added later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INFORMATION CARD
  // ---------------------------------------------------------------------------

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 19,
            color: teal,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'What happens next?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Your image will open in Image Review, where you can annotate what you see. The computer analysis runs separately on the original image.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
