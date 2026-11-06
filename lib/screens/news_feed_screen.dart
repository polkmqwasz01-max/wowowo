import 'package:flutter/material.dart';
import 'dart:async';

import '../core/theme/app_theme_colors.dart';
import '../models/coin.dart';
import '../models/market_snapshot.dart';
import '../models/news.dart';
import '../repositories/coin_repository.dart';
import '../repositories/market_snapshot_repository.dart';
import '../repositories/news_repository.dart';
import 'news_detail_screen.dart';
import '../controllers/notification_controller.dart';
import 'notification_screen.dart';

class NewsFeedScreen extends StatefulWidget {
  final ValueChanged<int>? onTabSelected; // Parameter callback untuk pindah tab

  const NewsFeedScreen({
    super.key,
    this.onTabSelected,
  });

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final NewsRepository _newsRepository = NewsRepository();
  final CoinRepository _coinRepository = CoinRepository();
  final MarketSnapshotRepository _marketRepository =
      MarketSnapshotRepository();
  final NotificationController _notificationController =
    NotificationController();

  int _unreadNotificationCount = 0;

  late Future<List<News>> _newsFuture;
  late Future<List<_RankedAsset>> _rankingFuture;

  String _selectedFilter = 'Latest';
  int _newsBlockRepeatCount = 1;
  int _desktopNewsCount = 12;

  AppThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()!;
  }

// Tambahkan di dalam _NewsFeedScreenState:
late final PageController _bannerPageController;
Timer? _bannerTimer;
int _currentBannerIndex = 0;

@override
void initState() {
  super.initState();
  _bannerPageController = PageController(initialPage: 0);
  _startBannerAutoScroll();
  _loadNews();
  _loadRanking();
  _loadUnreadNotificationCount();
}

void _startBannerAutoScroll() {
  _bannerTimer?.cancel();
  _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
    if (_bannerPageController.hasClients) {
      _currentBannerIndex = (_currentBannerIndex + 1) % 4; // Total 4 banner
      _bannerPageController.animateToPage(
        _currentBannerIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  });
}

@override
void dispose() {
  _bannerTimer?.cancel();
  _bannerPageController.dispose();
  super.dispose();
}

  void _loadNews() {
    _newsFuture = _newsRepository.getLatestNews(limit: 100);
  }

  void _loadRanking() {
    _rankingFuture = _loadRealRanking();
  }

Future<void> _loadUnreadNotificationCount() async {
  try {
    final state = await _notificationController.load();

    if (!mounted) {
      return;
    }

    setState(() {
      _unreadNotificationCount = state.unreadCount;
    });
  } catch (_) {
    // Jangan membuat NewsFeed gagal hanya karena notification gagal dimuat.
  }
}

  Future<List<_RankedAsset>> _loadRealRanking() async {
    final coins = await _coinRepository.getAllCoins();

    final results = await Future.wait(
      coins.map((coin) async {
        final snapshot = await _marketRepository.getLatestSnapshot(
          coin.id,
        );

        if (snapshot == null) {
          return null;
        }

        return _RankedAsset(
          coin: coin,
          snapshot: snapshot,
        );
      }),
    );

    final ranking = results.whereType<_RankedAsset>().toList();

    ranking.sort((a, b) {
      final aCap = a.snapshot.marketCap ?? 0;
      final bCap = b.snapshot.marketCap ?? 0;
      return bCap.compareTo(aCap);
    });

    return ranking.take(5).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _newsBlockRepeatCount = 1;
      _loadNews();
      _loadRanking();
    });

    try {
      await Future.wait([
        _newsFuture,
        _rankingFuture,
      ]);
    } catch (_) {}
  }

  void _retry() {
    setState(() {
      _loadNews();
      _loadRanking();
    });
  }

  List<News> _applyFilter(List<News> newsList) {
    final list = List<News>.from(newsList);

    switch (_selectedFilter) {
      case 'Importance':
        list.sort(
          (a, b) => (b.importance ?? 0).compareTo(
            a.importance ?? 0,
          ),
        );
        return list;

      case 'Bullish':
        return list
            .where(
              (n) => n.sentiment?.toLowerCase() == 'bullish',
            )
            .toList();

      case 'Bearish':
        return list
            .where(
              (n) => n.sentiment?.toLowerCase() == 'bearish',
            )
            .toList();

      case 'Latest':
      default:
        return list;
    }
  }

  String _getImageUrl(
    String seed, {
    int width = 900,
    int height = 500,
  }) {
    final cleanSeed = seed.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');

    return 'https://picsum.photos/seed/$cleanSeed/$width/$height';
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: colors.background,

          // APP BAR HANYA MOBILE
appBar: isDesktop
    ? null
    : AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            // Branding Logo Badge
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: colors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),

            // Typography Logo & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            Row(
              children: [
                Text(
                  'CRIP',
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'CHECK',
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
                      'INTELLIGENCE HUB',
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 8,
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
        actions: [
          _buildNotificationButton(context, colors),
          const SizedBox(width: 8),
        ],
      ),

          body: FutureBuilder<List<News>>(
            future: _newsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: colors.accent,
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(context);
              }

              final rawNews = snapshot.data ?? [];
              final newsList = _applyFilter(rawNews);

              if (newsList.isEmpty) {
                return _buildEmptyState(context);
              }

              if (isDesktop) {
                return _buildDesktopContent(context, newsList);
              }

              return _buildMobileContent(context, newsList);
            },
          ),
        );
      },
    );
  }

