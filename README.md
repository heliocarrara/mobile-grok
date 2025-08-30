# Mobile Grok - Gerenciador de Atividades com IA

Um aplicativo Flutter para gerenciamento de atividades com integração de IA usando a API Grok.

## 🚀 Funcionalidades

- **Gerenciamento de Atividades**: Crie, edite e organize suas atividades
- **Categorização**: Organize atividades por categorias personalizadas
- **Integração com IA**: Chatbot integrado com a API Grok para assistência
- **Notificações**: Lembretes e notificações para suas atividades
- **Backup e Restauração**: Sistema de backup local dos dados
- **Tema Personalizável**: Interface adaptável com temas claro/escuro

## 📱 Screenshots

*Screenshots do aplicativo serão adicionadas aqui*

## 🛠️ Tecnologias Utilizadas

- **Flutter**: Framework de desenvolvimento mobile
- **Provider**: Gerenciamento de estado
- **SQLite**: Banco de dados local
- **HTTP**: Comunicação com APIs
- **Flutter Local Notifications**: Sistema de notificações
- **File Picker**: Seleção de arquivos para backup

## 📋 Pré-requisitos

- Flutter SDK (versão 3.0.0 ou superior)
- Dart SDK
- Android Studio / VS Code
- Dispositivo Android ou emulador

## 🔧 Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/seu-usuario/mobile-grok.git
   cd mobile-grok
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Configure a API Grok**
   - Crie um arquivo `lib/services/api_keys.dart`
   - Adicione sua chave da API Grok:
   ```dart
   class ApiKeys {
     static const String grokApiKey = 'sua-chave-aqui';
   }
   ```

4. **Execute o aplicativo**
   ```bash
   flutter run
   ```

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada da aplicação
├── models/                   # Modelos de dados
│   ├── atividade.dart
│   ├── categoria.dart
│   └── configuracao.dart
├── providers/                # Gerenciamento de estado
│   ├── atividade_provider.dart
│   └── theme_provider.dart
├── screens/                  # Telas da aplicação
│   ├── dashboard_screen.dart
│   ├── adicionar_atividade_screen.dart
│   ├── categorias_screen.dart
│   ├── chatbot_screen.dart
│   ├── configuracoes_screen.dart
│   └── detalhes_atividade_screen.dart
├── services/                 # Serviços e APIs
│   ├── database_service.dart
│   ├── grok_api_service.dart
│   ├── notification_service.dart
│   └── backup_service.dart
├── utils/                    # Utilitários
│   ├── constants.dart
│   └── theme.dart
└── widgets/                  # Widgets reutilizáveis
    ├── atividade_card.dart
    ├── loading_widget.dart
    └── progress_indicator.dart
```

## 🔑 Configuração da API

Para usar o chatbot com IA, você precisa:

1. Obter uma chave da API Grok
2. Criar o arquivo `lib/services/api_keys.dart`
3. Adicionar sua chave no arquivo

## 📦 Build do APK

Para gerar o APK de release:

```bash
flutter build apk --release
```

O APK será gerado em: `build/app/outputs/flutter-apk/app-release.apk`

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👨‍💻 Autor

**Seu Nome**
- GitHub: [@seu-usuario](https://github.com/seu-usuario)

## 🙏 Agradecimentos

- Flutter Team pelo framework incrível
- Grok pela API de IA
- Comunidade Flutter pela documentação e suporte

## 📞 Suporte

Se você encontrar algum problema ou tiver sugestões, por favor abra uma [issue](https://github.com/seu-usuario/mobile-grok/issues).
