import 'package:flutter/material.dart';
import '../models/atividade.dart';
import '../services/nfc_service.dart';

class NfcShareScreen extends StatefulWidget {
  final Atividade atividade;

  const NfcShareScreen({
    super.key,
    required this.atividade,
  });

  @override
  State<NfcShareScreen> createState() => _NfcShareScreenState();
}

class _NfcShareScreenState extends State<NfcShareScreen>
    with TickerProviderStateMixin {
  bool _isTransmitting = false;
  bool _isSuccess = false;
  bool _nfcAvailable = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _checkNfcAvailability() async {
    final available = await NfcService.isNfcAvailable();
    setState(() {
      _nfcAvailable = available;
    });
  }

  Future<void> _startTransmission() async {
    if (!_nfcAvailable) return;

    setState(() {
      _isTransmitting = true;
      _isSuccess = false;
    });

    _pulseController.repeat(reverse: true);

    try {
      final success = await NfcService.transmitActivity(widget.atividade);
      
      setState(() {
        _isTransmitting = false;
        _isSuccess = success;
      });

      _pulseController.stop();

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      setState(() {
        _isTransmitting = false;
        _isSuccess = false;
      });
      _pulseController.stop();
      _showErrorDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Sucesso!'),
          ],
        ),
        content: const Text('Atividade compartilhada com sucesso via NFC!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erro'),
          ],
        ),
        content: const Text(
          'Não foi possível compartilhar a atividade. '
          'Verifique se o NFC está habilitado e tente novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartilhar via NFC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Informações da atividade
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atividade a compartilhar:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.atividade.titulo,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    if (widget.atividade.descricao != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.description,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.atividade.descricao!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.atividade.categoriaDisplayName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Área de transmissão NFC
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_nfcAvailable) ...[
                      const Icon(
                        Icons.nfc_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'NFC não disponível',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Verifique se o NFC está habilitado nas configurações',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ] else if (_isTransmitting) ...[
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).primaryColor.withOpacity(0.2),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.nfc,
                                size: 60,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Aproxime o dispositivo...',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Encoste os dispositivos para transmitir a atividade',
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.nfc,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Pronto para compartilhar',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toque no botão abaixo para iniciar o compartilhamento',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Botão de ação
            if (_nfcAvailable && !_isTransmitting)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startTransmission,
                  icon: const Icon(Icons.nfc),
                  label: const Text('Iniciar Compartilhamento'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

            if (_isTransmitting)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await NfcService.stopSession();
                    setState(() {
                      _isTransmitting = false;
                    });
                    _pulseController.stop();
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
