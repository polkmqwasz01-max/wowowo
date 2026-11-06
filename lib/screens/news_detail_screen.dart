import 'package:flutter/material.dart';

import '../core/theme/app_theme_colors.dart';
import '../models/news.dart';
import '../repositories/news_repository.dart';
import 'market_snapshot_detail_screen.dart';

class NewsDetailScreen extends StatefulWidget {
  final News news;

  const NewsDetailScreen({
    super.key,
    required this.news,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late final PageController _pageController;
  late final NewsRepository _newsRepository;
  late Future<List<News>> _relatedNewsFuture;

  static const blueColor = Color(0xFF42A5F5);

  AppThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()!;
  }

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _newsRepository = NewsRepository();

    _relatedNewsFuture = _loadRelatedNews();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ============================================================
  // IMAGE
  // ============================================================

  String _getImageUrl(
    String seed, {
    int width = 1200,
    int height = 700,
  }) {
    final cleanSeed = seed
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');

    return 'https://picsum.photos/seed/$cleanSeed/$width/$height';
  }

  // ============================================================
  // RELATED NEWS
  // ============================================================

  Future<List<News>> _loadRelatedNews() async {
    final allNews = await _newsRepository.getLatestNews(
      limit: 100,
    );

    final candidates = allNews.where(_isValidRelatedCandidate).toList();

    candidates.sort(_compareRelatedNews);

    return candidates.take(3).toList();
  }

  bool _isValidRelatedCandidate(News news) {
    if (identical(news, widget.news)) {
      return false;
    }

    final sameTitle =
        news.title.trim().toLowerCase() ==
        widget.news.title.trim().toLowerCase();

    final sameCoin =
        news.coinId == widget.news.coinId;

    final sameDate =
        news.generatedAt == widget.news.generatedAt;

    if (sameTitle && sameCoin) {
      return false;
    }

    if (sameTitle && sameDate) {
      return false;
    }

    return true;
  }

  int _compareRelatedNews(News a, News b) {
    final aScore = _relatedScore(a);
    final bScore = _relatedScore(b);

    return bScore.compareTo(aScore);
  }

  double _relatedScore(News news) {
    double score = 0;

    if (news.coinId == widget.news.coinId) {
      score += 100;
    }

    final currentSentiment = widget.news.sentiment?.toLowerCase();
    final candidateSentiment = news.sentiment?.toLowerCase();

    if (currentSentiment != null &&
        candidateSentiment != null &&
        currentSentiment == candidateSentiment) {
      score += 20;
    }

    score += (news.importance ?? 0) * 5;

    final ageHours = DateTime.now()
        .difference(news.generatedAt.toLocal())
        .inHours
        .clamp(0, 240);

    final recencyScore = 10 - (ageHours / 24);

    score += recencyScore.clamp(0, 10);

    return score;
  }

  // ============================================================
  // SENTIMENT
  // ============================================================

  Color _sentimentColor(BuildContext context, News news) {
    final colors = _colors(context);
    switch (news.sentiment?.toLowerCase()) {
      case 'bullish':
        return colors.accent;

      case 'bearish':
        return colors.bearish;

      default:
        return colors.secondaryText;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return _buildDesktopMainLayout(context);
          }

          return _buildMobileMainLayout(context);
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP LAYOUT (RELATED INTELLIGENCE FIXED ON RIGHT)
  // ============================================================

  Widget _buildDesktopMainLayout(BuildContext context) {
    final colors = _colors(context);

    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(context, true),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1450),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SISI KIRI: Hanya Berita & Market Snapshot yang saling bergeser lewat PageView
                      Expanded(
                        flex: 7,
                        child: PageView(
                          controller: _pageController,
                          physics: const PageScrollPhysics(),
                          children: [
                            _buildDesktopArticleScrollContent(context),
                            _buildMarketSnapshotContent(context),
                          ],
                        ),
                      ),

                      // GARIS PEMBATAS
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        color: colors.border,
                      ),

                      // SISI KANAN: Related Intelligence TETAP & TIDAK BERGESER
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: _buildRelatedSection(context, isDesktop: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _buildMobileMainLayout(BuildContext context) {
    return SafeArea(
      child: PageView(
        controller: _pageController,
        physics: const PageScrollPhysics(),
        children: [
          Column(
            children: [
              _buildAppBar(context, false),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 50),
                  child: _buildMobileArticleLayout(context),
                ),
              ),
            ],
          ),
          _buildMarketPage(context),
        ],
      ),
    );
  }

  Widget _buildDesktopArticleScrollContent(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArticleHeader(context, true),
          const SizedBox(height: 30),
          _buildHeroImage(context),
          const SizedBox(height: 36),
          _buildArticleContent(context),
          const SizedBox(height: 22),
          _buildSwipeHint(context),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMarketSnapshotContent(BuildContext context) {
    final colors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MARKET SNAPSHOT',
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            // Menggunakan Tab Switcher yang identik agar UI simetris dan konsisten
            _buildDesktopTabSwitcher(context),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: MarketSnapshotDetailScreen(
            key: ValueKey('market-${widget.news.coinId}'),
            coinId: widget.news.coinId,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar(BuildContext context, bool isDesktop) {
    final colors = _colors(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : 8,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colors.secondaryText,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isDesktop ? 'Back to News' : 'Back',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            'CripCheck',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (isDesktop) const SizedBox(width: 10),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE ARTICLE LAYOUT
  // ============================================================

  Widget _buildMobileArticleLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildArticleHeader(context, false),
        const SizedBox(height: 28),
        _buildHeroImage(context),
        const SizedBox(height: 34),
        _buildArticleContent(context),
        const SizedBox(height: 18),
        _buildSwipeHint(context),
        const SizedBox(height: 34),
        _buildRelatedSection(context, isDesktop: false),
      ],
    );
  }

  // ============================================================
  // ARTICLE HEADER & NAVIGATION
  // ============================================================

  Widget _buildArticleHeader(BuildContext context, bool isDesktop) {
    final colors = _colors(context);
    final news = widget.news;
    final sentimentColor = _sentimentColor(context, news);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NEWS DETAIL',
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            // Tombol Navigasi Alternatif (Tab Switcher) untuk Desktop
            if (isDesktop) _buildDesktopTabSwitcher(context),
          ],
        ),

        const SizedBox(height: 14),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (news.sentiment != null)
              _buildBadge(
                label: news.sentiment!.toUpperCase(),
                color: sentimentColor,
              ),
            if (news.importance != null)
              _buildBadge(
                label: 'IMPORTANCE ${news.importance}',
                color: blueColor,
              ),
          ],
        ),

        const SizedBox(height: 18),

        Text(
          news.title,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: isDesktop ? 36 : 28,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -0.8,
          ),
        ),

        const SizedBox(height: 14),

        _buildArticleMeta(context),

        if (!isDesktop) ...[
          const SizedBox(height: 20),
          _buildMarketNavigationHint(context, false),
        ],
      ],
    );
  }

  /// Alternative Navigation: Modern Segmented Switcher untuk Desktop
  Widget _buildDesktopTabSwitcher(BuildContext context) {
    final colors = _colors(context);

    return ListenableBuilder(
      listenable: _pageController,
      builder: (context, _) {
        final currentPage =
            _pageController.hasClients && (_pageController.page?.round() ?? 0) == 1
                ? 1
                : 0;

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabOption(
                context: context,
                label: 'Article',
                icon: Icons.article_outlined,
                isSelected: currentPage == 0,
                onTap: _goToNews,
              ),
              const SizedBox(width: 2),
              _buildTabOption(
                context: context,
                label: 'Market Snapshot',
                icon: Icons.show_chart_rounded,
                isSelected: currentPage == 1,
                onTap: _goToMarket,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = _colors(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: isSelected
              ? Border.all(color: colors.accent.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? colors.accent : colors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colors.primaryText : colors.secondaryText,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketNavigationHint(BuildContext context, bool isDesktop) {
    final colors = _colors(context);

    return Center(
      child: Text(
        'Swipe left to view market data',
        style: TextStyle(
          color: colors.secondaryText,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildArticleMeta(BuildContext context) {
    final colors = _colors(context);

    return Row(
      children: [
        Text(
          _formatDate(widget.news.generatedAt),
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '•',
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'CripCheck',
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ARTICLE CONTENT
  // ============================================================
Widget _buildArticleContent(BuildContext context) {
  final news = widget.news;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildArticleSection(context, content: news.introduction),
      _buildArticleSection(context, content: news.body),
      _buildArticleSection(context, content: news.conclusion),
    ],
  );
}

Widget _buildArticleSection(
  BuildContext context, {
  required String content,
}) {
  if (content.trim().isEmpty) {
    return const SizedBox.shrink();
  }

  final colors = _colors(context);

  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Text(
      content,
      style: TextStyle(
        color: colors.primaryText.withValues(alpha: 0.9), // Menggunakan tema warna primaryText
        fontSize: 15,
        height: 1.75,
      ),
    ),
  );
}

  // ============================================================
  // HERO IMAGE
  // ============================================================

  Widget _buildHeroImage(BuildContext context) {
    final colors = _colors(context);
    final imageUrl = _getImageUrl(
      widget.news.imageSeed,
      width: 1200,
      height: 700,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 8.5,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildImageLoading(context);
          },
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(context),
        ),
      ),
    );
  }

  Widget _buildImageLoading(BuildContext context) {
    final colors = _colors(context);

    return Container(
      color: colors.card,
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
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    final colors = _colors(context);

    return Container(
      color: colors.elevated,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_outlined,
              color: Color(0xFF66707C),
              size: 42,
            ),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SWIPE HINT
  // ============================================================

  Widget _buildSwipeHint(BuildContext context) {
    final colors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swipe_left_rounded,
            color: colors.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Swipe left to view Market Snapshot',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_rounded,
            color: colors.secondaryText,
            size: 15,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RELATED INTELLIGENCE
  // ============================================================

  Widget _buildRelatedSection(BuildContext context, {required bool isDesktop}) {
    return FutureBuilder<List<News>>(
      future: _relatedNewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildRelatedLoading(context, isDesktop: isDesktop);
        }

        if (snapshot.hasError) {
          return _buildRelatedError(context, isDesktop: isDesktop);
        }

        final relatedNews = snapshot.data ?? [];

        if (relatedNews.isEmpty) {
          return _buildRelatedEmpty(context, isDesktop: isDesktop);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRelatedHeader(context, isDesktop: isDesktop),
            const SizedBox(height: 16),
            Column(
              children: [
                for (int index = 0; index < relatedNews.length; index++) ...[
                  _buildRelatedCard(
                    context,
                    relatedNews[index],
                    isDesktop: isDesktop,
                  ),
                  if (index < relatedNews.length - 1)
                    const SizedBox(height: 14),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRelatedHeader(BuildContext context, {required bool isDesktop}) {
    final colors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: colors.accent,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Related Intelligence',
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'Continue reading related market stories',
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedCard(
    BuildContext context,
    News news, {
    required bool isDesktop,
  }) {
    final colors = _colors(context);
    final imageUrl = _getImageUrl(
      news.imageSeed,
      width: 700,
      height: 400,
    );

    final sentimentColor = _sentimentColor(context, news);

    return Card(
      color: colors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRelatedNews(news),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 8.5,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildCardImagePlaceholder(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (news.sentiment != null)
                        _buildSmallSentimentBadge(news, sentimentColor),
                      const Spacer(),
                      Text(
                        _formatDate(news.generatedAt),
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    news.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'READ STORY',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: colors.accent,
                        size: 12,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallSentimentBadge(News news, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        news.sentiment!.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildCardImagePlaceholder(BuildContext context) {
    final colors = _colors(context);

    return Container(
      color: colors.elevated,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Color(0xFF66707C),
          size: 30,
        ),
      ),
    );
  }

  Widget _buildRelatedLoading(BuildContext context, {required bool isDesktop}) {
    final colors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRelatedHeader(context, isDesktop: isDesktop),
          const SizedBox(height: 28),
          Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedEmpty(BuildContext context, {required bool isDesktop}) {
    final colors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRelatedHeader(context, isDesktop: isDesktop),
          const SizedBox(height: 22),
          Text(
            'No related stories available yet.',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedError(BuildContext context, {required bool isDesktop}) {
    final colors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRelatedHeader(context, isDesktop: isDesktop),
          const SizedBox(height: 22),
          Text(
            'Unable to load related stories.',
            style: TextStyle(color: colors.secondaryText, fontSize: 11),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              setState(() {
                _relatedNewsFuture = _loadRelatedNews();
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: colors.accent,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Retry',
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGE & MARKET PAGE
  // ============================================================

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMarketPage(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildMarketAppBar(context),
          Expanded(
            child: MarketSnapshotDetailScreen(
              key: ValueKey('market-${widget.news.coinId}'),
              coinId: widget.news.coinId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketAppBar(BuildContext context) {
    final colors = _colors(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          InkWell(
            onTap: _goToNews,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colors.secondaryText,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Back to News',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            'CripCheck',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE NAVIGATION
  // ============================================================

  void _goToNews() {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToMarket() {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _openRelatedNews(News news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(news: news),
      ),
    );
  }

  // ============================================================
  // DATE FORMATTING
  // ============================================================

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
  }
}