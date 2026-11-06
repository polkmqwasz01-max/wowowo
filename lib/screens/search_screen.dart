import 'package:flutter/material.dart';

import '../core/theme/app_theme_colors.dart';
import '../models/news.dart';
import '../repositories/news_repository.dart';
import 'news_detail_screen.dart';
import 'search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final NewsRepository _newsRepository = NewsRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;

  late Future<List<News>> _newsFuture;

  bool _showAllNews = false;

  static const List<String> _popularSearches = [
    'Zcash',
    'XRP',
    'Solana',
    'Ethereum',
    'ETF',
    'Fed Rate',
    'BnB',
    'DeFi',
  ];

  AppThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()!;
  }

  Map<String, dynamic> _getRandomMarketStatus(
      BuildContext context, String term, int index) {
    final colors = _colors(context);
    final hash = term.hashCode + index;

    final statuses = [
      {
        'label': 'High Vol',
        'icon': Icons.north_east_rounded,
        'color': colors.accent,
        'bg': colors.accent.withValues(alpha: 0.12),
      },
      {
        'label': 'Bullish',
        'icon': Icons.trending_up_rounded,
        'color': colors.accent,
        'bg': colors.accent.withValues(alpha: 0.12),
      },
      {
        'label': 'Hot',
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.orangeAccent,
        'bg': Colors.orangeAccent.withValues(alpha: 0.12),
      },
      {
        'label': 'Bearish',
        'icon': Icons.trending_down_rounded,
        'color': colors.bearish,
        'bg': colors.bearish.withValues(alpha: 0.12),
      },
      {
        'label': 'Breakout',
        'icon': Icons.bolt_rounded,
        'color': Colors.amberAccent,
        'bg': Colors.amberAccent.withValues(alpha: 0.12),
      },
    ];

    return statuses[hash.abs() % statuses.length];
  }

  @override
  void initState() {
    super.initState();
    _loadNews();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeSearchOverlayEntry();

    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    _searchFocusNode
      ..removeListener(_onFocusChanged)
      ..dispose();

    super.dispose();
  }

  void _loadNews() {
    _newsFuture = _newsRepository.getLatestNews(limit: 100);
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {});

    _searchOverlayEntry?.markNeedsBuild();
  }

  void _onFocusChanged() {
    if (!mounted) return;

    if (!_searchFocusNode.hasFocus) {
      _removeSearchOverlayEntry();
    }
  }

  void _showSearchOverlayEntry(List<News> news) {
    if (_searchOverlayEntry != null) {
      _searchOverlayEntry!.markNeedsBuild();
      return;
    }

    _searchOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            ModalBarrier(
              color: Colors.transparent,
              dismissible: true,
              onDismiss: () {
                _searchFocusNode.unfocus();
              },
            ),
            CompositedTransformFollower(
              link: _searchLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 58),
              child: Material(
                color: Colors.transparent,
                child: _buildSearchOverlayContent(context, news),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_searchOverlayEntry!);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadNews();
      _showAllNews = false;
    });
    try {
      await _newsFuture;
    } catch (_) {}
  }

  void _openNews(News news) {
    _searchFocusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(news: news),
      ),
    );
  }

  void _openSearchResults(String query, List<News> news) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    _searchFocusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(query: trimmedQuery),
      ),
    );
  }

  void _selectPopularSearch(String value, List<News> news) {
    _searchController
      ..text = value
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: value.length),
      );

    _removeSearchOverlayEntry();
    _searchFocusNode.unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(query: value),
      ),
    );
  }

  void _removeSearchOverlayEntry() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context),
      body: FutureBuilder<List<News>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }
          if (snapshot.hasError) {
            return _buildErrorState(context);
          }

          final news = snapshot.data ?? [];
          if (news.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            color: colors.accent,
            backgroundColor: colors.card,
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 950;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 16,
                    vertical: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1600,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBarAndSearch(context, news),
                          const SizedBox(height: 20),
                          _buildMarketSummaryMetrics(context, news),
                          const SizedBox(height: 24),
                          isDesktop
                              ? _buildDesktopMainGrid(
                                  context,
                                  news,
                                  constraints.maxWidth,
                                )
                              : _buildMobileLayout(context, news),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

PreferredSizeWidget _buildAppBar(BuildContext context) {
  final colors = _colors(context);

  return AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: colors.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    titleSpacing: 24,
    title: Row(
      children: [
        // Branding Icon Badge
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colors.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            Icons.search_rounded,
            color: colors.accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Typography Title & Status
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'INTELLIGENCE ',
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'HUB',
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color: colors.accent,
                  size: 5,
                ),
                const SizedBox(width: 4),
                Text(
                  'SEARCH & SIGNALS',
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildTopBarAndSearch(BuildContext context, List<News> news) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        return isWide
            ? Row(
                children: [
                  Expanded(
                    child: _buildIntro(context),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildSearchArea(context, news),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntro(context),
                  const SizedBox(height: 16),
                  _buildSearchArea(context, news),
                ],
              );
      },
    );
  }

  Widget _buildIntro(BuildContext context) {
    final colors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: colors.accent, size: 6),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE FEED',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Crypto Market Signals',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchArea(BuildContext context, List<News> news) {
    final colors = _colors(context);

    return CompositedTransformTarget(
      link: _searchLayerLink,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.accent.withValues(alpha: 0.05),
              blurRadius: 15,
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 14,
          ),
          cursorColor: colors.accent,
          textInputAction: TextInputAction.search,
          onTap: () {
            _showSearchOverlayEntry(news);
          },
          onChanged: (_) {
            if (_searchOverlayEntry == null) {
              _showSearchOverlayEntry(news);
            } else {
              _searchOverlayEntry!.markNeedsBuild();
            }

            setState(() {});
          },
          onSubmitted: (value) {
            _openSearchResults(value, news);
          },
          decoration: InputDecoration(
            hintText: 'Search assets, keywords, news...',
            hintStyle: TextStyle(
              color: colors.secondaryText,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colors.accent,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _searchFocusNode.requestFocus();

                      if (_searchOverlayEntry == null) {
                        _showSearchOverlayEntry(news);
                      } else {
                        _searchOverlayEntry!.markNeedsBuild();
                      }

                      setState(() {});
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.secondaryText,
                      size: 18,
                    ),
                  )
                : null,
            filled: true,
            fillColor: colors.card,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colors.accent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOverlayContent(BuildContext context, List<News> news) {
    final colors = _colors(context);
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildSearchQueryPanel(context, query, news),
    );
  }

  Widget _buildSearchQueryPanel(
      BuildContext context, String query, List<News> news) {
    final colors = _colors(context);
    final matches = _sortedNews(news)
        .where(
            (item) => item.title.toLowerCase().contains(query.toLowerCase()))
        .take(3)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final match in matches)
            InkWell(
              onTap: () => _openNews(match),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: colors.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.primaryText, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _openSearchResults(query, news),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'See all results for "$query"',
                    style: TextStyle(
                        color: colors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMarketSummaryMetrics(BuildContext context, List<News> news) {
    final colors = _colors(context);
    final highImpCount = news.where((n) => (n.importance ?? 0) >= 8).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricTile(context, 'Total Signals', '${news.length}',
              Icons.article_outlined, colors.accent),
          _buildDivider(context),
          _buildMetricTile(context, 'High Impact', '$highImpCount',
              Icons.bolt_rounded, Colors.amberAccent),
          _buildDivider(context),
          _buildMetricTile(context, 'Sentiment', 'Bullish 68%',
              Icons.show_chart_rounded, colors.accent),
          _buildDivider(context),
          _buildMetricTile(context, 'Top Asset', 'BTC/USDT',
              Icons.currency_bitcoin_rounded, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, String label, String value,
      IconData icon, Color color) {
    final colors = _colors(context);

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: colors.secondaryText, fontSize: 11)),
            Text(value,
                style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final colors = _colors(context);
    return Container(height: 24, width: 1, color: colors.border);
  }

// Gantikan method _buildDesktopMainGrid di SearchScreen dengan:
Widget _buildDesktopMainGrid(
    BuildContext context, List<News> news, double screenWidth) {
  final sortedNews = _sortedNews(news);
  final visibleNews =
      _showAllNews ? sortedNews : sortedNews.take(12).toList();
  final gridColumns = screenWidth > 1400 ? 3 : 2;

  return SizedBox(
    height: MediaQuery.of(context).size.height - 180,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SCROLLABLE LEFT COLUMN
        Expanded(
          flex: 9,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(right: 16, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                    context,
                    title: 'Market Highlights',
                    subtitle: 'Curated signals sorted by impact'),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: visibleNews.length,
                  itemBuilder: (context, index) {
                    return _buildRichGridCard(
                        context, visibleNews[index], index + 1);
                  },
                ),
                const SizedBox(height: 20),
                _buildMoreButton(context, news),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),

        // FIXED RIGHT SIDEBAR
        SizedBox(
          width: 340,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildPopularSearchPanel(context, news),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Gantikan method _buildMobileLayout di SearchScreen untuk Hirarki Visual yang Lebih Rapi:
Widget _buildMobileLayout(BuildContext context, List<News> news) {
  final sortedNews = _sortedNews(news);
  final visibleNews =
      _showAllNews ? sortedNews : sortedNews.take(6).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildPopularSearchPanel(context, news),
      const SizedBox(height: 24),
      _buildSectionHeader(
          context,
          title: 'Market Highlights',
          subtitle: 'Curated signals sorted by impact'),
      const SizedBox(height: 14),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visibleNews.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          return _buildRichGridCard(
              context, visibleNews[index], index + 1);
        },
      ),
      const SizedBox(height: 20),
      _buildMoreButton(context, news),
    ],
  );
}

  Widget _buildRichGridCard(BuildContext context, News news, int index) {
    final colors = _colors(context);
    final importance = news.importance ?? 1;
    final isHighImpact = importance >= 7;

    final imageUrl = news.imageSeed.startsWith('http')
        ? news.imageSeed
        : 'https://picsum.photos/seed/${Uri.encodeComponent(news.imageSeed)}/800/450';

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
              color: isHighImpact
                  ? colors.accent.withValues(alpha: 0.25)
                  : colors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: AspectRatio(
                      aspectRatio: 2.35,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return Container(
                            color: colors.elevated,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: colors.secondaryText,
                                size: 32,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;

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
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.30),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: colors.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '#${index.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: isHighImpact
                                ? Colors.amberAccent
                                : colors.secondaryText,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$importance/10',
                            style: TextStyle(
                              color: isHighImpact
                                  ? Colors.amberAccent
                                  : colors.primaryText,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: _buildSentimentTag(context, importance),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildChip(context, '#Crypto'),
                        _buildChip(context, '#Market'),
                        if (isHighImpact) _buildChip(context, '#Breaking'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      news.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (news.introduction.trim().isNotEmpty)
                      Text(
                        news.introduction.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: colors.border,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: colors.secondaryText,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(news.generatedAt),
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.visibility_outlined,
                          color: colors.secondaryText,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(importance * 120) + 340}',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: colors.accent,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentimentTag(BuildContext context, int importance) {
    final colors = _colors(context);

    Color bg = colors.secondaryText.withValues(alpha: 0.15);
    Color fg = colors.secondaryText;
    String label = 'NEUTRAL';

    if (importance >= 7) {
      bg = colors.accent.withValues(alpha: 0.15);
      fg = colors.accent;
      label = 'BULLISH';
    } else if (importance <= 3) {
      bg = colors.bearish.withValues(alpha: 0.15);
      fg = colors.bearish;
      label = 'BEARISH';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    final colors = _colors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(color: colors.secondaryText, fontSize: 10)),
    );
  }

  Widget _buildSectionHeader(BuildContext context,
      {required String title, required String subtitle}) {
    final colors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: colors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: TextStyle(color: colors.secondaryText, fontSize: 12)),
      ],
    );
  }

  Widget _buildMoreButton(BuildContext context, List<News> news) {
    final colors = _colors(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => setState(() => _showAllNews = !_showAllNews),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(_showAllNews ? 'SHOW LESS' : 'LOAD MORE SIGNALS',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildPopularSearchPanel(BuildContext context, List<News> news) {
    final colors = _colors(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded,
                      color: colors.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Trending Assets',
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              for (int i = 0; i < _popularSearches.length; i++) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        _selectPopularSearch(_popularSearches[i], news),
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i < 3
                                    ? colors.accent
                                    : colors.secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _popularSearches[i],
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final status = _getRandomMarketStatus(
                                  context, _popularSearches[i], i);

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: status['bg'] as Color,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (status['color'] as Color)
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      status['icon'] as IconData,
                                      color: status['color'] as Color,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status['label'] as String,
                                      style: TextStyle(
                                        color: status['color'] as Color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: colors.secondaryText,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (i < _popularSearches.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colors = _colors(context);
    return Center(
        child: CircularProgressIndicator(color: colors.accent, strokeWidth: 2));
  }

  Widget _buildErrorState(BuildContext context) {
    final colors = _colors(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colors.secondaryText, size: 40),
          const SizedBox(height: 12),
          Text('Error loading data', style: TextStyle(color: colors.primaryText)),
          ElevatedButton(
              onPressed: () => setState(_loadNews),
              child: const Text('RETRY')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = _colors(context);
    return Center(
        child: Text('No news available',
            style: TextStyle(color: colors.secondaryText)));
  }

  List<News> _sortedNews(List<News> news) {
    return List<News>.from(news)
      ..sort((a, b) => (b.importance ?? 0).compareTo(a.importance ?? 0));
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}