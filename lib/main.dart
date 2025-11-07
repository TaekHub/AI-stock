// 파일명: main.dart
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api.dart';
import 'widgets/ticker_search.dart';
import 'widgets/line_chart_widget.dart';
import 'widgets/indicator_table_widget.dart';
import 'widgets/news_widget.dart';
import 'widgets/indicator_chart_widget.dart';
import 'widgets/stock_list_widget.dart';
import 'dart:convert';
import 'app_intro_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialPage() async {
    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool('agreedToDisclaimer') ?? false;
    return agreed ? const StockListPage() : const AppIntroPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '주가 분석 앱',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.data!;
          }
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        },
      ),
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
  List<Map<String, dynamic>> favoriteStocks = [];

  @override
  void initState() {
    super.initState();
    checkServer();
    fetchGeneralNews();
    loadFavorites();
  }

  Future<void> checkServer() async {
    final isServerUp = await checkServerStatus();
    setState(() {
      serverAvailable = isServerUp;
    });
    if (!isServerUp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버에 연결할 수 없습니다. 백엔드 서버를 확인하세요.')),
      );
    }
  }

  Future<void> fetchGeneralNews() async {
    setState(() {
      isLoading = true;
    });
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

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorites');
    if (favoritesJson != null) {
      final List<dynamic> favorites = jsonDecode(favoritesJson);
      setState(() {
        favoriteStocks = favorites.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites', jsonEncode(favoriteStocks));
  }

  void toggleFavorite(Map<String, dynamic> stock) {
    setState(() {
      final index = favoriteStocks.indexWhere((item) => item['ticker'] == stock['ticker'] && item['market'] == stock['market']);
      if (index >= 0) {
        favoriteStocks.removeAt(index);
      } else {
        favoriteStocks.add(stock);
      }
    });
    saveFavorites();
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
              selectedIndex: _selectedIndex,
              onIndexChanged: _onItemTapped,
              toggleFavorite: toggleFavorite,
              favoriteStocks: favoriteStocks,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.show_chart, color: Colors.blueAccent, size: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '주식 투자 통합 분석 플랫폼',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
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
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              dropdownColor: Colors.grey[800],
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearchDialog(context),
            padding: const EdgeInsets.only(right: 16),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01, horizontal: screenWidth * 0.03),
            color: Colors.grey[850]!.withOpacity(0.7), // 불투명도 조정
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: screenWidth * 0.05,
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    '이 앱은 주식 투자의 도움을 주고자 지표 분석만 하며,\n투자의 책임은 본인에게 있습니다.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.orange,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: !serverAvailable
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    '데이터를 불러올 수 없습니다',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '서버에 연결할 수 없습니다',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: checkServer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('재시도'),
                  ),
                ],
              ),
            )
                : isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text(
                    '데이터를 불러오는 중입니다',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
                : _selectedIndex == 0
                ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Text(
                      '해외 인기 종목',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: screenHeight * 0.4,
                      child: StockListWidget(
                        market: 'US',
                        showPopularOnly: true,
                        selectedIndex: _selectedIndex,
                        onIndexChanged: _onItemTapped,
                        toggleFavorite: toggleFavorite,
                        favoriteStocks: favoriteStocks,
                      ),
                    ),
                  ),
                  const Divider(
                    color: Colors.grey,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Text(
                      '국내 인기 종목',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: screenHeight * 0.4,
                      child: StockListWidget(
                        market: 'KR',
                        showPopularOnly: true,
                        selectedIndex: _selectedIndex,
                        onIndexChanged: _onItemTapped,
                        toggleFavorite: toggleFavorite,
                        favoriteStocks: favoriteStocks,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.1),
                ],
              ),
            )
                : _selectedIndex == 1
                ? NewsWidget(
              ticker: 'general',
              market: selectedMarket,
            )
                : favoriteStocks.isEmpty
                ? Center(
              child: Text(
                '관심목록에 추가된 종목이 없습니다.',
                style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.05),
              ),
            )
                : ListView.builder(
              itemCount: favoriteStocks.length,
              itemBuilder: (context, index) {
                final stock = favoriteStocks[index];
                return ListTile(
                  leading: const Icon(Icons.circle, color: Colors.green, size: 10),
                  title: Text(
                    stock['name'] as String,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: screenWidth * 0.06,
                    ),
                    onPressed: () {
                      toggleFavorite(stock);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StockHomePage(
                          ticker: stock['ticker'] as String,
                          market: stock['market'] as String,
                          selectedIndex: _selectedIndex,
                          onIndexChanged: _onItemTapped,
                          toggleFavorite: toggleFavorite,
                          favoriteStocks: favoriteStocks,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
        selectedLabelStyle: TextStyle(fontSize: screenWidth * 0.035, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: screenWidth * 0.035),
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
  final Function(Map<String, dynamic>) toggleFavorite;
  final List<Map<String, dynamic>> favoriteStocks;

  const StockHomePage({
    super.key,
    required this.ticker,
    required this.market,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.toggleFavorite,
    required this.favoriteStocks,
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
  bool isLoading = true;
  String? errorMessage;

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
      setState(() {
        isLoading = false;
        errorMessage = '종목이 선택되지 않았습니다';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

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
        news = newsData['news'];
        selectedTicker = ticker;
        selectedTickerName = tickerInfo['name'] ?? ticker;
        isLoading = false;
      });
    } catch (e) {
      print('데이터 로드 오류: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
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

  void handleIndicatorTap(String group) {
    setState(() {
      selectedGroups = [group];
      _tabController.animateTo(3);
    });
  }

  bool isFavorite() {
    return widget.favoriteStocks.any((stock) => stock['ticker'] == selectedTicker && stock['market'] == selectedMarket);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndicatorKeys = getSelectedIndicatorKeys();

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

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
          style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite() ? Icons.star : Icons.star_border,
              color: isFavorite() ? Colors.yellow : Colors.grey,
              size: screenWidth * 0.06,
            ),
            onPressed: () {
              widget.toggleFavorite({
                'ticker': selectedTicker,
                'market': selectedMarket,
                'name': selectedTickerName,
              });
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01, horizontal: screenWidth * 0.03),
            color: Colors.grey[850]!.withOpacity(0.7),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: screenWidth * 0.05,
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    '이 앱은 주식 투자의 도움을 주고자 지표 분석만 하며, \n투자의 책임은 본인에게 있습니다.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.orange,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text(
                    '데이터를 불러오는 중입니다',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
                : errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    '데이터를 불러올 수 없습니다',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => fetchData(selectedTicker),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('재시도'),
                  ),
                ],
              ),
            )
                : _selectedIndex == 0
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (change != null && changePercent != null)
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedTickerName,
                          style: TextStyle(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              selectedMarket == 'KR'
                                  ? '${closes.last.toInt()}'
                                  : '${closes.last.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Text(
                              selectedMarket == 'KR'
                                  ? '${change >= 0 ? '+' : ''}${change.toInt()} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)'
                                  : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                color: change >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: screenHeight * 0.02),
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
                                  SizedBox(height: 36),
                                  Container(
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
                            SingleChildScrollView(
                              child: IndicatorTableWidget(
                                indicators: indicators,
                                onIndicatorTap: handleIndicatorTap,
                              ),
                            ),
                            NewsWidget(
                              ticker: selectedTicker,
                              market: selectedMarket,
                            ),
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(height: screenHeight * 0.02),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.06,
                                        vertical: screenHeight * 0.015,
                                      ),
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
                                    child: Text(
                                      '지표 선택',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
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
              ],
            )
                : _selectedIndex == 1
                ? NewsWidget(
              ticker: selectedTicker,
              market: selectedMarket,
            )
                : widget.favoriteStocks.isEmpty
                ? const Center(child: Text('관심목록에 추가된 종목이 없습니다.', style: TextStyle(color: Colors.white)))
                : ListView.builder(
              itemCount: widget.favoriteStocks.length,
              itemBuilder: (context, index) {
                final stock = widget.favoriteStocks[index];
                return ListTile(
                  title: Text(
                    stock['name'] as String,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StockHomePage(
                          ticker: stock['ticker'] as String,
                          market: stock['market'] as String,
                          selectedIndex: _selectedIndex,
                          onIndexChanged: widget.onIndexChanged,
                          toggleFavorite: widget.toggleFavorite,
                          favoriteStocks: widget.favoriteStocks,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
        selectedLabelStyle: TextStyle(fontSize: screenWidth * 0.035, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: screenWidth * 0.035),
        onTap: widget.onIndexChanged,
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