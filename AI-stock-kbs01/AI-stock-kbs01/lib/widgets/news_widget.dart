// 파일명: news_widget.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsWidget extends StatelessWidget {
  final List<dynamic> news;

  const NewsWidget({super.key, required this.news});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) {
      print('뉴스 데이터 오류: news가 비어 있습니다.');
      return const Text(
        '📢 뉴스 데이터를 불러올 수 없습니다.',
        style: TextStyle(color: Colors.white),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Text(
              '📰 최신 뉴스',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ...news.map((article) {
            if (article['title'] == null || article['pubDate'] == null) {
              print('뉴스 항목 오류: title 또는 pubDate가 누락되었습니다.');
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // 간격 넓히기
              child: Card(
                color: Colors.grey[850], // 배경 색상 조정
                elevation: 6, // 그림자 강화
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20.0), // 내부 패딩 조정
                  title: Text(
                    article['title'] ?? '제목 없음',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18, // 글씨 크기 조정
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      article['pubDate']?.split(' ').sublist(0, 4).join(' ') ?? '날짜 없음',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14, // 글씨 크기 조정
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  onTap: () {
                    if (article['url'] != null) {
                      _launchURL(article['url']);
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}