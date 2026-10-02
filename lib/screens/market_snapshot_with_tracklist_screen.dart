import 'package:flutter/material.dart';

import '../core/theme/app_theme_colors.dart';
import '../models/coin.dart';
import '../models/market_snapshot.dart';
import 'market_snapshot_detail_screen.dart';

// Public model class to pair Coin and Snapshot safely
class CoinWithSnapshot {
  final Coin coin;
  final MarketSnapshot snapshot;

  const CoinWithSnapshot({
    required this.coin,
    required this.snapshot,
  });
}

class MarketSnapshotWithTracklistScreen extends StatefulWidget {
  final int initialCoinId;
  final List<CoinWithSnapshot> assets;

  const MarketSnapshotWithTracklistScreen({
    super.key,
    required this.initialCoinId,
    required this.assets,
  });

  @override
  State<MarketSnapshotWithTracklistScreen> createState() =>
      _MarketSnapshotWithTracklistScreenState();
}

class _MarketSnapshotWithTracklistScreenState
    extends State<MarketSnapshotWithTracklistScreen> {
  late int _currentCoinId;

  @override
  void initState() {
    super.initState();
    _currentCoinId = widget.initialCoinId;
  }

  AppThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()!;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
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
                              // LEFT SIDE: Market Snapshot Detail takes 7/10 width
                              Expanded(
                                flex: 7,
                                child: MarketSnapshotDetailScreen(
                                  key: ValueKey('market-$_currentCoinId'),
                                  coinId: _currentCoinId,
                                ),
                              ),

                              // DIVIDER LINE
                              Container(
                                width: 1,
                                margin: const EdgeInsets.symmetric(horizontal: 28),
                                color: colors.border,
                              ),

                              // RIGHT SIDE: Interactive Tracklist Sidebar takes 3/10 width
                              Expanded(
                                flex: 3,
                                child: SingleChildScrollView(
                                  child: _buildTracklistSidebar(context),
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

          // MOBILE VIEW: Fullscreen snapshot with proper column layout
          return SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, false),
                Expanded(
                  child: MarketSnapshotDetailScreen(
                    key: ValueKey('market-$_currentCoinId'),
                    coinId: _currentCoinId,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDesktop) {
    final colors = _colors(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
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
                    isDesktop ? 'Back to Market Overview' : 'Back',
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

  Widget _buildTracklistSidebar(BuildContext context) {
    final colors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MAIN INDEX TRACKLIST',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Select an asset to update market snapshot',
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            for (int i = 0; i < widget.assets.length; i++) ...[
              _buildSidebarTile(widget.assets[i], i + 1),
              if (i < widget.assets.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSidebarTile(CoinWithSnapshot item, int rank) {
    final colors = _colors(context);
    final isSelected = item.coin.id == _currentCoinId;
    final change = item.snapshot.priceChange24h ?? 0;
    final changeColor = change >= 0 ? colors.accent : colors.bearish;

    return InkWell(
      onTap: () {
        setState(() {
          _currentCoinId = item.coin.id;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.card : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.accent.withValues(alpha: 0.4) : colors.border,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
                      fontSize: 12,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.snapshot.priceUsd?.toStringAsFixed(2) ?? '0'}',
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: changeColor,
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
}