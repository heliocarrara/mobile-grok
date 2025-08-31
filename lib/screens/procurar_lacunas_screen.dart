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
                : _buildLacunasList(),
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
}
