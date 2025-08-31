// 파일명: api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:retry/retry.dart';

// 에뮬레이터에서 실행 시 호스트 머신의 IP로 접근
const String baseUrl = 'http://172.30.1.20:8000'; // 포트가 32937이면 수정 필요

Future<List<Map<String, String>>> fetchTickers(String market) async {
  return await retry(
        () async {
      final response = await http.get(Uri.parse('$baseUrl/tickers?market=$market'));
      print('fetchTickers response for $market: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        if (data is Map<String, dynamic> && data['tickers'] is List) {
          return List<Map<String, String>>.from(
            data['tickers'].map((item) => {
              'ticker': item['ticker'].toString(),
              'name': item['name'].toString(),
            }),
          );
        } else {
          throw Exception('Invalid tickers data format');
        }
      } else {
        throw Exception('Failed to load tickers: ${response.statusCode} - ${response.body}');
      }
    },
    maxAttempts: 3,
    delayFactor: Duration(seconds: 1),
  );
}

Future<Map<String, dynamic>> fetchStockData(String ticker, String market, {String period = "3mo"}) async {
  return await retry(
        () async {
      final response = await http.get(Uri.parse('$baseUrl/analyze?ticker=$ticker&market=$market&period=$period'));
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          throw Exception('Invalid stock data format');
        }
      } else {
        throw Exception('Failed to load stock data: ${response.statusCode} - ${response.body}');
      }
    },
    maxAttempts: 3,
    delayFactor: Duration(seconds: 1),
  );
}

Future<Map<String, dynamic>> fetchNews(String ticker, String market, {int start = 1, int display = 10}) async {
  final url = Uri.parse('$baseUrl/news?ticker=$ticker&market=$market&start=$start&display=$display');
  return await retry(
        () async {
      try {
        final response = await http.get(url);
        print('News API response for $ticker ($market, start=$start, display=$display): ${response.statusCode}');
        if (response.statusCode == 200) {
          final decodedBody = utf8.decode(response.bodyBytes);
          final data = jsonDecode(decodedBody);
          if (data is Map<String, dynamic> && data['news'] is List) {
            return {
              'news': List<Map<String, dynamic>>.from(data['news'].map((item) => {
                'title': item['title']?.toString() ?? '제목 없음',
                'url': item['link']?.toString() ?? '',
                'pubDate': item['pubDate']?.toString() ?? '',
                'sentiment': item['sentiment']?.toString() ?? '중립',
                'color': item['color'] != null
                    ? Color(int.parse(item['color'].replaceFirst('#', '0xFF')))
                    : Colors.yellow,
              })),
              'total': data['total'] ?? 0,
            };
          } else {
            throw Exception('Invalid news data format: ${data.toString()}');
          }
        } else {
          throw Exception('Failed to load news: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('News fetch error: $e');
        throw Exception('Failed to fetch news: $e');
      }
    },
    maxAttempts: 3,
    delayFactor: const Duration(seconds: 1),
  );
}

Future<Map<String, double>> fetchChangeComparison(String ticker, String market) async {
  final url = Uri.parse('$baseUrl/compare?ticker=$ticker&market=$market');
  return await retry(
        () async {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        try {
          final decodedBody = utf8.decode(response.bodyBytes);
          final decoded = jsonDecode(decodedBody);
          return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
        } catch (e) {
          print('❌ 변동률 JSON 파싱 오류: $e');
          throw Exception('Failed to parse change comparison data');
        }
      } else {
        print('❌ 변동률 비교 요청 실패: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load change comparison');
      }
    },
    maxAttempts: 3,
    delayFactor: Duration(seconds: 1),
  );
}

Future<Map<String, dynamic>> fetchTickerInfo(String ticker, String market) async {
  return await retry(
        () async {
      final response = await http.get(Uri.parse('$baseUrl/ticker_info?ticker=$ticker&market=$market'));
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          throw Exception('Invalid ticker info format');
        }
      } else {
        print('❌ 종목 정보 요청 실패: ${response.statusCode} - ${response.body}');
        return {'name': ticker};
      }
    },
    maxAttempts: 3,
    delayFactor: Duration(seconds: 1),
  );
}

Future<bool> checkServerStatus() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/tickers?market=US'));
    return response.statusCode == 200;
  } catch (e) {
    print('Server status check failed: $e');
    return false;
  }
}