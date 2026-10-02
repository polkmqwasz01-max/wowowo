import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/market_snapshot.dart';

class MarketSnapshotRepository {
  final SupabaseClient _client;

  MarketSnapshotRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<MarketSnapshot>> getSnapshotsForCoin(
    int coinId, {
    int limit = 100,
  }) async {
    final response = await _client
        .from('market_snapshots')
        .select()
        .eq('coin_id', coinId)
        .order('snapshot_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => MarketSnapshot.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<MarketSnapshot>> getHistoricalSnapshots(
    int coinId, {
    DateTime? from,
    DateTime? to,
    int limit = 1000,
  }) async {
    var query = _client.from('market_snapshots').select().eq('coin_id', coinId);

    if (from != null) {
      query = query.gte('snapshot_at', from.toIso8601String());
    }

    if (to != null) {
      query = query.lte('snapshot_at', to.toIso8601String());
    }

    final response = await query
        .order('snapshot_at', ascending: true)
        .limit(limit);

    return (response as List)
        .map((row) => MarketSnapshot.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

Future<List<MarketSnapshot>> getHistoricalSnapshotsByRange(
  int coinId, {
  required Duration range,
}) async {
  final now = DateTime.now().toUtc();
  final from = now.subtract(range);

  final estimatedPoints =
      (range.inMinutes / 20).ceil() + 10;

  final limit = estimatedPoints.clamp(100, 3000);

  debugPrint(
    'HISTORY RANGE: coinId=$coinId '
    'range=${range.inHours}h '
    'from=${from.toIso8601String()} '
    'to=${now.toIso8601String()} '
    'limit=$limit',
  );

  final snapshots = await getHistoricalSnapshots(
    coinId,
    from: from,
    to: now,
    limit: limit,
  );

  debugPrint(
    'HISTORY RESULT: coinId=$coinId '
    'count=${snapshots.length}',
  );

  if (snapshots.isNotEmpty) {
    debugPrint(
      'HISTORY ACTUAL RANGE: '
      '${snapshots.first.snapshotAt.toIso8601String()} '
      '-> '
      '${snapshots.last.snapshotAt.toIso8601String()}',
    );
  }

  return snapshots;
}

Future<MarketSnapshot?> getLatestSnapshot(int coinId) async {
  final response = await _client
      .from('market_snapshots')
      .select()
      .eq('coin_id', coinId)
      .order('snapshot_at', ascending: false)
      .limit(1)
      .maybeSingle();

  if (response == null) {
    debugPrint(
      'LATEST SNAPSHOT: coinId=$coinId => NULL',
    );
    return null;
  }

  debugPrint(
    'LATEST SNAPSHOT: coinId=$coinId '
    'rawMarketCap=${response['market_cap']} '
    'rawVolume=${response['volume_24h']} '
    'price=${response['price_usd']}',
  );

  final snapshot = MarketSnapshot.fromMap(
    Map<String, dynamic>.from(response),
  );

  debugPrint(
    'PARSED SNAPSHOT: coinId=$coinId '
    'marketCap=${snapshot.marketCap} '
    'volume=${snapshot.volume24h}',
  );

  return snapshot;
}

  Future<List<MarketSnapshot>> getHistoricalSnapshotsForCoins(
  List<int> coinIds, {
  DateTime? from,
  DateTime? to,
  int limit = 5000,
}) async {
  if (coinIds.isEmpty) {
    return [];
  }

  var query = _client
      .from('market_snapshots')
      .select()
      .inFilter('coin_id', coinIds);

  if (from != null) {
    query = query.gte(
      'snapshot_at',
      from.toIso8601String(),
    );
  }

  if (to != null) {
    query = query.lte(
      'snapshot_at',
      to.toIso8601String(),
    );
  }

  final response = await query
      .order(
        'snapshot_at',
        ascending: true,
      )
      .limit(limit);

  return (response as List)
      .map(
        (row) => MarketSnapshot.fromMap(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}

}
