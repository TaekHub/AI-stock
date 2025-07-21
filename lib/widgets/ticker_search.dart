import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class TickerSearch extends StatefulWidget {
  final String market;
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final Function(Map<String, dynamic>) toggleFavorite;
  final List<Map<String, dynamic>> favoriteStocks;

  const TickerSearch({
    super.key,
    required this.market,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.toggleFavorite,
    required this.favoriteStocks,
  });

  @override
  State<TickerSearch> createState() => _TickerSearchState();
}

class _TickerSearchState extends State<TickerSearch> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _suggestions = [];
  List<Map<String, String>> _allTickers = [];
  bool _isLoading = false;
  String? _errorMessage;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot = await _dbRef.child('tickers/${widget.market}').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final tickers = data.entries.map((entry) {
          return {
            'ticker': entry.key,
            'name': entry.value as String,
          };
        }).toList();

        setState(() {
          _allTickers = tickers;
          _suggestions = tickers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '${widget.market == 'KR' ? '국내' : '해외'} 주식 데이터가 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = widget.market == 'KR'
            ? '국내 주식 데이터를 불러올 수 없습니다.'
            : '해외 주식 데이터를 불러올 수 없습니다.';
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = _allTickers;
      });
      return;
    }

    final queryLower = query.toLowerCase();
    final filtered = _allTickers.where((ticker) {
      final tickerLower = ticker['ticker']!.toLowerCase();
      final nameLower = ticker['name']!.toLowerCase();
      return tickerLower.contains(queryLower) || nameLower.contains(queryLower);
    }).toList();

    filtered.sort((a, b) {
      final aName = a['name']!.toLowerCase();
      final bName = b['name']!.toLowerCase();
      if (aName.startsWith(queryLower) && !bName.startsWith(queryLower)) {
        return -1;
      } else if (!aName.startsWith(queryLower) && bName.startsWith(queryLower)) {
        return 1;
      }
      return aName.compareTo(bName);
    });

    setState(() {
      _suggestions = filtered;
    });
  }

  void _onTickerSelected(String ticker, String name) {
    _controller.clear();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockHomePage(
          ticker: ticker,
          market: widget.market,
          selectedIndex: widget.selectedIndex,
          onIndexChanged: widget.onIndexChanged,
          toggleFavorite: widget.toggleFavorite,
          favoriteStocks: widget.favoriteStocks,
        ),
      ),
    );
  }

  void _onCustomTickerSubmitted(String query) {
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockHomePage(
            ticker: query.toUpperCase(),
            market: widget.market,
            selectedIndex: widget.selectedIndex,
            onIndexChanged: widget.onIndexChanged,
            toggleFavorite: widget.toggleFavorite,
            favoriteStocks: widget.favoriteStocks,
          ),
        ),
      );
      _controller.clear();
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
              labelText: '종목 검색',
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => _onCustomTickerSubmitted(_controller.text),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: _onSearch,
            onSubmitted: _onCustomTickerSubmitted,
          ),
          const SizedBox(height: 16),
          _isLoading
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
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadSuggestions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('재시도'),
                          ),
                        ],
                      ),
                    )
                  : _suggestions.isEmpty
                      ? const Text(
                          '검색 결과가 없습니다.',
                          style: TextStyle(color: Colors.white),
                        )
                      : SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final ticker = _suggestions[index];
                              return ListTile(
                                title: Text(
                                  '${ticker['name']} (${ticker['ticker']})',
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                subtitle: Text(
                                  '시장: ${widget.market}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                onTap: () => _onTickerSelected(ticker['ticker']!, ticker['name']!),
                              );
                            },
                          ),
                        ),
        ],
      ),
    );
  }
}