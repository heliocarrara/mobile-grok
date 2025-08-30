import 'package:json_annotation/json_annotation.dart';

part 'configuracao.g.dart';

@JsonSerializable()
class Configuracao {
  final int? id;
  final String chave;
  final String valor;

  Configuracao({
    this.id,
    required this.chave,
    required this.valor,
  });

  factory Configuracao.fromJson(Map<String, dynamic> json) => _$ConfiguracaoFromJson(json);
  Map<String, dynamic> toJson() => _$ConfiguracaoToJson(this);

  Configuracao copyWith({
    int? id,
    String? chave,
    String? valor,
  }) {
    return Configuracao(
      id: id ?? this.id,
      chave: chave ?? this.chave,
      valor: valor ?? this.valor,
    );
  }
}
