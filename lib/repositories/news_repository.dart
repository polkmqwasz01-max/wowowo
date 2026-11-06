import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/news.dart';

class NewsRepository {
  final SupabaseClient _client;

  NewsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<News>> getLatestNews({int limit = 20}) async {
    final response = await _client
        .from('news')
        .select()
        .order('generated_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => News.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }
}
