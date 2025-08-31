import 'package:json_annotation/json_annotation.dart';

part 'atividade.g.dart';

enum CategoriaEnum {
  faculdade,
  casa,
  lazer,
  alimentacao,
  financas,
  trabalho,
  saude,
  outros;

  String get displayName {
    switch (this) {
      case CategoriaEnum.faculdade:
        return 'Faculdade';
      case CategoriaEnum.casa:
        return 'Casa';
      case CategoriaEnum.lazer:
        return 'Lazer';
      case CategoriaEnum.alimentacao:
        return 'Alimentação';
      case CategoriaEnum.financas:
        return 'Finanças';
      case CategoriaEnum.trabalho:
        return 'Trabalho';
      case CategoriaEnum.saude:
        return 'Saúde';
      case CategoriaEnum.outros:
        return 'Outros';
    }
  }

  String get name => toString().split('.').last;
  String get categoriaDisplayName => displayName;
}

enum RepeticaoEnum {
  nenhuma,
  diaria,
  semanal,
  mensal;

  String get displayName {
    switch (this) {
      case RepeticaoEnum.nenhuma:
        return 'Nenhuma';
      case RepeticaoEnum.diaria:
        return 'Diária';
      case RepeticaoEnum.semanal:
        return 'Semanal';
      case RepeticaoEnum.mensal:
        return 'Mensal';
    }
  }

  String get repeticaoDisplayName => displayName;
}

enum NotificationTiming {
  none,
  onTime,
  fifteenMinBefore,
  thirtyMinBefore,
  oneHourBefore,
  oneDayBefore;

  String get displayName {
    switch (this) {
      case NotificationTiming.none:
        return 'Sem notificação';
      case NotificationTiming.onTime:
        return 'No horário';
      case NotificationTiming.fifteenMinBefore:
        return '15 minutos antes';
      case NotificationTiming.thirtyMinBefore:
        return '30 minutos antes';
      case NotificationTiming.oneHourBefore:
        return '1 hora antes';
      case NotificationTiming.oneDayBefore:
        return '1 dia antes';
    }
  }

  Duration? get duration {
    switch (this) {
      case NotificationTiming.none:
        return null;
      case NotificationTiming.onTime:
        return Duration.zero;
      case NotificationTiming.fifteenMinBefore:
        return const Duration(minutes: 15);
      case NotificationTiming.thirtyMinBefore:
        return const Duration(minutes: 30);
      case NotificationTiming.oneHourBefore:
        return const Duration(hours: 1);
      case NotificationTiming.oneDayBefore:
        return const Duration(days: 1);
    }
  }
}

@JsonSerializable()
class Atividade { // para campos dinâmicos

  Atividade({
    this.id,
    required this.titulo,
    this.descricao,
    required this.categoria,
    required this.dataHora,
    this.duracao,
    this.concluida = false,
    this.repeticao = RepeticaoEnum.nenhuma,
    this.prioridade = 3,
    this.meta,
    this.jsonExtra,
    this.notificationTiming = NotificationTiming.fifteenMinBefore,
  });

  factory Atividade.fromJson(Map<String, dynamic> json) => _$AtividadeFromJson(json);
  final int? id;
  final String titulo;
  final String? descricao;
  final CategoriaEnum categoria;
  final DateTime dataHora;
  final int? duracao; // em minutos
  final bool concluida;
  final RepeticaoEnum repeticao;
  final int prioridade; // 1-5
  final String? meta;
  final String? jsonExtra;
  final NotificationTiming notificationTiming;
  Map<String, dynamic> toJson() => _$AtividadeToJson(this);

  Atividade copyWith({
    int? id,
    String? titulo,
    String? descricao,
    CategoriaEnum? categoria,
    DateTime? dataHora,
    int? duracao,
    bool? concluida,
    RepeticaoEnum? repeticao,
    int? prioridade,
    String? meta,
    String? jsonExtra,
    NotificationTiming? notificationTiming,
  }) => Atividade(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      dataHora: dataHora ?? this.dataHora,
      duracao: duracao ?? this.duracao,
      concluida: concluida ?? this.concluida,
      repeticao: repeticao ?? this.repeticao,
      prioridade: prioridade ?? this.prioridade,
      meta: meta ?? this.meta,
      jsonExtra: jsonExtra ?? this.jsonExtra,
      notificationTiming: notificationTiming ?? this.notificationTiming,
    );

  String get categoriaDisplayName => categoria.displayName;
  String get repeticaoDisplayName => repeticao.displayName;
}
