import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';
import 'services/api.dart';
import 'widgets/ticker_search.dart';
import 'widgets/line_chart_widget.dart';
import 'widgets/indicator_table_widget.dart';
import 'widgets/news_widget.dart';
import 'widgets/stock_list_widget.dart';
import 'widgets/indicator_chart_widget.dart';
import 'widgets/indicator_info_dialog.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'app_intro_page.dart';

// 디바이스 ID 생성 및 저장
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('device_id');
  if (deviceId == null) {
    deviceId = const Uuid().v4();
    await prefs.setString('device_id', deviceId);
  }
  print('Device ID: $deviceId'); // 디버깅 로그
  return deviceId;
}

// 사용자 설정 저장/로드
Future<void> saveUserSettings(String market) async {
  final deviceId = await getDeviceId();
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(deviceId)
        .set({'preferredMarket': market, 'deviceId': deviceId}, SetOptions(merge: true));
    print('User settings saved: market=$market, deviceId=$deviceId');
  } catch (e) {
    print('Error saving user settings: $e');
  }
}

Future<String> loadUserSettings() async {
  final deviceId = await getDeviceId();
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(deviceId)
        .get();
    print('User settings loaded: ${doc.data()}');
    return doc.data()?['preferredMarket'] ?? 'US';
  } catch (e) {
    print('Error loading user settings: $e');
    return 'US'; // 기본값
  }
}

// Analytics 이벤트 로깅
void logSearchEvent(String ticker, String market) async {
  try {
    await FirebaseAnalytics.instance.logEvent(
      name: 'search_stock',
      parameters: {'ticker': ticker, 'market': market, 'deviceId': await getDeviceId()},
    );
    print('Analytics: search_stock event logged for ticker: $ticker, market: $market');
  } catch (e) {
    print('Error logging search event: $e');
  }
}

