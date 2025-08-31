import 'dart:convert';
import 'package:http/http.dart' as http;
// ...existing code...
import '../providers/atividade_provider.dart';

class GrokApiService {
  factory GrokApiService() => _instance;
  GrokApiService._internal();
  static final GrokApiService _instance = GrokApiService._internal();

  static const String _baseUrl = 'https://api.x.ai';
  String? _apiKey;
  bool _isConfigured = false;

  // Configurar API key
  void configure(String apiKey) {
    _apiKey = apiKey;
    _isConfigured = true;
  }

  // Verificar se está configurado
  bool get isConfigured => _isConfigured && _apiKey != null;

  // Processar comando do usuário
  Future<ChatResponse> processCommand(String userMessage, AtividadeProvider provider) async {
    if (!isConfigured) {
      return ChatResponse(
        message: 'API do Grok não está configurada. Configure sua API key nas configurações.',
        type: ChatResponseType.error,
      );
    }

    try {
      // Primeiro, tentar processar comandos básicos localmente
      final localResponse = await _processLocalCommand(userMessage, provider);
      if (localResponse != null) {
        return localResponse;
      }

      // Se não for um comando local, usar Grok API
      return await _processWithGrokApi(userMessage, provider);
    } catch (e) {
      return ChatResponse(
        message: 'Erro ao processar comando: $e',
        type: ChatResponseType.error,
      );
    }
  }

  // Processar comandos básicos localmente
  Future<ChatResponse?> _processLocalCommand(String message, AtividadeProvider provider) async {
    final lowerMessage = message.toLowerCase().trim();

    // Comandos de ajuda
    if (lowerMessage.contains('ajuda') || lowerMessage.contains('help')) {
      return ChatResponse(
        message: _getHelpMessage(),
        type: ChatResponseType.info,
      );
    }

    // Comando para listar atividades
    if (lowerMessage.contains('listar') || lowerMessage.contains('mostrar') || lowerMessage.contains('atividades')) {
      final atividades = provider.atividadesFiltradas;
      if (atividades.isEmpty) {
        return ChatResponse(
          message: 'Não há atividades cadastradas.',
          type: ChatResponseType.info,
        );
      }

      final atividadesText = atividades.take(5).map((a) {
        final status = a.concluida ? '✅' : '⏳';
        final data = '${a.dataHora.day}/${a.dataHora.month} ${a.dataHora.hour}:${a.dataHora.minute.toString().padLeft(2, '0')}';
        return '$status ${a.titulo} ($data)';
      }).join('\n');

      return ChatResponse(
        message: 'Suas próximas atividades:\n$atividadesText${atividades.length > 5 ? '\n... e mais ${atividades.length - 5} atividades' : ''}',
        type: ChatResponseType.info,
      );
    }

    // Comando para mostrar progresso
    if (lowerMessage.contains('progresso') || lowerMessage.contains('progress')) {
      final hoje = DateTime.now();
      final progresso = await provider.getProgressoDiario(hoje);
      return ChatResponse(
        message: 'Seu progresso de hoje: ${progresso.toStringAsFixed(1)}%',
        type: ChatResponseType.info,
      );
    }

    // Comando para mostrar atividades atrasadas
    if (lowerMessage.contains('atrasadas') || lowerMessage.contains('atrasado')) {
      final atrasadas = provider.getAtividadesAtrasadas();
      if (atrasadas.isEmpty) {
        return ChatResponse(
          message: 'Ótimo! Você não tem atividades atrasadas.',
          type: ChatResponseType.success,
        );
      }

      final atrasadasText = atrasadas.take(3).map((a) {
        final data = '${a.dataHora.day}/${a.dataHora.month} ${a.dataHora.hour}:${a.dataHora.minute.toString().padLeft(2, '0')}';
        return '⚠️ ${a.titulo} ($data)';
      }).join('\n');

      return ChatResponse(
        message: 'Atividades atrasadas:\n$atrasadasText${atrasadas.length > 3 ? '\n... e mais ${atrasadas.length - 3} atividades atrasadas' : ''}',
        type: ChatResponseType.warning,
      );
    }

    return null; // Não é um comando local
  }

