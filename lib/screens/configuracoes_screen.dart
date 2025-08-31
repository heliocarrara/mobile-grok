import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../services/database_service.dart';
import '../services/grok_api_service.dart';
import '../services/secure_storage_service.dart';
import '../services/backup_service.dart';
// ...existing code...
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
  String? _grokApiKey;
  String _nomeUsuario = '';

  final DatabaseService _databaseService = DatabaseService();
  final GrokApiService _grokApiService = GrokApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  final BackupService _backupService = BackupService();

  @override
  void initState() {
    super.initState();
    _loadConfiguracoes();
  }

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
          _buildSectionHeader('Usuário'),
          _buildUserSettings(),
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

  Widget _buildUserSettings() => Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Nome do usuário'),
            subtitle: Text(
              _nomeUsuario.isEmpty ? 'Não definido' : _nomeUsuario,
            ),
            leading: const Icon(Icons.person),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editarNomeUsuario,
          ),
        ],
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
              subtitle: Text(_horaInicioDia),
              leading: const Icon(Icons.access_time),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selecionarHoraInicio,
            ),
          ],
        ],
      ),
    );

  Widget _buildAppearanceSettings() => Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Card(
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
        ),
    );

  Widget _buildDataSettings() => Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Chave da API (Grok)'),
            subtitle: Text(
              _grokApiKey == null || _grokApiKey!.isEmpty
                  ? 'Não configurada'
                  : ('••••${_grokApiKey!.length > 4 ? _grokApiKey!.substring(_grokApiKey!.length - 4) : _grokApiKey!}'),
            ),
            leading: const Icon(Icons.vpn_key),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _grokApiKey == null || _grokApiKey!.isEmpty ? null : _removerGrokApiKey,
                  child: const Text('Remover'),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: _editarGrokApiKey,
          ),
          const Divider(),
          ListTile(
            title: const Text('Exportar dados'),
            subtitle: const Text('Salvar backup das atividades'),
            leading: const Icon(Icons.download),
            trailing: _isLoading ? const SizedBox(width:24,height:24,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.chevron_right),
            onTap: _isLoading ? null : _exportarDados,
          ),
          const Divider(),
          ListTile(
            title: const Text('Importar dados'),
            subtitle: const Text('Restaurar backup'),
            leading: const Icon(Icons.upload),
            trailing: _isLoading ? const SizedBox(width:24,height:24,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.chevron_right),
            onTap: _isLoading ? null : _importarDados,
          ),
          const Divider(),
          ListTile(
            title: const Text('Limpar dados'),
            subtitle: const Text('Excluir todas as atividades'),
            leading: const Icon(Icons.delete_forever, color: AppTheme.errorColor),
            trailing: _isLoading ? const SizedBox(width:24,height:24,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.chevron_right),
            onTap: _isLoading ? null : _confirmarLimpeza,
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

  Future<void> _loadConfiguracoes() async {
    try {
      // Load Grok API key
      String? key = await _secureStorage.readGrokApiKey();
      if (key == null) {
        final legacy = await _databaseService.getConfiguracao('grok_api_key');
        if (legacy != null && legacy.isNotEmpty) {
          await _secureStorage.saveGrokApiKey(legacy);
          await _databaseService.deleteConfiguracao('grok_api_key');
          key = legacy;
        }
      }

      // Load user name
      final nomeUsuario = await _databaseService.getConfiguracao('nome_usuario') ?? '';

      if (mounted) {
        setState(() {
          _grokApiKey = key;
          _nomeUsuario = nomeUsuario;
        });
        if (key != null) {
          _grokApiService.configure(key);
        }
      }
    } catch (e) {
      // ignore load errors silently
    }
  }

  Future<void> _editarGrokApiKey() async {
  final controller = TextEditingController(text: _grokApiKey ?? '');

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Grok API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Insira sua chave da API do Grok.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'sk-...'
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (salvar ?? false) {
      final newKey = controller.text.trim();

      // Simple validation
      if (newKey.isEmpty || newKey.length < 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chave inválida. Insira ao menos 10 caracteres.')),
          );
        }
        return;
      }

      try {
  // Save securely
  await _secureStorage.saveGrokApiKey(newKey);
  _grokApiService.configure(newKey);
        if (mounted) {
          setState(() {
            _grokApiKey = newKey;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chave da API salva com sucesso!')),
          );
        }

        // Validate key in background and inform user
        final isValid = await _grokApiService.validateApiKey(newKey);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isValid ? 'Chave validada com sucesso.' : 'A chave parece inválida (ou API inacessível).')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar chave: $e')),
          );
        }
      }
    }
  }

  Future<void> _removerGrokApiKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover chave da API'),
        content: const Text('Deseja realmente remover a chave da API do Grok?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await _secureStorage.deleteGrokApiKey();
        // Optionally remove from DB as well
        await _databaseService.setConfiguracao('grok_api_key', '');
        _grokApiService.configure('');
        if (mounted) {
          setState(() => _grokApiKey = null);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave removida')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao remover chave: $e')));
        }
      }
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
      );

        if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
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

        if (confirmacao ?? false) {
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

    if (confirmacao ?? false) {
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

  Future<void> _editarNomeUsuario() async {
    final controller = TextEditingController(text: _nomeUsuario);

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nome do Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite seu nome para personalizar a experiência.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Seu nome',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (salvar ?? false) {
      final novoNome = controller.text.trim();
      
      try {
        await _databaseService.setConfiguracao('nome_usuario', novoNome);
        
        if (mounted) {
          setState(() {
            _nomeUsuario = novoNome;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nome salvo com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar nome: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}
