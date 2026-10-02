import 'package:flutter/material.dart';

import '../core/theme/app_theme_colors.dart';
import '../models/coin.dart';
import '../models/market_snapshot.dart';
import '../repositories/coin_repository.dart';
import '../repositories/market_snapshot_repository.dart';
import '../widgets/price_history_chart.dart';

class MarketSnapshotDetailScreen extends StatefulWidget {
  final int coinId;

  const MarketSnapshotDetailScreen({
    super.key,
    required this.coinId,
  });

  @override
  State<MarketSnapshotDetailScreen> createState() =>
      _MarketSnapshotDetailScreenState();
}

class _MarketSnapshotDetailScreenState
    extends State<MarketSnapshotDetailScreen> {
  final MarketSnapshotRepository _marketRepository =
      MarketSnapshotRepository();
  final CoinRepository _coinRepository = CoinRepository();

  Coin? _coin;
  MarketSnapshot? _snapshot;
  List<MarketSnapshot> _historicalSnapshots = [];

  Duration _selectedRange = const Duration(days: 1);

  bool _isLoading = true;
  bool _isLoadingHistory = true;

  String? _errorMessage;
  String? _historyErrorMessage;

  AppThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()!;
  }

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadHistoricalData();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final coin = await _coinRepository.getCoinById(widget.coinId);

      final snapshots = await _marketRepository.getSnapshotsForCoin(
        widget.coinId,
        limit: 1,
      );

      if (!mounted) return;

      setState(() {
        _coin = coin;
        _snapshot = snapshots.isNotEmpty ? snapshots.first : null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load market data.';
      });
    }
  }

