// This file contains the pop-up dialogs used on the patient profile screen.
//
// It keeps the clinical note and imaging consent dialogs separate from
// the main patient profile screen.
//
// The clinical note is saved through DatabaseService.
//
// The imaging consent signature is:
// 1. Drawn by the user.
// 2. Checked to make sure an actual signature was drawn.
// 3. Captured as a PNG image.
// 4. Saved in the application's documents directory.
// 5. Stored in the patient database together with the signing date.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/database_service.dart';


// ============================================================================
// CLINICAL NOTE DIALOG
// ============================================================================

/// Opens the clinical note editor.
///
/// Returns the updated note when the user presses Save.
///
/// Returns null when the user cancels the dialog.
Future<String?> showClinicalNoteDialog({
  required BuildContext context,
  required String initialNote,
}) async {
  // Create a controller containing the patient's existing note.
  final controller = TextEditingController(
    text: initialNote,
  );

  // Display the note editor as a centred dialog.
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        // Dialog heading.
        title: const Text(
          'Clinical note',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        // Clinical note text field.
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Enter a clinical note...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              alignLabelWithHint: true,
            ),
          ),
        ),

        // Dialog buttons.
        actions: [
          // Close the dialog without saving anything.
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),

          // Return the edited note to the patient profile screen.
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                controller.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  // Dispose the controller after the dialog has closed.
  controller.dispose();

  return result;
}


// ============================================================================
// IMAGING CONSENT DIALOG
// ============================================================================

