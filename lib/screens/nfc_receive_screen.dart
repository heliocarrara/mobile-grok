import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/atividade.dart';
import '../services/nfc_service.dart';
import '../providers/atividade_provider.dart';

class NfcReceiveScreen extends StatefulWidget {
  const NfcReceiveScreen({super.key});

  @override
  State<NfcReceiveScreen> createState() => _NfcReceiveScreenState();
}

class _NfcReceiveScreenState extends State<NfcReceiveScreen>
    with TickerProviderStateMixin {
  bool _isReceiving = false;
  bool _nfcAvailable = false;
  Atividade? _receivedActivity;
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

  Future<void> _startReceiving() async {
    if (!_nfcAvailable) return;

    setState(() {
      _isReceiving = true;
      _receivedActivity = null;
    });

    _pulseController.repeat(reverse: true);

    try {
      final activity = await NfcService.receiveActivity();
      
      setState(() {
        _isReceiving = false;
        _receivedActivity = activity;
      });

      _pulseController.stop();

      if (activity != null) {
        _showActivityPreview(activity);
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      setState(() {
        _isReceiving = false;
        _receivedActivity = null;
      });
      _pulseController.stop();
      _showErrorDialog();
    }
  }

  void _showActivityPreview(Atividade activity) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.blue),
            SizedBox(width: 8),
            Text('Atividade Recebida'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deseja adicionar esta atividade ao seu calendário?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activity.titulo,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (activity.descricao != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.description, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(activity.descricao!)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 18),
                          const SizedBox(width: 8),
                          Text(activity.categoriaDisplayName),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${activity.dataHora.day}/${activity.dataHora.month}/${activity.dataHora.year} '
                            '${activity.dataHora.hour.toString().padLeft(2, '0')}:'
                            '${activity.dataHora.minute.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                      if (activity.duracao != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer, size: 18),
                            const SizedBox(width: 8),
                            Text('${activity.duracao} minutos'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _receivedActivity = null;
              });
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveActivity(activity);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveActivity(Atividade activity) async {
    try {
      final provider = Provider.of<AtividadeProvider>(context, listen: false);
      await provider.addAtividade(activity);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Atividade adicionada com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Erro ao salvar atividade: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          'Não foi possível receber a atividade. '
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
        title: const Text('Receber via NFC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Instruções
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Como receber uma atividade:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('1. Toque no botão "Iniciar Recepção"'),
                    const SizedBox(height: 4),
                    const Text('2. Aproxime seu dispositivo do outro celular'),
                    const SizedBox(height: 4),
                    const Text('3. Aguarde a transferência da atividade'),
                    const SizedBox(height: 4),
                    const Text('4. Confirme se deseja adicionar a atividade'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Área de recepção NFC
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
                    ] else if (_isReceiving) ...[
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
                                color: Colors.blue.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.nfc,
                                size: 60,
                                color: Colors.blue,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Aguardando atividade...',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aproxime o dispositivo que está transmitindo',
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.download,
                          size: 60,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Pronto para receber',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toque no botão abaixo para iniciar a recepção',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Botão de ação
            if (_nfcAvailable && !_isReceiving)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startReceiving,
                  icon: const Icon(Icons.download),
                  label: const Text('Iniciar Recepção'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

            if (_isReceiving)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await NfcService.stopSession();
                    setState(() {
                      _isReceiving = false;
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
