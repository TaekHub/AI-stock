import 'package:flutter/material.dart';
import '../services/api.dart';
import '../main.dart';

class TickerSearch extends StatefulWidget {
  final String market;
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final Function(Map<String, dynamic>) toggleFavorite;
  final List<Map<String, dynamic>> favoriteStocks;
  final Function(String)? onSelect;

  const TickerSearch({
    super.key,
    required this.market,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.toggleFavorite,
    required this.favoriteStocks,
    this.onSelect,
  });

  @override
  State<TickerSearch> createState() => _TickerSearchState();
}

class _TickerSearchState extends State<TickerSearch> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> searchTickers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      final data = await fetchTickers(widget.market) as Map<String, dynamic>;
      print('Ticker search data: $data'); // 디버깅 로그
      setState(() {
        final tickerList = data['tickers'] as List<dynamic>? ?? [];
        print('Ticker list: $tickerList'); // 추가 로그
        searchResults = tickerList
            .where((ticker) {
          final tickerData = ticker as Map<String, dynamic>;
          final tickerString = tickerData['ticker']?.toString().toLowerCase() ?? '';
          final nameString = tickerData['name']?.toString().toLowerCase() ?? '';
          return tickerString.contains(query.toLowerCase()) || nameString.contains(query.toLowerCase());
        })
            .cast<Map<String, dynamic>>()
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error searching tickers: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: '종목 검색...',
              hintStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70),
                onPressed: () {
                  _controller.clear();
                  searchTickers('');
                },
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: searchTickers,
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
          if (searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final ticker = searchResults[index];
                  final isFavorite = widget.favoriteStocks.any(
                          (item) => item['ticker'] == ticker['ticker'] && item['market'] == widget.market);
                  return ListTile(
                    title: Text(
                      ticker['name'] ?? ticker['ticker'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      ticker['ticker']?.toString() ?? 'Unknown',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.yellow : Colors.grey,
                      ),
                      onPressed: () {
                        widget.toggleFavorite({
                          'ticker': ticker['ticker'],
                          'market': widget.market,
                          'name': ticker['name'] ?? ticker['ticker'] ?? 'Unknown',
                        });
                      },
                    ),
                    onTap: () {
                      final tickerId = ticker['ticker'] as String?;
                      if (tickerId != null) {
                        widget.onSelect?.call(tickerId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StockHomePage(
                              ticker: tickerId,
                              market: widget.market,
                              selectedIndex: widget.selectedIndex,
                              onIndexChanged: widget.onIndexChanged,
                              toggleFavorite: widget.toggleFavorite,
                              favoriteStocks: widget.favoriteStocks,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}