  // Processar com Grok API
  Future<ChatResponse> _processWithGrokApi(String message, AtividadeProvider provider) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'grok-beta',
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(),
            },
            {
              'role': 'user',
              'content': message,
            },
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Tentar executar ações baseadas na resposta
        final actionResponse = await _executeActions(content, provider);
        
        return ChatResponse(
          message: content,
          type: ChatResponseType.success,
          actions: actionResponse,
        );
      } else {
        return ChatResponse(
          message: 'Erro na API do Grok: ${response.statusCode}',
          type: ChatResponseType.error,
        );
      }
    } catch (e) {
      return ChatResponse(
        message: 'Erro de conexão com Grok API: $e',
        type: ChatResponseType.error,
      );
    }
  }

  // Validar chave de API fazendo uma requisição mínima
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'grok-beta',
          'messages': [
            {'role': 'system', 'content': 'ping'},
            {'role': 'user', 'content': 'ping'},
          ],
          'max_tokens': 1,
        }),
      );

      // 200 -> key válida; 401/403 -> inválida
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Executar ações baseadas na resposta da IA
  Future<List<ChatAction>> _executeActions(String response, AtividadeProvider provider) async {
    final actions = <ChatAction>[];
    final lowerResponse = response.toLowerCase();

    // Detectar criação de atividade
    if (lowerResponse.contains('criar') || lowerResponse.contains('nova atividade')) {
      actions.add(ChatAction(
        type: ChatActionType.createActivity,
        message: 'Vou te ajudar a criar uma nova atividade. Use o botão "Adicionar Atividade" ou me diga os detalhes.',
      ));
    }

    // Detectar conclusão de atividade
    if (lowerResponse.contains('concluir') || lowerResponse.contains('marcar como feito')) {
      actions.add(ChatAction(
        type: ChatActionType.completeActivity,
        message: 'Para marcar uma atividade como concluída, clique nela na lista principal.',
      ));
    }

    return actions;
  }

  // Obter prompt do sistema
  String _getSystemPrompt() => '''
Você é um assistente de IA para gerenciamento de atividades. Você ajuda o usuário a:

1. Criar novas atividades
2. Gerenciar atividades existentes
3. Fornecer dicas de produtividade
4. Responder perguntas sobre organização

O usuário tem atividades organizadas por categorias: Faculdade, Casa, Lazer, Alimentação, Finanças, Trabalho, Saúde, Outros.

Responda de forma amigável e útil. Se o usuário quiser criar uma atividade, peça os detalhes necessários como título, data/hora, categoria, prioridade, etc.

Mantenha suas respostas concisas e práticas.
''';

  // Obter mensagem de ajuda
  String _getHelpMessage() => '''
🤖 **Comandos disponíveis:**

**Básicos:**
• "listar atividades" - Mostrar suas atividades
• "progresso" - Ver progresso do dia
• "atividades atrasadas" - Ver o que está pendente

**Criação:**
• "criar atividade" - Criar nova atividade
• "nova tarefa" - Criar nova tarefa

**Gerenciamento:**
• "concluir atividade" - Marcar como feita
• "adiar atividade" - Mover para outro horário

**Dicas:**
• "dicas de produtividade" - Receber conselhos
• "organizar dia" - Sugestões de organização

**Configuração:**
• "configurar api" - Configurar Grok API

Digite "ajuda" a qualquer momento para ver esta lista!
''';
}

// Classes de resposta
class ChatResponse {

  ChatResponse({
    required this.message,
    required this.type,
    this.actions,
  });
  final String message;
  final ChatResponseType type;
  final List<ChatAction>? actions;
}

enum ChatResponseType {
  success,
  error,
  warning,
  info,
}

class ChatAction {

  ChatAction({
    required this.type,
    required this.message,
  });
  final ChatActionType type;
  final String message;
}

enum ChatActionType {
  createActivity,
  completeActivity,
  editActivity,
  deleteActivity,
  showHelp,
}
