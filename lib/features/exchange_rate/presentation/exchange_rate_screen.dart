import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/currency_data.dart';
import '../../../presentation/home/currency_provider.dart';
import '../../../presentation/currency_manage_screen.dart';
import '../services/exchange_rate_service.dart';

class ExchangeRateScreen extends ConsumerStatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  ConsumerState<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends ConsumerState<ExchangeRateScreen> {
  String _selectedBase = 'KRW';
  String _selectedTarget = 'USD';
  String _selectedTargetCountry = '미국';
  String _selectedRange = '1M';

  List<dynamic> _chartData = [];
  bool _isLoading = false;
  double _currentRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final service = ref.read(exchangeRateServiceProvider);

    // Load latest rate from cache
    final rates = await service.getLatestRates(_selectedBase);
    if (rates.containsKey(_selectedTarget)) {
      _currentRate = rates[_selectedTarget]!;
      // Inverse for KRW base display (usually we want Target/KRW rate, but here we have KRW based rates)
      // If base is KRW, rates['USD'] is 0.00075. We usually want USD/KRW = 1333.
      if (_selectedBase == 'KRW') {
        _currentRate = _currentRate == 0 ? 0 : (1 / _currentRate);
      }
    } else if (rates.isEmpty) {
      // Placeholder if no cache
      _currentRate = 1335.0;
    }

    // Load chart data
    final data = await service.getChartData(
      base: _selectedTarget,
      target: _selectedBase,
      range: _selectedRange,
    );

    // Fallback Mock Data if empty (since DB might be empty)
    if (data.isEmpty) {
      _chartData = _generateMockData(_selectedRange);
    } else {
      _chartData = data;
    }

    setState(() => _isLoading = false);
  }

  List<dynamic> _generateMockData(String range) {
    int count = range == '1W'
        ? 7
        : (range == '1M' ? 30 : (range == '6M' ? 26 : 12));
    final now = DateTime.now();
    return List.generate(count, (i) {
      return {
        "d": DateFormat(
          'yyyy-MM-dd',
        ).format(now.subtract(Duration(days: count - 1 - i))),
        "v": 1300.0 + (i * 2) % 50, // Mock variation
      };
    });
  }

  void _showCurrencyPicker(List<String> favoriteCodes) {
    if (favoriteCodes.isEmpty) {
      _showNoFavoritesDialog();
      return;
    }

    // Create list of {name, code}
    final items = favoriteCodes.map((code) {
      final name = CurrencyData.getCountryName(code);
      return {'name': name, 'code': code};
    }).toList();

    int tempIndex = items.indexWhere((i) => i['code'] == _selectedTarget);
    if (tempIndex < 0) tempIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text(
                      "관리",
                      style: TextStyle(color: Colors.grey),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToManage();
                    },
                  ),
                  const Text(
                    "국가 선택",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      color: Colors.grey,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text(
                      "확인",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      final selected = items[tempIndex];
                      setState(() {
                        _selectedTargetCountry = selected['name']!;
                        _selectedTarget = selected['code']!;
                        _loadData();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: tempIndex,
                ),
                itemExtent: 44,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                onSelectedItemChanged: (index) => tempIndex = index,
                children: items.map((item) {
                  return Center(
                    child: Text(
                      "${item['name']} (${item['code']})",
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoFavoritesDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("즐겨찾기 없음"),
        content: const Text("환율 정보를 보려면 먼저 즐겨찾는 국가를 등록해야 합니다."),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("관리 페이지로 이동"),
            onPressed: () {
              Navigator.pop(context);
              _navigateToManage();
            },
          ),
        ],
      ),
    );
  }

  void _navigateToManage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CurrencyManageScreen()),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favoriteCodes = ref.watch(favoriteCurrenciesProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          "환율 추이",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.settings),
            onPressed: _navigateToManage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Card: Currency Selector & Current Rate
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showCurrencyPicker(favoriteCodes),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$_selectedTargetCountry ($_selectedTarget)",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    NumberFormat('#,##0.00').format(_currentRate),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    "1 $_selectedTarget = $_currentRate KRW",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Period Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: ['1W', '1M', '6M', '1Y'].map((range) {
                    final isSelected = _selectedRange == range;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRange = range;
                            _loadData();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            range,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.black
                                  : (isDark ? Colors.white54 : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Chart
            Container(
              height: 300,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _chartData.asMap().entries.map((e) {
                              return FlSpot(
                                e.key.toDouble(),
                                (e.value['v'] as num).toDouble(),
                              );
                            }).toList(),
                            isCurved: true,
                            color: const Color(0xFF30D158),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF30D158).withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 40),
            Text(
              "Data provided by ExchangeRate.host",
              style: TextStyle(
                color: isDark ? Colors.white30 : Colors.grey[400],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