Future<void> _loadHistoricalData() async {
  try {
    setState(() {
      _isLoadingHistory = true;
      _historyErrorMessage = null;
    });

    final selectedRange = _selectedRange;

    final historicalSnapshots = await _marketRepository
        .getHistoricalSnapshotsByRange(
      widget.coinId,
      range: selectedRange,
    );

    if (!mounted) return;

    setState(() {
      _historicalSnapshots = historicalSnapshots;
      _isLoadingHistory = false;
    });
  } catch (_) {
    if (!mounted) return;

    setState(() {
      _isLoadingHistory = false;
      _historyErrorMessage =
          'Failed to load price history.';
    });
  }
}

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadData(),
      _loadHistoricalData(),
    ]);
  }

  // ---------------------------------------------------------------------------
  // ROOT
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = _colors(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: colors.accent,
          strokeWidth: 2.2,
        ),
      );
    }

    final errorMessage = _errorMessage;

    if (errorMessage != null) {
      return _buildErrorState(context, errorMessage);
    }

    if (_snapshot == null) {
      return _buildEmptyState(context);
    }

    final snapshot = _snapshot!;

    return RefreshIndicator(
      color: colors.accent,
      backgroundColor: colors.card,
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 52),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1080,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(context),
                  const SizedBox(height: 20),
                  _buildHero(context, snapshot),
                  const SizedBox(height: 30),
                  _buildSectionLabel(
                    context,
                    title: 'PERFORMANCE',
                    subtitle: 'Price movement across selected periods',
                  ),
                  const SizedBox(height: 12),
                  _buildPerformance(context, snapshot),
                  const SizedBox(height: 30),
                  _buildMarketOverview(context, snapshot),
                  const SizedBox(height: 30),
                  _buildHistorySection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR / EMPTY STATES
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(BuildContext context, String message) {
    final colors = _colors(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildStateContent(
          context,
          icon: Icons.cloud_off_rounded,
          iconColor: colors.bearish,
          title: 'Unable to load market data',
          message: message,
          action: OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 16,
            ),
            label: const Text('Retry'),
            style: _outlinedButtonStyle(context),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = _colors(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildStateContent(
          context,
          icon: Icons.bar_chart_rounded,
          iconColor: colors.secondaryText,
          title: 'No market data available',
          message: 'Market snapshot data is currently unavailable.',
          action: OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 16,
            ),
            label: const Text('Retry'),
            style: _outlinedButtonStyle(context),
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required Widget action,
  }) {
    final colors = _colors(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.07),
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor.withValues(alpha: 0.16),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: iconColor,
            size: 25,
          ),
        ),
        const SizedBox(height: 17),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.15,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 19),
        action,
      ],
    );
  }

  ButtonStyle _outlinedButtonStyle(BuildContext context) {
    final colors = _colors(context);

    return OutlinedButton.styleFrom(
      foregroundColor: colors.primaryText,
      side: BorderSide(
        color: colors.border,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 11,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
      ),
      textStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE HEADER
  // ---------------------------------------------------------------------------

  Widget _buildPageHeader(BuildContext context) {
    final colors = _colors(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 440;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MARKET SNAPSHOT',
              style: TextStyle(
                color: colors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Asset overview',
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.05,
              ),
            ),
          ],
        );

        final liveIndicator = Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.28),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE DATA',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              liveIndicator,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: titleBlock,
            ),
            const SizedBox(width: 16),
            liveIndicator,
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HERO
  // ---------------------------------------------------------------------------

  Widget _buildHero(BuildContext context, MarketSnapshot snapshot) {
    final colors = _colors(context);
    final coin = _coin;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return _buildMobileHero(context, snapshot, coin);
          }

          return _buildDesktopHero(context, snapshot, coin);
        },
      ),
    );
  }

  Widget _buildDesktopHero(
    BuildContext context,
    MarketSnapshot snapshot,
    Coin? coin,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: _buildCoinIdentity(context, coin),
        ),
        const SizedBox(width: 22),
        Expanded(
          flex: 5,
          child: _buildHeroPrice(context, snapshot),
        ),
        const SizedBox(width: 20),
        _buildHeroChange(context, snapshot.priceChange24h),
      ],
    );
  }

  Widget _buildMobileHero(
    BuildContext context,
    MarketSnapshot snapshot,
    Coin? coin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoinIdentity(context, coin),
        const SizedBox(height: 28),
        _buildHeroPrice(context, snapshot),
        const SizedBox(height: 18),
        _buildHeroChange(context, snapshot.priceChange24h),
      ],
    );
  }

  Widget _buildCoinIdentity(BuildContext context, Coin? coin) {
    final colors = _colors(context);

    if (coin == null) {
      return Text(
        'Market Data',
        style: TextStyle(
          color: colors.primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.elevated,
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            coin.symbol.isNotEmpty ? coin.symbol[0].toUpperCase() : '?',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                coin.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                coin.symbol.toUpperCase(),
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPrice(BuildContext context, MarketSnapshot snapshot) {
    final colors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURRENT PRICE',
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _formatPrice(snapshot.priceUsd),
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 43,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroChange(BuildContext context, double? value) {
    final colors = _colors(context);
    final color = _changeColor(context, value);
    final isPositive = value != null && value > 0;
    final isNegative = value != null && value < 0;

    return Container(
      constraints: const BoxConstraints(
        minWidth: 118,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '24H CHANGE',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPositive || isNegative)
                Container(
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: color,
                    size: 13,
                  ),
                ),
              if (isPositive || isNegative) const SizedBox(width: 6),
              Text(
                _formatPercentage(value),
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION LABEL
  // ---------------------------------------------------------------------------

  Widget _buildSectionLabel(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final colors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PERFORMANCE
  // ---------------------------------------------------------------------------

  Widget _buildPerformance(BuildContext context, MarketSnapshot snapshot) {
    final colors = _colors(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 500;

          if (isSmall) {
            return Column(
              children: [
                _buildPerformanceItem(
                  context,
                  label: '1H',
                  value: snapshot.priceChange1h,
                ),
                Divider(
                  color: colors.border.withValues(alpha: 0.75),
                  height: 1,
                ),
                _buildPerformanceItem(
                  context,
                  label: '24H',
                  value: snapshot.priceChange24h,
                  emphasized: true,
                ),
                Divider(
                  color: colors.border.withValues(alpha: 0.75),
                  height: 1,
                ),
                _buildPerformanceItem(
                  context,
                  label: '7D',
                  value: snapshot.priceChange7d,
                ),
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildPerformanceItem(
                    context,
                    label: '1H',
                    value: snapshot.priceChange1h,
                  ),
                ),
                Container(
                  width: 1,
                  color: colors.border.withValues(alpha: 0.75),
                ),
                Expanded(
                  child: _buildPerformanceItem(
                    context,
                    label: '24H',
                    value: snapshot.priceChange24h,
                    emphasized: true,
                  ),
                ),
                Container(
                  width: 1,
                  color: colors.border.withValues(alpha: 0.75),
                ),
                Expanded(
                  child: _buildPerformanceItem(
                    context,
                    label: '7D',
                    value: snapshot.priceChange7d,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceItem(
    BuildContext context, {
    required String label,
    required double? value,
    bool emphasized = false,
  }) {
    final colors = _colors(context);
    final color = _changeColor(context, value);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: emphasized
                  ? color
                  : color.withValues(alpha: 0.62),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized
                    ? colors.primaryText
                    : colors.secondaryText,
                fontSize: 11,
                fontWeight: emphasized
                    ? FontWeight.w800
                    : FontWeight.w700,
              ),
            ),
          ),
          Text(
            _formatPercentage(value),
            style: TextStyle(
              color: color,
              fontSize: emphasized ? 16 : 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.15,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MARKET OVERVIEW
  // ---------------------------------------------------------------------------

  Widget _buildMarketOverview(
    BuildContext context,
    MarketSnapshot snapshot,
  ) {
    final colors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(
            context,
            title: 'MARKET OVERVIEW',
          ),
          const SizedBox(height: 19),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 500;

              if (isSmall) {
                return Column(
                  children: [
                    _buildOverviewMetric(
                      context,
                      label: 'Market Cap',
                      value: _formatCurrency(snapshot.marketCap),
                    ),
                    const SizedBox(height: 19),
                    _buildOverviewMetric(
                      context,
                      label: 'Volume (24h)',
                      value: _formatCurrency(snapshot.volume24h),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildOverviewMetric(
                      context,
                      label: 'Market Cap',
                      value: _formatCurrency(snapshot.marketCap),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 52,
                    color: colors.border,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: _buildOverviewMetric(
                        context,
                        label: 'Volume (24h)',
                        value: _formatCurrency(snapshot.volume24h),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: colors.border.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: colors.secondaryText,
              ),
              const SizedBox(width: 7),
              Text(
                'Snapshot',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  _formatDateTime(snapshot.snapshotAt),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardTitle(
    BuildContext context, {
    required String title,
  }) {
    final colors = _colors(context);

    return Text(
      title,
      style: TextStyle(
        color: colors.primaryText,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _buildOverviewMetric(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PRICE HISTORY
  // ---------------------------------------------------------------------------

  Widget _buildHistorySection(BuildContext context) {
    final colors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 480;

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHistoryHeader(context),
                    const SizedBox(height: 15),
                    _buildRangeSelector(context),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildHistoryHeader(context),
                  ),
                  const SizedBox(width: 16),
                  _buildRangeSelector(context),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildHistoryContent(context),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(BuildContext context) {
    final colors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRICE HISTORY',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Historical price movement',
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSelector(BuildContext context) {
    final colors = _colors(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRangeChip(
            context,
            '1D',
            const Duration(days: 1),
          ),
          _buildRangeChip(
            context,
            '7D',
            const Duration(days: 7),
          ),
          _buildRangeChip(
            context,
            '30D',
            const Duration(days: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeChip(
    BuildContext context,
    String label,
    Duration duration,
  ) {
    final colors = _colors(context);
    final isSelected = _selectedRange == duration;

    return InkWell(
      onTap: () {
        if (isSelected) return;

        setState(() {
          _selectedRange = duration;
        });

        _loadHistoricalData();
      },
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.elevated
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: isSelected
              ? Border.all(
                  color: colors.accent.withValues(alpha: 0.26),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? colors.primaryText
                : colors.secondaryText,
            fontSize: 10,
            fontWeight: isSelected
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryContent(BuildContext context) {
    final colors = _colors(context);

    if (_isLoadingHistory) {
      return SizedBox(
        height: 260,
        child: Center(
          child: CircularProgressIndicator(
            color: colors.accent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_historyErrorMessage != null) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: colors.secondaryText,
                size: 30,
              ),
              const SizedBox(height: 10),
              Text(
                _historyErrorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadHistoricalData,
                style: _outlinedButtonStyle(context),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_historicalSnapshots.length < 2) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: colors.secondaryText,
                size: 30,
              ),
              const SizedBox(height: 10),
              Text(
                'Not enough historical data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

return SizedBox(
  height: 280,
  child: PriceHistoryChart(
    key: ValueKey(_selectedRange),
    snapshots: _historicalSnapshots,
    range: _selectedRange,
  ),
);
  }

  // ---------------------------------------------------------------------------
  // FORMATTERS
  // ---------------------------------------------------------------------------

  String _formatPrice(double? value) {
    if (value == null) return '-';

    if (value >= 1) {
      return '\$${value.toStringAsFixed(2)}';
    }

    if (value >= 0.01) {
      return '\$${value.toStringAsFixed(4)}';
    }

    return '\$${value.toStringAsFixed(8)}';
  }

  String _formatCurrency(double? value) {
    if (value == null) return '-';

    if (value >= 1000000000) {
      return '\$${(value / 1000000000).toStringAsFixed(2)}B';
    }

    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    }

    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    }

    return '\$${value.toStringAsFixed(2)}';
  }

  String _formatPercentage(double? value) {
    if (value == null) return '-';

    final sign = value > 0 ? '+' : '';

    return '$sign${value.toStringAsFixed(2)}%';
  }

  Color _changeColor(BuildContext context, double? value) {
    final colors = _colors(context);

    if (value == null || value == 0) {
      return colors.secondaryText;
    }

    return value > 0 ? colors.accent : colors.bearish;
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
