import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();

    return _database!;
  }

  static Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'pocketscope.db',
    );

    return openDatabase(
      path,
      version: 10,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createDatabase(
    Database database,
    int version,
  ) async {
    await database.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        id_passport TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        occupation TEXT NOT NULL,
        hpcsa_registration_number TEXT,
        password TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        surname TEXT NOT NULL,
        identity_number TEXT,
        date_of_birth TEXT,
        sex_at_birth TEXT NOT NULL,
        gender TEXT NOT NULL,
        gender_description TEXT,
        phone_number TEXT NOT NULL,
        email TEXT,
        address TEXT NOT NULL,
        medical_record_number TEXT,
        clinical_note TEXT,
        imaging_consent_signature_path TEXT,
        imaging_consent_date TEXT,
        clinic_name TEXT,
        doctor_gp_name TEXT,
        user_id INTEGER
      )
    ''');

    await database.execute('''
      CREATE TABLE samples (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        specimen_type TEXT NOT NULL,
        sample_specification TEXT NOT NULL,
        magnification TEXT NOT NULL,
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
      CREATE TABLE clinical_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id TEXT NOT NULL,
        sample_id TEXT NOT NULL UNIQUE,
        report_date TEXT NOT NULL,
        patient_name TEXT NOT NULL,
        specimen TEXT NOT NULL,
        collected_date TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        registration_number TEXT NOT NULL,
        facility_name TEXT NOT NULL,
        screening_result TEXT NOT NULL,
        measurements TEXT NOT NULL,
        confidence_level TEXT NOT NULL,
        interpretation TEXT NOT NULL,
        image_path TEXT
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
        'counter_type': 'medical_record',
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

  static Future<bool> _columnExists(
    Database database,
    String tableName,
    String columnName,
  ) async {
    final result = await database.rawQuery(
      'PRAGMA table_info($tableName)',
    );

    return result.any(
      (column) =>
          column['name']?.toString() == columnName,
    );
  }

  static Future<void> _addColumnIfMissing(
    Database database, {
    required String tableName,
    required String columnName,
    required String columnDefinition,
  }) async {
    final exists = await _columnExists(
      database,
      tableName,
      columnName,
    );

    if (!exists) {
      await database.execute(
        'ALTER TABLE $tableName '
        'ADD COLUMN $columnName $columnDefinition',
      );
    }
  }

  static Future<void> _upgradeDatabase(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    await _addColumnIfMissing(
      database,
      tableName: 'patients',
      columnName: 'medical_record_number',
      columnDefinition: 'TEXT',
    );

    await _addColumnIfMissing(
      database,
      tableName: 'patients',
      columnName: 'clinical_note',
      columnDefinition: 'TEXT',
    );

    await _addColumnIfMissing(
      database,
      tableName: 'patients',
      columnName: 'imaging_consent_signature_path',
      columnDefinition: 'TEXT',
    );

    await _addColumnIfMissing(
      database,
      tableName: 'patients',
      columnName: 'imaging_consent_date',
      columnDefinition: 'TEXT',
    );

    await _addColumnIfMissing(
      database,
      tableName: 'patients',
      columnName: 'clinic_name',
      columnDefinition: 'TEXT',
    );

    await _addColumnIfMissing(
      database,
      tableName: 'patients',
      columnName: 'doctor_gp_name',
      columnDefinition: 'TEXT',
    );

    await _addColumnIfMissing(
      database,
      tableName: 'patients',
      columnName: 'identity_number',
      columnDefinition: 'TEXT',
    );

    await _addColumnIfMissing(
      database,
      tableName: 'patients',
      columnName: 'user_id',
      columnDefinition: 'INTEGER',
    );

    await _addColumnIfMissing(
      database,
      tableName: 'samples',
      columnName: 'sample_specification',
      columnDefinition: 'TEXT NOT NULL DEFAULT \'\'',
    );

    await _addColumnIfMissing(
      database,
      tableName: 'samples',
      columnName: 'magnification',
      columnDefinition: 'TEXT NOT NULL DEFAULT \'\'',
    );

    final medicalRecordCounter = await database.query(
      'id_counters',
      where: 'counter_type = ?',
      whereArgs: ['medical_record'],
      limit: 1,
    );

    if (medicalRecordCounter.isEmpty) {
      await database.insert(
        'id_counters',
        {
          'counter_type': 'medical_record',
          'next_number': 1,
        },
      );
    }

    // Version 10 adds permanent clinical reports.
    final reportsTable = await database.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      AND name = 'clinical_reports'
      ''',
    );

    if (reportsTable.isEmpty) {
      await database.execute('''
        CREATE TABLE clinical_reports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          patient_id TEXT NOT NULL,
          sample_id TEXT NOT NULL UNIQUE,
          report_date TEXT NOT NULL,
          patient_name TEXT NOT NULL,
          specimen TEXT NOT NULL,
          collected_date TEXT NOT NULL,
          doctor_name TEXT NOT NULL,
          registration_number TEXT NOT NULL,
          facility_name TEXT NOT NULL,
          screening_result TEXT NOT NULL,
          measurements TEXT NOT NULL,
          confidence_level TEXT NOT NULL,
          interpretation TEXT NOT NULL,
          image_path TEXT
        )
      ''');
    }
  }

  // ---------------------------------------------------------------------------
  // USERS
  // ---------------------------------------------------------------------------

  static Future<void> saveUser(
    Map<String, dynamic> user,
  ) async {
    final database = await DatabaseService.database;

    await database.insert(
      'users',
      user,
    );
  }

  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    final database = await DatabaseService.database;

    final results = await database.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [
        email,
        password,
      ],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  static Future<Map<String, dynamic>?> getUser(
    int userId,
  ) async {
    final database = await DatabaseService.database;

    final results = await database.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  static Future<Map<String, dynamic>?> getUserByEmail(
    String email,
  ) async {
    final database = await DatabaseService.database;

    final results = await database.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  static Future<void> updateUserPassword({
    required String email,
    required String newPassword,
  }) async {
    final database = await DatabaseService.database;

    await database.update(
      'users',
      {
        'password': newPassword,
      },
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // ---------------------------------------------------------------------------
  // PATIENTS
  // ---------------------------------------------------------------------------

  static Future<void> savePatient(
    Map<String, dynamic> patient,
  ) async {
    final database = await DatabaseService.database;

    await database.insert(
      'patients',
      patient,
    );
  }

  static Future<void> updatePatient(
    String patientId,
    Map<String, dynamic> patient,
  ) async {
    final database = await DatabaseService.database;

    await database.update(
      'patients',
      patient,
      where: 'id = ?',
      whereArgs: [patientId],
    );
  }

  static Future<List<Map<String, dynamic>>> getPatients() async {
    final database = await DatabaseService.database;

    return database.query(
      'patients',
      orderBy: 'id ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getPatientsForUser(
    int userId,
  ) async {
    final database = await DatabaseService.database;

    return database.query(
      'patients',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
  }

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

  static Future<Map<String, dynamic>?> getPatientForUser({
    required String patientId,
    required int userId,
  }) async {
    final database = await DatabaseService.database;

    final results = await database.query(
      'patients',
      where: 'id = ? AND user_id = ?',
      whereArgs: [
        patientId,
        userId,
      ],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  static Future<bool> updatePatientClinicalNote({
    required String patientId,
    required String clinicalNote,
  }) async {
    final database = await DatabaseService.database;

    final updatedRows = await database.update(
      'patients',
      {
        'clinical_note': clinicalNote,
      },
      where: 'id = ?',
      whereArgs: [patientId],
    );

    return updatedRows == 1;
  }

  static Future<void> updatePatientMedicalRecordNumber({
    required String patientId,
    required String medicalRecordNumber,
  }) async {
    final database = await DatabaseService.database;

    await database.update(
      'patients',
      {
        'medical_record_number': medicalRecordNumber,
      },
      where: 'id = ?',
      whereArgs: [patientId],
    );
  }

  static Future<void> updatePatientClinic({
    required String patientId,
    required String clinicName,
  }) async {
    final database = await DatabaseService.database;

    await database.update(
      'patients',
      {
        'clinic_name': clinicName,
      },
      where: 'id = ?',
      whereArgs: [patientId],
    );
  }

  static Future<void> updatePatientDoctorGp({
    required String patientId,
    required String doctorGpName,
  }) async {
    final database = await DatabaseService.database;

    await database.update(
      'patients',
      {
        'doctor_gp_name': doctorGpName,
      },
      where: 'id = ?',
      whereArgs: [patientId],
    );
  }

  static Future<bool> saveImagingConsent({
    required String patientId,
    required String signaturePath,
    required DateTime signedDate,
  }) async {
    final database = await DatabaseService.database;

    final updatedRows = await database.update(
      'patients',
      {
        'imaging_consent_signature_path': signaturePath,
        'imaging_consent_date': signedDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [patientId],
    );

    return updatedRows == 1;
  }

  static Future<void> clearImagingConsent(
    String patientId,
  ) async {
    final database = await DatabaseService.database;

    await database.update(
      'patients',
      {
        'imaging_consent_signature_path': null,
        'imaging_consent_date': null,
      },
      where: 'id = ?',
      whereArgs: [patientId],
    );
  }

  static Future<int> getPatientCount() async {
    final database = await DatabaseService.database;

    final result = await database.rawQuery(
      'SELECT COUNT(*) AS count FROM patients',
    );

    return result.first['count'] as int;
  }

  // ---------------------------------------------------------------------------
  // SAMPLES
  // ---------------------------------------------------------------------------

  static Future<void> saveSample(
    Map<String, dynamic> sample,
  ) async {
    final database = await DatabaseService.database;

    await database.insert(
      'samples',
      sample,
    );
  }

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

  static Future<int> getSampleCount() async {
    final database = await DatabaseService.database;

    final result = await database.rawQuery(
      'SELECT COUNT(*) AS count FROM samples',
    );

    return result.first['count'] as int;
  }

  static Future<int> getPendingSampleCount() async {
    final database = await DatabaseService.database;

    final result = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM samples
      WHERE LOWER(TRIM(COALESCE(analysis_status, ''))) IN (
        'new sample',
        'analysis due',
        'pending'
      )
    ''');

    return result.first['count'] as int;
  }

  static Future<List<Map<String, dynamic>>> getRecentSamples({
    int limit = 3,
  }) async {
    final database = await DatabaseService.database;

    return database.rawQuery(
      '''
      SELECT
        samples.id AS sample_id,
        samples.patient_id,
        samples.specimen_type,
        samples.sample_specification,
        samples.magnification,
        samples.reason_for_visit,
        samples.collection_date_time,
        samples.analysis_date_time,
        samples.analysis_status,
        patients.first_name,
        patients.surname,
        patients.date_of_birth

      FROM samples

      INNER JOIN patients
        ON samples.patient_id = patients.id

      ORDER BY
        datetime(samples.collection_date_time) DESC

      LIMIT ?
      ''',
      [limit],
    );
  }

  static Future<void> updateSampleAnalysis({
    required String sampleId,
    required DateTime analysisDateTime,
    required String analysisStatus,
  }) async {
    final database = await DatabaseService.database;

    await database.update(
      'samples',
      {
        'analysis_date_time': analysisDateTime.toIso8601String(),
        'analysis_status': analysisStatus,
      },
      where: 'id = ?',
      whereArgs: [sampleId],
    );
  }

  // ---------------------------------------------------------------------------
  // ANALYSIS RESULTS
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // CLINICAL REPORTS
  // ---------------------------------------------------------------------------

  static Future<void> saveClinicalReport(
    Map<String, dynamic> report,
  ) async {
    final database = await DatabaseService.database;

    await database.insert(
      'clinical_reports',
      report,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getClinicalReportsForPatient(
    String patientId,
  ) async {
    final database = await DatabaseService.database;

    return database.query(
      'clinical_reports',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'report_date DESC',
    );
  }

  static Future<Map<String, dynamic>?> getClinicalReport(
    String sampleId,
  ) async {
    final database = await DatabaseService.database;

    final results = await database.query(
      'clinical_reports',
      where: 'sample_id = ?',
      whereArgs: [sampleId],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  // ---------------------------------------------------------------------------
  // IMAGES
  // ---------------------------------------------------------------------------

  static Future<void> saveImage(
    Map<String, dynamic> image,
  ) async {
    final database = await DatabaseService.database;

    await database.insert(
      'images',
      image,
    );
  }

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

  static Future<void> deleteImage(
    String imageId,
  ) async {
    await deleteImageRecord(imageId);
  }
}
