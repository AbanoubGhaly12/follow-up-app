import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'church_followup.db');

    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE families ADD COLUMN floor_number TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE families ADD COLUMN family_head TEXT');
    }
    if (oldVersion < 4) {
      // Forcefully recreate tables for structural shift (zone -> street -> family)
      await db.execute('DROP TABLE IF EXISTS members');
      await db.execute('DROP TABLE IF EXISTS families');
      // Recreate DB base with new schema (version 4)
      await _createDB(db, newVersion);
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE message_templates (
          id TEXT PRIMARY KEY,
          title TEXT,
          type TEXT,
          content TEXT,
          created_at TEXT,
          updated_at TEXT
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE followups (
          id TEXT PRIMARY KEY,
          family_id TEXT,
          followup_date TEXT,
          notes TEXT,
          type TEXT,
          created_at TEXT,
          updated_at TEXT,
          FOREIGN KEY (family_id) REFERENCES families (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE followups ADD COLUMN family_name TEXT');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE followups ADD COLUMN member_id TEXT');
      await db.execute('ALTER TABLE followups ADD COLUMN member_name TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Zones Table
    await db.execute('''
      CREATE TABLE zones (
        id TEXT PRIMARY KEY,
        name TEXT,
        tag TEXT,
        description TEXT,
        zone_admins TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Streets Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS streets (
        id TEXT PRIMARY KEY,
        zone_id TEXT,
        name TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (zone_id) REFERENCES zones (id) ON DELETE CASCADE
      )
    ''');

    // Families Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS families (
        id TEXT PRIMARY KEY,
        street_id TEXT,
        family_head TEXT,
        marriage_date TEXT,
        landline TEXT,
        street TEXT,
        building_number TEXT,
        floor_number TEXT,
        flat_number TEXT,
        street_from TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (street_id) REFERENCES streets (id) ON DELETE CASCADE
      )
    ''');

    // Members Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS members (
        id TEXT PRIMARY KEY,
        family_id TEXT,
        name TEXT,
        birthdate TEXT,
        mobile_number TEXT,
        email TEXT,
        confession_father TEXT,
        confession_father_church_name TEXT,
        national_id TEXT,
        belong_to_church_name TEXT,
        is_dead INTEGER,
        death_date TEXT,
        marital_status TEXT,
        college_year TEXT,
        profession TEXT,
        weekly_off_days TEXT,
        role TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (family_id) REFERENCES families (id) ON DELETE CASCADE
      )
    ''');

    // Message Templates Table
    await db.execute('''
      CREATE TABLE message_templates (
        id TEXT PRIMARY KEY,
        title TEXT,
        type TEXT,
        content TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Followups Table
    await db.execute('''
      CREATE TABLE followups (
        id TEXT PRIMARY KEY,
        family_id TEXT,
        family_name TEXT,
        member_id TEXT,
        member_name TEXT,
        followup_date TEXT,
        notes TEXT,
        type TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (family_id) REFERENCES families (id) ON DELETE CASCADE,
        FOREIGN KEY (member_id) REFERENCES members (id) ON DELETE CASCADE
      )
    ''');
  }
}
