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

@JsonSerializable()
class Atividade {
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
  final String? jsonExtra; // para campos dinâmicos

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
  });

  factory Atividade.fromJson(Map<String, dynamic> json) => _$AtividadeFromJson(json);
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
  }) {
    return Atividade(
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
    );
  }

  String get categoriaDisplayName => categoria.displayName;
  String get repeticaoDisplayName => repeticao.displayName;
}
