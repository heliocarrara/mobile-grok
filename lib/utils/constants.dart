class AppConstants {
  // Configurações de animação
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Configurações de notificação
  static const int notificationReminderMinutes = 15;
  static const String notificationChannelId = 'mobile_grok_channel';
  static const String notificationChannelName = 'Mobile Grok Notifications';
  static const String notificationChannelDescription = 'Notifications for activities and reminders';

  // Configurações de backup
  static const String backupFileName = 'mobile_grok_backup.json';
  static const String backupFolderName = 'MobileGrok';

  // Configurações de UI
  static const double defaultBorderRadius = 16.0;
  static const double cardBorderRadius = 20.0;
  static const double buttonBorderRadius = 16.0;
  static const double inputBorderRadius = 16.0;

  // Configurações de prioridade
  static const int minPrioridade = 1;
  static const int maxPrioridade = 5;
  static const int defaultPrioridade = 3;

  // Configurações de duração
  static const int minDuracao = 5; // minutos
  static const int maxDuracao = 480; // 8 horas
  static const int defaultDuracao = 60; // 1 hora

  // Configurações de data
  static const int maxDaysInPast = 365;
  static const int maxDaysInFuture = 365;

  // Mensagens de erro
  static const String errorLoadingActivities = 'Erro ao carregar atividades';
  static const String errorSavingActivity = 'Erro ao salvar atividade';
  static const String errorDeletingActivity = 'Erro ao excluir atividade';
  static const String errorUpdatingActivity = 'Erro ao atualizar atividade';
  static const String errorBackup = 'Erro ao fazer backup';
  static const String errorRestore = 'Erro ao restaurar backup';

  // Mensagens de sucesso
  static const String successActivitySaved = 'Atividade salva com sucesso';
  static const String successActivityDeleted = 'Atividade excluída com sucesso';
  static const String successActivityUpdated = 'Atividade atualizada com sucesso';
  static const String successBackupCreated = 'Backup criado com sucesso';
  static const String successBackupRestored = 'Backup restaurado com sucesso';

  // Textos de interface
  static const String appName = 'Mobile Grok';
  static const String appTagline = 'Organize sua vida com IA';
  static const String emptyStateTitle = 'Nenhuma atividade encontrada';
  static const String emptyStateMessage = 'Adicione uma nova atividade para começar!';
  static const String loadingMessage = 'Carregando...';
  static const String retryButton = 'Tentar Novamente';
  static const String cancelButton = 'Cancelar';
  static const String saveButton = 'Salvar';
  static const String deleteButton = 'Excluir';
  static const String editButton = 'Editar';
  static const String confirmButton = 'Confirmar';

  // Configurações de IA
  static const String grokApiUrl = 'https://api.grok.ai/v1/chat/completions';
  static const String defaultSystemPrompt = '''
Você é um assistente de produtividade especializado em gerenciamento de atividades.
Ajude o usuário a organizar suas tarefas de forma eficiente e produtiva.
Você pode criar, editar, adiar e excluir atividades.
Sempre seja útil e prestativo.
''';

  // Configurações de tema
  static const String lightThemeName = 'Claro';
  static const String darkThemeName = 'Escuro';
  static const String systemThemeName = 'Sistema';

  // Configurações de categoria
  static const Map<String, String> categoriaIcons = {
    'faculdade': 'school',
    'casa': 'home',
    'lazer': 'sports_esports',
    'alimentacao': 'restaurant',
    'financas': 'account_balance_wallet',
    'trabalho': 'work',
    'saude': 'favorite',
    'outros': 'more_horiz',
  };

  // Configurações de repetição
  static const Map<String, String> repeticaoLabels = {
    'nenhuma': 'Nenhuma',
    'diaria': 'Diária',
    'semanal': 'Semanal',
    'mensal': 'Mensal',
  };

  // Configurações de prioridade
  static const Map<int, String> prioridadeLabels = {
    1: 'Baixa',
    2: 'Média',
    3: 'Alta',
    4: 'Urgente',
    5: 'Crítica',
  };

  // Configurações de validação
  static const int minTitleLength = 1;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxMetaLength = 200;
}
