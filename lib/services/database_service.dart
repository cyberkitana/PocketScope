import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Handles the SQLite database used by LabScreen.
class DatabaseService {
  static Database? _database;

  /// Returns the application database.
  ///
  /// If the database has not been opened yet, it creates it first.
  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();

    return _database!;
  }

  /// Opens the SQLite database.
  static Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'labscreen.db',
    );

    return openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Creates the database tables when the database is first created.
  static Future<void> _createDatabase(
    Database database,
    int version,
  ) async {
    await database.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        surname TEXT NOT NULL,
        date_of_birth TEXT,
        sex_at_birth TEXT NOT NULL,
        gender TEXT NOT NULL,
        gender_description TEXT,
        phone_number TEXT NOT NULL,
        email TEXT,
        address TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE samples (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        specimen_type TEXT NOT NULL,
        reason_for_visit TEXT NOT NULL,
        collection_date_time TEXT NOT NULL,
        analysis_date_time TEXT,
        analysis_status TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE images (
        id TEXT PRIMARY KEY,
        sample_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        captured_at TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE analysis_results (
        sample_id TEXT PRIMARY KEY,
        analysis_date_time TEXT NOT NULL,
        analysis_status TEXT NOT NULL,
        detected_features TEXT NOT NULL,
        screening_result TEXT NOT NULL,
        confidence REAL
      )
    ''');

    await database.execute('''
      CREATE TABLE detections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_id TEXT NOT NULL,
        label TEXT NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        confidence REAL
      )
    ''');

    await database.execute('''
      CREATE TABLE id_counters (
        counter_type TEXT PRIMARY KEY,
        next_number INTEGER NOT NULL
      )
    ''');

    await database.insert(
      'id_counters',
      {
        'counter_type': 'patient',
        'next_number': 1,
      },
    );

    await database.insert(
      'id_counters',
      {
        'counter_type': 'urine',
        'next_number': 1,
      },
    );

    await database.insert(
      'id_counters',
      {
        'counter_type': 'blood',
        'next_number': 1,
      },
    );

    await database.insert(
      'id_counters',
      {
        'counter_type': 'image_urine',
        'next_number': 1,
      },
    );

    await database.insert(
      'id_counters',
      {
        'counter_type': 'image_blood',
        'next_number': 1,
      },
    );
  }

  /// Upgrades older database versions when the structure changes.
  static Future<void> _upgradeDatabase(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _upgradeToVersion2(database);
    }
  }

  /// Migrates the original database structure to version 2.
  static Future<void> _upgradeToVersion2(
    Database database,
  ) async {
    await database.transaction((transaction) async {
      await transaction.execute('''
        ALTER TABLE patients
        RENAME TO patients_old
      ''');

      await transaction.execute('''
        CREATE TABLE patients (
          id TEXT PRIMARY KEY,
          first_name TEXT NOT NULL,
          surname TEXT NOT NULL,
          date_of_birth TEXT,
          sex_at_birth TEXT NOT NULL,
          gender TEXT NOT NULL,
          gender_description TEXT,
          phone_number TEXT NOT NULL,
          email TEXT,
          address TEXT NOT NULL
        )
      ''');

      await transaction.execute('''
        INSERT INTO patients (
          id,
          first_name,
          surname,
          date_of_birth,
          sex_at_birth,
          gender,
          gender_description,
          phone_number,
          email,
          address
        )
        SELECT
          id,
          first_name,
          surname,
          date_of_birth,
          sex_at_birth,
          gender,
          gender_description,
          '',
          NULL,
          ''
        FROM patients_old
      ''');

      await transaction.execute(
        'DROP TABLE patients_old',
      );

      await transaction.execute('''
        ALTER TABLE samples
        RENAME TO samples_old
      ''');

      await transaction.execute('''
        CREATE TABLE samples (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          specimen_type TEXT NOT NULL,
          reason_for_visit TEXT NOT NULL,
          collection_date_time TEXT NOT NULL,
          analysis_date_time TEXT,
          analysis_status TEXT NOT NULL
        )
      ''');

      await transaction.execute('''
        INSERT INTO samples (
          id,
          patient_id,
          specimen_type,
          reason_for_visit,
          collection_date_time,
          analysis_date_time,
          analysis_status
        )
        SELECT
          id,
          patient_id,
          specimen_type,
          reason_for_visit,
          collection_date_time,
          analysis_date_time,
          analysis_status
        FROM samples_old
      ''');

      await transaction.execute(
        'DROP TABLE samples_old',
      );

      await transaction.execute('''
        ALTER TABLE analysis_results
        RENAME TO analysis_results_old
      ''');

      await transaction.execute('''
        CREATE TABLE analysis_results (
          sample_id TEXT PRIMARY KEY,
          analysis_date_time TEXT NOT NULL,
          analysis_status TEXT NOT NULL,
          detected_features TEXT NOT NULL,
          screening_result TEXT NOT NULL,
          confidence REAL
        )
      ''');

      await transaction.execute('''
        INSERT INTO analysis_results (
          sample_id,
          analysis_date_time,
          analysis_status,
          detected_features,
          screening_result,
          confidence
        )
        SELECT
          sample_id,
          analysis_date_time,
          analysis_status,
          detected_features,
          screening_result,
          confidence
        FROM analysis_results_old
      ''');

      await transaction.execute(
        'DROP TABLE analysis_results_old',
      );

      await transaction.execute('''
        CREATE TABLE detections (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image_id TEXT NOT NULL,
          label TEXT NOT NULL,
          x REAL NOT NULL,
          y REAL NOT NULL,
          width REAL NOT NULL,
          height REAL NOT NULL,
          confidence REAL
        )
      ''');

      await transaction.insert(
        'id_counters',
        {
          'counter_type': 'image_urine',
          'next_number': 1,
        },
      );

      await transaction.insert(
        'id_counters',
        {
          'counter_type': 'image_blood',
          'next_number': 1,
        },
      );
    });
  }

  /// Saves a patient to the database.
  static Future<void> savePatient(
    Map<String, dynamic> patient,
  ) async {
    final database = await DatabaseService.database;

    await database.insert(
      'patients',
      patient,
    );
  }

  /// Retrieves all patients from the database.
  static Future<List<Map<String, dynamic>>> getPatients() async {
    final database = await DatabaseService.database;

    return database.query(
      'patients',
      orderBy: 'id ASC',
    );
  }

  /// Retrieves one patient using their patient ID.
  static Future<Map<String, dynamic>?> getPatient(
    String patientId,
  ) async {
    final database = await DatabaseService.database;

    final results = await database.query(
      'patients',
      where: 'id = ?',
      whereArgs: [patientId],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  /// Saves a sample to the database.
  static Future<void> saveSample(
    Map<String, dynamic> sample,
  ) async {
    final database = await DatabaseService.database;

    await database.insert(
      'samples',
      sample,
    );
  }

  /// Retrieves all samples belonging to one patient.
  static Future<List<Map<String, dynamic>>> getSamplesForPatient(
    String patientId,
  ) async {
    final database = await DatabaseService.database;

    return database.query(
      'samples',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'collection_date_time DESC',
    );
  }

  /// Retrieves one sample using its sample ID.
  static Future<Map<String, dynamic>?> getSample(
    String sampleId,
  ) async {
    final database = await DatabaseService.database;

    final results = await database.query(
      'samples',
      where: 'id = ?',
      whereArgs: [sampleId],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  /// Updates a sample when its analysis is completed.
  static Future<void> updateSampleAnalysis({
    required String sampleId,
    required DateTime analysisDateTime,
    required String analysisStatus,
  }) async {
    final database = await DatabaseService.database;

    await database.update(
      'samples',
      {
        'analysis_date_time':
            analysisDateTime.toIso8601String(),
        'analysis_status': analysisStatus,
      },
      where: 'id = ?',
      whereArgs: [sampleId],
    );
  }

  /// Saves the analysis result for a sample.
  static Future<void> saveAnalysisResult(
    Map<String, dynamic> result,
  ) async {
    final database = await DatabaseService.database;

    await database.insert(
      'analysis_results',
      result,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Saves an uploaded image to the database.
  static Future<void> saveImage(
    Map<String, dynamic> image,
  ) async {
    final database = await DatabaseService.database;

    await database.insert(
      'images',
      image,
    );
  }

  /// Retrieves all images belonging to one sample.
  static Future<List<Map<String, dynamic>>> getImagesForSample(
    String sampleId,
  ) async {
    final database = await DatabaseService.database;

    return database.query(
      'images',
      where: 'sample_id = ?',
      whereArgs: [sampleId],
      orderBy: 'captured_at ASC',
    );
  }

  /// Deletes one image record from the database.
  static Future<void> deleteImageRecord(
    String imageId,
  ) async {
    final database = await DatabaseService.database;

    await database.delete(
      'images',
      where: 'id = ?',
      whereArgs: [imageId],
    );
  }

  /// Deletes one image from the database using its image ID.
  static Future<void> deleteImage(
    String imageId,
  ) async {
    await deleteImageRecord(imageId);
  }
}