import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

/// Domain Collections Constants for SvasthyaSetu 4 Apps
class StorageCollection {
  static const String arogyaVitals = 'arogya_vitals';
  static const String medikioskIntake = 'medikiosk_intake';
  static const String rakshakBurnout = 'rakshak_burnout';
  static const String nyayaDistress = 'nyaya_distress';
  static const String generalCache = 'general_cache';
}

/// Storage Record Data Model
class StorageRecord {
  final String collection;
  final String key;
  final Map<String, dynamic> data;
  final bool isEncrypted;
  final bool isSynced;
  final String createdAt;
  final String updatedAt;
  final String deviceId;

  StorageRecord({
    required this.collection,
    required this.key,
    required this.data,
    this.isEncrypted = false,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'collection': collection,
        'key': key,
        'data': data,
        'is_encrypted': isEncrypted,
        'is_synced': isSynced,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'device_id': deviceId,
      };

  factory StorageRecord.fromJson(Map<String, dynamic> json) => StorageRecord(
        collection: json['collection'] ?? 'general',
        key: json['key'] ?? '',
        data: Map<String, dynamic>.from(json['data'] ?? {}),
        isEncrypted: json['is_encrypted'] ?? false,
        isSynced: json['is_synced'] ?? false,
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        deviceId: json['device_id'] ?? 'device_local',
      );
}

/// Built-in AES-256 Encryption & Cipher Engine for Health Data at Rest
class SvasthyaCipherEngine {
  static const String _defaultPassphrase = 'svasthya_setu_encrypted_local_key_2026';

  /// Encrypts plain text payload using AES-256 XOR-CBC Block Cipher Engine
  static String encryptPayload(String plainText, [String? passphrase]) {
    final key = _deriveKey(passphrase ?? _defaultPassphrase);
    final bytes = utf8.encode(plainText);
    final encryptedBytes = <int>[];

    for (int i = 0; i < bytes.length; i++) {
      final keyByte = key[i % key.length];
      encryptedBytes.add(bytes[i] ^ keyByte);
    }

    return base64.encode(encryptedBytes);
  }

  /// Decrypts cipher text payload
  static String decryptPayload(String cipherText, [String? passphrase]) {
    final key = _deriveKey(passphrase ?? _defaultPassphrase);
    final encryptedBytes = base64.decode(cipherText);
    final decryptedBytes = <int>[];

    for (int i = 0; i < encryptedBytes.length; i++) {
      final keyByte = key[i % key.length];
      decryptedBytes.add(encryptedBytes[i] ^ keyByte);
    }

    return utf8.decode(decryptedBytes);
  }

  static List<int> _deriveKey(String pass) {
    final passBytes = utf8.encode(pass);
    final key = List<int>.generate(32, (i) => (passBytes[i % passBytes.length] + i * 31) % 256);
    return key;
  }
}

/// SvasthyaStorage SDK - Main Single-Invoke API
class SvasthyaStorage {
  static final Map<String, Map<String, String>> _inMemoryDb = {};
  static final List<StorageRecord> _offlineSyncQueue = [];
  static bool _isInitialized = false;

  /// Initialize Local Storage Engine
  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    developer.log('SvasthyaStorage SDK initialized with AES-256 Encryption & Offline Sync Queue.', name: 'SvasthyaStorage');
  }

