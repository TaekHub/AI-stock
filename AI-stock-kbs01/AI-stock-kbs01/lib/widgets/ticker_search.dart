import 'package:flutter/material.dart';
import 'package:test01/services/api.dart';

class TickerSearch extends StatefulWidget {
  final String market;
  final Function(String) onTickerSelected;

  const TickerSearch({
    super.key,
    required this.market,
    required this.onTickerSelected,
  });

  @override
  State<TickerSearch> createState() => _TickerSearchState();
}

class _TickerSearchState extends State<TickerSearch> {
  List<Map<String, String>> tickers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadTickers();
  }

  @override
  void didUpdateWidget(covariant TickerSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.market != widget.market) {
      loadTickers();
    }
  }

  Future<void> loadTickers() async {
    setState(() {
      isLoading = true;
    });
    try {
      final fetchedTickers = await fetchTickers(widget.market);
      setState(() {
        tickers = fetchedTickers;
        isLoading = false;
      });
    } catch (e) {
      print('티커 목록 불러오기 실패: $e');
      setState(() {
        tickers = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('티커 목록을 불러오는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        final searchText = textEditingValue.text.toLowerCase().trim();
        return tickers
            .where((ticker) {
          final name = ticker['name']?.toLowerCase() ?? '';
          final tickerCode = ticker['ticker']?.toLowerCase() ?? '';
          // 종목명 또는 티커가 검색어와 부분 일치하는지 확인
          return name.contains(searchText) || tickerCode.contains(searchText);
        })
            .map((ticker) => '${ticker['name']} (${ticker['ticker']})');
      },
      onSelected: (String selection) {
        final ticker = selection.split('(').last.replaceAll(')', '').trim();
        widget.onTickerSelected(ticker);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: widget.market == 'US' ? '예: Apple (AAPL)' : '예: 삼성전자 (005930)',
            border: const OutlineInputBorder(),
            suffixIcon: isLoading ? const CircularProgressIndicator() : null,
          ),
          onSubmitted: (value) {
            onFieldSubmitted();
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              width: MediaQuery.of(context).size.width * 0.6,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}