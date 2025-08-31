// 파일명: main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/indicator_info_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

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
    try {
      // Firestore에서 즐겨찾기 로드
      final snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: 'test_user')
          .get();
      final firestoreFavorites = snapshot.docs.map((doc) => doc.data()).toList();

      // 기존 SharedPreferences 로드 (병행 유지)
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('favorites');
      List<Map<String, dynamic>> localFavorites = [];
      if (favoritesJson != null) {
        final List<dynamic> favorites = jsonDecode(favoritesJson);
        localFavorites = favorites.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      setState(() {
        // Firestore와 로컬 데이터를 병합
        favoriteStocks = [...localFavorites, ...firestoreFavorites];
      });
    } catch (e) {
      print('Firestore load error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기 로드 실패: $e')),
      );
    }
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites', jsonEncode(favoriteStocks));
  }

  void toggleFavorite(Map<String, dynamic> stock) async {
    try {
      final index = favoriteStocks.indexWhere((item) => item['ticker'] == stock['ticker'] && item['market'] == stock['market']);
      if (index >= 0) {
        setState(() {
          favoriteStocks.removeAt(index);
        });
        // Firestore에서 삭제
        final snapshot = await FirebaseFirestore.instance
            .collection('favorites')
            .where('ticker', isEqualTo: stock['ticker'])
            .where('market', isEqualTo: stock['market'])
            .where('userId', isEqualTo: 'test_user')
            .get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      } else {
        setState(() {
          favoriteStocks.add(stock);
        });
        // Firestore에 추가
        await FirebaseFirestore.instance.collection('favorites').add({
          'ticker': stock['ticker'],
          'market': stock['market'],
          'name': stock['name'],
          'timestamp': Timestamp.now(),
          'userId': 'test_user', // 임시, 나중에 Authentication으로 변경
        });
      }
      await saveFavorites();
    } catch (e) {
      print('Firestore error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기 업데이트 실패: $e')),
      );
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
            const Icon(Icons.show_chart, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(
              '주식 투자 통합 분석 플랫폼',
              style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: selectedMarket,
            items: const [
              DropdownMenuItem(value: 'US', child: Text('US')),
              DropdownMenuItem(value: 'KR', child: Text('KR')),
            ],
            onChanged: (value) {
              setState(() {
                selectedMarket = value!;
              });
            },
            dropdownColor: Colors.grey[850],
            style: const TextStyle(color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedIndex == 0
                ? StockListWidget(
              market: selectedMarket,
              showPopularOnly: true,
              selectedIndex: _selectedIndex,
              onIndexChanged: _onItemTapped,
              toggleFavorite: toggleFavorite,
              favoriteStocks: favoriteStocks,
            )
                : _selectedIndex == 1
                ? NewsWidget(
              ticker: '',
              market: selectedMarket,
            )
                : favoriteStocks.isEmpty
                ? const Center(child: Text('관심목록에 추가된 종목이 없습니다.', style: TextStyle(color: Colors.white)))
                : ListView.builder(
              itemCount: favoriteStocks.length,
              itemBuilder: (context, index) {
                final stock = favoriteStocks[index];
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

  @override
  void dispose() {
    super.dispose();
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

class _StockHomePageState extends State<StockHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> dates = [];
  List<double> closes = [];
  List<double> volumes = [];
  Map<String, dynamic> indicators = {};
  Map<String, List<double?>> indicatorsSeries = {};
  List<String> selectedGroups = ['RSI', 'MACD', 'Stochastic'];
  Map<String, List<String>> groupedIndicators = {
    'RSI': ['RSI'],
    'MACD': ['MACD'],
    'Stochastic': ['SlowK', 'SlowD'],
    'SMA': ['SMA10', 'SMA50'],
    'EMA': ['EMA20', 'EMA50'],
    'Bollinger Band': ['BB_upper', 'BB_lower'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch stock data here (omitted for brevity, add your existing logic)
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ticker,
          style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '차트'),
            Tab(text: '지표'),
            Tab(text: '뉴스'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chart tab
          LineChartWidget(
            dates: dates,
            closes: closes,
            volumes: volumes,
            isKoreanMarket: widget.market == 'KR',
          ),
          // Indicators tab
          SingleChildScrollView(
            child: Column(
              children: [
                IndicatorTableWidget(
                  indicators: indicators,
                  onIndicatorTap: (group) {
                    showDialog(
                      context: context,
                      builder: (context) => IndicatorInfoDialog(
                        group: group,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return MultiSelectDialog(
                          items: groupedIndicators.keys.map((group) => MultiSelectItem(group, group)).toList(),
                          initialValue: selectedGroups,
                          onConfirm: (values) {
                            setState(() {
                              selectedGroups = values;
                            });
                          },
                          title: Text(
                            '지표 선택',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
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
          // News tab
          NewsWidget(
            ticker: widget.ticker,
            market: widget.market,
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
        currentIndex: widget.selectedIndex,
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