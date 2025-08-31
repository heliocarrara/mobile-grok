RUN ON ANDROID EMULATOR

Este arquivo explica, passo-a-passo, como rodar este projeto Flutter no emulador que estamos usando atualmente (emulator-5554) no Windows (PowerShell).

Sumário rápido
- Emulador alvo: emulator-5554 (no ambiente detectado foi um dispositivo Android 14 / API 34)
- Requisitos: Flutter instalado, Android SDK (com command-line tools idealmente), Android Studio (opcional)

Checklist
- [ ] Ter Flutter instalado e no PATH
- [ ] Ter um emulador Android rodando (ex: emulator-5554)
- [ ] Ter dependências do projeto instaladas com `flutter pub get`
- [ ] Aceitar licenças do Android SDK (se necessário)

Instruções passo a passo (PowerShell)

1) Abrir PowerShell na pasta do projeto
```powershell
cd C:\Users\helio\AndroidStudioProjects\mobile-grok
```

2) Conferir dispositivos/emuladores disponíveis
```powershell
flutter devices
flutter emulators
```
- No ambiente atual o emulador em uso é `emulator-5554`.
- Para iniciar um emulador listado por id: `flutter emulators --launch <emulator id>`

3) (Se o emulador não estiver rodando) Iniciar o emulador
- Usando Flutter (se houver um emulador criado):
```powershell
flutter emulators --launch pixel_5_-_api_34
```
- Ou, usando o Android SDK `emulator` (se disponível):
```powershell
emulator -avd <avd_name>
```

4) Instalar dependências do Flutter
```powershell
flutter pub get
```

5) Rodar o app no emulador em execução (exemplo usando `emulator-5554`)
```powershell
# lista devices para confirmar id
flutter devices
# rodar no dispositivo/emulador específico
flutter run -d emulator-5554
```
- Se quiser rodar no emulador padrão detectado, basta `flutter run` e escolher o dispositivo interativamente.

Problemas comuns e como resolver

A) `sdkmanager not found` / `flutter doctor --android-licenses` falha
- Significa que as Android Command-line Tools não estão instaladas.
- Instalação rápida via PowerShell (exemplo):
```powershell
# Baixa command-line tools (ajuste a URL se necessário)
$uri = 'https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip'
$out = "$env:USERPROFILE\Downloads\cmdline-tools.zip"
Invoke-WebRequest -Uri $uri -OutFile $out
# Extrair para a pasta do SDK
Expand-Archive -Path $out -DestinationPath 'C:\Users\helio\AppData\Local\Android\sdk\cmdline-tools'
# Mover os arquivos para a subpasta 'latest' (ou usar a pasta conforme o zip extrai)
# Depois, adicione ao PATH: C:\Users\helio\AppData\Local\Android\sdk\cmdline-tools\latest\bin
```
- Alternativa (GUI): abrir Android Studio → Tools → SDK Manager → SDK Tools → marcar "Android SDK Command-line Tools" e aplicar.
- Depois de instalar as cmdline-tools, aceite as licenças:
```powershell
flutter doctor --android-licenses
```

B) Precisa de imagem Android 33 (API 33) ou criar um AVD específico
- Instalar via `sdkmanager`:
```powershell
sdkmanager --sdk_root="C:\Users\helio\AppData\Local\Android\sdk" "platform-tools" "platforms;android-33" "system-images;android-33;google_apis;x86_64" "emulator"
```
- Criar AVD:
```powershell
avdmanager create avd -n pixel_api_33 -k "system-images;android-33;google_apis;x86_64" -d pixel
```

C) Build lento / erros de Gradle
- Rode `flutter clean` e depois `flutter pub get` antes de `flutter run`.
- Se houver erros de SDK/Gradle, abra o projeto Android no Android Studio para resolver dependências.

Dicas de debug rápido
- Para ver logs em tempo real: `flutter run` ou `flutter logs`.
- Para testes rápidos: `flutter test` (rodar testes unitários existentes).

Notas finais
- No histórico deste ambiente detectamos um emulador Android 14 (API 34) com id `emulator-5554`. Rodar o aplicativo neste emulador deve funcionar sem precisar instalar a imagem 33. Se você especificamente quer testar em Android 13 (API 33), siga a seção B para instalar a imagem e criar um AVD API 33.
- Se ocorrerem erros, copie o output do terminal e abra aqui que eu te ajudo a resolver.

Arquivo criado automaticamente por instruções do repositório. Boa execução.
