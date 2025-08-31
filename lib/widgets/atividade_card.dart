import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/atividade.dart';
import '../utils/theme.dart';

class AtividadeCard extends StatefulWidget {
  const AtividadeCard({
    super.key,
    required this.atividade,
    this.onTap,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  final Atividade atividade;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
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
      builder: (context, child) => Transform.scale(
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
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: widget.atividade.concluida
                            ? null
                            : LinearGradient(
                                colors: [
                                  categoriaColor.withOpacity(0.08),
                                  categoriaColor.withOpacity(0.03),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        border: Border.all(
                          color: widget.atividade.concluida
                              ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                              : isAtrasada
                                  ? AppTheme.warningColor.withOpacity(0.5)
                                  : categoriaColor.withOpacity(0.28),
                          width: widget.atividade.concluida ? 1 : 2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCheckbox(categoriaColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildTitle()),
                                    const SizedBox(width: 8),
                                    _buildTimeInfo(),
                                  ],
                                ),
                                if (widget.atividade.descricao != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: _buildDescription(),
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: categoriaColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(_getCategoriaIcon(widget.atividade.categoria.name), size: 14, color: categoriaColor),
                                          const SizedBox(width: 6),
                                          Text(widget.atividade.categoria.name.toUpperCase(), style: TextStyle(fontSize: 11, color: categoriaColor, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.textSecondaryColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(_prioridadeIcon(widget.atividade.prioridade), size: 14, color: _prioridadeColor(widget.atividade.prioridade)),
                                          const SizedBox(width: 6),
                                          Text(_prioridadeLabel(widget.atividade.prioridade), style: TextStyle(fontSize: 11, color: _prioridadeColor(widget.atividade.prioridade), fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                    if (widget.atividade.duracao != null) ...[
                                      const SizedBox(width: 8),
                                      _buildDuracaoChip(),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAtrasada && !widget.atividade.concluida)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4)],
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.timer_off, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('ATRASADA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(Color categoriaColor) => GestureDetector(
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

  Widget _buildTitle() => Text(
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

  Widget _buildDescription() => Padding(
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

  Widget _buildDuracaoChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
              size: 10,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 2),
            Text(
              '${widget.atividade.duracao}m',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );

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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: timeColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: timeColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            timeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: timeColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!widget.atividade.concluida && !isAtrasada) ...[
          const SizedBox(height: 4),
          Text(
            _getTimeAgo(widget.atividade.dataHora),
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textLightColor,
            ),
            overflow: TextOverflow.ellipsis,
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

  IconData _prioridadeIcon(int prioridade) {
    switch (prioridade) {
      case 1:
        return Icons.keyboard_arrow_down;
      case 2:
        return Icons.low_priority;
      case 3:
        return Icons.flag;
      case 4:
        return Icons.priority_high;
      case 5:
        return Icons.warning;
      default:
        return Icons.flag;
    }
  }

  Color _prioridadeColor(int prioridade) {
    switch (prioridade) {
      case 1:
        return AppTheme.successColor;
      case 2:
        return AppTheme.infoColor;
      case 3:
        return AppTheme.warningColor;
      case 4:
      case 5:
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  String _prioridadeLabel(int prioridade) {
    switch (prioridade) {
      case 1:
        return 'Baixa';
      case 2:
        return 'Média';
      case 3:
        return 'Alta';
      case 4:
        return 'Urgente';
      case 5:
        return 'Crítica';
      default:
        return 'Normal';
    }
  }
}
