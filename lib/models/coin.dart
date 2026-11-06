class Coin {
  final int id;
  final String coingeckoId;
  final String symbol;
  final String name;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Coin({
    required this.id,
    required this.coingeckoId,
    required this.symbol,
    required this.name,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Coin.fromMap(Map<String, dynamic> map) {
    return Coin(
      id: (map['id'] as num).toInt(),
      coingeckoId: map['coingecko_id'] as String,
      symbol: map['symbol'] as String,
      name: map['name'] as String,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
