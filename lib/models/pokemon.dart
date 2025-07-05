class Pokemon {
  final int id;
  final String nome;
  final String tipo;
  final String imagem;

  Pokemon({required this.id, required this.nome, required this.tipo, required this.imagem});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'imagem': imagem,
    };
  }
}
