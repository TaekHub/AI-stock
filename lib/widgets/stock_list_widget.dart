// 파일명: stock_list_widget.dart
import 'package:flutter/material.dart';
import 'package:stock_analysis_app/services/api.dart';
import 'package:stock_analysis_app/main.dart';
import 'package:skeletonizer/skeletonizer.dart';

class StockListWidget extends StatefulWidget {
  final String market;
  final bool showPopularOnly;
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final Function(Map<String, dynamic>) toggleFavorite;
  final List<Map<String, dynamic>> favoriteStocks;

  const StockListWidget({
    super.key,
    required this.market,
    this.showPopularOnly = false,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.toggleFavorite,
    required this.favoriteStocks,
  });

  @override
  State<StockListWidget> createState() => _StockListWidgetState();
}

class _StockListWidgetState extends State<StockListWidget> {
  List<Map<String, dynamic>> usStocks = [];
  List<Map<String, dynamic>> krStocks = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadStockData();
  }

  Future<void> loadStockData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      List<Map<String, dynamic>> usData = [];
      List<Map<String, dynamic>> krData = [];

      // US 인기 주식
      if (widget.showPopularOnly) {
        print('Loading US popular stocks...'); // 디버깅 로그
        final usTickers = (await fetchTickers('US')).take(5).toList();
        print('US tickers: $usTickers'); // 디버깅 로그
        usData = await _loadStockDataForTickers(usTickers, 'US');
        print('US stocks loaded: $usData'); // 디버깅 로그
      }

      // KR 인기 주식
      if (widget.showPopularOnly) {
        print('Loading KR popular stocks...'); // 디버깅 로그
        final krTickers = [
          {'ticker': '005930', 'name': '삼성전자'},
          {'ticker': '035720', 'name': '카카오'},
          {'ticker': '000660', 'name': 'SK하이닉스'},
          {'ticker': '035420', 'name': '네이버'},
          {'ticker': '005380', 'name': '현대차'},
        ];
        print('KR tickers: $krTickers'); // 디버깅 로그
        krData = await _loadStockDataForTickers(krTickers, 'KR');
        print('KR stocks loaded: $krData'); // 디버깅 로그
      } else {
        // 관심목록 탭: 선택된 시장의 모든 주식
        print('Loading stocks for market: ${widget.market}'); // 디버깅 로그
        final tickers = (await fetchTickers(widget.market)).take(10).toList();
        print('Tickers for ${widget.market}: $tickers'); // 디버깅 로그
        final data = await _loadStockDataForTickers(tickers, widget.market);
        print('Stocks loaded for ${widget.market}: $data'); // 디버깅 로그
        if (widget.market == 'US') {
          usData = data;
        } else {
          krData = data;
        }
      }

      setState(() {
        usStocks = usData;
        krStocks = krData;
        isLoading = false;
      });
    } catch (e) {
      print('종목 데이터 로드 실패: $e'); // 디버깅 로그
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadStockDataForTickers(List<Map<String, String>> tickers, String market) async {
    final futures = tickers.map((ticker) async {
      try {
        final data = await fetchStockData(ticker['ticker']!, market, period: "3mo");
        if (data['closes'] != null && data['closes'].isNotEmpty) {
          final currentPrice = data['closes'].last.toDouble();
          final previousPrice = data['closes'].length > 1
              ? data['closes'][data['closes'].length - 2].toDouble()
              : currentPrice;
          final change = currentPrice - previousPrice;
          final changePercent = previousPrice != 0 ? (change / previousPrice) * 100 : 0;

          return {
            'ticker': ticker['ticker'],
            'name': ticker['name'],
            'price': currentPrice,
            'change': change,
            'changePercent': changePercent,
            'market': market,
          };
        }
        return null;
      } catch (e) {
        print('Error loading data for ${ticker['ticker']} ($market): $e'); // 디버깅 로그
        return null;
      }
    });

    final results = await Future.wait(futures);
    return results.where((data) => data != null).cast<Map<String, dynamic>>().toList();
  }

  bool isFavorite(Map<String, dynamic> stock) {
    return widget.favoriteStocks.any((item) => item['ticker'] == stock['ticker'] && item['market'] == stock['market']);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (isLoading) {
      return const Center(
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
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadStockData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('재시도'),
            ),
          ],
        ),
      );
    }

    if (widget.showPopularOnly && usStocks.isEmpty && krStocks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.white70, size: 40),
            SizedBox(height: 16),
            Text(
              '인기 종목 데이터가 없습니다',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showPopularOnly && usStocks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '미국 인기 종목 (${usStocks.length}/5)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: usStocks.length,
              itemBuilder: (context, index) => buildStockTile(context, usStocks[index]),
            ),
          ],
          if (widget.showPopularOnly && krStocks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '한국 인기 종목 (${krStocks.length}/5)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: krStocks.length,
              itemBuilder: (context, index) => buildStockTile(context, krStocks[index]),
            ),
          ],
          if (!widget.showPopularOnly && (usStocks.isNotEmpty || krStocks.isNotEmpty)) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.market == 'US' ? '미국 종목' : '한국 종목',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.market == 'US' ? usStocks.length : krStocks.length,
              itemBuilder: (context, index) =>
                  buildStockTile(context, widget.market == 'US' ? usStocks[index] : krStocks[index]),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildStockTile(BuildContext context, Map<String, dynamic> stock) {
    final double change = stock['change'];
    final double changePercent = stock['changePercent'];
    return ListTile(
      title: Text(
        '${stock['name']} (${stock['ticker']})',
        style: const TextStyle(color: Colors.white, fontSize: 16),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      subtitle: Text(
        '시장: ${stock['market']}',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isFavorite(stock) ? Icons.star : Icons.star_border,
              color: isFavorite(stock) ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              widget.toggleFavorite(stock);
              setState(() {});
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stock['market'] == 'KR'
                        ? stock['price'].toInt().toString()
                        : stock['price'].toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: change >= 0 ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stock['market'] == 'KR'
                        ? '${change >= 0 ? '+' : ''}${change.toInt()} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)'
                        : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: change >= 0 ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockHomePage(
              ticker: stock['ticker'] as String,
              market: stock['market'] as String,
              selectedIndex: widget.selectedIndex,
              onIndexChanged: widget.onIndexChanged,
              toggleFavorite: widget.toggleFavorite,
              favoriteStocks: widget.favoriteStocks,
            ),
          ),
        );
      },
    );
  }
}