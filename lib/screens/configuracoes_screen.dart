import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool _notificacoesAtivas = true;
  String _horaInicioDia = '06:00';
  bool _isLoading = false;
  
  final BackupService _backupService = BackupService();
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Notificações'),
          _buildNotificationSettings(),
          const SizedBox(height: 24),
          _buildSectionHeader('Aparência'),
          _buildAppearanceSettings(),
          const SizedBox(height: 24),
          _buildSectionHeader('Dados'),
          _buildDataSettings(),
        ],
      ),
    );

  Widget _buildSectionHeader(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );

  Widget _buildNotificationSettings() => Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Notificações'),
            subtitle: const Text('Receber lembretes de atividades'),
            value: _notificacoesAtivas,
            onChanged: (value) {
              setState(() {
                _notificacoesAtivas = value;
              });
            },
            secondary: Icon(
              _notificacoesAtivas ? Icons.notifications_active : Icons.notifications_off,
              color: _notificacoesAtivas ? AppTheme.successColor : Colors.grey,
            ),
          ),
          if (_notificacoesAtivas) ...[
            const Divider(),
            ListTile(
              title: const Text('Hora de início do dia'),
              subtitle: Text('$_horaInicioDia'),
              leading: const Icon(Icons.access_time),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selecionarHoraInicio,
            ),
          ],
        ],
      ),
    );

  Widget _buildAppearanceSettings() => Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Tema escuro'),
                subtitle: const Text('Usar tema escuro'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  if (value) {
                    themeProvider.setDarkTheme();
                  } else {
                    themeProvider.setLightTheme();
                  }
                },
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: themeProvider.isDarkMode ? AppTheme.primaryColor : Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );

  Widget _buildDataSettings() => Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Exportar dados'),
            subtitle: const Text('Salvar backup das atividades'),
            leading: const Icon(Icons.download),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportarDados,
          ),
          const Divider(),
          ListTile(
            title: const Text('Importar dados'),
            subtitle: const Text('Restaurar backup'),
            leading: const Icon(Icons.upload),
            trailing: const Icon(Icons.chevron_right),
            onTap: _importarDados,
          ),
          const Divider(),
          ListTile(
            title: const Text('Limpar dados'),
            subtitle: const Text('Excluir todas as atividades'),
            leading: const Icon(Icons.delete_forever, color: AppTheme.errorColor),
            trailing: const Icon(Icons.chevron_right),
            onTap: _confirmarLimpeza,
          ),
        ],
      ),
    );

  Future<void> _selecionarHoraInicio() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.parse('2023-01-01 $_horaInicioDia:00'),
      ),
    );

    if (hora != null) {
      setState(() {
        _horaInicioDia = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _exportarDados() async {
    setState(() => _isLoading = true);
    
    try {
      final filePath = await _backupService.exportData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup criado com sucesso!\nArquivo: $filePath'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar backup: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importarDados() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

        if (result != null && result.files.isNotEmpty) {
        final String? filePath = result.files.first.path;
        if (filePath == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Caminho do arquivo inválido'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          return;
        }

        // Validar arquivo
        final isValid = await _backupService.validateBackupFile(filePath);
        if (!isValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Arquivo de backup inválido'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          return;
        }

        // Confirmar importação
        final confirmacao = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Importação'),
            content: const Text(
              'Isso irá substituir todos os dados atuais. '
              'Tem certeza que deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
                child: const Text('Importar'),
              ),
            ],
          ),
        );

        if (confirmacao == true) {
          setState(() => _isLoading = true);

          await _backupService.importData(filePath);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dados importados com sucesso!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar dados: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmarLimpeza() async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Limpeza'),
        content: const Text(
          'Tem certeza que deseja excluir todas as atividades? '
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
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      setState(() => _isLoading = true);
      
      try {
        await _backupService.clearAllData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todos os dados foram limpos com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao limpar dados: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
