import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/currency_data.dart';
import '../../../presentation/home/currency_provider.dart';
import '../../../presentation/currency_manage_screen.dart';
import '../../../services/admob_service.dart';
import '../services/exchange_rate_service.dart';
import '../../../presentation/widgets/global_banner_ad.dart';

class ExchangeRateScreen extends ConsumerStatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  ConsumerState<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends ConsumerState<ExchangeRateScreen> {
  String _selectedBase = 'KRW';
  String _selectedTarget = 'USD';
  String _selectedRange = '1W'; // Default to 1 Week

  List<dynamic> _chartData = [];
  bool _isLoading = false;
  double _currentRate = 0.0;
  double _minRate = 0.0;
  double _maxRate = 0.0;
  double _avgRate = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithSelectedId();
    });
  }

  void _initializeWithSelectedId() {
    final selectedId = ref.read(selectedCurrencyIdProvider);
    if (selectedId != null) {
      _selectedTarget = selectedId.split(':').last;
    } else {
      final favorites = ref.read(favoriteCurrenciesProvider);
      if (favorites.isNotEmpty) {
        _selectedTarget = favorites.first.split(':').last;
      }
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final service = ref.read(exchangeRateServiceProvider);

    // Latest rate from cache - DB base is always 'KRW'
    final rates = await service.getLatestRates('KRW');
    if (rates.containsKey(_selectedTarget)) {
      final rate = rates[_selectedTarget]!;
      _currentRate = rate == 0 ? 0 : (1 / rate);
    }

    // Chart data from fx_history - Base should be selected currency, target KRW
    final data = await service.getChartData(
      base: _selectedTarget,
      target: _selectedBase,
      range: _selectedRange,
    );

    _chartData = data.isEmpty ? _generateMockData(_selectedRange) : data;

    // Calculate Min/Max/Avg
    if (_chartData.isNotEmpty) {
      final values = _chartData.map((e) => (e['v'] as num).toDouble()).toList();
      _minRate = values.reduce((a, b) => a < b ? a : b);
      _maxRate = values.reduce((a, b) => a > b ? a : b);
      _avgRate = values.reduce((a, b) => a + b) / values.length;
    }

    setState(() => _isLoading = false);
  }

  List<dynamic> _generateMockData(String range) {
    int count = range == '1W'
        ? 7
        : (range == '1M' ? 30 : (range == '6M' ? 180 : 365));
    final now = DateTime.now();
    return List.generate(count, (i) {
      return {
        "d": DateFormat(
          'yyyy-MM-dd',
        ).format(now.subtract(Duration(days: count - 1 - i))),
        "v": (1300.0 + (i * 2 + (i % 3 * 10)) % 60).roundToDouble(),
      };
    });
  }

  void _onCurrencySelected(String key) {
    setState(() {
      _selectedTarget = key.split(':').last;
      _selectedRange = '1W'; // Reset to 1W on currency switch
    });
    ref.read(selectedCurrencyIdProvider.notifier).setSelectedId(key);
    _loadData();
  }

  String _formatRate(double value) {
    if (value < 100) {
      return NumberFormat('#,##0.00').format(value);
    }
    return NumberFormat('#,##0').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favoriteCodes = ref.watch(favoriteCurrenciesProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "환율 추이",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CurrencyManageScreen()),
            ).then((_) => setState(() {})),
          ),
        ],
      ),
      body: Column(
        children: [
          // Favorite Horizontal List
          _buildFavoriteList(favoriteCodes),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildCurrentInfo(isDark),
                            const SizedBox(height: 12),
                            _buildPeriodSelector(isDark),
                            const SizedBox(height: 16),
                            _buildStatsCards(isDark),
                            const SizedBox(height: 16),
                            _buildChartSection(isDark),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const GlobalBannerAd(),
        ],
      ),
    );
  }

  Widget _buildFavoriteList(List<String> keys) {
    if (keys.isEmpty) return const SizedBox.shrink();

    // Find the full key for the currently selected target code to maintain sync
    String selectedKey = keys.firstWhere(
      (k) => k.endsWith(":$_selectedTarget") || k == _selectedTarget,
      orElse: () => _selectedTarget,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: _HorizontalDialPicker<String>(
        items: keys,
        selectedValue: selectedKey,
        onChanged: _onCurrencySelected,
        viewportFraction: 0.35,
        itemBuilder: (context, key, opacity, scale) {
          final isSelected = selectedKey == key;
          final parts = key.split(':');

          // New Structure: Name:Code
          // Old Structure: Code (fallback)
          final name = parts[0];
          final code = parts.length > 1 ? parts[1] : parts[0];

          return Text(
            "${CurrencyData.getFlag(name)} $code",
            style: TextStyle(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color:
                  (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black)
                      .withOpacity(opacity),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentInfo(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(
              "${CurrencyData.getCountryName(_selectedTarget)} ",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _selectedTarget,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _formatRate(_currentRate),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              "원",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: ['1W', '1M', '6M', '1Y'].map((range) {
          final isSelected = _selectedRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (range == '1Y') {
                  // 1. Start background loading immediately
                  _loadData();

                  // 2. Show ad while loading
                  AdMobService.instance.showInterstitialAd(
                    onAdDismissed: () {
                      if (mounted) {
                        setState(() => _selectedRange = range);
                        // Data is already loading/loaded in background
                      }
                    },
                  );
                } else {
                  setState(() => _selectedRange = range);
                  _loadData();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  range,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white30 : Colors.grey[600]),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCards(bool isDark) {
    return Row(
      children: [
        _buildStatCard("최고", _maxRate, const Color(0xFFEF4444), isDark),
        const SizedBox(width: 8),
        _buildStatCard("최저", _minRate, const Color(0xFF10B981), isDark),
        const SizedBox(width: 8),
        _buildAvgCard("평균", _avgRate, isDark),
      ],
    );
  }

  Widget _buildStatCard(String title, double value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "${_formatRate(value)}원",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvgCard(String title, double value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white30 : Colors.black38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "${_formatRate(value)}원",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(bool isDark) {
    return Container(
      height: 350,
      width: double.infinity,
      padding: const EdgeInsets.only(right: 15, top: 20, bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: _minRate * 0.995,
          maxY: _maxRate * 1.005,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white10 : Colors.grey[100]!,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _chartData.length) {
                    if (value.toInt() % (_chartData.length / 5).ceil() == 0) {
                      final dateStr = _chartData[value.toInt()]['d'] as String;
                      final date = DateTime.parse(dateStr);
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _formatRate(value),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _chartData
                  .asMap()
                  .entries
                  .map(
                    (e) => FlSpot(
                      e.key.toDouble(),
                      (e.value['v'] as num).toDouble(),
                    ),
                  )
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFF3B82F6),
              barWidth: _selectedRange == '1W'
                  ? 4
                  : (_selectedRange == '1M' ? 3 : 2),
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.2),
                    const Color(0xFF3B82F6).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF3B82F6) : Colors.black87,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = _chartData[spot.x.toInt()]['d'];
                  return LineTooltipItem(
                    "$date\n${_formatRate(spot.y)}원",
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalDialPicker<T> extends StatefulWidget {
  final List<T> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final Widget Function(BuildContext, T, double opacity, double scale)
  itemBuilder;
  final double viewportFraction;

  const _HorizontalDialPicker({
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    required this.itemBuilder,
    required this.viewportFraction,
  });

  @override
  State<_HorizontalDialPicker<T>> createState() =>
      __HorizontalDialPickerState<T>();
}

class __HorizontalDialPickerState<T> extends State<_HorizontalDialPicker<T>> {
  late PageController _controller;
  late double _currentPage;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.items.indexOf(widget.selectedValue);
    _currentPage = initialIndex >= 0 ? initialIndex.toDouble() : 0;
    _controller = PageController(
      initialPage: initialIndex >= 0 ? initialIndex : 0,
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_HorizontalDialPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      final index = widget.items.indexOf(widget.selectedValue);
      if (index >= 0) {
        // Use jumpToPage typically for setup changes, or animate if you prefer smooth transition
        // Using animate for better UX if the user didn't initiate it via scroll
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller.hasClients) {
            _controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF2F2F7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                setState(() {
                  _currentPage = _controller.page ?? 0;
                });
              }
              if (notification is ScrollEndNotification) {
                final int newIndex = _controller.page!.round();
                if (widget.items[newIndex] != widget.selectedValue) {
                  HapticFeedback.lightImpact();
                  widget.onChanged(widget.items[newIndex]);
                }
              }
              return true;
            },
            child: PageView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final double difference = (index - _currentPage).abs();
                final double opacity = (1 - (difference * 0.5)).clamp(0.2, 1.0);
                final double scale = (1.1 - (difference * 0.1)).clamp(0.9, 1.1);

                return Center(
                  child: widget.itemBuilder(
                    context,
                    widget.items[index],
                    opacity,
                    scale,
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF2C2C2E),
                            const Color(0xFF2C2C2E).withOpacity(0),
                            const Color(0xFF2C2C2E).withOpacity(0),
                            const Color(0xFF2C2C2E),
                          ]
                        : [
                            Colors.white,
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0),
                            Colors.white,
                          ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            child: IgnorePointer(
              child: Icon(
                CupertinoIcons.chevron_left,
                size: 16,
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            right: 12,
            child: IgnorePointer(
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
