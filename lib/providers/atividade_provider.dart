import 'package:flutter/foundation.dart';
import '../models/atividade.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AtividadeProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  List<Atividade> _atividades = [];
  List<Atividade> _atividadesFiltradas = [];
  bool _isLoading = false;
  String? _error;
  CategoriaEnum? _filtroCategoria;
  int? _filtroPrioridade;

  // Getters
  List<Atividade> get atividades => _atividades;
  List<Atividade> get atividadesFiltradas => _atividadesFiltradas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CategoriaEnum? get filtroCategoria => _filtroCategoria;
  int? get filtroPrioridade => _filtroPrioridade;

  // Carregar todas as atividades
  Future<void> loadAtividades() async {
    _setLoading(true);
    try {
      _atividades = await _databaseService.getAllAtividades();
      _aplicarFiltros();
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar atividades: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Carregar atividades por data
  Future<void> loadAtividadesByDate(DateTime date) async {
    _setLoading(true);
    try {
      _atividades = await _databaseService.getAtividadesByDate(date);
      _aplicarFiltros();
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar atividades: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Adicionar atividade
  Future<bool> addAtividade(Atividade atividade) async {
    try {
      final id = await _databaseService.insertAtividade(atividade);
      final novaAtividade = atividade.copyWith(id: id);
      _atividades.add(novaAtividade);
      _aplicarFiltros();
      
      // Schedule notification for the new activity
      await _notificationService.scheduleAtividadeNotification(novaAtividade);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao adicionar atividade: $e';
      notifyListeners();
      return false;
    }
  }

  // Atualizar atividade
  Future<bool> updateAtividade(Atividade atividade) async {
    try {
      await _databaseService.updateAtividade(atividade);
      final index = _atividades.indexWhere((a) => a.id == atividade.id);
      if (index != -1) {
        _atividades[index] = atividade;
        _aplicarFiltros();
        
        // Reschedule notification for the updated activity
        await _notificationService.scheduleAtividadeNotification(atividade);
        
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar atividade: $e';
      notifyListeners();
      return false;
    }
  }

  // Deletar atividade
  Future<bool> deleteAtividade(int id) async {
    try {
      // Cancel notification before deleting
      await _notificationService.cancelAtividadeNotification(id);
      
      await _databaseService.deleteAtividade(id);
      _atividades.removeWhere((a) => a.id == id);
      _aplicarFiltros();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao deletar atividade: $e';
      notifyListeners();
      return false;
    }
  }

  // Toggle atividade concluída
  Future<bool> toggleAtividadeConcluida(int id) async {
    try {
      final atividade = _atividades.firstWhere((a) => a.id == id);
      final novaConcluida = !atividade.concluida;
      
      await _databaseService.toggleAtividadeConcluida(id, novaConcluida);
      
      final index = _atividades.indexWhere((a) => a.id == id);
      if (index != -1) {
        final atividadeAtualizada = atividade.copyWith(concluida: novaConcluida);
        _atividades[index] = atividadeAtualizada;
        _aplicarFiltros();
        
        // Handle notification based on completion status
        if (novaConcluida) {
          // Cancel notification when task is completed
          await _notificationService.cancelAtividadeNotification(id);
        } else {
          // Reschedule notification when task is uncompleted
          await _notificationService.scheduleAtividadeNotification(atividadeAtualizada);
        }
        
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Erro ao alterar status da atividade: $e';
      notifyListeners();
      return false;
    }
  }

  // Aplicar filtros
  void aplicarFiltros({CategoriaEnum? categoria, int? prioridade}) {
    _filtroCategoria = categoria;
    _filtroPrioridade = prioridade;
    _aplicarFiltros();
    notifyListeners();
  }

  // Setter para filtro de categoria
  void setFiltroCategoria(CategoriaEnum? categoria) {
    _filtroCategoria = categoria;
    _aplicarFiltros();
    notifyListeners();
  }

  // Setter para filtro de prioridade
  void setFiltroPrioridade(int? prioridade) {
    _filtroPrioridade = prioridade;
    _aplicarFiltros();
    notifyListeners();
  }

  // Toggle atividade (wrapper para toggleAtividadeConcluida)
  Future<void> toggleAtividade(Atividade atividade) async {
    if (atividade.id != null) {
      await toggleAtividadeConcluida(atividade.id!);
    }
  }

  void _aplicarFiltros() {
    _atividadesFiltradas = _atividades.where((atividade) {
      var passaFiltro = true;

      if (_filtroCategoria != null) {
        passaFiltro = passaFiltro && atividade.categoria == _filtroCategoria;
      }

      if (_filtroPrioridade != null) {
        passaFiltro = passaFiltro && atividade.prioridade == _filtroPrioridade;
      }

      return passaFiltro;
    }).toList();

    // Ordenar por data/hora
    _atividadesFiltradas.sort((a, b) => a.dataHora.compareTo(b.dataHora));
  }

  // Limpar filtros
  void limparFiltros() {
    _filtroCategoria = null;
    _filtroPrioridade = null;
    _atividadesFiltradas = List.from(_atividades);
    _atividadesFiltradas.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    notifyListeners();
  }

  // Obter progresso diário
  Future<double> getProgressoDiario(DateTime date) async {
    try {
      return await _databaseService.getProgressoDiario(date);
    } catch (e) {
      _error = 'Erro ao calcular progresso: $e';
      notifyListeners();
      return 0.0;
    }
  }

  // Obter atividades próximas (próximas 24 horas)
  List<Atividade> getAtividadesProximas() {
    final agora = DateTime.now();
    final amanha = agora.add(const Duration(days: 1));
    
    return _atividades.where((atividade) => !atividade.concluida && 
             atividade.dataHora.isAfter(agora) && 
             atividade.dataHora.isBefore(amanha)).toList()
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
  }

  // Obter atividades atrasadas
  List<Atividade> getAtividadesAtrasadas() {
    final agora = DateTime.now();
    
    return _atividades.where((atividade) => !atividade.concluida && atividade.dataHora.isBefore(agora)).toList()
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Obter atividade por ID
  Future<Atividade?> getAtividadeById(int id) async {
    try {
      return await _databaseService.getAtividadeById(id);
    } catch (e) {
      _error = 'Erro ao buscar atividade: $e';
      notifyListeners();
      return null;
    }
  }

  // Atualizar data/hora da atividade
  Future<bool> updateAtividadeDataHora(int id, DateTime novaDataHora) async {
    try {
      await _databaseService.updateAtividadeDataHora(id, novaDataHora);
      
      // Atualizar na lista local
      final index = _atividades.indexWhere((a) => a.id == id);
      if (index != -1) {
        _atividades[index] = _atividades[index].copyWith(dataHora: novaDataHora);
        _aplicarFiltros();
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar data/hora: $e';
      notifyListeners();
      return false;
    }
  }

  // Obter atividades por data específica
  Future<List<Atividade>> getAtividadesByDate(DateTime date) async {
    try {
      return await _databaseService.getAtividadesByDate(date);
    } catch (e) {
      _error = 'Erro ao buscar atividades por data: $e';
      notifyListeners();
      return [];
    }
  }
}
