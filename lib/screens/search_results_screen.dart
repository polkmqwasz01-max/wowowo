import 'package:flutter/material.dart';

import '../core/theme/app_theme_colors.dart';
import '../models/news.dart';
import '../repositories/news_repository.dart';
import 'news_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({
    super.key,
    required this.query,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final NewsRepository _newsRepository = NewsRepository();

  late final TextEditingController _searchController;

  List<News> _allNews = [];
  List<News> _results = [];

  late String _currentQuery;

  bool _isLoading = true;
  bool _hasError = false;

  AppThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()!;
  }

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.query.trim();
    _searchController = TextEditingController(text: _currentQuery);
    _loadNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final news = await _newsRepository.getLatestNews(limit: 100);
      if (!mounted) return;

      setState(() {
        _allNews = news;
        _results = _filterNews(_currentQuery);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allNews = [];
        _results = [];
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  List<News> _filterNews(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = normalizedQuery.isEmpty
        ? List<News>.from(_allNews)
        : _allNews.where((news) {
            return news.title.toLowerCase().contains(normalizedQuery);
          }).toList();

    filtered.sort((a, b) => (b.importance ?? 0).compareTo(a.importance ?? 0));
    return filtered;
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    setState(() {
      _currentQuery = query;
      _results = _filterNews(query);
    });
  }

  void _openNews(News news) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.primaryText, size: 18),
        ),
        title: Text(
          'SEARCH INTELLIGENCE',
          style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final gridColumns = constraints.maxWidth > 1300 ? 3 : 2;

          if (_isLoading) return _buildLoadingState(context);
          if (_hasError) return _buildErrorState(context);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 16, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchField(context),
                    const SizedBox(height: 24),
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _results.isEmpty
                        ? _buildEmptyState(context)
                        : (isDesktop
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridColumns,
                                  childAspectRatio: 2.5,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _results.length,
                                itemBuilder: (context, index) =>
                                    _buildRichResultCard(
                                        context, _results[index], index + 1),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _results.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) =>
                                    _buildRichResultCard(
                                        context, _results[index], index + 1),
                              )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final colors = _colors(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _performSearch(),
        style: TextStyle(color: colors.primaryText, fontSize: 14),
        cursorColor: colors.accent,
        decoration: InputDecoration(
          hintText: 'Search asset or topic...',
          hintStyle: TextStyle(color: colors.secondaryText),
          prefixIcon: Icon(Icons.search_rounded, color: colors.accent),
          suffixIcon: IconButton(
            onPressed: () {
              _searchController.clear();
              _performSearch();
            },
            icon: Icon(Icons.close_rounded, color: colors.secondaryText),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentQuery.isEmpty
              ? 'All Results'
              : 'Search Results for "$_currentQuery"',
          style: TextStyle(
              color: colors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text('${_results.length} results found',
            style: TextStyle(color: colors.secondaryText, fontSize: 12)),
      ],
    );
  }

  Widget _buildRichResultCard(BuildContext context, News news, int number) {
    final colors = _colors(context);
    final importance = news.importance ?? 1;

    final sentiment = news.sentiment?.toUpperCase() ?? 'NEUTRAL';

    Color sentimentColor;
    Color sentimentBackground;

    switch (sentiment) {
      case 'BULLISH':
        sentimentColor = colors.accent;
        sentimentBackground = colors.accent.withValues(alpha: 0.10);
        break;

      case 'BEARISH':
        sentimentColor = colors.bearish;
        sentimentBackground = colors.bearish.withValues(alpha: 0.10);
        break;

      default:
        sentimentColor = Colors.blueAccent;
        sentimentBackground = Colors.blueAccent.withValues(alpha: 0.10);
    }

    final isHighImpact = importance >= 7;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openNews(news),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 145,
                    height: 135,
                    child: _buildNewsThumbnail(context, news),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 135,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildResultBadge(
                              '#${number.toString().padLeft(2, '0')}',
                              color: colors.accent,
                            ),
                            const SizedBox(width: 6),
                            _buildResultBadge(
                              sentiment,
                              color: sentimentColor,
                              backgroundColor: sentimentBackground,
                            ),
                            const Spacer(),
                            _buildImportanceBadge(context, importance),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Expanded(
                          child: Text(
                            news.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildResultTag(context, 'CRYPTO'),
                            const SizedBox(width: 5),
                            _buildResultTag(context, 'MARKET'),
                            if (isHighImpact) ...[
                              const SizedBox(width: 5),
                              _buildResultTag(
                                context,
                                'BREAKING',
                                color: Colors.orangeAccent,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: colors.secondaryText,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(news.generatedAt),
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.visibility_outlined,
                              color: colors.secondaryText,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(importance * 120) + 340}',
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 10,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: colors.accent,
                              size: 17,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsThumbnail(BuildContext context, News news) {
    final colors = _colors(context);

    final seed = Uri.encodeComponent(
      news.imageSeed.trim().isEmpty ? news.title : news.imageSeed,
    );

    final imageUrl = 'https://picsum.photos/seed/$seed/500/500';

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _buildNewsImagePlaceholder(context, news);
          },
          loadingBuilder: (
            context,
            child,
            loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }

            return Container(
              color: colors.elevated,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accent,
                  ),
                ),
              ),
            );
          },
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'NEWS',
              style: TextStyle(
                color: colors.accent,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsImagePlaceholder(BuildContext context, News news) {
    final colors = _colors(context);

    return Container(
      color: colors.elevated,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.article_rounded,
            color: colors.secondaryText,
            size: 42,
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Text(
              news.imageSeed.isNotEmpty
                  ? news.imageSeed.toUpperCase()
                  : 'NEWS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBadge(
    String text, {
    required Color color,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildResultTag(
    BuildContext context,
    String label, {
    Color? color,
  }) {
    final colors = _colors(context);
    final effectiveColor = color ?? colors.secondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: colors.border,
          width: 0.7,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildImportanceBadge(BuildContext context, int importance) {
    final colors = _colors(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: Colors.amberAccent,
            size: 11,
          ),
          const SizedBox(width: 3),
          Text(
            '$importance',
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colors = _colors(context);
    return Center(child: CircularProgressIndicator(color: colors.accent));
  }

  Widget _buildErrorState(BuildContext context) {
    final colors = _colors(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, color: colors.secondaryText, size: 40),
          const SizedBox(height: 12),
          Text('Error loading search results',
              style: TextStyle(color: colors.primaryText)),
          ElevatedButton(onPressed: _loadNews, child: const Text('RETRY')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = _colors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border)),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: colors.secondaryText, size: 40),
          const SizedBox(height: 12),
          Text('No matching news found.',
              style: TextStyle(
                  color: colors.primaryText, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}