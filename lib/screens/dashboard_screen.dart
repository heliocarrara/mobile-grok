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
                        _buildProgressSection(),
                        _buildFilters(provider),
                        _buildAtividadesList(provider),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              );
            },
            icon: const Icon(Icons.smart_toy),
            label: const Text('IA'),
            backgroundColor: AppTheme.secondaryColor,
            elevation: 8,
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text('Criar tarefa rápida'),
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdicionarAtividadeScreen()),
                          );
                          if (result == true) {
                            await _loadData();
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.smart_toy),
                        title: const Text('Criar com IA'),
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                          );
                          if (result == true) {
                            await _loadData();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            elevation: 8,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );

  Widget _buildSliverAppBar() => SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      centerTitle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: GestureDetector(
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
              // atualizar dados sem bloquear o callback do date picker
              // ignore: unawaited_futures
              _loadData();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, d MMMM', 'pt_BR').format(_selectedDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mobile Grok',
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
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CategoriasScreen()),
                          );
                        },
                        icon: const Icon(Icons.category, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ConfiguracoesScreen()),
                          );
                        },
                        icon: const Icon(Icons.settings, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // compute a flexible size for the radial indicator so the row
              // doesn't overflow on very narrow widths (e.g. small windows)
              final available = constraints.maxWidth;
              final radialWidth = min(96.0, max(48.0, available * 0.35));

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Radial progress (responsive)
                  SizedBox(
                    width: radialWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Progresso Diário',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RadialProgressIndicator(
                          progress: _progressoDiario,
                          size: radialWidth,
                          centerLabel: 'Concl.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Summary cards
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Próxima',
                                value: proximas.isNotEmpty ? DateFormat('HH:mm - d MMM').format(proximas.first.dataHora) : '—',
                                icon: Icons.schedule,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Atrasadas',
                                value: atrasadas.length.toString(),
                                icon: Icons.error_outline,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          title: 'Concluídas hoje',
                          value: concluidasHoje.toString(),
                          icon: Icons.check_circle,
                          color: AppTheme.successColor,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

  Widget _buildStatCard({required String title, required String value, required IconData icon, Color? color}) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (color ?? AppTheme.primaryColor).withOpacity(0.12),
            ),
            child: Icon(icon, color: color ?? AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );

  Widget _buildFilters(AtividadeProvider provider) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
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
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder),
                    const SizedBox(width: 8),
                    Text(provider.filtroCategoria?.displayName ?? 'Categoria', overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),

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
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag),
                    const SizedBox(width: 8),
                    Text(provider.filtroPrioridade?.toString() ?? 'Prioridade', overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),

            // Clear filters
            TextButton.icon(
              onPressed: provider.limparFiltros,
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpar'),
            ),
          ],
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
        margin: const EdgeInsets.symmetric(horizontal: 20),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (atrasadas.isNotEmpty) ...[
            _buildSectionHeader('Atrasadas', Icons.warning, AppTheme.errorColor),
            const SizedBox(height: 8),
            ...atrasadas.map((atividade) => AtividadeCard(
              atividade: atividade,
              onTap: () => _openDetalhesAtividade(atividade),
              onToggle: () => _toggleAtividade(atividade),
              onEdit: () => _editAtividade(atividade),
              onDelete: () => _deleteAtividade(atividade),
            )),
            const SizedBox(height: 20),
          ],
          if (proximas.isNotEmpty) ...[
            _buildSectionHeader('Próximas', Icons.schedule, AppTheme.infoColor),
            const SizedBox(height: 8),
            ...proximas.map((atividade) => AtividadeCard(
              atividade: atividade,
              onTap: () => _openDetalhesAtividade(atividade),
              onToggle: () => _toggleAtividade(atividade),
              onEdit: () => _editAtividade(atividade),
              onDelete: () => _deleteAtividade(atividade),
            )),
            const SizedBox(height: 20),
          ],
          if (concluidas.isNotEmpty) ...[
            _buildSectionHeader('Concluídas', Icons.check_circle, AppTheme.successColor),
            const SizedBox(height: 8),
            ...concluidas.map((atividade) => AtividadeCard(
              atividade: atividade,
              onTap: () => _openDetalhesAtividade(atividade),
              onToggle: () => _toggleAtividade(atividade),
              onEdit: () => _editAtividade(atividade),
              onDelete: () => _deleteAtividade(atividade),
            )),
          ],
        ],
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
