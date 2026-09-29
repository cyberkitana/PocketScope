import '../services/database_service.dart';

/// Generates sequential IDs for patients, samples, and images.
class IdGenerator {
  /// Generates the next patient ID.
  ///
  /// Example:
  /// P-000001
  /// P-000002
  static Future<String> generatePatientId() async {
    return _generateId(
      counterType: 'patient',
      prefix: 'P',
    );
  }

  /// Generates the next sample ID based on specimen type.
  ///
  /// Urine:
  /// U-000001
  ///
  /// Blood:
  /// B-000001
  static Future<String> generateSampleId(
    String specimenType,
  ) async {
    if (specimenType == 'Urine') {
      return _generateId(
        counterType: 'urine',
        prefix: 'U',
      );
    }

    return _generateId(
      counterType: 'blood',
      prefix: 'B',
    );
  }

  /// Generates the next image ID based on specimen type.
  ///
  /// Urine:
  /// IMG-U-000001
  ///
  /// Blood:
  /// IMG-B-000001
  static Future<String> generateImageId(
    String specimenType,
  ) async {
    if (specimenType == 'Urine') {
      return _generateId(
        counterType: 'image_urine',
        prefix: 'IMG-U',
      );
    }

    return _generateId(
      counterType: 'image_blood',
      prefix: 'IMG-B',
    );
  }

  /// Gets the next number from the database and formats it as an ID.
  static Future<String> _generateId({
    required String counterType,
    required String prefix,
  }) async {
    final database = await DatabaseService.database;

    final results = await database.query(
      'id_counters',
      where: 'counter_type = ?',
      whereArgs: [counterType],
      limit: 1,
    );

    if (results.isEmpty) {
      throw Exception(
        'No ID counter found for $counterType.',
      );
    }

    final currentNumber = results.first['next_number'] as int;

    await database.update(
      'id_counters',
      {
        'next_number': currentNumber + 1,
      },
      where: 'counter_type = ?',
      whereArgs: [counterType],
    );

    final formattedNumber = currentNumber
        .toString()
        .padLeft(6, '0');

    return '$prefix-$formattedNumber';
  }
}