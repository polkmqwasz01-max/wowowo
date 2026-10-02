class MarketSnapshot {
  final int id;
  final int coinId;
  final double? priceUsd;
  final double? marketCap;
  final double? volume24h;
  final double? priceChange1h;
  final double? priceChange24h;
  final double? priceChange7d;
  final DateTime snapshotAt;
  final DateTime createdAt;

  const MarketSnapshot({
    required this.id,
    required this.coinId,
    this.priceUsd,
    this.marketCap,
    this.volume24h,
    this.priceChange1h,
    this.priceChange24h,
    this.priceChange7d,
    required this.snapshotAt,
    required this.createdAt,
  });

  factory MarketSnapshot.fromMap(Map<String, dynamic> map) {
    return MarketSnapshot(
      id: (map['id'] as num).toInt(),
      coinId: (map['coin_id'] as num).toInt(),
      priceUsd: (map['price_usd'] as num?)?.toDouble(),
      marketCap: (map['market_cap'] as num?)?.toDouble(),
      volume24h: (map['volume_24h'] as num?)?.toDouble(),
      priceChange1h: (map['price_change_1h'] as num?)?.toDouble(),
      priceChange24h: (map['price_change_24h'] as num?)?.toDouble(),
      priceChange7d: (map['price_change_7d'] as num?)?.toDouble(),
      snapshotAt: DateTime.parse(map['snapshot_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
