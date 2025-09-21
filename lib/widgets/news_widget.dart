// 파일명: news_widget.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';

class NewsWidget extends StatefulWidget {
  final String ticker;
  final String market;

  const NewsWidget({
    super.key,
    required this.ticker,
    required this.market,
  });

  @override
  State<NewsWidget> createState() => _NewsWidgetState();
}

class _NewsWidgetState extends State<NewsWidget> {
  List<Map<String, dynamic>> news = [];
  bool isLoading = true;
  String? errorMessage;
  int start = 1;
  final int display = 10;
  int total = 0;
  final int maxPages = 10;

  @override
  void initState() {
    super.initState();
    loadNews();
  }

  Future<void> loadNews({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }
    try {
      final data = await fetchNews(
        widget.ticker,
        widget.market,
        start: loadMore ? start + display : 1,
        display: display,
      );
      print('News data for ${widget.ticker} (${widget.market}): $data');
      setState(() {
        if (!loadMore) {
          news = List<Map<String, dynamic>>.from(data['news'] ?? []);
        } else {
          news.addAll(List<Map<String, dynamic>>.from(data['news'] ?? []));
        }
        start = loadMore ? start + display : 1;
        total = data['total'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading news: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> launchURL(String url) async {
    if (url.isEmpty) {
      print('Empty URL attempted to launch');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 링크가 없습니다')),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Cannot launch URL: $url');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('링크를 열 수 없습니다: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (isLoading && news.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              '뉴스를 불러오는 중입니다',
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
              '뉴스를 불러올 수 없습니다',
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
              onPressed: () => loadNews(),
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

    if (news.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.white70, size: 40),
            SizedBox(height: 16),
            Text(
              '뉴스가 없습니다',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: news.length,
            itemBuilder: (context, index) {
              final item = news[index];
              final url = item['url']?.toString() ?? '';
              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    item['title']?.toString() ?? '제목 없음',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['pubDate']?.toString() ?? '날짜 없음',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        item['sentiment']?.toString() ?? '중립',
                        style: TextStyle(
                          color: item['color'] is String
                              ? Color(int.parse(item['color'].replaceFirst('#', '0xFF')))
                              : (item['color'] is Color ? item['color'] as Color : Colors.yellow),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => launchURL(url),
                ),
              );
            },
          ),
        ),
        if (start + display <= total && start + display <= maxPages * display)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => loadNews(loadMore: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                '더 보기 (${(start + display) ~/ display}/${maxPages})',
                style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}