/// Opens the imaging consent form.
///
/// The user must draw an actual signature before the Save consent
/// button becomes available.
///
/// A simple click, tap or extremely small movement does not count
/// as a signature.
///
/// Returns the signing date when consent is successfully saved.
///
/// Returns null when the user cancels the form.
Future<DateTime?> showImagingConsentDialog({
  required BuildContext context,
  required String patientId,
}) async {
  // This key identifies the complete signature area.
  //
  // The RepaintBoundary uses this key later when the signature
  // is captured as a PNG image.
  final signatureKey = GlobalKey();

  // Stores all positions touched while the user draws.
  //
  // Offset.infinite is used to mark the end of one stroke.
  final List<Offset> signaturePoints = [];

  // Open the consent form as a centred dialog.
  final signedDate = await showDialog<DateTime>(
    context: context,

    // Do not allow the user to accidentally dismiss the consent
    // form by clicking outside the dialog.
    barrierDismissible: false,

    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (
          BuildContext context,
          StateSetter setDialogState,
        ) {
          // Check whether the points currently recorded
          // represent an actual handwritten signature.
          final hasSignature = _hasActualSignature(
            signaturePoints,
          );

          return AlertDialog(
            // Dialog heading.
            title: const Text(
              'Imaging consent',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),

            // Consent form content.
            content: SizedBox(
              width: 430,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please sign below to provide imaging consent.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // SIGNATURE AREA
                  // ----------------------------------------------------------

                  RepaintBoundary(
                    key: signatureKey,
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          // Start recording a new signature stroke.
                          onPanStart: (details) {
                            setDialogState(() {
                              signaturePoints.add(
                                details.localPosition,
                              );
                            });
                          },

                          // Continue recording the current signature stroke.
                          onPanUpdate: (details) {
                            setDialogState(() {
                              signaturePoints.add(
                                details.localPosition,
                              );
                            });
                          },

                          // Mark the end of the current signature stroke.
                          onPanEnd: (details) {
                            setDialogState(() {
                              signaturePoints.add(
                                Offset.infinite,
                              );
                            });
                          },

                          // Paint the recorded signature points.
                          child: CustomPaint(
                            painter: SignaturePainter(
                              // Make a copy of the points so that
                              // the painter receives the current drawing.
                              points: List<Offset>.from(
                                signaturePoints,
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Let the user know whether a valid signature
                  // has been detected.
                  Text(
                    hasSignature
                        ? 'Signature captured.'
                        : 'Draw your signature in the box above.',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasSignature
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Clear the current signature.
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      // Disable the button when there is nothing to clear.
                      onPressed: signaturePoints.isEmpty
                          ? null
                          : () {
                              setDialogState(() {
                                // Remove every recorded signature point.
                                signaturePoints.clear();
                              });
                            },
                      child: const Text(
                        'Clear signature',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Consent actions.
            actions: [
              // Cancel without saving the consent.
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),

              // Save is disabled until a real signature is present.
              FilledButton(
                onPressed: hasSignature
                    ? () {
                        _saveSignatureAndConsent(
                          dialogContext: dialogContext,
                          signatureKey: signatureKey,
                          patientId: patientId,
                          signaturePoints: signaturePoints,
                        );
                      }
                    : null,
                child: const Text(
                  'Save consent',
                ),
              ),
            ],
          );
        },
      );
    },
  );

  return signedDate;
}


// ============================================================================
// SIGNATURE VALIDATION
// ============================================================================

/// Determines whether the user has actually drawn a signature.
///
/// A single click or tap should not count as a signature.
///
/// There must be meaningful movement between points in the
/// signature area.
///
/// The check also ignores Offset.infinite because those values
/// are only used to separate individual strokes.
bool _hasActualSignature(
  List<Offset> points,
) {
  // Check each pair of neighbouring points.
  for (
    int index = 0;
    index < points.length - 1;
    index++
  ) {
    final current = points[index];
    final next = points[index + 1];

    // Offset.infinite marks the end of a stroke.
    //
    // It is not a real drawing position and must therefore
    // not be included in the distance calculation.
    if (current == Offset.infinite ||
        next == Offset.infinite) {
      continue;
    }

    // Calculate horizontal movement.
    final dx = next.dx - current.dx;

    // Calculate vertical movement.
    final dy = next.dy - current.dy;

    // Calculate the squared distance between the points.
    //
    // Squared distance is enough for checking the threshold
    // and avoids an unnecessary square-root calculation.
    final distanceSquared =
        (dx * dx) + (dy * dy);

    // Three pixels or more between two points counts as
    // meaningful movement.
    if (distanceSquared >= 9) {
      return true;
    }
  }

  // No meaningful movement was found.
  return false;
}


// ============================================================================
// SAVE SIGNATURE
// ============================================================================

/// Captures the handwritten signature and saves it as a PNG.
///
/// The PNG is stored in the application's documents directory.
///
/// SQLite stores:
/// - the signature file path
/// - the date and time the consent was signed
///
/// The signature is checked again immediately before saving so that
/// an empty signature cannot accidentally be stored.
Future<void> _saveSignatureAndConsent({
  required BuildContext dialogContext,
  required GlobalKey signatureKey,
  required String patientId,
  required List<Offset> signaturePoints,
}) async {
  try {
    // ------------------------------------------------------------------------
    // CHECK THE SIGNATURE AGAIN
    // ------------------------------------------------------------------------

    // Do not rely only on the button being enabled.
    //
    // Check the drawing again immediately before saving.
    if (!_hasActualSignature(signaturePoints)) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Please draw a signature before saving consent.',
            ),
          ),
        );
      }

      return;
    }

    // ------------------------------------------------------------------------
    // FIND THE SIGNATURE AREA
    // ------------------------------------------------------------------------

    // Find the render object belonging to the signature area.
    final renderObject = signatureKey.currentContext
        ?.findRenderObject();

    // Confirm that Flutter found the expected repaint boundary.
    if (renderObject == null ||
        renderObject is! RenderRepaintBoundary) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text(
              'The signature could not be captured.',
            ),
          ),
        );
      }

      return;
    }

    // Dart now knows that this is a RenderRepaintBoundary.
    final RenderRepaintBoundary boundary =
        renderObject;

    // ------------------------------------------------------------------------
    // CAPTURE THE SIGNATURE
    // ------------------------------------------------------------------------

    // Convert the visible signature area into an image.
    final ui.Image image = await boundary.toImage(
      pixelRatio: 3,
    );

    // Convert the captured image into PNG data.
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    // Stop if Flutter could not create the PNG data.
    if (byteData == null) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text(
              'The signature image could not be created.',
            ),
          ),
        );
      }

      return;
    }

    // Convert the PNG data into bytes that can be written to disk.
    final Uint8List pngBytes =
        byteData.buffer.asUint8List();

    // ------------------------------------------------------------------------
    // CREATE THE SIGNATURE DIRECTORY
    // ------------------------------------------------------------------------

    // Find the application's documents directory.
    final documentsDirectory =
        await getApplicationDocumentsDirectory();

    // Store all patient consent signatures in one folder.
    final signatureDirectory = Directory(
      '${documentsDirectory.path}/consent_signatures',
    );

    // Create the folder when it does not already exist.
    if (!await signatureDirectory.exists()) {
      await signatureDirectory.create(
        recursive: true,
      );
    }

    // ------------------------------------------------------------------------
    // CREATE THE SIGNATURE FILE
    // ------------------------------------------------------------------------

    // Use the patient ID in the filename so that each patient's
    // current consent signature has a predictable location.
    final signatureFile = File(
      '${signatureDirectory.path}/${patientId}_consent.png',
    );

    // Write the signature PNG to disk.
    await signatureFile.writeAsBytes(
      pngBytes,
      flush: true,
    );

    // Confirm that the file was actually created.
    if (!await signatureFile.exists()) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text(
              'The signature file could not be saved.',
            ),
          ),
        );
      }

      return;
    }

    // ------------------------------------------------------------------------
    // SAVE THE CONSENT INFORMATION
    // ------------------------------------------------------------------------

    // Record the exact date and time on which consent was signed.
    final signedDate = DateTime.now();

    // Save the signature path and signing date to SQLite.
    final saved = await DatabaseService.saveImagingConsent(
      patientId: patientId,
      signaturePath: signatureFile.path,
      signedDate: signedDate,
    );

    // If the database update did not affect the patient record,
    // do not report the consent as successfully saved.
    if (!saved) {
      // Remove the newly-created signature file because the
      // database did not successfully store the consent record.
      if (await signatureFile.exists()) {
        await signatureFile.delete();
      }

      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text(
              'The imaging consent could not be saved.',
            ),
          ),
        );
      }

      return;
    }

    // ------------------------------------------------------------------------
    // CLOSE THE DIALOG
    // ------------------------------------------------------------------------

    // The dialog may have been closed while the asynchronous
    // file/database operations were running.
    if (!dialogContext.mounted) {
      return;
    }

    // Close the dialog and return the signing date to the
    // patient profile screen.
    Navigator.pop(
      dialogContext,
      signedDate,
    );
  } catch (error) {
    // Do not try to use a BuildContext that is no longer mounted.
    if (!dialogContext.mounted) {
      return;
    }

    // Tell the user that something went wrong.
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(
        content: Text(
          'Could not save imaging consent: $error',
        ),
      ),
    );
  }
}


// ============================================================================
// SIGNATURE PAINTER
// ============================================================================

/// Draws the user's handwritten signature.
///
/// Each Offset represents a position touched by the mouse or finger.
///
/// Consecutive points are connected with lines.
///
/// Offset.infinite marks the end of one stroke so that a line is
/// not accidentally drawn between two separate strokes.
class SignaturePainter extends CustomPainter {
  /// All recorded drawing positions.
  final List<Offset> points;

  SignaturePainter({
    required this.points,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    // Define the appearance of the handwritten signature.
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw each section of the signature.
    for (
      int index = 0;
      index < points.length - 1;
      index++
    ) {
      final currentPoint = points[index];
      final nextPoint = points[index + 1];

      // Offset.infinite means that the current stroke has ended.
      //
      // Do not draw a line through the stroke separator.
      if (currentPoint == Offset.infinite ||
          nextPoint == Offset.infinite) {
        continue;
      }

      // Draw a line between the two recorded points.
      canvas.drawLine(
        currentPoint,
        nextPoint,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant SignaturePainter oldDelegate,
  ) {
    // Repaint whenever the signature points change.
    return true;
  }
}