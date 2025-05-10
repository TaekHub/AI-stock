// main.dart
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'services/api.dart';
import 'widgets/ticker_search.dart';
import 'widgets/line_chart_widget.dart';
import 'widgets/compare_change_widget.dart';
import 'widgets/indicator_table_widget.dart';
import 'widgets/news_widget.dart';
import 'widgets/volume_chart_widget.dart';
import 'widgets/indicator_chart_widget.dart';
import 'widgets/stock_list_widget.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '주가 분석 앱',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900], // 전체 배경 색상 조정
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      home: const StockListPage(),
    );
  }
}

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> with TickerProviderStateMixin {
  String selectedMarket = 'US';
  int _selectedIndex = 0;
  List<dynamic> news = [];
  bool isLoading = true;
  bool serverAvailable = true;

  @override
  void initState() {
    super.initState();
    checkServer();
    fetchGeneralNews();
  }

  Future<void> checkServer() async {
    final isServerUp = await checkServerStatus();
    setState(() {
      serverAvailable = isServerUp;
    });
    if (!isServerUp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버에 연결할 수 없습니다. 백엔드 서버를 확인하세요.')),
      );
    }
  }

  Future<void> fetchGeneralNews() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        news = [
          {'title': '시장 뉴스 1', 'content': '시장 관련 뉴스 내용 1'},
          {'title': '시장 뉴스 2', 'content': '시장 관련 뉴스 내용 2'},
        ];
        isLoading = false;
      });
    } catch (e) {
      print('전체 뉴스 로드 실패: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TickerSearch(
              market: selectedMarket,
              onTickerSelected: (ticker) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockHomePage(
                      ticker: ticker,
                      market: selectedMarket,
                      selectedIndex: _selectedIndex,
                      onIndexChanged: _onItemTapped,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.show_chart, color: Colors.blueAccent, size: 32), // 아이콘 색상 변경
            const SizedBox(width: 8),
            const Text(
              '주식 투자 통합 분석 플랫폼',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: selectedMarket,
              onChanged: (String? newValue) {
                setState(() {
                  selectedMarket = newValue!;
                });
              },
              items: <String>['US', 'KR']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value == 'US' ? '해외 주식' : '국내 주식',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              dropdownColor: Colors.grey[800],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _showSearchDialog(context),
            ),
          ],
        ),
      ),
      body: !serverAvailable
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '서버에 연결할 수 없습니다.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: checkServer,
              child: Text('재시도', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      )
          : isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedIndex == 0
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '해외 인기 종목',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StockListWidget(
              market: 'US',
              showPopularOnly: true,
              selectedIndex: _selectedIndex,
              onIndexChanged: _onItemTapped,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '국내 인기 종목',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StockListWidget(
              market: 'KR',
              showPopularOnly: true,
              selectedIndex: _selectedIndex,
              onIndexChanged: _onItemTapped,
            ),
          ),
        ],
      )
          : _selectedIndex == 1
          ? NewsWidget(news: news)
          : const Center(child: Text('관심목록 탭', style: TextStyle(color: Colors.white))),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up, size: 28),
            label: '시장',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper, size: 28),
            label: '뉴스',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star, size: 28),
            label: '관심목록',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent, // 선택 색상 변경
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 14),
        onTap: _onItemTapped,
        backgroundColor: Colors.grey[850],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class StockHomePage extends StatefulWidget {
  final String ticker;
  final String market;
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const StockHomePage({
    super.key,
    required this.ticker,
    required this.market,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  State<StockHomePage> createState() => _StockHomePageState();
}

class _StockHomePageState extends State<StockHomePage> with TickerProviderStateMixin {
  String selectedTicker = '';
  String selectedMarket = 'US';
  String selectedTickerName = '';
  List<String> dates = [];
  List<double> closes = [];
  List<double> volumes = [];
  Map<String, dynamic> indicators = {};
  Map<String, List<double?>> indicatorsSeries = {};
  List<dynamic> news = [];
  late TabController _tabController;
  int _selectedIndex = 0;

  final Map<String, List<String>> groupedIndicators = {
    'RSI': ['RSI'],
    'MACD': ['MACD'],
    'Stochastic': ['SlowK', 'SlowD'],
    'SMA': ['SMA10', 'SMA50'],
    'EMA': ['EMA20', 'EMA50'],
    'Bollinger Band': ['BB_upper', 'BB_lower'],
    'CCI': ['CCI'],
    'MFI': ['MFI'],
    'ADX': ['ADX'],
  };

  List<String> selectedGroups = ['RSI', 'MACD'];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _tabController = TabController(length: 4, vsync: this);
    selectedTicker = widget.ticker;
    selectedMarket = widget.market;
    fetchData(widget.ticker);
  }

  Future<void> fetchData(String ticker) async {
    if (ticker.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종목을 선택해주세요!')),
      );
      return;
    }

    try {
      final data = await fetchStockData(ticker, selectedMarket, period: "3mo");
      final newsData = await fetchNews(ticker, selectedMarket);
      final tickerInfo = await fetchTickerInfo(ticker, selectedMarket);

      setState(() {
        dates = List<String>.from(data['dates'] ?? []);
        closes = List<double>.from(data['closes']?.map((e) => (e as num).toDouble()) ?? []);
        volumes = List<double>.from(data['volumes']?.map((e) => (e as num).toDouble()) ?? []);
        indicators = Map<String, dynamic>.from(data['indicators'] ?? {});
        indicatorsSeries = Map<String, List<double?>>.from(
          data['indicators_series']?.map((k, v) => MapEntry(k, List<double?>.from(v))) ?? {},
        );
        news = newsData;
        selectedTicker = ticker;
        selectedTickerName = tickerInfo['name'] ?? ticker;
      });
    } catch (e) {
      print('데이터 로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  List<String> getSelectedIndicatorKeys() {
    final List<String> keys = [];
    for (final group in selectedGroups) {
      final sublist = groupedIndicators[group];
      if (sublist != null) keys.addAll(sublist);
    }
    return keys;
  }

  // 추가: 지표 클릭 시 호출되는 메서드
  void handleIndicatorTap(String group) {
    setState(() {
      selectedGroups = [group]; // 클릭한 지표 그룹만 선택
      _tabController.animateTo(3); // "분석" 탭으로 이동 (인덱스 3)
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndicatorKeys = getSelectedIndicatorKeys();

    double? change;
    double? changePercent;
    if (closes.length >= 2) {
      final currentClose = closes.last;
      final previousClose = closes[closes.length - 2];
      change = currentClose - previousClose;
      changePercent = (change / previousClose) * 100;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedTickerName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: _selectedIndex == 0
          ? Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (change != null && changePercent != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedTickerName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        selectedMarket == 'KR'
                            ? '${closes.last.toInt()}'
                            : '${closes.last.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        selectedMarket == 'KR'
                            ? '${change >= 0 ? '+' : ''}${change.toInt()} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)'
                            : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: change >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 20),
            if (dates.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.trending_up, size: 24),
                          child: Text(
                            '개요',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Tab(
                          icon: Icon(Icons.table_chart, size: 24),
                          child: Text(
                            '기술적',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Tab(
                          icon: Icon(Icons.newspaper, size: 24),
                          child: Text(
                            '뉴스',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Tab(
                          icon: Icon(Icons.bar_chart, size: 24),
                          child: Text(
                            '분석',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blueAccent,
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 300,
                                  child: LineChartWidget(
                                    dates: dates,
                                    closes: closes,
                                    volumes: volumes,
                                    isKoreanMarket: selectedMarket == 'KR',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IndicatorTableWidget(
                            indicators: indicators,
                            onIndicatorTap: handleIndicatorTap, // 콜백 전달
                          ),
                          NewsWidget(news: news),
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return MultiSelectDialog(
                                          items: groupedIndicators.keys
                                              .map((group) => MultiSelectItem(group, group))
                                              .toList(),
                                          initialValue: selectedGroups,
                                          onConfirm: (values) {
                                            setState(() {
                                              selectedGroups = values.cast<String>();
                                            });
                                          },
                                          title: const Text(
                                            '지표 선택',
                                            style: TextStyle(color: Colors.white, fontSize: 18),
                                          ),
                                          searchable: true,
                                          selectedColor: Colors.blueAccent,
                                          unselectedColor: Colors.grey,
                                          itemsTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          selectedItemsTextStyle: const TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: const Text(
                                    '지표 선택',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                IndicatorChartWidget(
                                  dates: dates,
                                  indicators: indicators,
                                  indicatorsSeries: indicatorsSeries,
                                  selectedGroups: selectedGroups,
                                  groupedIndicators: groupedIndicators,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (dates.isEmpty)
              Center(
                child: Text(
                  '데이터를 불러올 수 없습니다.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
          ],
        ),
      )
          : _selectedIndex == 1
          ? NewsWidget(news: news)
          : const Center(child: Text('관심목록 탭', style: TextStyle(color: Colors.white))),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up, size: 28),
            label: '시장',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper, size: 28),
            label: '뉴스',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star, size: 28),
            label: '관심목록',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 14),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          widget.onIndexChanged(index);
        },
        backgroundColor: Colors.grey[850],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}