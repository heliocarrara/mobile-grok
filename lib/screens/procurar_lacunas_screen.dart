import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/atividade_provider.dart';
import '../models/atividade.dart';
import '../utils/theme.dart';
import 'adicionar_atividade_screen.dart';

class ProcurarLacunasScreen extends StatefulWidget {
  const ProcurarLacunasScreen({super.key});

  @override
  State<ProcurarLacunasScreen> createState() => _ProcurarLacunasScreenState();
}

class _ProcurarLacunasScreenState extends State<ProcurarLacunasScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _lacunas = [];
  bool _isLoading = false;
  Map<String, dynamic> _estatisticas = {};

  @override
  void initState() {
    super.initState();
    _buscarLacunas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procurar Lacunas'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(child: _buildLacunasList()),
                      if (_estatisticas.isNotEmpty) _buildEstatisticas(),
                      _buildNavigationButtons(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 30)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) {
            setState(() {
              _selectedDate = date;
            });
            _buscarLacunas();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLacunasList() {
    if (_lacunas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma lacuna encontrada',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seu dia está bem preenchido!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lacunas.length,
      itemBuilder: (context, index) {
        final lacuna = _lacunas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.access_time,
                color: AppTheme.infoColor,
                size: 20,
              ),
            ),
            title: Text(
              'Tempo livre: ${lacuna['duracao']} minutos',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${DateFormat('HH:mm').format(lacuna['inicio'])} - ${DateFormat('HH:mm').format(lacuna['fim'])}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _criarAtividadeNaLacuna(lacuna),
              tooltip: 'Criar atividade',
            ),
          ),
        );
      },
    );
  }

  Future<void> _buscarLacunas() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<AtividadeProvider>();
      await provider.loadAtividadesByDate(_selectedDate);
      
      final atividades = provider.atividades
          .where((a) => 
              a.dataHora.day == _selectedDate.day &&
              a.dataHora.month == _selectedDate.month &&
              a.dataHora.year == _selectedDate.year)
          .toList();
      
      // Ordenar por data/hora
      atividades.sort((a, b) => a.dataHora.compareTo(b.dataHora));
      
      final lacunas = <Map<String, dynamic>>[];
      
      // Definir horário de trabalho (6h às 22h)
      final inicioDia = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 6, 0);
      final fimDia = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 22, 0);
      
      DateTime ultimoFim = inicioDia;
      
      for (final atividade in atividades) {
        final inicioAtividade = atividade.dataHora;
        
        // Se há uma lacuna entre a última atividade e esta
        if (inicioAtividade.isAfter(ultimoFim)) {
          final duracaoMinutos = inicioAtividade.difference(ultimoFim).inMinutes;
          
          // Só considera lacunas de pelo menos 30 minutos
          if (duracaoMinutos >= 30) {
            lacunas.add({
              'inicio': ultimoFim,
              'fim': inicioAtividade,
              'duracao': duracaoMinutos,
            });
          }
        }
        
        // Atualizar último fim (considerando duração da atividade)
        final duracaoAtividade = atividade.duracao ?? 60; // Default 1 hora
        ultimoFim = inicioAtividade.add(Duration(minutes: duracaoAtividade));
      }
      
      // Verificar lacuna no final do dia
      if (ultimoFim.isBefore(fimDia)) {
        final duracaoMinutos = fimDia.difference(ultimoFim).inMinutes;
        if (duracaoMinutos >= 30) {
          lacunas.add({
            'inicio': ultimoFim,
            'fim': fimDia,
            'duracao': duracaoMinutos,
          });
        }
      }
      
      // Calcular estatísticas do dia
      _calcularEstatisticas(atividades, lacunas);
      
      setState(() {
        _lacunas = lacunas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar lacunas: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _criarAtividadeNaLacuna(Map<String, dynamic> lacuna) {
    final novaAtividade = Atividade(
      titulo: '',
      categoria: CategoriaEnum.outros,
      dataHora: lacuna['inicio'],
      duracao: (lacuna['duracao'] as int).clamp(30, 120), // Entre 30min e 2h
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdicionarAtividadeScreen(atividade: novaAtividade),
      ),
    ).then((result) {
      if (result == true) {
        _buscarLacunas(); // Recarregar lacunas
      }
    });
  }

  void _calcularEstatisticas(List<Atividade> atividades, List<Map<String, dynamic>> lacunas) {
    const int totalMinutosDia = 16 * 60; // 6h às 22h = 16 horas
    
    // Calcular minutos preenchidos
    int minutosPreenchidos = 0;
    for (final atividade in atividades) {
      minutosPreenchidos += atividade.duracao ?? 60;
    }
    
    // Calcular minutos ociosos
    int minutosOciosos = 0;
    for (final lacuna in lacunas) {
      minutosOciosos += lacuna['duracao'] as int;
    }
    
    // Calcular porcentagem por categoria
    Map<CategoriaEnum, int> minutosPorCategoria = {};
    for (final atividade in atividades) {
      final categoria = atividade.categoria;
      final duracao = atividade.duracao ?? 60;
      minutosPorCategoria[categoria] = (minutosPorCategoria[categoria] ?? 0) + duracao;
    }
    
    Map<CategoriaEnum, double> porcentagemPorCategoria = {};
    for (final entry in minutosPorCategoria.entries) {
      porcentagemPorCategoria[entry.key] = (entry.value / totalMinutosDia) * 100;
    }
    
    _estatisticas = {
      'totalMinutos': totalMinutosDia,
      'minutosPreenchidos': minutosPreenchidos,
      'minutosOciosos': minutosOciosos,
      'porcentagemPreenchida': (minutosPreenchidos / totalMinutosDia) * 100,
      'porcentagemOciosa': (minutosOciosos / totalMinutosDia) * 100,
      'porcentagemPorCategoria': porcentagemPorCategoria,
    };
  }

  Widget _buildEstatisticas() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estatísticas do Dia',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress bar para minutos preenchidos
          _buildProgressBar(
            'Tempo Preenchido',
            _estatisticas['porcentagemPreenchida'],
            AppTheme.successColor,
            '${_estatisticas['minutosPreenchidos']} min',
          ),
          const SizedBox(height: 12),
          
          // Progress bar para minutos ociosos
          _buildProgressBar(
            'Tempo Ocioso',
            _estatisticas['porcentagemOciosa'],
            AppTheme.infoColor,
            '${_estatisticas['minutosOciosos']} min',
          ),
          const SizedBox(height: 16),
          
          // Progress bars por categoria
          Text(
            'Por Categoria',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          ...(_estatisticas['porcentagemPorCategoria'] as Map<CategoriaEnum, double>)
              .entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildProgressBar(
                      entry.key.displayName,
                      entry.value,
                      AppTheme.categoriaColors[entry.key.name] ?? AppTheme.primaryColor,
                      '${entry.value.toStringAsFixed(1)}%',
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage, Color color, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                });
                await _buscarLacunas();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Dia Anterior'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
                await _buscarLacunas();
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Próximo Dia'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
