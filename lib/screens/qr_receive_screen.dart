import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/atividade.dart';
import '../providers/atividade_provider.dart';
import '../services/qr_sharing_service.dart';

class QrReceiveScreen extends StatefulWidget {
  const QrReceiveScreen({Key? key}) : super(key: key);

  @override
  State<QrReceiveScreen> createState() => _QrReceiveScreenState();
}

class _QrReceiveScreenState extends State<QrReceiveScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isProcessing = false;
  bool _showScanner = false;
  Atividade? _scannedActivity;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    _textController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _handleQrData() async {
    final qrData = _textController.text.trim();
    
    if (qrData.isEmpty) {
      _showErrorDialog('Campo vazio', 'Por favor, cole o código QR no campo de texto.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    if (!QrSharingService.isValidQrData(qrData)) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('QR Code inválido', 
          'Este código não contém uma atividade válida do Mobile Grok.');
      return;
    }

    final activity = QrSharingService.decodeQrData(qrData);
    if (activity == null) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Erro ao processar', 
          'Não foi possível processar os dados da atividade.');
      return;
    }

    setState(() {
      _isProcessing = false;
      _scannedActivity = activity;
    });

    _showActivityDialog(activity);
  }

  void _handleScannedData(String qrData) {
    if (!QrSharingService.isValidQrData(qrData)) {
      _showErrorDialog('QR Code inválido', 
          'Este QR Code não contém uma atividade válida do Mobile Grok.');
      return;
    }

    final activity = QrSharingService.decodeQrData(qrData);
    if (activity == null) {
      _showErrorDialog('Erro ao processar', 
          'Não foi possível processar os dados da atividade.');
      return;
    }

    setState(() {
      _showScanner = false;
      _scannedActivity = activity;
    });

    _showActivityDialog(activity);
  }

  void _showActivityDialog(Atividade activity) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.green),
            SizedBox(width: 8),
            Text('Atividade Recebida'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deseja adicionar esta atividade ao seu calendário?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (activity.descricao.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      activity.descricao,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.dataHora.day}/${activity.dataHora.month}/${activity.dataHora.year} às ${activity.dataHora.hour.toString().padLeft(2, '0')}:${activity.dataHora.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanning();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _saveActivity(activity);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
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
      
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorDialog('Erro ao salvar', 
          'Não foi possível adicionar a atividade: $e');
      _resetScanning();
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanning();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receber via QR Code'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showScanner = !_showScanner;
              });
            },
            icon: Icon(_showScanner ? Icons.keyboard : Icons.qr_code_scanner),
          ),
        ],
      ),
      body: _showScanner ? _buildScanner() : _buildTextInput(),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                Icons.qr_code_scanner,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Posicione o QR Code dentro da área de escaneamento',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Scanner
        Expanded(
          child: MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScannedData(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
        ),
        
        // Footer com controles
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => cameraController.toggleTorch(),
                    icon: const Icon(Icons.flash_on),
                    iconSize: 32,
                  ),
                  IconButton(
                    onPressed: () => cameraController.switchCamera(),
                    icon: const Icon(Icons.flip_camera_android),
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Aponte a câmera para o QR Code gerado pelo outro dispositivo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instruções
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Como receber:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Use o botão da câmera no topo para escanear QR Code\n'
                  '• Ou copie e cole o texto do QR Code no campo abaixo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Campo de texto
          TextField(
            controller: _textController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Cole o código QR aqui',
              hintText: 'MGROK_ACTIVITY:{"titulo":"..."}',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _textController.text = data!.text!;
                  }
                },
                icon: const Icon(Icons.paste),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botão processar
          ElevatedButton(
            onPressed: _isProcessing ? null : _handleQrData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isProcessing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Processando...'),
                    ],
                  )
                : const Text(
                    'Processar QR Code',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
}