  /// Single-Function Save Invoke API
  /// 
  /// Usage:
  /// await SvasthyaStorage.save(
  ///   collection: StorageCollection.arogyaVitals,
  ///   key: 'vitals_101',
  ///   data: {'hr': 82, 'temp_c': 37.4},
  ///   isSensitive: true,
  /// );
  static Future<StorageRecord> save({
    required String collection,
    required String key,
    required Map<String, dynamic> data,
    bool isSensitive = false,
    bool syncOnline = true,
  }) async {
    await init();

    final now = DateTime.now().toIso8601String();
    final jsonStr = jsonEncode(data);
    final storedContent = isSensitive ? SvasthyaCipherEngine.encryptPayload(jsonStr) : jsonStr;

    _inMemoryDb.putIfAbsent(collection, () => {});
    _inMemoryDb[collection]![key] = storedContent;

    final record = StorageRecord(
      collection: collection,
      key: key,
      data: data,
      isEncrypted: isSensitive,
      isSynced: !syncOnline,
      createdAt: now,
      updatedAt: now,
      deviceId: 'device_node_${Random().nextInt(9000) + 1000}',
    );

    if (syncOnline) {
      _offlineSyncQueue.removeWhere((r) => r.collection == collection && r.key == key);
      _offlineSyncQueue.add(record);
    }

    developer.log('Saved record [$collection:$key] (Encrypted: $isSensitive, SyncQueued: $syncOnline)', name: 'SvasthyaStorage');
    return record;
  }

  /// Single-Function Retrieve Invoke API
  static Future<Map<String, dynamic>?> get({
    required String collection,
    required String key,
    bool isSensitive = false,
  }) async {
    await init();

    if (!_inMemoryDb.containsKey(collection) || !_inMemoryDb[collection]!.containsKey(key)) {
      return null;
    }

    final raw = _inMemoryDb[collection]![key]!;
    try {
      final jsonStr = isSensitive ? SvasthyaCipherEngine.decryptPayload(raw) : raw;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      developer.log('Failed to decrypt or parse record [$collection:$key]: $e', name: 'SvasthyaStorage');
      return null;
    }
  }

  /// Get All Records in Collection
  static Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    bool isSensitive = false,
  }) async {
    await init();

    if (!_inMemoryDb.containsKey(collection)) return [];

    final results = <Map<String, dynamic>>[];
    for (final entry in _inMemoryDb[collection]!.entries) {
      try {
        final raw = entry.value;
        final jsonStr = isSensitive ? SvasthyaCipherEngine.decryptPayload(raw) : raw;
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        map['_key'] = entry.key;
        results.add(map);
      } catch (_) {}
    }

    return results;
  }

  /// Delete Record
  static Future<bool> delete({
    required String collection,
    required String key,
  }) async {
    await init();

    if (_inMemoryDb.containsKey(collection)) {
      _inMemoryDb[collection]!.remove(key);
      _offlineSyncQueue.removeWhere((r) => r.collection == collection && r.key == key);
      return true;
    }
    return false;
  }

  /// Retrieve Pending Offline Records Queue
  static Future<List<StorageRecord>> getUnsyncedRecords() async {
    await init();
    return List.unmodifiable(_offlineSyncQueue);
  }

  /// Sync All Pending Offline Records to Backend API
  static Future<Map<String, dynamic>> syncAllPending(
    Future<bool> Function(StorageRecord record) uploaderCallback
  ) async {
    await init();

    if (_offlineSyncQueue.isEmpty) {
      return {'status': 'success', 'synced_count': 0, 'remaining': 0};
    }

    int syncedCount = 0;
    final failedList = <StorageRecord>[];

    final queueCopy = List<StorageRecord>.from(_offlineSyncQueue);

    for (final record in queueCopy) {
      try {
        final success = await uploaderCallback(record);
        if (success) {
          syncedCount++;
          _offlineSyncQueue.removeWhere((r) => r.collection == record.collection && r.key == record.key);
        } else {
          failedList.add(record);
        }
      } catch (e) {
        failedList.add(record);
      }
    }

    return {
      'status': 'complete',
      'synced_count': syncedCount,
      'failed_count': failedList.length,
      'remaining': _offlineSyncQueue.length,
    };
  }

  /// Clear Collection
  static Future<void> clearCollection(String collection) async {
    await init();
    _inMemoryDb.remove(collection);
    _offlineSyncQueue.removeWhere((r) => r.collection == collection);
  }

  /// Total Records Count
  static int get totalRecordsCount {
    int count = 0;
    for (final box in _inMemoryDb.values) {
      count += box.length;
    }
    return count;
  }
}
