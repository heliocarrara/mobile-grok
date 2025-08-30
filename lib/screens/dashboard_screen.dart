import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  double _progressoDiario = 0.0;
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
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _fadeController.forward();
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
    _updateProgresso();
  }

  Future<void> _updateProgresso() async {
    final provider = context.read<AtividadeProvider>();
    final progresso = await provider.getProgressoDiario(_selectedDate);
    setState(() {
      _progressoDiario = progresso;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatbotScreen()),
            ),
            icon: const Icon(Icons.smart_toy),
            label: const Text('IA'),
            backgroundColor: AppTheme.secondaryColor,
            elevation: 8,
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdicionarAtividadeScreen()),
              );
              if (result == true) {
                _loadData();
              }
            },
            child: const Icon(Icons.add),
            elevation: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CategoriasScreen()),
                        ),
                        icon: const Icon(Icons.category, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ConfiguracoesScreen()),
                        ),
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
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM', 'pt_BR').format(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
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
                _loadData();
              }
            },
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Progresso Diário',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ProgressIndicator(
            progress: _progressoDiario,
            label: 'Atividades Concluídas',
            height: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AtividadeProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<CategoriaEnum>(
              value: provider.filtroCategoria,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todas'),
                ),
                ...CategoriaEnum.values.map((categoria) => DropdownMenuItem(
                  value: categoria,
                  child: Text(categoria.displayName),
                )),
              ],
              onChanged: (value) {
                provider.setFiltroCategoria(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: provider.filtroPrioridade,
              decoration: const InputDecoration(
                labelText: 'Prioridade',
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todas'),
                ),
                ...List.generate(5, (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1}'),
                )),
              ],
              onChanged: (value) {
                provider.setFiltroPrioridade(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtividadesList(AtividadeProvider provider) {
    final atividades = provider.atividadesFiltradas;
    
    if (atividades.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
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
      margin: const EdgeInsets.all(20),
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
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
  }

  void _openDetalhesAtividade(Atividade atividade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesAtividadeScreen(atividade: atividade),
      ),
    ).then((_) => _loadData());
  }

  void _toggleAtividade(Atividade atividade) {
    context.read<AtividadeProvider>().toggleAtividade(atividade);
  }

  void _editAtividade(Atividade atividade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdicionarAtividadeScreen(atividade: atividade),
      ),
    ).then((_) => _loadData());
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
             onPressed: () {
               context.read<AtividadeProvider>().deleteAtividade(atividade.id!);
               Navigator.pop(context);
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
