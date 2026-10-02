import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme_colors.dart';
import '../models/market_snapshot.dart';

class PriceHistoryChart extends StatelessWidget {
  final List<MarketSnapshot> snapshots;
  final Duration range;

  const PriceHistoryChart({
    super.key,
    required this.snapshots,
    required this.range,
  });

  AppThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()!;
  }

  @override
  Widget build(BuildContext context) {

    final validSnapshots = snapshots
        .where((snapshot) => snapshot.priceUsd != null)
        .toList()
      ..sort(
        (a, b) => a.snapshotAt.compareTo(b.snapshotAt),
      );

    if (validSnapshots.length < 2) {
      return SizedBox(
        height: 280,
        child: _ChartEmptyState(
          icon: Icons.show_chart_rounded,
          message: 'Not enough historical data.',
        ),
      );
    }

    final prices = validSnapshots
        .map((snapshot) => snapshot.priceUsd!)
        .toList();

    final spots = _buildSpots(validSnapshots);
    final bounds = _calculateBounds(prices);
    final trendColor = _calculateTrendColor(
      context,
      prices,
    );

    final minX = spots.first.x;
    final maxX = spots.last.x;

    return SizedBox(
      height: 280,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
        child: LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: bounds.minY,
            maxY: bounds.maxY,
            clipData: const FlClipData.all(),
            backgroundColor: Colors.transparent,

            // ---------------------------------------------------------------
            // GRID
            // ---------------------------------------------------------------

            gridData: _buildGridData(
              context,
              minPrice: bounds.dataMin,
              maxPrice: bounds.dataMax,
            ),

            // ---------------------------------------------------------------
            // AXES
            // ---------------------------------------------------------------

            titlesData: _buildTitlesData(
              context,
              snapshots: validSnapshots,
              minX: minX,
              maxX: maxX,
            ),

            borderData: FlBorderData(
              show: false,
            ),

            // ---------------------------------------------------------------
            // TOUCH
            // ---------------------------------------------------------------

            lineTouchData: _buildTouchData(
              context,
              trendColor,
              validSnapshots,
              minX: minX,
              maxX: maxX,
            ),

            // ---------------------------------------------------------------
            // LINE
            // ---------------------------------------------------------------

            lineBarsData: [
              _buildLine(
                context,
                spots: spots,
                color: trendColor,
              ),
            ],
          ),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  // ===========================================================================
  // SPOTS
  // ===========================================================================

  /// X axis menggunakan timestamp asli.
  ///
  /// Ini penting supaya jarak antar titik benar-benar merepresentasikan waktu.
  /// Bukan sekadar:
  ///
  /// 0, 1, 2, 3, 4...
  ///
  /// Dengan timestamp:
  ///
  /// 1D = jam
  /// 7D = hari
  /// 30D = hari
  List<FlSpot> _buildSpots(
    List<MarketSnapshot> snapshots,
  ) {
    final firstTime = snapshots.first.snapshotAt.toLocal();

    return snapshots.map((snapshot) {
      final time = snapshot.snapshotAt.toLocal();

      final seconds = time.difference(firstTime).inMilliseconds /
          Duration.millisecondsPerSecond;

      return FlSpot(
        seconds,
        snapshot.priceUsd!,
      );
    }).toList();
  }

  // ===========================================================================
  // BOUNDS
  // ===========================================================================

  _ChartBounds _calculateBounds(
    List<double> prices,
  ) {
    final minPrice = prices.reduce(
      (a, b) => a < b ? a : b,
    );

    final maxPrice = prices.reduce(
      (a, b) => a > b ? a : b,
    );

    final priceRange = maxPrice - minPrice;

    final padding = priceRange == 0
        ? math.max(
            maxPrice.abs() * 0.05,
            0.01,
          )
        : priceRange * 0.12;

    return _ChartBounds(
      dataMin: minPrice,
      dataMax: maxPrice,
      minY: math.max(
        0,
        minPrice - padding,
      ),
      maxY: maxPrice + padding,
    );
  }

  // ===========================================================================
  // TREND
  // ===========================================================================

  Color _calculateTrendColor(
    BuildContext context,
    List<double> prices,
  ) {
    final colors = _colors(context);

    final first = prices.first;
    final last = prices.last;

    if (last > first) {
      return colors.accent;
    }

    if (last < first) {
      return colors.bearish;
    }

    return colors.secondaryText;
  }

  // ===========================================================================
  // GRID
  // ===========================================================================

  FlGridData _buildGridData(
    BuildContext context, {
    required double minPrice,
    required double maxPrice,
  }) {
    final colors = _colors(context);

    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: _calculatePriceInterval(
        minPrice,
        maxPrice,
      ),
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: colors.border.withValues(alpha: 0.38),
          strokeWidth: 0.7,
          dashArray: const [4, 4],
        );
      },
    );
  }

  // ===========================================================================
  // X AXIS
  // ===========================================================================

  FlTitlesData _buildTitlesData(
    BuildContext context, {
    required List<MarketSnapshot> snapshots,
    required double minX,
    required double maxX,
  }) {
    final colors = _colors(context);

    final labelCount = _getLabelCount(
      snapshots.length,
    );

    final interval = maxX <= minX
        ? 1
        : (maxX - minX) / (labelCount - 1);

    return FlTitlesData(
      topTitles: const AxisTitles(
        sideTitles: SideTitles(
          showTitles: false,
        ),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(
          showTitles: false,
        ),
      ),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(
          showTitles: false,
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          getTitlesWidget: (value, meta) {
            final snapshot = _findNearestSnapshot(
              snapshots,
              value,
            );

            if (snapshot == null) {
              return const SizedBox.shrink();
            }

            final isFirst =
                value <= minX + interval * 0.25;

            final isLast =
                value >= maxX - interval * 0.25;

            if (!isFirst && !isLast) {
              final distanceFromGrid =
                  ((value - minX) / interval);

              final rounded =
                  distanceFromGrid.round();

              if ((distanceFromGrid - rounded).abs() > 0.15) {
                return const SizedBox.shrink();
              }
            }

            return SideTitleWidget(
              meta: meta,
              space: 7,
              child: Text(
                _formatAxisLabel(
                  snapshot.snapshotAt,
                ),
                style: TextStyle(
                  color: colors.secondaryText.withValues(
                    alpha: 0.82,
                  ),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // LABEL LOGIC
  // ===========================================================================

  int _getLabelCount(int snapshotCount) {
    if (range.inDays <= 1) {
      return 5;
    }

    if (range.inDays <= 7) {
      return 6;
    }

    return 6;
  }

  String _formatAxisLabel(DateTime value) {
    final local = value.toLocal();

    // -------------------------------------------------------------------------
    // 1 DAY
    // -------------------------------------------------------------------------

    if (range.inHours <= 24) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }

    // -------------------------------------------------------------------------
    // 7 DAYS
    // -------------------------------------------------------------------------

    if (range.inDays <= 7) {
      return '${local.day.toString().padLeft(2, '0')} '
          '${_monthShort(local.month)}';
    }

    // -------------------------------------------------------------------------
    // 30 DAYS
    // -------------------------------------------------------------------------

    return '${local.day.toString().padLeft(2, '0')} '
        '${_monthShort(local.month)}';
  }

  String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  MarketSnapshot? _findNearestSnapshot(
    List<MarketSnapshot> snapshots,
    double x,
  ) {
    if (snapshots.isEmpty) {
      return null;
    }

    final firstTime = snapshots.first.snapshotAt.toLocal();

    MarketSnapshot? nearest;
    double smallestDistance = double.infinity;

    for (final snapshot in snapshots) {
      final time = snapshot.snapshotAt.toLocal();

      final seconds = time.difference(firstTime).inMilliseconds /
          Duration.millisecondsPerSecond;

      final distance = (seconds - x).abs();

      if (distance < smallestDistance) {
        smallestDistance = distance;
        nearest = snapshot;
      }
    }

    return nearest;
  }

  // ===========================================================================
  // TOUCH
  // ===========================================================================

  LineTouchData _buildTouchData(
    BuildContext context,
    Color trendColor,
    List<MarketSnapshot> snapshots, {
    required double minX,
    required double maxX,
  }) {
    final colors = _colors(context);

    return LineTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      touchSpotThreshold: 18,
      getTouchedSpotIndicator: (
        LineChartBarData barData,
        List<int> spotIndexes,
      ) {
        return spotIndexes.map((index) {
          return TouchedSpotIndicatorData(
            FlLine(
              color: trendColor.withValues(
                alpha: 0.42,
              ),
              strokeWidth: 1,
              dashArray: const [4, 4],
            ),
            FlDotData(
              show: true,
              getDotPainter: (
                spot,
                percent,
                bar,
                index,
              ) {
                return FlDotCirclePainter(
                  radius: 4.5,
                  color: trendColor,
                  strokeWidth: 2,
                  strokeColor: colors.card,
                );
              },
            ),
          );
        }).toList();
      },
      touchTooltipData: LineTouchTooltipData(
        tooltipPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        tooltipMargin: 10,
        maxContentWidth: 160,
        getTooltipColor: (_) => colors.elevated,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final snapshot = _findSnapshotForX(
              snapshots,
              spot.x,
            );

            if (snapshot == null) {
              return null;
            }

            return LineTooltipItem(
              '',
              const TextStyle(),
              children: [
                TextSpan(
                  text: _formatPrice(
                    snapshot.priceUsd!,
                  ),
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                TextSpan(
                  text:
                      '\n${_formatDateTime(snapshot.snapshotAt)}',
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  MarketSnapshot? _findSnapshotForX(
    List<MarketSnapshot> snapshots,
    double x,
  ) {
    if (snapshots.isEmpty) {
      return null;
    }

    final firstTime = snapshots.first.snapshotAt.toLocal();

    MarketSnapshot? nearest;
    double smallestDistance = double.infinity;

    for (final snapshot in snapshots) {
      final time = snapshot.snapshotAt.toLocal();

      final snapshotX =
          time.difference(firstTime).inMilliseconds /
              Duration.millisecondsPerSecond;

      final distance = (snapshotX - x).abs();

      if (distance < smallestDistance) {
        smallestDistance = distance;
        nearest = snapshot;
      }
    }

    return nearest;
  }

  // ===========================================================================
  // LINE
  // ===========================================================================

  LineChartBarData _buildLine(
    BuildContext context, {
    required List<FlSpot> spots,
    required Color color,
  }) {
    final colors = _colors(context);

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.20,
      color: color,
      barWidth: 2.4,
      isStrokeCapRound: true,
      isStrokeJoinRound: true,
      dotData: const FlDotData(
        show: false,
      ),
      shadow: Shadow(
        color: color.withValues(alpha: 0.16),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.13),
            color.withValues(alpha: 0.035),
            colors.card.withValues(alpha: 0.0),
          ],
          stops: const [
            0.0,
            0.55,
            1.0,
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FORMATTERS
  // ===========================================================================

  String _formatPrice(double value) {
    if (value >= 1000) {
      return '\$${_formatCompact(value)}';
    }

    if (value >= 1) {
      return '\$${value.toStringAsFixed(2)}';
    }

    if (value >= 0.01) {
      return '\$${value.toStringAsFixed(4)}';
    }

    return '\$${value.toStringAsFixed(8)}';
  }

  String _formatCompact(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    }

    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }

    return value.toStringAsFixed(2);
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  double _calculatePriceInterval(
    double minPrice,
    double maxPrice,
  ) {
    final priceRange = maxPrice - minPrice;

    if (priceRange <= 0) {
      return maxPrice == 0
          ? 1
          : maxPrice.abs() * 0.1;
    }

    return priceRange / 4;
  }
}

// =============================================================================
// CHART BOUNDS
// =============================================================================

class _ChartBounds {
  final double dataMin;
  final double dataMax;
  final double minY;
  final double maxY;

  const _ChartBounds({
    required this.dataMin,
    required this.dataMax,
    required this.minY,
    required this.maxY,
  });
}

// =============================================================================
// EMPTY STATE
// =============================================================================

class _ChartEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ChartEmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppThemeColors>()!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: colors.secondaryText,
            size: 26,
          ),
        ),
        const SizedBox(height: 11),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
