import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/atividade.dart';
import '../models/categoria.dart';
import '../models/configuracao.dart';
import 'database_service.dart';

class BackupService {
  factory BackupService() => _instance;
  BackupService._internal();
  static final BackupService _instance = BackupService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Estrutura do backup
  Map<String, dynamic> _createBackupData({
    required List<Atividade> atividades,
    required List<Categoria> categorias,
    required List<Configuracao> configuracoes,
  }) => {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'atividades': atividades.map((a) => a.toJson()).toList(),
        'categorias': categorias.map((c) => c.toJson()).toList(),
        'configuracoes': configuracoes.map((c) => c.toJson()).toList(),
      },
    };

  // Exportar dados para JSON
  Future<String> exportData() async {
    try {
      // Obter todos os dados
      final atividades = await _databaseService.getAllAtividades();
      final categorias = await _databaseService.getAllCategorias();
      final configuracoes = await _getAllConfiguracoes();

      // Criar estrutura de backup
      final backupData = _createBackupData(
        atividades: atividades,
        categorias: categorias,
        configuracoes: configuracoes,
      );

      // Converter para JSON
      final jsonString = jsonEncode(backupData);
      
      // Salvar arquivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'mobile_grok_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      throw Exception('Erro ao exportar dados: $e');
    }
  }

  // Importar dados de JSON
  Future<void> importData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Arquivo de backup não encontrado');
      }

      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validar versão
      final version = backupData['version'] as String;
      if (version != '1.0') {
        throw Exception('Versão de backup não suportada: $version');
      }

      final data = backupData['data'] as Map<String, dynamic>;
      
      // Importar categorias primeiro
      final categoriasJson = data['categorias'] as List<dynamic>;
      for (final categoriaJson in categoriasJson) {
        final categoria = Categoria.fromJson(categoriaJson as Map<String, dynamic>);
        await _databaseService.insertCategoria(categoria);
      }

      // Importar atividades
      final atividadesJson = data['atividades'] as List<dynamic>;
      for (final atividadeJson in atividadesJson) {
        final atividade = Atividade.fromJson(atividadeJson as Map<String, dynamic>);
        await _databaseService.insertAtividade(atividade);
      }

      // Importar configurações
      final configuracoesJson = data['configuracoes'] as List<dynamic>;
      for (final configuracaoJson in configuracoesJson) {
        final configuracao = Configuracao.fromJson(configuracaoJson as Map<String, dynamic>);
        await _databaseService.setConfiguracao(configuracao.chave, configuracao.valor);
      }
    } catch (e) {
      throw Exception('Erro ao importar dados: $e');
    }
  }

  // Obter todas as configurações
  Future<List<Configuracao>> _getAllConfiguracoes() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('configuracoes');
    
    return List.generate(maps.length, (i) => Configuracao(
        id: maps[i]['id'],
        chave: maps[i]['chave'],
        valor: maps[i]['valor'],
      ));
  }

  // Limpar todos os dados
  Future<void> clearAllData() async {
    try {
      final db = await _databaseService.database;
      
      // Limpar todas as tabelas
      await db.delete('atividades');
      await db.delete('categorias');
      await db.delete('configuracoes');
      
      // Recriar categorias padrão
      await _databaseService.initializeDefaultCategories();
    } catch (e) {
      throw Exception('Erro ao limpar dados: $e');
    }
  }

  // Verificar permissões de armazenamento (Android)
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // Para iOS, não precisamos de permissão especial
  }

  // Obter lista de backups disponíveis
  Future<List<File>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      
      return files
          .whereType<File>()
          .where((file) => file.path.contains('mobile_grok_backup_'))
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    } catch (e) {
      return [];
    }
  }

  // Validar arquivo de backup
  Future<bool> validateBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Verificar estrutura básica
      if (!backupData.containsKey('version') || 
          !backupData.containsKey('data') ||
          !backupData.containsKey('timestamp')) {
        return false;
      }

      final data = backupData['data'] as Map<String, dynamic>;
      
      // Verificar se tem as seções necessárias
      if (!data.containsKey('atividades') ||
          !data.containsKey('categorias') ||
          !data.containsKey('configuracoes')) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
