import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class BloodAnalysisResult {
  final bool success;
  final String screeningName;
  final String screeningStatus;
  final String screeningMotivation;
  final bool prototypeOnly;
  final double modelConfidence;
  final int cellsAssessed;
  final int rbcCount;
  final int wbcCount;
  final int plateletCount;
  final double meanRbcDiameterPx;
  final double sizeVariationPercent;
  final int sickleLikeCount;
  final List<String> additionalFindings;
  final List<Map<String, dynamic>> detections;
  final List<Map<String, dynamic>> sickleLikeCells;
  final String annotatedImagePath;
  final String inputImagePath;

  BloodAnalysisResult({
    required this.success,
    required this.screeningName,
    required this.screeningStatus,
    required this.screeningMotivation,
    required this.prototypeOnly,
    required this.modelConfidence,
    required this.cellsAssessed,
    required this.rbcCount,
    required this.wbcCount,
    required this.plateletCount,
    required this.meanRbcDiameterPx,
    required this.sizeVariationPercent,
    required this.sickleLikeCount,
    required this.additionalFindings,
    required this.detections,
    required this.sickleLikeCells,
    required this.annotatedImagePath,
    required this.inputImagePath,
  });

  factory BloodAnalysisResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final counts = Map<String, dynamic>.from(
      json['counts'] ?? {},
    );

    final findings =
        (json['additional_findings'] as List<dynamic>? ?? [])
            .map((finding) => finding.toString())
            .toList();

    final detections =
        (json['detections'] as List<dynamic>? ?? [])
            .map(
              (detection) =>
                  Map<String, dynamic>.from(
                detection as Map,
              ),
            )
            .toList();

    final sickleCells =
        (json['sickle_like_cells'] as List<dynamic>? ?? [])
            .map(
              (cell) =>
                  Map<String, dynamic>.from(
                cell as Map,
              ),
            )
            .toList();

    return BloodAnalysisResult(
      success: json['success'] == true,
      screeningName:
          json['screening_name']?.toString() ??
              'Blood smear screening',
      screeningStatus:
          json['screening_status']?.toString() ??
              'review',
      screeningMotivation:
          json['screening_motivation']?.toString() ??
              '',
      prototypeOnly:
          json['prototype_only'] == true,
      modelConfidence:
          _toDouble(json['model_confidence']),
      cellsAssessed:
          _toInt(json['cells_assessed']),
      rbcCount:
          _toInt(
        counts['RBC'] ?? counts['rbc'],
      ),
      wbcCount:
          _toInt(
        counts['WBC'] ?? counts['wbc'],
      ),
      plateletCount:
          _toInt(
        counts['Platelets'] ??
            counts['platelets'],
      ),
      meanRbcDiameterPx:
          _toDouble(
        json['mean_rbc_diameter_px'],
      ),
      sizeVariationPercent:
          _toDouble(
        json['size_variation_percent'],
      ),
      sickleLikeCount:
          _toInt(
        json['sickle_like_count'],
      ),
      additionalFindings: findings,
      detections: detections,
      sickleLikeCells: sickleCells,
      annotatedImagePath:
          json['annotated_image_path']?.toString() ??
              '',
      inputImagePath:
          json['input_image_path']?.toString() ??
              '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

class PythonAnalysisService {
  static const String serverUrl =
      'https://magnetize-undertake-impromptu.ngrok-free.dev';

  static Future<BloodAnalysisResult> analyzeBloodSmear({
    required String imagePath,
  }) async {
    final imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      throw Exception(
        'The selected image could not be found.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$serverUrl/analyze'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imagePath,
      ),
    );

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'The Python analysis server returned '
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'The Python analysis server returned '
        'an invalid response.',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['error']?.toString() ??
            'Computer analysis failed.',
      );
    }

    final annotatedImageBase64 =
        decoded['annotated_image_base64']
            ?.toString();

    String annotatedImagePath = '';

    if (annotatedImageBase64 != null &&
        annotatedImageBase64.isNotEmpty) {
      final bytes =
          base64Decode(annotatedImageBase64);

      final directory =
          await Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}pocketscope_analysis',
      ).create(
        recursive: true,
      );

      final outputFile = File(
        '${directory.path}${Platform.pathSeparator}analysed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await outputFile.writeAsBytes(bytes);

      annotatedImagePath =
          outputFile.path;
    }

    final resultJson =
        Map<String, dynamic>.from(decoded);

    resultJson['annotated_image_path'] =
        annotatedImagePath;

    resultJson['input_image_path'] =
        imagePath;

    return BloodAnalysisResult.fromJson(
      resultJson,
    );
  }
}