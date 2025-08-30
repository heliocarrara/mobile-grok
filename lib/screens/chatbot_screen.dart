import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/atividade_provider.dart';
import '../utils/theme.dart';
import '../services/grok_api_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final GrokApiService _grokService = GrokApiService();

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      'Olá! Sou seu assistente de IA para gerenciar atividades. '
      'Posso ajudar você a:\n'
      '• Criar novas atividades\n'
      '• Editar atividades existentes\n'
      '• Marcar atividades como concluídas\n'
      '• Adiar atividades\n'
      '• Excluir atividades\n\n'
      'Como posso ajudar você hoje?',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _limparChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'IA está digitando...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviarMensagem(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _enviarMensagem,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _enviarMensagem() {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _addUserMessage(message);
    _messageController.clear();
    _processarMensagem(message);
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _addBotMessage(String text, [ChatResponseType? type]) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
        responseType: type,
      ));
    });
  }

  Future<void> _processarMensagem(String message) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular processamento da IA
      await Future.delayed(const Duration(seconds: 1));
      
      final response = await _gerarRespostaIA(message);
      _addBotMessage(response);
    } catch (e) {
      _addBotMessage('Desculpe, ocorreu um erro ao processar sua mensagem. Tente novamente.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _gerarRespostaIA(String message) async {
    try {
      final provider = context.read<AtividadeProvider>();
      final response = await _grokService.processCommand(message, provider);
      
      // Executar ações se houver
      if (response.actions != null) {
        for (final action in response.actions!) {
          _addBotMessage(action.message);
        }
      }
      
      return response.message;
    } catch (e) {
      return 'Erro ao processar comando: $e';
    }
  }



  void _limparChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Chat'),
        content: const Text('Tem certeza que deseja limpar todo o histórico do chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
              });
              _addBotMessage(
                'Chat limpo! Como posso ajudar você hoje?',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatResponseType? responseType;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.responseType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? AppTheme.primaryColor 
                        : _getMessageColor(context),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: !isUser ? Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ) : null,
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.secondaryColor,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }

  Color _getMessageColor(BuildContext context) {
    if (responseType == null) {
      return Theme.of(context).colorScheme.surface;
    }
    
    switch (responseType!) {
      case ChatResponseType.success:
        return AppTheme.successColor.withOpacity(0.1);
      case ChatResponseType.error:
        return AppTheme.errorColor.withOpacity(0.1);
      case ChatResponseType.warning:
        return AppTheme.warningColor.withOpacity(0.1);
      case ChatResponseType.info:
        return AppTheme.infoColor.withOpacity(0.1);
    }
  }
}
