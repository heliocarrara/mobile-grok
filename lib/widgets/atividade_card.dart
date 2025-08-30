import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/atividade.dart';
import '../utils/theme.dart';

class AtividadeCard extends StatefulWidget {
  final Atividade atividade;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AtividadeCard({
    super.key,
    required this.atividade,
    this.onTap,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<AtividadeCard> createState() => _AtividadeCardState();
}

class _AtividadeCardState extends State<AtividadeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAtrasada = widget.atividade.dataHora.isBefore(DateTime.now()) && !widget.atividade.concluida;
    final categoriaColor = AppTheme.categoriaColors[widget.atividade.categoria.name] ?? AppTheme.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Slidable(
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  if (widget.onEdit != null)
                    SlidableAction(
                      onPressed: (_) => widget.onEdit!(),
                      backgroundColor: AppTheme.infoColor,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Editar',
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                    ),
                  if (widget.onDelete != null)
                    SlidableAction(
                      onPressed: (_) => widget.onDelete!(),
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Excluir',
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                    ),
                ],
              ),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: widget.atividade.concluida
                          ? null
                          : LinearGradient(
                              colors: [
                                categoriaColor.withOpacity(0.1),
                                categoriaColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      border: Border.all(
                        color: widget.atividade.concluida
                            ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                            : isAtrasada
                                ? AppTheme.warningColor.withOpacity(0.5)
                                : categoriaColor.withOpacity(0.3),
                        width: widget.atividade.concluida ? 1 : 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildCheckbox(categoriaColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitle(),
                              if (widget.atividade.descricao != null) _buildDescription(),
                              const SizedBox(height: 12),
                              _buildDetails(categoriaColor),
                            ],
                          ),
                        ),
                        _buildTimeInfo(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckbox(Color categoriaColor) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: widget.atividade.concluida
              ? AppTheme.successGradient
              : LinearGradient(
                  colors: [
                    categoriaColor.withOpacity(0.2),
                    categoriaColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: widget.atividade.concluida
                ? AppTheme.successColor
                : categoriaColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: widget.atividade.concluida
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
            : null,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.atividade.titulo,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: widget.atividade.concluida
            ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)
            : Theme.of(context).textTheme.bodyLarge?.color,
        decoration: widget.atividade.concluida ? TextDecoration.lineThrough : null,
        decorationThickness: 2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        widget.atividade.descricao!,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          decoration: widget.atividade.concluida ? TextDecoration.lineThrough : null,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDetails(Color categoriaColor) {
    return Row(
      children: [
        _buildCategoriaChip(categoriaColor),
        const SizedBox(width: 8),
        _buildPrioridadeChip(),
        if (widget.atividade.duracao != null) ...[
          const SizedBox(width: 8),
          _buildDuracaoChip(),
        ],
      ],
    );
  }

  Widget _buildCategoriaChip(Color categoriaColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: categoriaColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: categoriaColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoriaIcon(widget.atividade.categoria.name),
            size: 14,
            color: categoriaColor,
          ),
          const SizedBox(width: 4),
          Text(
            widget.atividade.categoria.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: categoriaColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioridadeChip() {
    final prioridade = widget.atividade.prioridade;
    Color color;
    String label;

    switch (prioridade) {
      case 1:
        color = AppTheme.successColor;
        label = 'Baixa';
        break;
      case 2:
        color = AppTheme.infoColor;
        label = 'Média';
        break;
      case 3:
        color = AppTheme.warningColor;
        label = 'Alta';
        break;
      case 4:
        color = AppTheme.errorColor;
        label = 'Urgente';
        break;
      case 5:
        color = AppTheme.errorColor;
        label = 'Crítica';
        break;
      default:
        color = AppTheme.textSecondaryColor;
        label = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDuracaoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.textSecondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 12,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 2),
          Text(
            '${widget.atividade.duracao}min',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo() {
    final now = DateTime.now();
    final isAtrasada = widget.atividade.dataHora.isBefore(now) && !widget.atividade.concluida;
    final isHoje = widget.atividade.dataHora.day == now.day &&
        widget.atividade.dataHora.month == now.month &&
        widget.atividade.dataHora.year == now.year;

    String timeText;
    Color timeColor;

    if (widget.atividade.concluida) {
      timeText = 'Concluída';
      timeColor = AppTheme.successColor;
    } else if (isAtrasada) {
      timeText = 'Atrasada';
      timeColor = AppTheme.errorColor;
    } else if (isHoje) {
      timeText = DateFormat('HH:mm').format(widget.atividade.dataHora);
      timeColor = AppTheme.warningColor;
    } else {
      timeText = DateFormat('dd/MM HH:mm').format(widget.atividade.dataHora);
      timeColor = AppTheme.textSecondaryColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: timeColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: timeColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            timeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: timeColor,
            ),
          ),
        ),
        if (!widget.atividade.concluida && !isAtrasada) ...[
          const SizedBox(height: 4),
          Text(
            _getTimeAgo(widget.atividade.dataHora),
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textLightColor,
            ),
          ),
        ],
      ],
    );
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'faculdade':
        return Icons.school;
      case 'casa':
        return Icons.home;
      case 'lazer':
        return Icons.sports_esports;
      case 'alimentacao':
        return Icons.restaurant;
      case 'financas':
        return Icons.account_balance_wallet;
      case 'trabalho':
        return Icons.work;
      case 'saude':
        return Icons.favorite;
      case 'outros':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return 'em ${difference.inDays} dia${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'em ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'em ${difference.inMinutes} min';
    } else {
      return 'agora';
    }
  }
}
