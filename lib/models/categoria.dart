import 'package:json_annotation/json_annotation.dart';

part 'categoria.g.dart';

@JsonSerializable()
class Categoria {
  final int? id;
  final String nome;
  final String cor; // hex color
  final String icone; // icon reference

  Categoria({
    this.id,
    required this.nome,
    required this.cor,
    required this.icone,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => _$CategoriaFromJson(json);
  Map<String, dynamic> toJson() => _$CategoriaToJson(this);

  Categoria copyWith({
    int? id,
    String? nome,
    String? cor,
    String? icone,
  }) {
    return Categoria(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cor: cor ?? this.cor,
      icone: icone ?? this.icone,
    );
  }
}
