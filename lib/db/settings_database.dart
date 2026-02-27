import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SettingsDatabase {
  static final SettingsDatabase instance = SettingsDatabase._init();
  static Database? _database;

  static const _dbName = 'settings.db';
  static const _dbVersion = 1;

  SettingsDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // reserved for future migrations
  }

  // ─────────────────────────────────────────────────────────────
  // GENERIC KV API (LOW-LEVEL)
  // ─────────────────────────────────────────────────────────────

  Future<void> setBool(String key, bool value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value ? '1' : '0'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> getBool(
    String key, {
    bool defaultValue = false,
  }) async {
    final db = await database;
    final result =
        await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (result.isEmpty) return defaultValue;
    return result.first['value'] == '1';
  }

  Future<void> setString(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getString(String key) async {
    final db = await database;
    final result =
        await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Future<void> delete(String key) async {
    final db = await database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }

  // ─────────────────────────────────────────────────────────────
  // TYPED HELPERS (SAFE API)
  // ─────────────────────────────────────────────────────────────
  // Naming convention: domain.property

  // ───── AI

  Future<bool> isAiEnabled() => getBool('ai.enabled', defaultValue: false);

  Future<void> setAiEnabled(bool value) => setBool('ai.enabled', value);

  // ───── BACKUP

  Future<bool> isBackupEnabled() =>
      getBool('backup.enabled', defaultValue: false);

  Future<void> setBackupEnabled(bool value) => setBool('backup.enabled', value);

  Future<String?> getBackupProvider() => getString('backup.provider');

  Future<void> setBackupProvider(String provider) =>
      setString('backup.provider', provider);

  // ───── SUBSCRIPTION (DISPLAY STATE ONLY)

  Future<String> getSubscriptionStatus() async =>
      (await getString('subscription.status')) ?? 'none';

  Future<void> setSubscriptionStatus(String status) =>
      setString('subscription.status', status);

  Future<String?> getSubscriptionPlan() => getString('subscription.plan');

  Future<void> setSubscriptionPlan(String plan) =>
      setString('subscription.plan', plan);

  // ───── PROFILE / AUTH (LOCAL MIRROR ONLY)

  /// Whether user is logged in (derived from auth flow, not decided here)
  Future<bool> isLoggedIn() =>
      getBool('profile.logged_in', defaultValue: false);

  Future<void> setLoggedIn(bool value) => setBool('profile.logged_in', value);

  /// Auth provider: google | github | apple | none
  Future<String> getAuthProvider() async =>
      (await getString('profile.auth_provider')) ?? 'none';

  Future<void> setAuthProvider(String provider) =>
      setString('profile.auth_provider', provider);

  /// Optional display name (purely cosmetic)
  Future<String?> getDisplayName() => getString('profile.display_name');

  Future<void> setDisplayName(String name) =>
      setString('profile.display_name', name);

  /// Optional avatar URL (do NOT assume network availability)
  Future<String?> getAvatarUrl() => getString('profile.avatar_url');

  Future<void> setAvatarUrl(String url) => setString('profile.avatar_url', url);

  /// Clears all profile-related state on logout
  Future<void> clearProfile() async {
    await delete('profile.logged_in');
    await delete('profile.auth_provider');
    await delete('profile.display_name');
    await delete('profile.avatar_url');
  }
}
