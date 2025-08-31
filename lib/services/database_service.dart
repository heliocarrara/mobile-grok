import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/atividade.dart';
import '../models/categoria.dart';
import '../models/configuracao.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'mobile_grok.db';
  static const int _databaseVersion = 1;

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela atividades
    await db.execute('''
      CREATE TABLE atividades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descricao TEXT,
        categoria TEXT NOT NULL,
        dataHora TEXT NOT NULL,
        duracao INTEGER,
        concluida INTEGER NOT NULL DEFAULT 0,
        repeticao TEXT NOT NULL DEFAULT 'nenhuma',
        prioridade INTEGER NOT NULL DEFAULT 3,
        meta TEXT,
        jsonExtra TEXT
      )
    ''');

    // Tabela categorias
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cor TEXT NOT NULL,
        icone TEXT NOT NULL
      )
    ''');

    // Tabela configuracoes
    await db.execute('''
      CREATE TABLE configuracoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chave TEXT NOT NULL UNIQUE,
        valor TEXT NOT NULL
      )
    ''');

    // Inserir configurações padrão
    await _insertDefaultConfigurations(db);
  }

  Future<void> _insertDefaultConfigurations(Database db) async {
    final defaultConfigs = [
      {'chave': 'hora_inicio_dia', 'valor': '06:00'},
      {'chave': 'notificacoes_ativas', 'valor': 'true'},
      {'chave': 'tema_escuro', 'valor': 'false'},
    ];

    for (var config in defaultConfigs) {
      await db.insert('configuracoes', config);
    }
  }

  // CRUD Atividades
  Future<int> insertAtividade(Atividade atividade) async {
    final db = await database;
    return await db.insert('atividades', {
      'titulo': atividade.titulo,
      'descricao': atividade.descricao,
      'categoria': atividade.categoria.name,
      'dataHora': atividade.dataHora.toIso8601String(),
      'duracao': atividade.duracao,
      'concluida': atividade.concluida ? 1 : 0,
      'repeticao': atividade.repeticao.name,
      'prioridade': atividade.prioridade,
      'meta': atividade.meta,
      'jsonExtra': atividade.jsonExtra,
    });
  }

  Future<List<Atividade>> getAllAtividades() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('atividades');
    return List.generate(maps.length, (i) {
      return Atividade(
        id: maps[i]['id'],
        titulo: maps[i]['titulo'],
        descricao: maps[i]['descricao'],
        categoria: CategoriaEnum.values.firstWhere(
          (e) => e.name == maps[i]['categoria'],
        ),
        dataHora: DateTime.parse(maps[i]['dataHora']),
        duracao: maps[i]['duracao'],
        concluida: maps[i]['concluida'] == 1,
        repeticao: RepeticaoEnum.values.firstWhere(
          (e) => e.name == maps[i]['repeticao'],
        ),
        prioridade: maps[i]['prioridade'],
        meta: maps[i]['meta'],
        jsonExtra: maps[i]['jsonExtra'],
      );
    });
  }

  Future<Atividade?> getAtividadeById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'atividades',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return Atividade(
      id: maps[0]['id'],
      titulo: maps[0]['titulo'],
      descricao: maps[0]['descricao'],
      categoria: CategoriaEnum.values.firstWhere(
        (e) => e.name == maps[0]['categoria'],
      ),
      dataHora: DateTime.parse(maps[0]['dataHora']),
      duracao: maps[0]['duracao'],
      concluida: maps[0]['concluida'] == 1,
      repeticao: RepeticaoEnum.values.firstWhere(
        (e) => e.name == maps[0]['repeticao'],
      ),
      prioridade: maps[0]['prioridade'],
      meta: maps[0]['meta'],
      jsonExtra: maps[0]['jsonExtra'],
    );
  }

  Future<int> updateAtividade(Atividade atividade) async {
    final db = await database;
    return await db.update(
      'atividades',
      {
        'titulo': atividade.titulo,
        'descricao': atividade.descricao,
        'categoria': atividade.categoria.name,
        'dataHora': atividade.dataHora.toIso8601String(),
        'duracao': atividade.duracao,
        'concluida': atividade.concluida ? 1 : 0,
        'repeticao': atividade.repeticao.name,
        'prioridade': atividade.prioridade,
        'meta': atividade.meta,
        'jsonExtra': atividade.jsonExtra,
      },
      where: 'id = ?',
      whereArgs: [atividade.id],
    );
  }

  Future<int> deleteAtividade(int id) async {
    final db = await database;
    return await db.delete(
      'atividades',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleAtividadeConcluida(int id, bool concluida) async {
    final db = await database;
    return await db.update(
      'atividades',
      {'concluida': concluida ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Categorias
  Future<int> insertCategoria(Categoria categoria) async {
    final db = await database;
    return await db.insert('categorias', {
      'nome': categoria.nome,
      'cor': categoria.cor,
      'icone': categoria.icone,
    });
  }

  Future<List<Categoria>> getAllCategorias() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categorias');
    return List.generate(maps.length, (i) {
      return Categoria(
        id: maps[i]['id'],
        nome: maps[i]['nome'],
        cor: maps[i]['cor'],
        icone: maps[i]['icone'],
      );
    });
  }

  Future<int> updateCategoria(Categoria categoria) async {
    final db = await database;
    return await db.update(
      'categorias',
      {
        'nome': categoria.nome,
        'cor': categoria.cor,
        'icone': categoria.icone,
      },
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<int> deleteCategoria(int id) async {
    final db = await database;
    return await db.delete(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Configurações
  Future<String?> getConfiguracao(String chave) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'configuracoes',
      where: 'chave = ?',
      whereArgs: [chave],
    );

    if (maps.isEmpty) return null;
    return maps[0]['valor'];
  }

  Future<int> setConfiguracao(String chave, String valor) async {
    final db = await database;
    return await db.insert(
      'configuracoes',
      {'chave': chave, 'valor': valor},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Métodos auxiliares
  Future<List<Atividade>> getAtividadesByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'atividades',
      where: 'dataHora >= ? AND dataHora < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dataHora ASC',
    );

    return List.generate(maps.length, (i) {
      return Atividade(
        id: maps[i]['id'],
        titulo: maps[i]['titulo'],
        descricao: maps[i]['descricao'],
        categoria: CategoriaEnum.values.firstWhere(
          (e) => e.name == maps[i]['categoria'],
        ),
        dataHora: DateTime.parse(maps[i]['dataHora']),
        duracao: maps[i]['duracao'],
        concluida: maps[i]['concluida'] == 1,
        repeticao: RepeticaoEnum.values.firstWhere(
          (e) => e.name == maps[i]['repeticao'],
        ),
        prioridade: maps[i]['prioridade'],
        meta: maps[i]['meta'],
        jsonExtra: maps[i]['jsonExtra'],
      );
    });
  }

  Future<double> getProgressoDiario(DateTime date) async {
    final atividades = await getAtividadesByDate(date);
    if (atividades.isEmpty) return 0.0;

    final concluidas = atividades.where((a) => a.concluida).length;
    return concluidas / atividades.length;
  }



  // Atualizar data/hora da atividade
  Future<int> updateAtividadeDataHora(int id, DateTime novaDataHora) async {
    final db = await database;
    return await db.update(
      'atividades',
      {'dataHora': novaDataHora.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }



  // Inicializar categorias padrão
  Future<void> initializeDefaultCategories() async {
    final db = await database;
    
    // Verificar se já existem categorias
    final existingCategories = await db.query('categorias');
    if (existingCategories.isNotEmpty) return;

    // Inserir categorias padrão
    final defaultCategories = [
      {'nome': 'Faculdade', 'cor': '#4CAF50', 'icone': 'school'},
      {'nome': 'Casa', 'cor': '#FF9800', 'icone': 'home'},
      {'nome': 'Lazer', 'cor': '#2196F3', 'icone': 'sports_esports'},
      {'nome': 'Alimentação', 'cor': '#FF5722', 'icone': 'restaurant'},
      {'nome': 'Finanças', 'cor': '#4CAF50', 'icone': 'account_balance_wallet'},
      {'nome': 'Trabalho', 'cor': '#9C27B0', 'icone': 'work'},
      {'nome': 'Saúde', 'cor': '#F44336', 'icone': 'favorite'},
      {'nome': 'Outros', 'cor': '#607D8B', 'icone': 'more_horiz'},
    ];

    for (final category in defaultCategories) {
      await db.insert('categorias', category);
    }
  }
}
