import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coin.dart';

class CoinRepository {
  final SupabaseClient _client;

  CoinRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<Coin?> getCoinById(int coinId) async {
    final response = await _client
        .from('coins')
        .select()
        .eq('id', coinId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Coin.fromMap(Map<String, dynamic>.from(response));
  }

  Future<List<Coin>> getAllCoins() async {
    final response = await _client
        .from('coins')
        .select();

    return (response as List)
        .map(
          (row) => Coin.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }
}