void logFavoriteEvent(String ticker, String market, bool added) async {
  try {
    await FirebaseAnalytics.instance.logEvent(
      name: 'favorite_stock',
      parameters: {
        'ticker': ticker,
        'market': market,
        'action': added ? 'add' : 'remove',
        'deviceId': await getDeviceId(),
      },
    );
    print('Analytics: favorite_stock event logged for ticker: $ticker, market: $market, action: ${added ? 'add' : 'remove'}');
  } catch (e) {
    print('Error logging favorite event: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
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
  bool isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    loadUserSettings().then((market) {
      setState(() {
        selectedMarket = market;
      });
    });
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
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('뉴스 로드 실패: $e')),
      );
    }
  }

  Future<void> loadFavorites() async {
    try {
      final deviceId = await getDeviceId();
      print('Loading favorites for deviceId: $deviceId');
      final snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(deviceId)
          .collection('stocks')
          .get();
      print('Favorites snapshot: ${snapshot.docs.length} documents, data: ${snapshot.docs.map((doc) => doc.data())}');
      setState(() {
        favoriteStocks = snapshot.docs
            .map((doc) => {
          'ticker': doc['ticker'] as String,
          'market': doc['market'] as String,
          'name': doc['name'] as String? ?? doc['ticker'],
        })
            .toList();
      });
    } catch (e) {
      print('Error loading favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기 로드 실패: Firestore 권한을 확인하세요 ($e)')),
      );
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> stock) async {
    final deviceId = await getDeviceId();
    final ticker = stock['ticker'] as String;
    final market = stock['market'] as String;
    final name = stock['name'] as String? ?? ticker;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('favorites')
          .doc(deviceId)
          .collection('stocks')
          .doc('$market-$ticker');

      if (favoriteStocks.any((item) => item['ticker'] == ticker && item['market'] == market)) {
        print('Removing favorite: $ticker ($market) for deviceId: $deviceId');
        await docRef.delete();
        setState(() {
          favoriteStocks.removeWhere((item) => item['ticker'] == ticker && item['market'] == market);
        });
        logFavoriteEvent(ticker, market, false);
      } else {
        print('Adding favorite: $ticker ($market) for deviceId: $deviceId');
        await docRef.set({
          'ticker': ticker,
          'market': market,
          'name': name,
          'deviceId': deviceId,
          'added_at': FieldValue.serverTimestamp(),
        });
        setState(() {
          favoriteStocks.add({
            'ticker': ticker,
            'market': market,
            'name': name,
          });
        });
        logFavoriteEvent(ticker, market, true);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기 업데이트 실패: Firestore 권한을 확인하세요 ($e)')),
      );
    }
  }

  void _onIndexChanged(int index) {
    setState(() {
      _selectedIndex = index;
      isSearchVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주가 분석 앱'),
        backgroundColor: Colors.grey[850],
        actions: [
          IconButton(
            icon: Icon(
              isSearchVisible ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isSearchVisible = !isSearchVisible;
              });
            },
          ),
          DropdownButton<String>(
            value: selectedMarket,
            items: const [
              DropdownMenuItem(value: 'US', child: Text('미국')),
              DropdownMenuItem(value: 'KR', child: Text('한국')),
            ],
            onChanged: (value) {
              setState(() {
                selectedMarket = value!;
                isSearchVisible = false;
              });
              saveUserSettings(value!);
            },
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white, fontSize: 16),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isSearchVisible)
            TickerSearch(
              market: selectedMarket,
              selectedIndex: _selectedIndex,
              onIndexChanged: _onIndexChanged,
              toggleFavorite: toggleFavorite,
              favoriteStocks: favoriteStocks,
              onSelect: (ticker) => logSearchEvent(ticker, selectedMarket),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                StockListWidget(
                  market: selectedMarket,
                  showPopularOnly: true,
                  selectedIndex: _selectedIndex,
                  onIndexChanged: _onIndexChanged,
                  toggleFavorite: toggleFavorite,
                  favoriteStocks: favoriteStocks,
                ),
                const Center(child: Text('뉴스 페이지 (구현 예정)', style: TextStyle(color: Colors.white))),
                StockListWidget(
                  market: selectedMarket,
                  showPopularOnly: false,
                  selectedIndex: _selectedIndex,
                  onIndexChanged: _onIndexChanged,
                  toggleFavorite: toggleFavorite,
                  favoriteStocks: favoriteStocks,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: '인기 종목'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: '뉴스'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: '관심목록'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onIndexChanged,
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

class _StockHomePageState extends State<StockHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> dates = [];
  List<double> closes = [];
  List<double> volumes = [];
  Map<String, dynamic> indicators = {};
  Map<String, List<double?>> indicatorsSeries = {};
  List<String> selectedGroups = [
    'RSI', 'MACD', 'CCI', 'MFI', 'ADX', 'Stochastic', 'SMA', 'EMA', 'Bollinger Band'
  ];
  Map<String, List<String>> groupedIndicators = {
    'RSI': ['RSI'],
    'MACD': ['MACD'],
    'CCI': ['CCI'],
    'MFI': ['MFI'],
    'ADX': ['ADX'],
    'Stochastic': ['SlowK', 'SlowD'],
    'SMA': ['SMA10', 'SMA50'],
    'EMA': ['EMA20', 'EMA50'],
    'Bollinger Band': ['BB_upper', 'BB_lower'],
  };
  bool isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStockData();
    logSearchEvent(widget.ticker, widget.market);
  }

  Future<void> _loadStockData() async {
    setState(() {
      isLoadingData = true;
    });
    try {
      final deviceId = await getDeviceId();
      // Firestore에서 캐시 데이터 우선 로드
      final doc = await FirebaseFirestore.instance
          .collection('stocks')
          .doc('${widget.market}-${widget.ticker}')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        print('Loaded cached stock data from Firestore');
        setState(() {
          dates = List<String>.from(data['dates'] ?? []);
          closes = List<double>.from(data['closes']?.map((x) => (x as num?)?.toDouble() ?? 0.0) ?? []);
          volumes = List<double>.from(data['volumes']?.map((x) => (x as num?)?.toDouble() ?? 0.0) ?? []);
          indicators = Map<String, dynamic>.from(data['indicators'] ?? {});
          indicatorsSeries = Map<String, List<double?>>.from(
            data['indicatorsSeries']?.map((key, value) => MapEntry(
              key,
              List<double?>.from((value as List?)?.map((v) => (v as num?)?.toDouble()) ?? []),
            )) ?? {},
          );
          isLoadingData = false;
        });
        return; // 캐시 데이터 사용
      }
      // 캐시 없으면 백엔드에서 로드
      final apiData = await fetchStockData(widget.ticker, widget.market, period: '1y');
      // ... 기존 로직
      // Firestore에 저장
      await FirebaseFirestore.instance
          .collection('stocks')
          .doc('${widget.market}-${widget.ticker}')
          .set({
        'dates': dates,
        'closes': closes,
        'volumes': volumes,
        'indicators': indicators,
        'indicatorsSeries': indicatorsSeries,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error loading stock data: $e');
      setState(() {
        isLoadingData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 로드 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: fetchTickerInfo(widget.ticker, widget.market),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('로딩 중...');
            }
            final name = snapshot.data?['name'] ?? widget.ticker;
            return Text('$name (${widget.ticker})');
          },
        ),
        backgroundColor: Colors.grey[850],
        actions: [
          IconButton(
            icon: Icon(
              widget.favoriteStocks.any((item) => item['ticker'] == widget.ticker && item['market'] == widget.market)
                  ? Icons.star
                  : Icons.star_border,
              color: widget.favoriteStocks.any((item) => item['ticker'] == widget.ticker && item['market'] == widget.market)
                  ? Colors.yellow
                  : Colors.grey,
            ),
            onPressed: () {
              widget.toggleFavorite({
                'ticker': widget.ticker,
                'market': widget.market,
                'name': widget.ticker,
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '차트'),
            Tab(text: '지표'),
            Tab(text: '뉴스'),
          ],
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueAccent,
        ),
      ),
      body: isLoadingData
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              '데이터를 불러오는 중입니다',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      )
          : indicators.isEmpty && indicatorsSeries.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            SizedBox(height: 16),
            Text(
              '지표 데이터를 불러올 수 없습니다',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '데이터가 비어 있거나 API 호출에 실패했습니다',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.02),
                LineChartWidget(
                  dates: dates,
                  closes: closes,
                  volumes: volumes,
                  isKoreanMarket: widget.market == 'KR',
                ),
                SizedBox(height: screenHeight * 0.02),
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
              ],
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return MultiSelectDialog(
                          items: groupedIndicators.keys
                              .map((group) => MultiSelectItem(group, group))
                              .toList(),
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