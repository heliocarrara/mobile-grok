import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoriaCard(
            context,
            'Faculdade',
            Icons.school,
            AppTheme.categoriaColors['faculdade']!,
            'Atividades relacionadas aos estudos',
          ),
          _buildCategoriaCard(
            context,
            'Casa',
            Icons.home,
            AppTheme.categoriaColors['casa']!,
            'Tarefas domésticas e organização',
          ),
          _buildCategoriaCard(
            context,
            'Lazer',
            Icons.sports_esports,
            AppTheme.categoriaColors['lazer']!,
            'Atividades de entretenimento',
          ),
          _buildCategoriaCard(
            context,
            'Alimentação',
            Icons.restaurant,
            AppTheme.categoriaColors['alimentacao']!,
            'Refeições e preparação de comida',
          ),
          _buildCategoriaCard(
            context,
            'Finanças',
            Icons.account_balance_wallet,
            AppTheme.categoriaColors['financas']!,
            'Controle financeiro e pagamentos',
          ),
          _buildCategoriaCard(
            context,
            'Trabalho',
            Icons.work,
            AppTheme.categoriaColors['trabalho']!,
            'Atividades profissionais',
          ),
          _buildCategoriaCard(
            context,
            'Saúde',
            Icons.favorite,
            AppTheme.categoriaColors['saude']!,
            'Exercícios e cuidados com a saúde',
          ),
          _buildCategoriaCard(
            context,
            'Outros',
            Icons.more_horiz,
            AppTheme.categoriaColors['outros']!,
            'Outras atividades diversas',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaCard(
    BuildContext context,
    String nome,
    IconData icone,
    Color cor,
    String descricao,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icone,
            color: cor,
            size: 24,
          ),
        ),
        title: Text(
          nome,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          descricao,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
          ),
        ),
        onTap: () {
          _editarCategoria(categoria);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Categoria: $nome'),
              backgroundColor: cor,
            ),
          );
        },
      ),
    );
  }

  void _editarCategoria(Categoria categoria) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${categoria.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Funcionalidade de edição de categorias será implementada em breve.'),
            const SizedBox(height: 16),
            Text('Por enquanto, as categorias são predefinidas e não podem ser editadas.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