Widget _buildNotificationButton(
  BuildContext context,
  AppThemeColors colors,
) {
  final unreadCount = _unreadNotificationCount;

  return IconButton(
    onPressed: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationScreen(
            onUnreadCountChanged: (count) {
              if (!mounted) {
                return;
              }

              setState(() {
                _unreadNotificationCount = count;
              });
            },
          ),
        ),
      );

      // Refresh count ketika kembali dari NotificationScreen.
      _loadUnreadNotificationCount();
    },
    icon: Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.notifications_outlined,
          color: colors.primaryText,
        ),

        if (unreadCount > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.background,
                  width: 2,
                ),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

  Widget _buildDesktopContent(BuildContext context, List<News> newsList) {
    final colors = _colors(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      color: colors.accent,
      backgroundColor: colors.card,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          32,
          28,
          32,
          40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1500,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDesktopHeader(context),
                const SizedBox(height: 24),
                _buildFilterBar(context),
                const SizedBox(height: 24),
                _buildDesktopHeroGrid(context, newsList),
                const SizedBox(height: 24),
                _buildDesktopSecondSection(context, newsList),
                const SizedBox(height: 24),
                _buildDesktopNewsGrid(context, newsList),
                const SizedBox(height: 32),
                if (_desktopNewsCount < _desktopAvailableNewsCount(newsList))
                  _buildDesktopMoreNewsButton(context, newsList),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _desktopAvailableNewsCount(List<News> newsList) {
    if (newsList.length <= 5) {
      return 0;
    }

    return newsList.length - 5;
  }

  Widget _buildMobileContent(BuildContext context, List<News> newsList) {
    final colors = _colors(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      color: colors.accent,
      backgroundColor: colors.card,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterBar(context),
            const SizedBox(height: 20),
            _buildRankingSection(context),
            const SizedBox(height: 20),
            for (int blockIndex = 0;
                blockIndex < _newsBlockRepeatCount;
                blockIndex++) ...[
              _buildNewsFeedBlock(
                context: context,
                newsList: newsList,
                blockIndex: blockIndex,
              ),
              const SizedBox(height: 20),
            ],
            _buildMoreNewsButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSecondSection(
      BuildContext context, List<News> newsList) {
    final rankingWidth = 0.32;

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftWidth = constraints.maxWidth * rankingWidth;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: leftWidth,
              child: _buildRankingSection(context),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _buildDesktopHighlights(context, newsList),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopHighlights(BuildContext context, List<News> newsList) {
    final colors = _colors(context);
    final items = newsList.skip(5).take(4).toList();

    if (items.isEmpty) {
      return _buildBanner(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Latest Intelligence',
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${items.length} stories',
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.9,
          ),
          itemBuilder: (context, index) {
            return _buildSubCard(context, items[index]);
          },
        ),
      ],
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopHeader(BuildContext context) {
    final colors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.newspaper_rounded,
              color: colors.accent,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market News',
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Latest crypto market intelligence and analysis',
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: colors.accent,
                  size: 8,
                ),
                const SizedBox(width: 7),
                Text(
                  'LIVE MARKET',
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final colors = _colors(context);

    return Row(
      children: [
        Text(
          'News Feed',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 18),
        _buildChip(context, 'Latest'),
        _buildChip(context, 'Importance'),
        _buildChip(context, 'Bullish'),
        _buildChip(context, 'Bearish'),
      ],
    );
  }

  Widget _buildDesktopHeroGrid(BuildContext context, List<News> newsList) {
    if (newsList.isEmpty) {
      return const SizedBox.shrink();
    }

    final mainNews = newsList[0];

    final leftNews = newsList.length >= 3
        ? newsList.sublist(1, 3)
        : newsList.skip(1).toList();

    final rightNews = newsList.length >= 5
        ? newsList.sublist(3, 5)
        : newsList.skip(3).toList();

    return SizedBox(
      height: 520,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT
          Expanded(
            flex: 3,
            child: Column(
              children: [
                if (leftNews.isNotEmpty)
                  Expanded(
                    child: _buildDesktopSideCard(
                      context,
                      leftNews[0],
                    ),
                  ),
                if (leftNews.length > 1) ...[
                  const SizedBox(height: 14),
                  Expanded(
                    child: _buildDesktopSideCard(
                      context,
                      leftNews[1],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 16),

          // CENTER FEATURE
          Expanded(
            flex: 6,
            child: _buildFeaturedCard(context, mainNews),
          ),

          const SizedBox(width: 16),

          // RIGHT
          Expanded(
            flex: 3,
            child: Column(
              children: [
                if (rightNews.isNotEmpty)
                  Expanded(
                    child: _buildDesktopSideCard(
                      context,
                      rightNews[0],
                    ),
                  ),
                if (rightNews.length > 1) ...[
                  const SizedBox(height: 14),
                  Expanded(
                    child: _buildDesktopSideCard(
                      context,
                      rightNews[1],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildDesktopNewsGrid(BuildContext context, List<News> newsList) {
  final colors = _colors(context);

  if (newsList.length <= 5) {
    return const SizedBox.shrink();
  }

  final available = newsList.skip(5).toList();
  final visibleCount = _desktopNewsCount.clamp(0, available.length);
  final remaining = available.take(visibleCount).toList();

  if (remaining.isEmpty) {
    return const SizedBox.shrink();
  }

  // Pecah daftar berita menjadi chunk/block berisi 9 berita per siklus
  const chunkSize = 9;
  final List<List<News>> chunks = [];
  for (var i = 0; i < remaining.length; i += chunkSize) {
    chunks.add(
      remaining.sublist(
        i,
        i + chunkSize > remaining.length ? remaining.length : i + chunkSize,
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'More Market News',
        style: TextStyle(
          color: colors.primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 16),

      // Render setiap kelompok berita dengan tata letak yang dinamis
      for (int i = 0; i < chunks.length; i++) ...[
        _buildDesktopNewsChunk(context, chunks[i], isFirstChunk: i == 0),
        if (i < chunks.length - 1) const SizedBox(height: 28),
      ],
    ],
  );
}

// Helper untuk menyusun variasi tampilan per siklus berita
Widget _buildDesktopNewsChunk(
  BuildContext context,
  List<News> chunk, {
  required bool isFirstChunk,
}) {
  final firstGridBatch = chunk.take(4).toList();
  final hasLandscapeNews = chunk.length > 4;
  final landscapeNews = hasLandscapeNews ? chunk[4] : null;
  final secondGridBatch = chunk.length > 5 ? chunk.skip(5).toList() : <News>[];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 1. Grid batch pertama (max 4)
      if (firstGridBatch.isNotEmpty)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: firstGridBatch.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            return _buildGridNewsCard(context, firstGridBatch[index]);
          },
        ),

      // Tampilkan Banner Carousel hanya di chunk pertama agar tidak terlalu padat
      if (isFirstChunk) ...[
        const SizedBox(height: 28),
        _buildBanner(context),
      ],

      // 2. Tampilan Landscape Card (Penghancur ritme grid)
      if (landscapeNews != null) ...[
        const SizedBox(height: 28),
        _buildDesktopLandscapeNewsCard(context, landscapeNews),
      ],

      // 3. Grid batch kedua (sisanya dalam chunk)
      if (secondGridBatch.isNotEmpty) ...[
        const SizedBox(height: 28),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: secondGridBatch.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            return _buildGridNewsCard(context, secondGridBatch[index]);
          },
        ),
      ],
    ],
  );
}

// Helper Widget: Kartu Lanskap Editorial untuk Desktop
Widget _buildDesktopLandscapeNewsCard(BuildContext context, News news) {
  final colors = _colors(context);
  final imageUrl = _getImageUrl(
    news.imageSeed,
    width: 1000,
    height: 400,
  );

  return Card(
    color: colors.card,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: colors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _openNews(news),
      child: SizedBox(
        height: 180,
        child: Row(
          children: [
            SizedBox(
              width: 320,
              height: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _imagePlaceholder(context),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        _sentimentBadge(context, news),
                        const SizedBox(width: 8),
                        Text(
                          'EDITOR\'S PICK',
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'CripCheck • ${_formatDate(news.generatedAt)}',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Read Story',
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: colors.accent,
                          size: 14,
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
  );
}

Widget _buildDesktopMoreNewsButton(
  BuildContext context,
  List<News> newsList,
) {
  final colors = _colors(context);
  final available = _desktopAvailableNewsCount(newsList);

  if (_desktopNewsCount >= available) {
    return const SizedBox.shrink();
  }

  final remainingNewsCount = available - _desktopNewsCount;

  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                // Tambah 9 item setiap kali ditekan agar pas dengan siklus layout chunk
                _desktopNewsCount += 9;

                if (_desktopNewsCount > available) {
                  _desktopNewsCount = available;
                }
              });
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'LOAD MORE INTELLIGENCE',
                    style: TextStyle(
                      color: colors.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+$remainingNewsCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Showing $_desktopNewsCount of $available stories',
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
  // MOBILE
  // ============================================================

  Widget _buildNewsFeedBlock({
    required BuildContext context,
    required List<News> newsList,
    required int blockIndex,
  }) {
    if (newsList.isEmpty) {
      return const SizedBox.shrink();
    }

    const itemsPerBlock = 18;

    final offset = (blockIndex * itemsPerBlock) % newsList.length;

    List<News> getSlice(int start, int end) {
      if (newsList.isEmpty) {
        return [];
      }

      final result = <News>[];

      for (int i = start; i < end; i++) {
        result.add(
          newsList[(offset + i) % newsList.length],
        );
      }

      return result;
    }

    final mainCard1 = newsList[offset];

    final subCardsGroup1 = getSlice(1, 6);
    final subCardsGroup2 = getSlice(6, 8);

    final mainCard2 = newsList.length > 8
        ? newsList[(offset + 8) % newsList.length]
        : null;

    final miniCardsList = getSlice(9, 14);
    final subCardsGroup3 = getSlice(14, 17);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainCard(context, mainCard1),
        const SizedBox(height: 16),
        for (final item in subCardsGroup1) ...[
          _buildSubCard(context, item),
          const SizedBox(height: 12),
        ],
        _buildBanner(context),
        const SizedBox(height: 16),
        for (final item in subCardsGroup2) ...[
          _buildSubCard(context, item),
          const SizedBox(height: 12),
        ],
        if (mainCard2 != null) ...[
          _buildMainCard(context, mainCard2),
          const SizedBox(height: 16),
        ],
        if (miniCardsList.isNotEmpty) ...[
          _buildMiniCardHorizontalList(context, miniCardsList),
          const SizedBox(height: 16),
        ],
        for (final item in subCardsGroup3) ...[
          _buildSubCard(context, item),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ============================================================
  // RANKING
  // ============================================================

  Widget _buildRankingSection(BuildContext context) {
    final colors = _colors(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: colors.accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Assets',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ranked by latest market capitalization',
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.circle,
                color: colors.accent,
                size: 7,
              ),
              const SizedBox(width: 5),
              Text(
                'LIVE',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: colors.border,
            height: 1,
          ),
          const SizedBox(height: 4),
          FutureBuilder<List<_RankedAsset>>(
            future: _rankingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'Ranking error:\n${snapshot.error}',
                    style: TextStyle(
                      color: colors.bearish,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              if (snapshot.data == null || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'No market ranking data available.',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (int index = 0; index < snapshot.data!.length; index++)
                    _buildRankingTile(
                      context,
                      snapshot.data![index],
                      index + 1,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankingTile(
    BuildContext context,
    _RankedAsset asset,
    int rank,
  ) {
    final colors = _colors(context);
    final change = asset.snapshot.priceChange24h ?? 0;

    final bullish = change >= 0;
    final statusColor = bullish ? colors.accent : colors.bearish;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3 ? colors.accent : colors.secondaryText,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildCoinAvatar(context, asset.coin),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.coin.symbol.toUpperCase(),
                  style: TextStyle(
                    color: colors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  asset.coin.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPrice(asset.snapshot.priceUsd),
                style: TextStyle(
                  color: colors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${bullish ? '+' : ''}${change.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NEWS CARDS
  // ============================================================

  Widget _buildFeaturedCard(BuildContext context, News news) {
    final colors = _colors(context);
    final imageUrl = _getImageUrl(
      news.imageSeed,
      width: 900,
      height: 600,
    );

    return Card(
      color: colors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openNews(news),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return _imagePlaceholder(context);
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
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sentimentBadge(context, news),
                  const SizedBox(height: 9),
                  Text(
                    news.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'CripCheck • ${_formatDate(news.generatedAt)}',
                    style: const TextStyle(
                      color: Color(0xFFCDD3DA),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSideCard(BuildContext context, News news) {
    final colors = _colors(context);
    final imageUrl = _getImageUrl(
      news.imageSeed,
      width: 500,
      height: 260,
    );

    return Card(
      color: colors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openNews(news),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 125,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _imagePlaceholder(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sentimentBadge(context, news),
                  const SizedBox(height: 7),
                  Text(
                    news.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(news.generatedAt),
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridNewsCard(BuildContext context, News news) {
    final colors = _colors(context);
    final imageUrl = _getImageUrl(
      news.imageSeed,
      width: 500,
      height: 300,
    );

    return Card(
      color: colors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openNews(news),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _imagePlaceholder(context),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sentimentBadge(context, news),
                        const SizedBox(height: 8),
                        Text(
                          news.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatDate(news.generatedAt),
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, News news) {
    final colors = _colors(context);
    final imageUrl = _getImageUrl(
      news.imageSeed,
      width: 700,
      height: 350,
    );

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
        onTap: () => _openNews(news),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return _imagePlaceholder(context);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sentimentBadge(context, news),
                  const SizedBox(height: 8),
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CripCheck • ${_formatDate(news.generatedAt)}',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCard(BuildContext context, News news) {
    final colors = _colors(context);
    final imageUrl = _getImageUrl(
      news.imageSeed,
      width: 200,
      height: 200,
    );

    return Card(
      color: colors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: () => _openNews(news),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatDate(news.generatedAt),
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 78,
                  height: 78,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return _imagePlaceholder(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildBanner(BuildContext context) {
  final colors = _colors(context);

final List<Map<String, dynamic>> bannerItems = [
  {
    'title': 'CripCheck Crypto Intelligence',
    'subtitle': 'Track real-time crypto market movements & analysis.',
    'tag': 'INTRO',
    'imageSeed': 'crypto101',
    'icon': Icons.bolt_rounded,
    'onTap': null,
  },
  {
    'title': 'Search Assets & Specific News',
    'subtitle': 'Find your favorite coins or trending news instantly.',
    'tag': 'SEARCH',
    'imageSeed': 'cryptosearch',
    'icon': Icons.search_rounded,
    'onTap': () {
      // Switch to Search Tab (Index 1) in MainScreen
      widget.onTabSelected?.call(1);
    },
  },
  {
    'title': 'Market Overview & Trends',
    'subtitle': 'View comprehensive statistics and live market charts.',
    'tag': 'MARKET',
    'imageSeed': 'cryptomarket',
    'icon': Icons.show_chart_rounded,
    'onTap': () {
      // Switch to Market Tab (Index 2) in MainScreen
      widget.onTabSelected?.call(2);
    },
  },
  {
    'title': 'Discover the Secret Screen!',
    'subtitle': 'Open any news detail to unlock hidden detailed analysis features.',
    'tag': 'SECRET TIPS',
    'imageSeed': 'cryptosecret',
    'icon': Icons.vpn_key_rounded,
    'onTap': null,
  },
];

  return Column(
    children: [
      SizedBox(
        height: 140,
        child: PageView.builder(
          controller: _bannerPageController,
          onPageChanged: (index) {
            setState(() {
              _currentBannerIndex = index;
            });
          },
          itemCount: bannerItems.length,
          itemBuilder: (context, index) {
            final item = bannerItems[index];
            final imageUrl = _getImageUrl(
              item['imageSeed'] as String,
              width: 800,
              height: 300,
            );

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.accent.withValues(alpha: 0.3)),
                ),
                child: InkWell(
                  onTap: item['onTap'] as VoidCallback?,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _imagePlaceholder(context),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.accent, width: 1.5),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: colors.accent,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.accent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item['tag'] as String,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item['title'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['subtitle'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item['onTap'] != null)
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      // Indicator Dots
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          bannerItems.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: _currentBannerIndex == index ? 18 : 6,
            decoration: BoxDecoration(
              color: _currentBannerIndex == index
                  ? colors.accent
                  : colors.secondaryText.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildMiniCardHorizontalList(
      BuildContext context, List<News> newsList) {
    final colors = _colors(context);

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: newsList.length,
        itemBuilder: (context, index) {
          final news = newsList[index];

          final imageUrl = _getImageUrl(
            news.imageSeed,
            width: 300,
            height: 180,
          );

          return Container(
            width: 205,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openNews(news),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _imagePlaceholder(context);
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            news.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(news.generatedAt),
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoreNewsButton(BuildContext context) {
    final colors = _colors(context);

    return Center(
      child: InkWell(
        onTap: () {
          setState(() {
            _newsBlockRepeatCount++;
          });
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MORE NEWS',
                style: TextStyle(
                  color: colors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_downward_rounded,
                color: colors.accent,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    final colors = _colors(context);
    final isSelected = _selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : colors.primaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        selectedColor: colors.accent,
        backgroundColor: colors.surface,
        checkmarkColor: Colors.black,
        side: BorderSide(
          color: isSelected ? colors.accent : colors.border,
        ),
        onSelected: (_) {
          setState(() {
            _selectedFilter = label;
            _desktopNewsCount = 12;
            _newsBlockRepeatCount = 1;
          });
        },
      ),
    );
  }

  Widget _sentimentBadge(BuildContext context, News news) {
    final colors = _colors(context);
    final sentiment = news.sentiment?.toLowerCase();

    if (sentiment == null) {
      return const SizedBox.shrink();
    }

    final bullish = sentiment == 'bullish';
    final color = bullish ? colors.accent : colors.bearish;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        sentiment.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCoinAvatar(BuildContext context, Coin coin) {
    if (coin.imageUrl != null && coin.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          coin.imageUrl!,
          width: 31,
          height: 31,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _coinFallback(context, coin);
          },
        ),
      );
    }

    return _coinFallback(context, coin);
  }

  Widget _coinFallback(BuildContext context, Coin coin) {
    final colors = _colors(context);

    return CircleAvatar(
      radius: 15.5,
      backgroundColor: colors.elevated,
      child: Text(
        coin.symbol.isNotEmpty ? coin.symbol[0].toUpperCase() : '?',
        style: TextStyle(
          color: colors.primaryText,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
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

  Widget _buildErrorState(BuildContext context) {
    final colors = _colors(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: colors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load news.',
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = _colors(context);

    return RefreshIndicator(
      color: colors.accent,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: Center(
              child: Text(
                'No news available for this filter.',
                style: TextStyle(
                  color: colors.secondaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openNews(News news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(news: news),
      ),
    );
  }

  String _formatPrice(double? value) {
    if (value == null) {
      return '--';
    }

    if (value >= 1000) {
      return '\$${value.toStringAsFixed(0)}';
    }

    if (value >= 1) {
      return '\$${value.toStringAsFixed(2)}';
    }

    return '\$${value.toStringAsFixed(4)}';
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}

class _RankedAsset {
  final Coin coin;
  final MarketSnapshot snapshot;

  const _RankedAsset({
    required this.coin,
    required this.snapshot,
  });
}