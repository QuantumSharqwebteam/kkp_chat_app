import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:kkpchatapp/data/models/extracted_product_data.dart';

class ProductDatabase {
  static final ProductDatabase _instance = ProductDatabase._internal();
  static Database? _database;

  factory ProductDatabase() {
    return _instance;
  }

  ProductDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'product_database.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    await _ensureSchema(db);
  }

  Future<void> _ensureSchema(Database db) async {
    final tableInfo = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='extracted_products'",
    );
    if (tableInfo.isEmpty) return;

    final result = await db.rawQuery("PRAGMA table_info(extracted_products)");
    final columnNames = result.map((e) => e['name']?.toString()).whereType<String>().toList();
    if (!columnNames.contains('customer_name')) {
      await db.execute('ALTER TABLE extracted_products ADD COLUMN customer_name TEXT');
    }
    if (!columnNames.contains('sent')) {
      await db.execute('ALTER TABLE extracted_products ADD COLUMN sent INTEGER DEFAULT 0');
    }
    if (!columnNames.contains('sent_at')) {
      await db.execute('ALTER TABLE extracted_products ADD COLUMN sent_at TEXT');
    }
    if (!columnNames.contains('order_id')) {
      await db.execute('ALTER TABLE extracted_products ADD COLUMN order_id TEXT');
    }
    if (!columnNames.contains('status')) {
      await db.execute('ALTER TABLE extracted_products ADD COLUMN status TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE extracted_products(
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        agent_email TEXT NOT NULL,
        customer_email TEXT NOT NULL,
        customer_name TEXT,
        quality TEXT,
        weave TEXT,
        quantity TEXT,
        composition TEXT,
        rate REAL,
        extracted_at TEXT NOT NULL,
        confidence REAL NOT NULL,
        sent INTEGER DEFAULT 0,
        sent_at TEXT,
        order_id TEXT,
        status TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE extracted_products ADD COLUMN customer_name TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE extracted_products ADD COLUMN sent INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE extracted_products ADD COLUMN sent_at TEXT');
      await db.execute('ALTER TABLE extracted_products ADD COLUMN order_id TEXT');
      await db.execute('ALTER TABLE extracted_products ADD COLUMN status TEXT');
    }
  }

  Future<int> insertExtractedProduct(ExtractedProductData data) async {
    Database db = await database;
    await _ensureSchema(db);
    return await db.insert(
      'extracted_products',
      {
        'id': data.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'chat_id': data.chatId,
        'agent_email': data.agentEmail,
        'customer_email': data.customerEmail,
        'customer_name': data.customerName,
        'quality': data.quality,
        'weave': data.weave,
        'quantity': data.quantity,
        'composition': data.composition,
        'rate': data.rate,
        'extracted_at': data.extractedAt.toIso8601String(),
        'confidence': data.confidence,
        'sent': data.sent ? 1 : 0,
        'sent_at': data.sentAt?.toIso8601String(),
        'order_id': data.orderId,
        'status': data.status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExtractedProductData>> getExtractedProductsByAgent(String agentEmail) async {
    Database db = await database;
    await _ensureSchema(db);
    final List<Map<String, dynamic>> maps = await db.query(
      'extracted_products',
      where: 'agent_email = ?',
      whereArgs: [agentEmail],
      orderBy: 'extracted_at DESC',
    );

    return List.generate(maps.length, (i) {
      return ExtractedProductData(
        id: maps[i]['id'],
        chatId: maps[i]['chat_id'],
        agentEmail: maps[i]['agent_email'],
        customerEmail: maps[i]['customer_email'],
        customerName: maps[i]['customer_name'],
        quality: maps[i]['quality'],
        weave: maps[i]['weave'],
        quantity: maps[i]['quantity'],
        composition: maps[i]['composition'],
        rate: maps[i]['rate'],
        extractedAt: DateTime.parse(maps[i]['extracted_at']),
        confidence: (maps[i]['confidence'] as num).toDouble(),
        extractionTimeMs: maps[i]['extraction_time_ms'],
        sent: (maps[i]['sent'] as int? ?? 0) == 1,
        sentAt: maps[i]['sent_at'] != null ? DateTime.tryParse(maps[i]['sent_at']) : null,
        orderId: maps[i]['order_id'],
        status: maps[i]['status'],
      );
    });
  }

  Future<List<ExtractedProductData>> getExtractedProductsByChat(String chatId) async {
    Database db = await database;
    await _ensureSchema(db);
    final List<Map<String, dynamic>> maps = await db.query(
      'extracted_products',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'extracted_at DESC',
    );

    return List.generate(maps.length, (i) {
      return ExtractedProductData(
        id: maps[i]['id'],
        chatId: maps[i]['chat_id'],
        agentEmail: maps[i]['agent_email'],
        customerEmail: maps[i]['customer_email'],
        customerName: maps[i]['customer_name'],
        quality: maps[i]['quality'],
        weave: maps[i]['weave'],
        quantity: maps[i]['quantity'],
        composition: maps[i]['composition'],
        rate: maps[i]['rate'],
        extractedAt: DateTime.parse(maps[i]['extracted_at']),
        confidence: (maps[i]['confidence'] as num).toDouble(),
        extractionTimeMs: maps[i]['extraction_time_ms'],
        sent: (maps[i]['sent'] as int? ?? 0) == 1,
        sentAt: maps[i]['sent_at'] != null ? DateTime.tryParse(maps[i]['sent_at']) : null,
        orderId: maps[i]['order_id'],
        status: maps[i]['status'],
      );
    });
  }

  Future<List<ExtractedProductData>> getExtractedProductsByDateRange(
    String agentEmail,
    DateTime startDate,
    DateTime endDate,
  ) async {
    Database db = await database;
    await _ensureSchema(db);
    final List<Map<String, dynamic>> maps = await db.query(
      'extracted_products',
      where: 'agent_email = ? AND extracted_at BETWEEN ? AND ?',
      whereArgs: [agentEmail, startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'extracted_at DESC',
    );

    return List.generate(maps.length, (i) {
      return ExtractedProductData(
        id: maps[i]['id'],
        chatId: maps[i]['chat_id'],
        agentEmail: maps[i]['agent_email'],
        customerEmail: maps[i]['customer_email'],
        customerName: maps[i]['customer_name'],
        quality: maps[i]['quality'],
        weave: maps[i]['weave'],
        quantity: maps[i]['quantity'],
        composition: maps[i]['composition'],
        rate: maps[i]['rate'],
        extractedAt: DateTime.parse(maps[i]['extracted_at']),
        confidence: (maps[i]['confidence'] as num).toDouble(),
        extractionTimeMs: maps[i]['extraction_time_ms'],
        sent: (maps[i]['sent'] as int? ?? 0) == 1,
        sentAt: maps[i]['sent_at'] != null ? DateTime.tryParse(maps[i]['sent_at']) : null,
        orderId: maps[i]['order_id'],
        status: maps[i]['status'],
      );
    });
  }

  Future<int> updateExtractedProduct(String id, Map<String, dynamic> updates) async {
    Database db = await database;
    return await db.update(
      'extracted_products',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExtractedProduct(String id) async {
    Database db = await database;
    return await db.delete(
      'extracted_products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    Database db = await database;
    db.close();
  }
}
