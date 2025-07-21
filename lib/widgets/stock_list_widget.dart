import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'main.dart';

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
  List<Map<String, dynamic>> stockData = [];
  bool isLoading = true;
  String? errorMessage;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

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
      List<Map<String, dynamic>> tempData = [];

      // Firebase에서 인기 종목 데이터 가져오기
      final snapshot = await _dbRef.child('popular_stocks/${widget.market}').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((ticker, stockInfo) {
          final stock = Map<String, dynamic>.from(stockInfo);
          stock['ticker'] = ticker;
          stock['market'] = widget.market;
          tempData.add(stock);
        });
      }

      setState(() {
        stockData = tempData;
        isLoading = false;
      });
    } catch (e) {
      print('종목 데이터 로드 실패: $e');
      setState(() {
        errorMessage = '데이터를 불러오는 중 오류가 발생했습니다';
        isLoading = false;
      });
    }
  }

  bool isFavorite(Map<String, dynamic> stock) {
    return widget.favoriteStocks.any((item) => 
        item['ticker'] == stock['ticker'] && item['market'] == stock['market']);
  }

  @override
  Widget build(BuildContext context) {
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

    if (errorMessage != null || stockData.isEmpty) {
      return Center(
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
              onPressed: loadStockData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Text('재시도'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: stockData.length,
      itemBuilder: (context, index) {
        final stock = stockData[index];
        final change = (stock['change'] ?? 0).toDouble();
        final changePercent = (stock['changePercent'] ?? 0).toDouble();

        return Builder(
          builder: (BuildContext newContext) {
            return Card(
              color: Colors.grey[850],
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  Icons.circle,
                  color: change >= 0 ? Colors.green : Colors.red,
                  size: 10,
                ),
                title: Text(
                  stock['name'] as String? ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                subtitle: Text(
                  '실시간 데이터 | ${widget.market == 'KR' ? 'KRW' : 'USD'}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
                              widget.market == 'KR'
                                  ? (stock['price']?.toInt() ?? 0).toString()
                                  : (stock['price']?.toStringAsFixed(2) ?? '0.00'),
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
                              widget.market == 'KR'
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
                    newContext,
                    MaterialPageRoute(
                      builder: (context) => StockHomePage(
                        ticker: stock['ticker'] as String,
                        market: widget.market,
                        selectedIndex: widget.selectedIndex,
                        onIndexChanged: widget.onIndexChanged,
                        toggleFavorite: widget.toggleFavorite,
                        favoriteStocks: widget.favoriteStocks,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}