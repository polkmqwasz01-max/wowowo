class News {
  final int id;
  final int coinId;
  final int snapshotId;
  final String title;
  final String imageSeed;
  final String introduction;
  final String body;
  final String conclusion;
  final String? sentiment;
  final int? importance;
  final DateTime generatedAt;
  final DateTime createdAt;

  const News({
    required this.id,
    required this.coinId,
    required this.snapshotId,
    required this.title,
    required this.imageSeed,
    required this.introduction,
    required this.body,
    required this.conclusion,
    this.sentiment,
    this.importance,
    required this.generatedAt,
    required this.createdAt,
  });

  factory News.fromMap(Map<String, dynamic> map) {
    return News(
      id: (map['id'] as num).toInt(),
      coinId: (map['coin_id'] as num).toInt(),
      snapshotId: (map['snapshot_id'] as num).toInt(),
      title: map['title'] as String,
      imageSeed: map['image_seed'] as String,
      introduction: map['introduction'] as String,
      body: map['body'] as String,
      conclusion: map['conclusion'] as String,
      sentiment: map['sentiment'] as String?,
      importance: (map['importance'] as num?)?.toInt(),
      generatedAt: DateTime.parse(map['generated_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
