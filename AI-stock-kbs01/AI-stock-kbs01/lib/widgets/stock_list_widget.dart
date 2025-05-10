// 파일명: stock_list_widget.dart
import 'package:flutter/material.dart';
import 'package:test01/services/api.dart';
import 'package:test01/main.dart';
import 'package:skeletonizer/skeletonizer.dart';

class StockListWidget extends StatefulWidget {
  final String market;
  final bool showPopularOnly;
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const StockListWidget({
    super.key,
    required this.market,
    this.showPopularOnly = false,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  State<StockListWidget> createState() => _StockListWidgetState();
}

class _StockListWidgetState extends State<StockListWidget> {
  List<Map<String, dynamic>> stockData = [];
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
      List<Map<String, dynamic>> tempData = [];

      final tickersToLoad = widget.showPopularOnly
          ? (await fetchTickers(widget.market)).take(5).toList()
          : (await fetchTickers(widget.market)).take(10).toList();

      for (var ticker in tickersToLoad) {
        try {
          final data = await fetchStockData(ticker['ticker']!, widget.market, period: "3mo");
          if (data['closes'] != null && data['closes'].isNotEmpty) {
            final currentPrice = data['closes'].last.toDouble();
            final previousPrice = data['closes'].length > 1
                ? data['closes'][data['closes'].length - 2].toDouble()
                : currentPrice;
            final change = currentPrice - previousPrice;
            final changePercent = (change / previousPrice) * 100;

            tempData.add({
              'ticker': ticker['ticker'],
              'name': ticker['name'],
              'price': currentPrice,
              'change': change,
              'changePercent': changePercent,
            });
          }
        } catch (e) {
          print('Error loading data for ${ticker['ticker']}: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('종목 ${ticker['name']} 데이터 로드 실패: $e')),
          );
        }
      }

      setState(() {
        stockData = tempData;
        isLoading = false;
      });
    } catch (e) {
      print('종목 데이터 로드 실패: $e');
      setState(() {
        errorMessage = '종목 데이터를 불러오는 중 오류가 발생했습니다: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Skeletonizer(
      enabled: true,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.circle, color: Colors.green, size: 10),
            title: Text('로딩 중...', style: TextStyle(color: Colors.white)),
            subtitle: Text('...', style: TextStyle(color: Colors.grey)),
            trailing: Text('...', style: TextStyle(color: Colors.white)),
          );
        },
      ),
    )
        : stockData.isEmpty
        ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          errorMessage ?? '데이터를 불러올 수 없습니다.',
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: loadStockData,
          child: Text('재시도'),
        ),
      ],
    )
        : ListView.builder(
      itemCount: stockData.length,
      itemBuilder: (context, index) {
        final stock = stockData[index];
        final change = stock['change'] as double;
        final changePercent = stock['changePercent'] as double;

        return Builder(
          builder: (BuildContext newContext) {
            return ListTile(
              leading: const Icon(Icons.circle, color: Colors.green, size: 10),
              title: Text(
                stock['name'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '14:15:00 | 실시간 CFD, USD 통화',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.market == 'KR'
                        ? stock['price'].toInt().toString()
                        : stock['price'].toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    widget.market == 'KR'
                        ? '${change >= 0 ? '+' : ''}${change.toInt()} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)'
                        : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: change >= 0 ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  newContext,
                  MaterialPageRoute(
                    builder: (context) => StockHomePage(
                      ticker: stock['ticker'],
                      market: widget.market,
                      selectedIndex: widget.selectedIndex,
                      onIndexChanged: widget.onIndexChanged,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}