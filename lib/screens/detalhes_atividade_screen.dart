import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/atividade_provider.dart';
import '../models/atividade.dart';
import '../utils/theme.dart';
import 'adicionar_atividade_screen.dart';

class DetalhesAtividadeScreen extends StatefulWidget {

  const DetalhesAtividadeScreen({
    super.key,
    required this.atividade,
  });
  final Atividade atividade;

  @override
  State<DetalhesAtividadeScreen> createState() => _DetalhesAtividadeScreenState();
}

class _DetalhesAtividadeScreenState extends State<DetalhesAtividadeScreen> {
  late Atividade _atividade;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _atividade = widget.atividade;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Atividade'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editarAtividade,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmarExclusao,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  _buildActionsSection(),
                ],
              ),
            ),
    );

  Widget _buildHeader() => Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _atividade.titulo,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _atividade.concluida 
                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                          : null,
                    ),
                  ),
                ),
                if (_atividade.concluida)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 32,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getCategoriaColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getCategoriaColor()),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoriaIcon(),
                    color: _getCategoriaColor(),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _atividade.categoriaDisplayName,
                    style: TextStyle(
                      color: _getCategoriaColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildInfoSection() => Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Data/Hora', DateFormat('dd/MM/yyyy HH:mm').format(_atividade.dataHora)),
            if (_atividade.descricao != null && _atividade.descricao!.isNotEmpty)
              _buildInfoRow('Descrição', _atividade.descricao!),
            if (_atividade.duracao != null)
              _buildInfoRow('Duração', '${_atividade.duracao} minutos'),
            _buildInfoRow('Prioridade', '${_atividade.prioridade}/5'),
            _buildInfoRow('Repetição', _atividade.repeticaoDisplayName),
            if (_atividade.meta != null && _atividade.meta!.isNotEmpty)
              _buildInfoRow('Meta', _atividade.meta!),
            _buildInfoRow('Status', _atividade.concluida ? 'Concluída' : 'Pendente'),
          ],
        ),
      ),
    );

  Widget _buildInfoRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );

  Widget _buildActionsSection() => Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (!_atividade.concluida) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _marcarComoConcluida,
                  icon: const Icon(Icons.check),
                  label: const Text('Marcar como Concluída'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _adiarAtividade,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Adiar Atividade'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
                    side: const BorderSide(color: AppTheme.warningColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _marcarComoPendente,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Marcar como Pendente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.infoColor,
                    side: const BorderSide(color: AppTheme.infoColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _editarAtividade,
                icon: const Icon(Icons.edit),
                label: const Text('Editar Atividade'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmarExclusao,
                icon: const Icon(Icons.delete),
                label: const Text('Excluir Atividade'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  Color _getCategoriaColor() {
    switch (_atividade.categoria) {
      case CategoriaEnum.faculdade:
        return const Color(0xFF9B59B6);
      case CategoriaEnum.casa:
        return const Color(0xFFE67E22);
      case CategoriaEnum.lazer:
        return const Color(0xFF1ABC9C);
      case CategoriaEnum.alimentacao:
        return const Color(0xFFE74C3C);
      case CategoriaEnum.financas:
        return const Color(0xFFF1C40F);
      case CategoriaEnum.trabalho:
        return const Color(0xFF34495E);
      case CategoriaEnum.saude:
        return const Color(0xFF2ECC71);
      case CategoriaEnum.outros:
        return const Color(0xFF95A5A6);
    }
  }

  IconData _getCategoriaIcon() {
    switch (_atividade.categoria) {
      case CategoriaEnum.faculdade:
        return Icons.school;
      case CategoriaEnum.casa:
        return Icons.home;
      case CategoriaEnum.lazer:
        return Icons.sports_esports;
      case CategoriaEnum.alimentacao:
        return Icons.restaurant;
      case CategoriaEnum.financas:
        return Icons.attach_money;
      case CategoriaEnum.trabalho:
        return Icons.work;
      case CategoriaEnum.saude:
        return Icons.favorite;
      case CategoriaEnum.outros:
        return Icons.more_horiz;
    }
  }

  Future<void> _marcarComoConcluida() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<AtividadeProvider>();
      await provider.toggleAtividadeConcluida(_atividade.id!);
      
      setState(() {
        _atividade = _atividade.copyWith(concluida: true);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atividade marcada como concluída!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao marcar como concluída: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _marcarComoPendente() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<AtividadeProvider>();
      await provider.toggleAtividadeConcluida(_atividade.id!);
      
      setState(() {
        _atividade = _atividade.copyWith(concluida: false);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atividade marcada como pendente!'),
            backgroundColor: AppTheme.infoColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao marcar como pendente: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _adiarAtividade() async {
    final novaData = await showDatePicker(
      context: context,
      initialDate: _atividade.dataHora,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (novaData != null) {
      final novaHora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_atividade.dataHora),
      );

      if (novaHora != null) {
        setState(() => _isLoading = true);
        
        try {
          final novaDataHora = DateTime(
            novaData.year,
            novaData.month,
            novaData.day,
            novaHora.hour,
            novaHora.minute,
          );

          final provider = context.read<AtividadeProvider>();
          await provider.updateAtividadeDataHora(_atividade.id!, novaDataHora);
          
          setState(() {
            _atividade = _atividade.copyWith(dataHora: novaDataHora);
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Atividade adiada com sucesso!'),
                backgroundColor: AppTheme.warningColor,
              ),
            );
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao adiar atividade: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _editarAtividade() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdicionarAtividadeScreen(atividade: _atividade),
      ),
    );

    if (resultado == true && mounted) {
      // Recarregar dados da atividade
      final provider = context.read<AtividadeProvider>();
      final atividadeAtualizada = await provider.getAtividadeById(_atividade.id!);
      if (atividadeAtualizada != null) {
        setState(() {
          _atividade = atividadeAtualizada;
        });
      }
    }
  }

  Future<void> _confirmarExclusao() async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir a atividade "${_atividade.titulo}"? '
          'Esta ação não pode ser desfeita.',
        ),
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
      await _excluirAtividade();
    }
  }

  Future<void> _excluirAtividade() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<AtividadeProvider>();
      await provider.deleteAtividade(_atividade.id!);
      
      if (mounted) {
        Navigator.pop(context, true); // Retorna true para indicar que foi excluída
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atividade excluída com sucesso!'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir atividade: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
