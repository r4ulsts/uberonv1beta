import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'historico.db');
    return await openDatabase(
      path,
      version: 3, // Atualizando a versão para incluir novos campos
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE historico(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT,
        valorUber REAL,
        valor99 REAL,
        kmRodados REAL,
        horasTrabalhadas REAL,
        custo REAL,
        ganho REAL,
        ganhoKm REAL,
        ganhoHora REAL,
        ganhoMinuto REAL,
        ganhoLiquido REAL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Se estiver numa versão anterior à 2, adiciona a coluna "ganho"
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE historico ADD COLUMN ganho REAL');
    }
    // Se estiver numa versão anterior à 3, adiciona as novas colunas
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE historico ADD COLUMN valorUber REAL');
      await db.execute('ALTER TABLE historico ADD COLUMN valor99 REAL');
      await db.execute('ALTER TABLE historico ADD COLUMN kmRodados REAL');
      await db.execute('ALTER TABLE historico ADD COLUMN horasTrabalhadas REAL');
      await db.execute('ALTER TABLE historico ADD COLUMN custo REAL');
    }
  }

  Future<void> inserirHistorico(Map<String, dynamic> historico) async {
    final db = await database;
    await db.insert('historico', historico);
  }

  Future<void> limparHistorico() async {
    final db = await database;
    await db.delete('historico');
  }

  Future<void> deletarHistorico(int id) async {
    final db = await database;
    await db.delete('historico', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> listarHistorico() async {
    final db = await database;
    return await db.query('historico', orderBy: 'id DESC');
  }
}