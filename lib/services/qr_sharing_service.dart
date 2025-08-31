import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/atividade.dart';

class QrSharingService {
  static const String _activityPrefix = 'MGROK_ACTIVITY:';
  
  /// Gera dados QR para uma atividade
  static String generateQrData(Atividade atividade) {
    try {
      final activityJson = atividade.toJson();
      // Remove o ID para criar uma nova atividade no dispositivo receptor
      activityJson.remove('id');
      final activityString = '$_activityPrefix${jsonEncode(activityJson)}';
      return activityString;
    } catch (e) {
      debugPrint('Erro ao gerar dados QR: $e');
      return '';
    }
  }
  
  /// Decodifica dados QR para uma atividade
  static Atividade? decodeQrData(String qrData) {
    try {
      if (!qrData.startsWith(_activityPrefix)) {
        debugPrint('QR Code não contém uma atividade válida');
        return null;
      }
      
      final activityJson = qrData.substring(_activityPrefix.length);
      final activityMap = jsonDecode(activityJson) as Map<String, dynamic>;
      
      return Atividade.fromJson(activityMap);
    } catch (e) {
      debugPrint('Erro ao decodificar dados QR: $e');
      return null;
    }
  }
  
  /// Verifica se os dados QR são válidos
  static bool isValidQrData(String qrData) {
    return qrData.startsWith(_activityPrefix);
  }
}
