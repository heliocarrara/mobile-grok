import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/atividade.dart';

class NfcService {
  static const String _activityPrefix = 'MGROK_ACTIVITY:';
  
  /// Verifica se o NFC está disponível no dispositivo
  static Future<bool> isNfcAvailable() async {
    return false; // NFC desabilitado
  }

  /// Transmite uma atividade via NFC (dispositivo origem)
  static Future<bool> transmitActivity(Atividade atividade) async {
    debugPrint('NFC não disponível - use QR Code');
    return false;
  }

  /// Recebe uma atividade via NFC (dispositivo destino)
  static Future<Atividade?> receiveActivity() async {
    debugPrint('NFC não disponível - use QR Code');
    return null;
  }

  /// Para a sessão NFC atual
  static Future<void> stopSession({String? errorMessage}) async {
    debugPrint('NFC não disponível');
  }

  /// Verifica se o NFC está habilitado
  static Future<bool> isNfcEnabled() async {
    return false; // NFC desabilitado
  }
}
