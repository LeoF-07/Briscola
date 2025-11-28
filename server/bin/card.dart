class Card {
  final String seme;
  final int valore;

  Card({required this.seme, required this.valore});

  Map<String, dynamic> toJson() { // la chiave è sempre una stringa, le altre cose dei dynamic
    return {
      'seme': seme,
      'valore': valore,
    };
  }
}