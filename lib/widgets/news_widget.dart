// 파일명: news_widget.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';

class NewsWidget extends StatefulWidget {
  final String ticker;
  final String market;

  const NewsWidget({super.key, required this.ticker, required this.market});

  @override
  State<NewsWidget> createState() => _NewsWidgetState();
}

class _NewsWidgetState extends State<NewsWidget> {
  List<Map<String, dynamic>> news = [];
  int currentPage = 1;
  final int itemsPerPage = 10;
  int totalItems = 0;
  bool isLoading = false;
  final int maxPages = 10; // 최대 100개 뉴스 ÷ 10개 per page

  @override
  void initState() {
    super.initState();
    _fetchNews(currentPage);
  }

  Future<void> _fetchNews(int page) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      news.clear(); // 새 페이지 로드 시 기존 데이터 초기화
    });
    try {
      final response = await fetchNews(
        widget.ticker,
        widget.market,
        start: (page - 1) * itemsPerPage + 1,
        display: itemsPerPage,
      );
      setState(() {
        news = response['news'];
        totalItems = response['total'] ?? 0;
        currentPage = page;
        isLoading = false;
      });
      print('News loaded for page $page: ${news.length} items, total: $totalItems');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('뉴스 로드 실패: $e')),
      );
      print('News fetch error: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('링크를 열 수 없습니다: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            '뉴스 (${news.length}/$totalItems)',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text(
                    '뉴스 데이터를 불러오는 중입니다',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          )
              : news.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '뉴스를 불러올 수 없습니다.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _fetchNews(currentPage),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('재시도'),
                ),
              ],
            ),
          )
              : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: news.length,
            itemBuilder: (context, index) {
              final article = news[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                child: Card(
                  color: Colors.grey[850],
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      article['title'] ?? '제목 없음',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Text(
                            article['pubDate']?.split(' ').sublist(0, 4).join(' ') ?? '날짜 없음',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (article['color'] as Color?)?.withOpacity(0.2) ?? Colors.yellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              article['sentiment'] ?? '중립',
                              style: TextStyle(
                                color: article['color'] as Color? ?? Colors.yellow,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () async {
                      final url = article['url'] as String?;
                      if (url != null && url.isNotEmpty) {
                        try {
                          await _launchURL(url);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('링크를 열 수 없습니다: $e')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('유효한 링크가 없습니다.')),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxPages, (index) {
              final page = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  onPressed: isLoading || page == currentPage ? null : () => _fetchNews(page),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: page == currentPage ? Colors.blueAccent : Colors.grey[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // 버튼 크기 축소
                    minimumSize: Size(screenWidth * 0.1, 36), // 최소 크기 설정
                  ),
                  child: Text(
                    '$page',
                    style: TextStyle(
                      color: page == currentPage ? Colors.white : Colors.white70,
                      fontSize: screenWidth * 0.035, // 글씨 크기 축소
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}