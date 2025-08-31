import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/atividade.dart';
import '../providers/atividade_provider.dart';
import '../utils/theme.dart';

class AdicionarAtividadeScreen extends StatefulWidget {

  const AdicionarAtividadeScreen({super.key, this.atividade});
  final Atividade? atividade;

  @override
  State<AdicionarAtividadeScreen> createState() => _AdicionarAtividadeScreenState();
}

class _AdicionarAtividadeScreenState extends State<AdicionarAtividadeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _metaController = TextEditingController();
  
  CategoriaEnum _categoriaSelecionada = CategoriaEnum.outros;
  DateTime _dataHoraSelecionada = DateTime.now();
  int? _duracao;
  RepeticaoEnum _repeticaoSelecionada = RepeticaoEnum.nenhuma;
  int _prioridadeSelecionada = 3;
  bool _isLoading = false;
  Set<int> _diasSemanaSelecionados = <int>{}; // 1=Monday, 7=Sunday
  NotificationTiming _notificationTiming = NotificationTiming.fifteenMinBefore;

  @override
  void initState() {
    super.initState();
    if (widget.atividade != null) {
      _preencherFormulario();
    }
  }

  void _preencherFormulario() {
  // widget.atividade is checked before calling this method in initState,
  // assert non-null here and use a local non-nullable variable so the
  // analyzer can treat fields as non-nullable.
  final atividade = widget.atividade!;
  _tituloController.text = atividade.titulo;
  _descricaoController.text = atividade.descricao ?? '';
  _metaController.text = atividade.meta ?? '';
  _categoriaSelecionada = atividade.categoria;
  _dataHoraSelecionada = atividade.dataHora;
  _duracao = atividade.duracao;
  _repeticaoSelecionada = atividade.repeticao;
  _prioridadeSelecionada = atividade.prioridade;
  _notificationTiming = atividade.notificationTiming;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _metaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text(widget.atividade != null && widget.atividade!.id != null ? 'Editar Atividade' : 'Nova Atividade'),
        actions: [
          if (widget.atividade != null && widget.atividade!.id != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmarExclusao,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTituloField(),
            const SizedBox(height: 16),
            _buildDescricaoField(),
            const SizedBox(height: 16),
            _buildCategoriaField(),
            const SizedBox(height: 16),
            _buildDataHoraField(),
            const SizedBox(height: 16),
            _buildDuracaoField(),
            const SizedBox(height: 16),
            _buildPrioridadeField(),
            const SizedBox(height: 16),
            _buildRepeticaoField(),
            const SizedBox(height: 16),
            if (_repeticaoSelecionada == RepeticaoEnum.semanal)
              _buildDiasSemanaSeletor(),
            if (_repeticaoSelecionada == RepeticaoEnum.semanal)
              const SizedBox(height: 16),
            _buildNotificationField(),
            const SizedBox(height: 16),
            _buildMetaField(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );

  Widget _buildTituloField() => TextFormField(
      controller: _tituloController,
      decoration: const InputDecoration(
        labelText: 'Título *',
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, insira um título';
        }
        return null;
      },
    );

  Widget _buildDescricaoField() => TextFormField(
      controller: _descricaoController,
      decoration: const InputDecoration(
        labelText: 'Descrição (opcional)',
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
    );

  Widget _buildCategoriaField() => DropdownButtonFormField<CategoriaEnum>(
      initialValue: _categoriaSelecionada,
      decoration: const InputDecoration(
        labelText: 'Categoria *',
        prefixIcon: Icon(Icons.category),
      ),
      items: CategoriaEnum.values.map((categoria) => DropdownMenuItem<CategoriaEnum>(
          value: categoria,
          child: Row(
            children: [
              Icon(
                _getCategoriaIcon(categoria),
                color: AppTheme.categoriaColors[categoria.name],
              ),
              const SizedBox(width: 8),
              Text(categoria.categoriaDisplayName),
            ],
          ),
        )).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _categoriaSelecionada = value;
          });
        }
      },
    );

  Widget _buildDataHoraField() => InkWell(
      onTap: _selecionarDataHora,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Data e Hora *',
          prefixIcon: Icon(Icons.schedule),
        ),
        child: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(_dataHoraSelecionada),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );

  Widget _buildDuracaoField() => TextFormField(
      decoration: const InputDecoration(
        labelText: 'Duração (minutos, opcional)',
        prefixIcon: Icon(Icons.access_time),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        setState(() {
          _duracao = value.isEmpty ? null : int.tryParse(value);
        });
      },
      initialValue: _duracao?.toString() ?? '',
    );

  Widget _buildPrioridadeField() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridade: $_prioridadeSelecionada',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Slider(
          value: _prioridadeSelecionada.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: _getPrioridadeColor(_prioridadeSelecionada),
          onChanged: (value) {
            setState(() {
              _prioridadeSelecionada = value.round();
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Baixa', style: TextStyle(color: _getPrioridadeColor(1))),
            Text('Alta', style: TextStyle(color: _getPrioridadeColor(5))),
          ],
        ),
      ],
    );

  Widget _buildRepeticaoField() => DropdownButtonFormField<RepeticaoEnum>(
      initialValue: _repeticaoSelecionada,
      decoration: const InputDecoration(
        labelText: 'Repetição',
        prefixIcon: Icon(Icons.repeat),
      ),
      items: RepeticaoEnum.values.map((repeticao) => DropdownMenuItem<RepeticaoEnum>(
          value: repeticao,
          child: Text(repeticao.repeticaoDisplayName),
        )).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _repeticaoSelecionada = value;
          });
        }
      },
    );

  Widget _buildDiasSemanaSeletor() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione os dias da semana:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDiaChip('Seg', 1),
            _buildDiaChip('Ter', 2),
            _buildDiaChip('Qua', 3),
            _buildDiaChip('Qui', 4),
            _buildDiaChip('Sex', 5),
            _buildDiaChip('Sáb', 6),
            _buildDiaChip('Dom', 7),
          ],
        ),
      ],
    );

  Widget _buildDiaChip(String label, int weekday) => FilterChip(
      label: Text(label),
      selected: _diasSemanaSelecionados.contains(weekday),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _diasSemanaSelecionados.add(weekday);
          } else {
            _diasSemanaSelecionados.remove(weekday);
          }
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );

  Widget _buildNotificationField() => DropdownButtonFormField<NotificationTiming>(
      initialValue: _notificationTiming,
      decoration: const InputDecoration(
        labelText: 'Notificação',
        prefixIcon: Icon(Icons.notifications),
      ),
      items: NotificationTiming.values.map((timing) => DropdownMenuItem<NotificationTiming>(
          value: timing,
          child: Text(timing.displayName),
        )).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _notificationTiming = value;
          });
        }
      },
    );

  Widget _buildMetaField() => TextFormField(
      controller: _metaController,
      decoration: const InputDecoration(
        labelText: 'Meta (opcional)',
        prefixIcon: Icon(Icons.flag),
      ),
      maxLines: 2,
    );

  Widget _buildActionButtons() => Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _salvarAtividade,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.atividade != null && widget.atividade!.id != null ? 'Atualizar' : 'Salvar'),
          ),
        ),
      ],
    );

  Future<void> _selecionarDataHora() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataHoraSelecionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null) {
      final hora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dataHoraSelecionada),
      );

      if (hora != null) {
        setState(() {
          _dataHoraSelecionada = DateTime(
            data.year,
            data.month,
            data.day,
            hora.hour,
            hora.minute,
          );
        });
      }
    }
  }

  Future<void> _salvarAtividade() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate weekday selection for weekly repetition
    if (_repeticaoSelecionada == RepeticaoEnum.semanal && _diasSemanaSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um dia da semana para repetição semanal'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<AtividadeProvider>();
      
      if (widget.atividade != null && widget.atividade!.id != null) {
        // Editing existing activity
        final atividade = Atividade(
          id: widget.atividade?.id,
          titulo: _tituloController.text.trim(),
          descricao: _descricaoController.text.trim().isEmpty 
              ? null 
              : _descricaoController.text.trim(),
          categoria: _categoriaSelecionada,
          dataHora: _dataHoraSelecionada,
          duracao: _duracao,
          repeticao: _repeticaoSelecionada,
          prioridade: _prioridadeSelecionada,
          meta: _metaController.text.trim().isEmpty 
              ? null 
              : _metaController.text.trim(),
          notificationTiming: _notificationTiming,
        );
        
        final success = await provider.updateAtividade(atividade);
        _handleSaveResult(success, provider, isUpdate: true);
      } else {
        // Creating new activity(ies)
        if (_repeticaoSelecionada == RepeticaoEnum.semanal && _diasSemanaSelecionados.isNotEmpty) {
          // Create multiple activities for selected weekdays
          await _criarAtividadesSemanais(provider);
        } else {
          // Create single activity
          final atividade = Atividade(
            titulo: _tituloController.text.trim(),
            descricao: _descricaoController.text.trim().isEmpty 
                ? null 
                : _descricaoController.text.trim(),
            categoria: _categoriaSelecionada,
            dataHora: _dataHoraSelecionada,
            duracao: _duracao,
            repeticao: _repeticaoSelecionada,
            prioridade: _prioridadeSelecionada,
            meta: _metaController.text.trim().isEmpty 
                ? null 
                : _metaController.text.trim(),
            notificationTiming: _notificationTiming,
          );
          
          final success = await provider.addAtividade(atividade);
          _handleSaveResult(success, provider);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _criarAtividadesSemanais(AtividadeProvider provider) async {
    int successCount = 0;
    final baseDate = _dataHoraSelecionada;
    
    for (final weekday in _diasSemanaSelecionados) {
      // Calculate the date for this weekday
      final targetDate = _getNextWeekdayDate(baseDate, weekday);
      
      final atividade = Atividade(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty 
            ? null 
            : _descricaoController.text.trim(),
        categoria: _categoriaSelecionada,
        dataHora: targetDate,
        duracao: _duracao,
        repeticao: RepeticaoEnum.semanal,
        prioridade: _prioridadeSelecionada,
        meta: _metaController.text.trim().isEmpty 
            ? null 
            : _metaController.text.trim(),
        notificationTiming: _notificationTiming,
      );
      
      final success = await provider.addAtividade(atividade);
      if (success) successCount++;
    }
    
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount atividade${successCount != 1 ? 's' : ''} criada${successCount != 1 ? 's' : ''} com sucesso!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  DateTime _getNextWeekdayDate(DateTime baseDate, int targetWeekday) {
    // Convert to ISO weekday (Monday = 1, Sunday = 7)
    final currentWeekday = baseDate.weekday;
    int daysToAdd = targetWeekday - currentWeekday;
    
    // If the target day is in the past this week, move to next week
    if (daysToAdd < 0) {
      daysToAdd += 7;
    }
    
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day + daysToAdd,
      baseDate.hour,
      baseDate.minute,
    );
  }

  void _handleSaveResult(bool success, AtividadeProvider provider, {bool isUpdate = false}) {
    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUpdate 
                  ? 'Atividade atualizada com sucesso!'
                  : 'Atividade criada com sucesso!',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erro ao salvar atividade'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _confirmarExclusao() async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta atividade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmacao ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final provider = context.read<AtividadeProvider>();
        final success = await provider.deleteAtividade(widget.atividade!.id!);

        if (success) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Atividade excluída com sucesso!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.error ?? 'Erro ao excluir atividade'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  IconData _getCategoriaIcon(CategoriaEnum categoria) {
    switch (categoria) {
      case CategoriaEnum.faculdade:
        return Icons.school;
      case CategoriaEnum.casa:
        return Icons.home;
      case CategoriaEnum.lazer:
        return Icons.sports_esports;
      case CategoriaEnum.alimentacao:
        return Icons.restaurant;
      case CategoriaEnum.financas:
        return Icons.account_balance_wallet;
      case CategoriaEnum.trabalho:
        return Icons.work;
      case CategoriaEnum.saude:
        return Icons.favorite;
      case CategoriaEnum.outros:
        return Icons.more_horiz;
    }
  }

  Color _getPrioridadeColor(int prioridade) {
    switch (prioridade) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
