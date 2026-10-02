import 'package:flutter/material.dart';

import '../core/theme/app_theme_colors.dart';
import '../models/coin.dart';
import '../models/market_snapshot.dart';
import '../repositories/coin_repository.dart';
import '../repositories/market_snapshot_repository.dart';
import 'market_snapshot_with_tracklist_screen.dart';

class MarketOverviewScreen extends StatefulWidget {
  const MarketOverviewScreen({super.key});

  @override
  State<MarketOverviewScreen> createState() => _MarketOverviewScreenState();
}

class _MarketOverviewScreenState extends State<MarketOverviewScreen> {
  final CoinRepository _coinRepository = CoinRepository();
  final MarketSnapshotRepository _marketRepository =
      MarketSnapshotRepository();

  bool _isLoading = true;
  String? _errorMessage;

  List<_CoinWithSnapshot> _assets = [];

  Coin? _featuredCoin;
  MarketSnapshot? _featuredSnapshot;
  List<MarketSnapshot> _featuredHistory = [];

  double _totalMarketCap = 0;
  double _totalVolume = 0;
  double _averageChange24h = 0;

  int _bullishCount = 0;

  static const Color _blue = Color(0xFF5B8CFF);

  AppThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()!;
  }

  @override
  void initState() {
    super.initState();
    _loadMarketOverview();
  }

  Future<void> _loadMarketOverview() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final coins = await _coinRepository.getAllCoins();

      final results = await Future.wait(
        coins.map((coin) async {
          try {
            final snapshot = await _marketRepository.getLatestSnapshot(
              coin.id,
            );

            if (snapshot == null) return null;

            return _CoinWithSnapshot(
              coin: coin,
              snapshot: snapshot,
            );
          } catch (e) {
            debugPrint('MARKET ERROR ${coin.symbol}: $e');
            return null;
          }
        }),
      );

      final assets = results
          .whereType<_CoinWithSnapshot>()
          .where(
            (item) =>
                item.snapshot.marketCap != null && item.snapshot.marketCap! > 0,
          )
          .toList();

      assets.sort((a, b) {
        final aCap = a.snapshot.marketCap ?? 0.0;
        final bCap = b.snapshot.marketCap ?? 0.0;
        return bCap.compareTo(aCap);
      });

      Coin? featuredCoin;
      MarketSnapshot? featuredSnapshot;
      List<MarketSnapshot> featuredHistory = [];

      if (assets.isNotEmpty) {
        featuredCoin = assets.first.coin;
        featuredSnapshot = assets.first.snapshot;

        featuredHistory = await _marketRepository.getHistoricalSnapshotsByRange(
          featuredCoin.id,
          range: const Duration(days: 7),
        );

        featuredHistory.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }

      double totalMarketCap = 0.0;
      double totalVolume = 0.0;
      double changeSum = 0.0;

      int bullishCount = 0;
      int changeCount = 0;

      for (final asset in assets) {
        final marketCap = asset.snapshot.marketCap ?? 0.0;
        final volume = asset.snapshot.volume24h ?? 0.0;
        final change = asset.snapshot.priceChange24h;

        totalMarketCap += marketCap;
        totalVolume += volume;

        if (change != null) {
          changeSum += change;
          changeCount++;

          if (change >= 0) {
            bullishCount++;
          }
        }
      }

      final averageChange = changeCount == 0 ? 0.0 : changeSum / changeCount;

      if (!mounted) return;

      setState(() {
        _assets = assets;
        _featuredCoin = featuredCoin;
        _featuredSnapshot = featuredSnapshot;
        _featuredHistory = featuredHistory;

        _totalMarketCap = totalMarketCap;
        _totalVolume = totalVolume;
        _averageChange24h = averageChange;

        _bullishCount = bullishCount;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('MARKET LOAD ERROR: $e');
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load market data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
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
        // Ikon Branding
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
            Icons.show_chart_rounded,
            color: colors.accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        
        // Judul & Subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'MARKET ',
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'OVERVIEW',
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
                  size: 6,
                ),
                const SizedBox(width: 4),
                Text(
                  'LIVE METRICS',
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

  Widget _buildBody(BuildContext context) {
    final colors = _colors(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: colors.accent,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_assets.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      color: colors.accent,
      backgroundColor: colors.surface,
      onRefresh: _loadMarketOverview,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 950;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              desktop ? 28 : 16,
              10,
              desktop ? 28 : 16,
              40,
            ),
            child: desktop
                ? _buildDesktopLayout(context)
                : _buildMobileLayout(context),
          );
        },
      ),
    );
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMarketSummary(context, mobile: true),
        const SizedBox(height: 24),
        _buildSectionHeader(
          context,
          title: 'Main Index',
          subtitle: 'INDEX',
        ),
        const SizedBox(height: 12),
        _buildMainIndex(context),
        const SizedBox(height: 24),
        _buildMarketOverviewStats(context),
        const SizedBox(height: 24),
        _buildMarketCapCard(context),
        const SizedBox(height: 20),
        _buildDominanceCard(context),
        const SizedBox(height: 20),
        _buildRankedCard(
          context,
          title: 'Highest Volume',
          subtitle: 'VOLUME',
          type: _RankingType.volume,
        ),
        const SizedBox(height: 20),
        _buildRankedCard(
          context,
          title: 'Top Gainers',
          subtitle: 'BULLISH',
          type: _RankingType.gainers,
        ),
        const SizedBox(height: 20),
        _buildRankedCard(
          context,
          title: 'Top Losers',
          subtitle: 'BEARISH',
          type: _RankingType.losers,
        ),
      ],
    );
  }

  // ============================================================
  // DESKTOP LAYOUT
  // ============================================================

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 65,
              child: _buildMarketSummary(context, mobile: false),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 35,
              child: Column(
                children: [
                  _buildDesktopIndexPanel(context),
                  const SizedBox(height: 16),
                  _buildMarketIntelligenceBanner(context),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildMarketOverviewStats(context),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildRankedCard(
                context,
                title: 'Highest Volume',
                subtitle: 'VOLUME',
                type: _RankingType.volume,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _buildRankedCard(
                context,
                title: 'Top Gainers',
                subtitle: 'BULLISH',
                type: _RankingType.gainers,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _buildRankedCard(
                context,
                title: 'Top Losers',
                subtitle: 'BEARISH',
                type: _RankingType.losers,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _buildMarketCapCard(context),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: _buildDominanceCard(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BANNER
  // ============================================================

  Widget _buildMarketIntelligenceBanner(BuildContext context) {
    final colors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.surface,
            _blue.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: _blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CRIPCHECK AI ANALYSIS',
                  style: TextStyle(
                    color: _blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Automated snapshot updates every 20 minutes.',
                  style: TextStyle(
                    color: colors.primaryText.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MARKET SUMMARY
  // ============================================================

  Widget _buildMarketSummary(BuildContext context, {required bool mobile}) {
    final colors = _colors(context);
    final coin = _featuredCoin!;
    final snapshot = _featuredSnapshot!;

    final change = snapshot.priceChange24h ?? 0;
    final positive = change >= 0;
    final color = positive ? colors.accent : colors.bearish;

    return Container(
      constraints: BoxConstraints(
        minHeight: mobile ? 480 : 540,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildCoinAvatar(context, coin, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      coin.symbol.toUpperCase(),
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              _buildChangeBadge(value: change, color: color),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'MARKET SUMMARY',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatPrice(snapshot.priceUsd),
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                positive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 5),
              Text(
                positive ? 'Bullish momentum' : 'Bearish momentum',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: mobile ? 200 : 260,
            width: double.infinity,
            child: _buildHistoricalChart(
              context,
              history: _featuredHistory,
              color: color,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  context,
                  label: '1H',
                  value: _formatPercent(snapshot.priceChange1h),
                  color: _changeColor(context, snapshot.priceChange1h),
                ),
              ),
              Expanded(
                child: _buildMetric(
                  context,
                  label: '24H',
                  value: _formatPercent(snapshot.priceChange24h),
                  color: _changeColor(context, snapshot.priceChange24h),
                ),
              ),
              Expanded(
                child: _buildMetric(
                  context,
                  label: '7D',
                  value: _formatPercent(snapshot.priceChange7d),
                  color: _changeColor(context, snapshot.priceChange7d),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INDEX
  // ============================================================

  Widget _buildDesktopIndexPanel(BuildContext context) {
    final colors = _colors(context);

    return Container(
      height: 440,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            title: 'Main Index',
            subtitle: 'TRACKLIST',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _assets.length,
              itemBuilder: (context, index) {
                return _buildAssetTile(
                  context,
                  item: _assets[index],
                  rank: index + 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainIndex(BuildContext context) {
    return _buildCard(
      context,
      child: Column(
        children: [
          for (int i = 0; i < _assets.length; i++)
            _buildAssetTile(
              context,
              item: _assets[i],
              rank: i + 1,
            ),
        ],
      ),
    );
  }

  Widget _buildAssetTile(
    BuildContext context, {
    required _CoinWithSnapshot item,
    required int rank,
  }) {
    final colors = _colors(context);
    final change = item.snapshot.priceChange24h ?? 0;
    final color = _changeColor(context, change);

    return InkWell(
      onTap: () => _openMarketDetail(item.coin.id),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 3,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 25,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _buildCoinAvatar(context, item.coin, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.coin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.coin.symbol.toUpperCase(),
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPrice(item.snapshot.priceUsd),
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatPercent(item.snapshot.priceChange24h),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MARKET STATS
  // ============================================================

  Widget _buildMarketOverviewStats(BuildContext context) {

    return Row(
      children: [
        Expanded(
          child: _buildSmallStat(
            context,
            label: 'TOTAL MARKET CAP',
            value: _formatCompactCurrency(_totalMarketCap),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSmallStat(
            context,
            label: '24H VOLUME',
            value: _formatCompactCurrency(_totalVolume),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSmallStat(
            context,
            label: 'AVG 24H',
            value: _formatPercent(_averageChange24h),
            color: _changeColor(context, _averageChange24h),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStat(
    BuildContext context, {
    required String label,
    required String value,
    Color? color,
  }) {
    final colors = _colors(context);
    final effectiveColor = color ?? colors.primaryText;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MARKET CAP CARD
  // ============================================================

  Widget _buildMarketCapCard(BuildContext context) {
    final colors = _colors(context);
    final isPositive = _averageChange24h >= 0;
    final chartColor = isPositive ? colors.accent : colors.bearish;

    return _buildCard(
      context,
      title: 'Crypto Market Cap',
      subtitle: 'TOTAL MARKET',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatCompactCurrency(_totalMarketCap),
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_assets.length} tracked assets',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 130,
            width: double.infinity,
            child: _buildHistoricalChart(
              context,
              history: _featuredHistory,
              color: chartColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOMINANCE CARD (EXPANDED TO FILL SPACE)
  // ============================================================

  Widget _buildDominanceCard(BuildContext context) {
    final colors = _colors(context);
    final featuredCap = _featuredSnapshot?.marketCap ?? 0;

    final dominance = _totalMarketCap <= 0
        ? 0.0
        : (featuredCap / _totalMarketCap) * 100;

    final bearishCount = _assets.length - _bullishCount;
    final bullishRatio = _assets.isEmpty
        ? 0.0
        : (_bullishCount / _assets.length) * 100;

    return _buildCard(
      context,
      title: 'Market Dominance',
      subtitle: 'MARKET BREADTH',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _featuredCoin == null
                ? '-'
                : '${_featuredCoin!.symbol.toUpperCase()} ${dominance.toStringAsFixed(1)}%',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Largest tracked asset dominance',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: dominance.clamp(1, 100).toInt(),
                  child: Container(
                    height: 10,
                    color: _blue,
                  ),
                ),
                Expanded(
                  flex: (100 - dominance).clamp(1, 100).toInt(),
                  child: Container(
                    height: 10,
                    color: colors.elevated,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_bullishCount Bullish',
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${bullishRatio.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.bearish,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$bearishCount Bearish',
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(100 - bullishRatio).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: colors.bearish,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RANKINGS
  // ============================================================

  Widget _buildRankedCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required _RankingType type,
  }) {
    final items = List<_CoinWithSnapshot>.from(_assets);

    switch (type) {
      case _RankingType.volume:
        items.sort(
          (a, b) => (b.snapshot.volume24h ?? 0)
              .compareTo(a.snapshot.volume24h ?? 0),
        );
        break;

      case _RankingType.gainers:
        items.sort(
          (a, b) => (b.snapshot.priceChange24h ?? 0)
              .compareTo(a.snapshot.priceChange24h ?? 0),
        );
        break;

      case _RankingType.losers:
        items.sort(
          (a, b) => (a.snapshot.priceChange24h ?? 0)
              .compareTo(b.snapshot.priceChange24h ?? 0),
        );
        break;
    }

    final visibleItems = items.take(5).toList();

    return _buildCard(
      context,
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          for (int i = 0; i < visibleItems.length; i++)
            _buildRankingTile(
              context,
              item: visibleItems[i],
              rank: i + 1,
              type: type,
            ),
        ],
      ),
    );
  }

  Widget _buildRankingTile(
    BuildContext context, {
    required _CoinWithSnapshot item,
    required int rank,
    required _RankingType type,
  }) {
    final colors = _colors(context);
    final change = item.snapshot.priceChange24h ?? 0;
    final changeColor = _changeColor(context, change);

    String rightValue;

    switch (type) {
      case _RankingType.volume:
        rightValue = _formatCompactCurrency(item.snapshot.volume24h);
        break;

      case _RankingType.gainers:
      case _RankingType.losers:
        rightValue = _formatPercent(change);
        break;
    }

    return InkWell(
      onTap: () => _openMarketDetail(item.coin.id),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _buildCoinAvatar(context, item.coin, size: 30),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.coin.symbol.toUpperCase(),
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _formatPrice(item.snapshot.priceUsd),
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              rightValue,
              style: TextStyle(
                color: type == _RankingType.volume
                    ? colors.primaryText
                    : changeColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GENERIC CARD
  // ============================================================

  Widget _buildCard(
    BuildContext context, {
    String? title,
    String? subtitle,
    required Widget child,
  }) {
    final colors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            _buildSectionHeader(
              context,
              title: title,
              subtitle: subtitle ?? '',
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final colors = _colors(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HISTORICAL CHART
  // ============================================================

  Widget _buildHistoricalChart(
    BuildContext context, {
    required List<MarketSnapshot> history,
    required Color color,
  }) {
    final colors = _colors(context);

    if (history.length < 2) {
      return Container(
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Text(
            'Not enough historical data',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(10),
      child: CustomPaint(
        painter: _HistoricalChartPainter(
          snapshots: history,
          color: color,
          borderColor: colors.border,
        ),
      ),
    );
  }

  // ============================================================
  // METRICS
  // ============================================================

  Widget _buildMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildChangeBadge({
    required double value,
    required Color color,
  }) {
    final positive = value >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            _formatPercent(value),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COIN AVATAR
  // ============================================================

  Widget _buildCoinAvatar(
    BuildContext context,
    Coin coin, {
    required double size,
  }) {
    final colors = _colors(context);
    final symbol = coin.symbol.trim();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.elevated,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: Text(
        symbol.isEmpty ? '?' : symbol.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: colors.primaryText,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // STATES
  // ============================================================

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
              color: colors.secondaryText,
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadMarketOverview,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryText,
                side: BorderSide(color: colors.border),
              ),
              child: const Text('Retry'),
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
      backgroundColor: colors.surface,
      onRefresh: _loadMarketOverview,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          Icon(
            Icons.bar_chart_rounded,
            color: colors.secondaryText,
            size: 46,
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'No market data available.',
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openMarketDetail(int coinId) {
    // Ensure we map the full master assets list so any tapped item 
    // (from volume, gainers, losers, or main index) has its complete data ready!
    final mappedAssets = _assets.map((item) {
      return CoinWithSnapshot(
        coin: item.coin,
        snapshot: item.snapshot,
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarketSnapshotWithTracklistScreen(
          initialCoinId: coinId,
          assets: mappedAssets,
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Color _changeColor(BuildContext context, double? value) {
    final colors = _colors(context);
    if (value == null) return colors.secondaryText;
    return value >= 0 ? colors.accent : colors.bearish;
  }

  String _formatPrice(double? price) {
    if (price == null) return '-';
    if (price >= 1000) return '\$${price.toStringAsFixed(2)}';
    if (price >= 1) return '\$${price.toStringAsFixed(2)}';
    if (price >= 0.01) return '\$${price.toStringAsFixed(4)}';
    return '\$${price.toStringAsFixed(8)}';
  }

  String _formatPercent(double? value) {
    if (value == null) return '-';
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';
  }

  String _formatCompactCurrency(double? value) {
    if (value == null || !value.isFinite) return '-';

    final absolute = value.abs();

    if (absolute >= 1000000000000) {
      return '\$${(value / 1000000000000).toStringAsFixed(2)}T';
    }

    if (absolute >= 1000000000) {
      return '\$${(value / 1000000000).toStringAsFixed(2)}B';
    }

    if (absolute >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    }

    if (absolute >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    }

    return '\$${value.toStringAsFixed(2)}';
  }
}

// ================================================================
// DATA HOLDER
// ================================================================

class _CoinWithSnapshot {
  final Coin coin;
  final MarketSnapshot snapshot;

  const _CoinWithSnapshot({
    required this.coin,
    required this.snapshot,
  });
}

// ================================================================
// RANKING TYPE
// ================================================================

enum _RankingType {
  volume,
  gainers,
  losers,
}

// ================================================================
// HISTORICAL CHART PAINTER
// ================================================================

class _HistoricalChartPainter extends CustomPainter {
  final List<MarketSnapshot> snapshots;
  final Color color;
  final Color borderColor;

  _HistoricalChartPainter({
    required this.snapshots,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (snapshots.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final prices = snapshots
        .map((snapshot) => snapshot.priceUsd)
        .whereType<double>()
        .toList();

    if (prices.length < 2) return;

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final range = maxPrice - minPrice;

    final gridPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final path = Path();

    for (int i = 0; i < prices.length; i++) {
      final double x = prices.length == 1
          ? 0.0
          : size.width * i / (prices.length - 1);

      final double normalized =
          range == 0 ? 0.5 : ((prices[i] - minPrice) / range).toDouble();

      final double y =
          size.height - (normalized * (size.height * 0.82)) - (size.height * 0.09);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      path,
      linePaint,
    );

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    canvas.drawPath(
      fillPath,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _HistoricalChartPainter oldDelegate,
  ) {
    return oldDelegate.snapshots != snapshots ||
        oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor;
  }
}