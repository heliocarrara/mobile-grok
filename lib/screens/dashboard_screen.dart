import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../providers/atividade_provider.dart';
import '../models/atividade.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/atividade_card.dart';
import '../widgets/progress_indicator.dart';
import '../widgets/loading_widget.dart';
import 'adicionar_atividade_screen.dart';
import 'chatbot_screen.dart';
import 'categorias_screen.dart';
import 'configuracoes_screen.dart';
import 'detalhes_atividade_screen.dart';
import 'procurar_lacunas_screen.dart';
import 'nfc_share_screen.dart';
import 'nfc_receive_screen.dart';
import 'qr_share_screen.dart';
import 'qr_receive_screen.dart';
import '../services/database_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  double _progressoDiario = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _nomeUsuario = '';
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // iniciar tarefas assíncronas após o primeiro frame
      // ignora warning de futures não aguardadas aqui, pois rodamos pós-frame
      // ignore: unawaited_futures
      _loadData();
      // ignore: unawaited_futures
      _loadNomeUsuario();
      // ignore: unawaited_futures
      _fadeController.forward();
      // ignore: unawaited_futures
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<AtividadeProvider>();
    await provider.loadAtividadesByDate(_selectedDate);
  await _updateProgresso();
  }

  Future<void> _updateProgresso() async {
    final provider = context.read<AtividadeProvider>();
    final progresso = await provider.getProgressoDiario(_selectedDate);
    setState(() {
      _progressoDiario = progresso;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      drawer: _buildDrawer(),
      body: Consumer<AtividadeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingWidget(
              message: AppConstants.loadingMessage,
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar atividades',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text(AppConstants.retryButton),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildDateSection(),
                        _buildProgressSection(),
                        _buildFilters(provider),
                        _buildAtividadesList(provider),
                        _buildDateNavigationButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

  Widget _buildSliverAppBar() => SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      centerTitle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _nomeUsuario.isEmpty ? 'Mobile Grok' : 'Bem-vindo, $_nomeUsuario',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Organize sua vida com IA',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons in header
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdicionarAtividadeScreen()),
                      );
                      if (result == true) {
                        await _loadData();
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Criar tarefa rápida',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

  Widget _buildDateSection() => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
              });
              await _loadData();
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

  Widget _buildProgressSection() => Consumer<AtividadeProvider>(
      builder: (context, provider, child) {
        final proximas = provider.getAtividadesProximas();
        final atrasadas = provider.getAtividadesAtrasadas();
        final concluidasHoje = provider.atividades.where((a) {
          final now = DateTime.now();
          return a.concluida && a.dataHora.day == now.day && a.dataHora.month == now.month && a.dataHora.year == now.year;
        }).length;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress section header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Progresso Diário',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Main metrics in organized layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 400;
                  
                  if (isWide) {
                    // Wide layout: 2x2 grid
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Próxima Tarefa',
                                value: proximas.isNotEmpty 
                                    ? DateFormat('HH:mm - d/MM').format(proximas.first.dataHora) 
                                    : 'Nenhuma',
                                icon: Icons.schedule,
                                color: AppTheme.infoColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Atrasadas',
                                value: atrasadas.length.toString(),
                                icon: Icons.warning_amber,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Concluído Hoje',
                                value: '$concluidasHoje tarefa${concluidasHoje != 1 ? 's' : ''}',
                                icon: Icons.check_circle,
                                color: AppTheme.successColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildProgressCard(),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Narrow layout: vertical list
                    return Column(
                      children: [
                        _buildStatCard(
                          title: 'Próxima Tarefa',
                          value: proximas.isNotEmpty 
                              ? DateFormat('HH:mm - d/MM').format(proximas.first.dataHora) 
                              : 'Nenhuma',
                          icon: Icons.schedule,
                          color: AppTheme.infoColor,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Atrasadas',
                                value: atrasadas.length.toString(),
                                icon: Icons.warning_amber,
                                color: AppTheme.errorColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Concluído',
                                value: concluidasHoje.toString(),
                                icon: Icons.check_circle,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildProgressCard(),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );

  Widget _buildStatCard({required String title, required String value, required IconData icon, Color? color}) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (color ?? AppTheme.primaryColor).withOpacity(0.15),
                ),
                child: Icon(icon, color: color ?? AppTheme.primaryColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

  Widget _buildProgressCard() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.15),
                ),
                child: Icon(Icons.pie_chart, color: AppTheme.primaryColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Progresso',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            width: 60,
            child: RadialProgressIndicator(
              progress: _progressoDiario,
              size: 60,
              centerLabel: '${(_progressoDiario * 100).toInt()}%',
            ),
          ),
        ],
      ),
    );

  Widget _buildFilters(AtividadeProvider provider) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Category quick menu
              PopupMenuButton<CategoriaEnum?>(
                tooltip: 'Categoria',
                onSelected: (value) => provider.setFiltroCategoria(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: null, child: Text('Todas')),
                  ...CategoriaEnum.values.map((c) => PopupMenuItem(value: c, child: Row(children: [Icon(_categoriaIcon(c)), const SizedBox(width:8), Text(c.displayName)]))),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        provider.filtroCategoria?.displayName ?? 'Categoria',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Priority quick menu
              PopupMenuButton<int?>(
                tooltip: 'Prioridade',
                onSelected: (value) => provider.setFiltroPrioridade(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: null, child: Text('Todas')),
                  ...List.generate(5, (i) => PopupMenuItem(value: i+1, child: Row(children: [Icon(_prioridadeIcon(i+1)), const SizedBox(width:8), Text('Nível ${i+1}')]))),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        provider.filtroPrioridade != null ? 'Nível ${provider.filtroPrioridade}' : 'Prioridade',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Clear filters
              TextButton.icon(
                onPressed: provider.limparFiltros,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Limpar'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      );

  IconData _prioridadeIcon(int nivel) {
    switch (nivel) {
      case 1: return Icons.low_priority;
      case 2: return Icons.flag_outlined;
      case 3: return Icons.outbound;
      case 4: return Icons.priority_high;
      case 5: return Icons.warning_amber;
      default: return Icons.flag;
    }
  }

  IconData _categoriaIcon(CategoriaEnum c) {
    switch (c) {
      case CategoriaEnum.faculdade: return Icons.school;
      case CategoriaEnum.casa: return Icons.home;
      case CategoriaEnum.lazer: return Icons.sports_esports;
      case CategoriaEnum.alimentacao: return Icons.restaurant;
      case CategoriaEnum.financas: return Icons.account_balance_wallet;
      case CategoriaEnum.trabalho: return Icons.work;
      case CategoriaEnum.saude: return Icons.health_and_safety;
      case CategoriaEnum.outros: return Icons.more_horiz;
    }
  }

  Widget _buildAtividadesList(AtividadeProvider provider) {
    final atividades = provider.atividadesFiltradas;
    
    if (atividades.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.emptyStateTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.emptyStateMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final atrasadas = atividades.where((a) => 
      a.dataHora.isBefore(DateTime.now()) && !a.concluida
    ).toList();
    
    final proximas = atividades.where((a) => 
      !a.dataHora.isBefore(DateTime.now()) && !a.concluida
    ).toList();
    
    final concluidas = atividades.where((a) => a.concluida).toList();

    // Sort proximas by date/time for gap calculation
    proximas.sort((a, b) => a.dataHora.compareTo(b.dataHora));

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (atrasadas.isNotEmpty) ...[
            _buildSectionHeader('Atrasadas', Icons.warning_amber, AppTheme.errorColor),
            const SizedBox(height: 12),
            ...atrasadas.map((atividade) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AtividadeCard(
                atividade: atividade,
                onTap: () => _openDetalhesAtividade(atividade),
                onToggle: () => _toggleAtividade(atividade),
                onEdit: () => _editAtividade(atividade),
                onDelete: () => _deleteAtividade(atividade),
                onDuplicate: () => _duplicateAtividade(atividade),
                onShare: () => _shareAtividadeQr(atividade),
              ),
            )),
            const SizedBox(height: 24),
          ],
          if (proximas.isNotEmpty) ...[
            _buildSectionHeader('Próximas', Icons.schedule, AppTheme.infoColor),
            const SizedBox(height: 12),
            ..._buildAtividadesWithGaps(proximas),
            const SizedBox(height: 24),
          ],
          if (concluidas.isNotEmpty) ...[
            _buildSectionHeader('Concluídas', Icons.check_circle, AppTheme.successColor),
            const SizedBox(height: 12),
            ...concluidas.map((atividade) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AtividadeCard(
                atividade: atividade,
                onTap: () => _openDetalhesAtividade(atividade),
                onToggle: () => _toggleAtividade(atividade),
                onEdit: () => _editAtividade(atividade),
                onDelete: () => _deleteAtividade(atividade),
                onDuplicate: () => _duplicateAtividade(atividade),
                onShare: () => _shareAtividadeQr(atividade),
              ),
            )),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildAtividadesWithGaps(List<Atividade> atividades) {
    final widgets = <Widget>[];
    
    for (int i = 0; i < atividades.length; i++) {
      final atividade = atividades[i];
      
      // Add the activity card
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AtividadeCard(
            atividade: atividade,
            onTap: () => _openDetalhesAtividade(atividade),
            onToggle: () => _toggleAtividade(atividade),
            onEdit: () => _editAtividade(atividade),
            onDelete: () => _deleteAtividade(atividade),
            onDuplicate: () => _duplicateAtividade(atividade),
            onShare: () => _shareAtividadeQr(atividade),
          ),
        ),
      );
      
      // Check for gap to next activity
      if (i < atividades.length - 1) {
        final nextAtividade = atividades[i + 1];
        final currentEnd = atividade.dataHora.add(Duration(minutes: atividade.duracao ?? 60));
        final nextStart = nextAtividade.dataHora;
        
        if (nextStart.isAfter(currentEnd)) {
          final gapMinutes = nextStart.difference(currentEnd).inMinutes;
          
          // Only show gaps of 30 minutes or more
          if (gapMinutes >= 30) {
            widgets.add(_buildGapIndicator(gapMinutes, currentEnd, nextStart));
          }
        }
      }
    }
    
    return widgets;
  }

  Widget _buildGapIndicator(int minutes, DateTime start, DateTime end) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    String timeText;
    if (hours > 0) {
      timeText = remainingMinutes > 0 
          ? '${hours}h ${remainingMinutes}min livre'
          : '${hours}h livre';
    } else {
      timeText = '${remainingMinutes}min livre';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.infoColor.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.free_breakfast,
              size: 16,
              color: AppTheme.infoColor.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              timeText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.infoColor.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const Spacer(),
            Text(
              '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) => Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );

  void _openDetalhesAtividade(Atividade atividade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesAtividadeScreen(atividade: atividade),
      ),
  ).then((_) async => await _loadData());
  }

  Future<void> _toggleAtividade(Atividade atividade) async {
    await context.read<AtividadeProvider>().toggleAtividade(atividade);
  await _updateProgresso();
  }

  void _editAtividade(Atividade atividade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdicionarAtividadeScreen(atividade: atividade),
      ),
  ).then((_) async => await _loadData());
  }

  void _duplicateAtividade(Atividade atividade) {
    // Create a new activity based on current one but without ID
    final novaAtividade = Atividade(
      titulo: atividade.titulo,
      descricao: atividade.descricao,
      categoria: atividade.categoria,
      dataHora: DateTime.now().add(const Duration(hours: 1)),
      duracao: atividade.duracao,
      repeticao: atividade.repeticao,
      prioridade: atividade.prioridade,
      meta: atividade.meta,
      notificationTiming: atividade.notificationTiming,
      concluida: false,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdicionarAtividadeScreen(atividade: novaAtividade),
      ),
    ).then((_) async => await _loadData());
  }

  Widget _buildDateNavigationButtons() => Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                  await _loadData();
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
                  await _loadData();
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

  Future<void> _loadNomeUsuario() async {
    try {
      final nome = await _databaseService.getConfiguracao('nome_usuario') ?? '';
      if (mounted) {
        setState(() {
          _nomeUsuario = nome;
        });
      }
    } catch (e) {
      // ignore errors silently
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
              Theme.of(context).colorScheme.surface,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: Text(
                        _nomeUsuario.isEmpty ? 'Mobile Grok' : _nomeUsuario,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        'Organize sua vida com IA',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.only(top: 16),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      isSelected: true,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.smart_toy,
                      title: 'IA Assistant',
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.search,
                      title: 'Procurar Lacunas',
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProcurarLacunasScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.category,
                      title: 'Categorias',
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CategoriasScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Divider(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      indent: 16,
                      endIndent: 16,
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.nfc,
                      title: 'Receber via NFC',
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NfcReceiveScreen()),
                        );
                        await _loadData();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.qr_code_scanner,
                      title: 'Receber via QR Code',
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const QrReceiveScreen()),
                        );
                        await _loadData();
                      },
                    ),
                    const SizedBox(height: 8),
                    Divider(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      indent: 16,
                      endIndent: 16,
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Configurações',
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ConfiguracoesScreen()),
                        );
                        if (result == true) {
                          await _loadNomeUsuario(); // Reload user name if changed
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected 
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected 
                ? AppTheme.primaryColor.withOpacity(0.2)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected 
                ? AppTheme.primaryColor
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected 
                ? AppTheme.primaryColor
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _shareAtividadeNfc(Atividade atividade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NfcShareScreen(atividade: atividade),
      ),
    );
  }

  void _shareAtividadeQr(Atividade atividade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrShareScreen(atividade: atividade),
      ),
    );
  }

  void _deleteAtividade(Atividade atividade) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
                 title: const Text('Confirmar Exclusão'),
         content: Text('Tem certeza que deseja excluir "${atividade.titulo}"?'),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text(AppConstants.cancelButton),
           ),
           ElevatedButton(
             onPressed: () async {
               await context.read<AtividadeProvider>().deleteAtividade(atividade.id!);
               Navigator.pop(context);
               await _loadData();
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: AppTheme.errorColor,
             ),
             child: const Text(AppConstants.deleteButton),
           ),
         ],
      ),
    );
  }
}
