// 파일명: api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, String>>> fetchTickers(String market) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/tickers?market=$market'));
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
}

Future<Map<String, dynamic>> fetchStockData(String ticker, String market, {String period = "3mo"}) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/analyze?ticker=$ticker&market=$market&period=$period'));
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
}

Future<List<Map<String, dynamic>>> fetchNews(String ticker, String market) async {
  String query = market == 'KR' ? '$ticker 뉴스' : '$ticker news';
  final url = Uri.parse('http://127.0.0.1:8000/news?ticker=$ticker&market=$market');

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final decodedBody = utf8.decode(response.bodyBytes);
    final data = jsonDecode(decodedBody);
    print('News API response for $ticker ($market): $data');
    if (data is Map<String, dynamic> && data['news'] is List) {
      return List<Map<String, dynamic>>.from(data['news'].map((item) => {
        'title': item['title'].toString().replaceAll(RegExp(r'<[^>]+>'), ''),
        'url': item['link'].toString(),
        'pubDate': item['pubDate'].toString(),
      }));
    } else {
      throw Exception('Invalid news data format');
    }
  } else {
    throw Exception('Failed to load news data: ${response.statusCode} - ${response.body}');
  }
}

Future<Map<String, double>> fetchChangeComparison(String ticker, String market) async {
  final url = Uri.parse('http://127.0.0.1:8000/compare?ticker=$ticker&market=$market');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    try {
      final decodedBody = utf8.decode(response.bodyBytes);
      final decoded = jsonDecode(decodedBody);
      return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      print('❌ 변동률 JSON 파싱 오류: $e');
    }
  } else {
    print('❌ 변동률 비교 요청 실패: ${response.statusCode} - ${response.body}');
  }
  return {};
}

Future<Map<String, dynamic>> fetchTickerInfo(String ticker, String market) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/ticker_info?ticker=$ticker&market=$market'));
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
}

Future<bool> checkServerStatus() async {
  try {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/tickers?market=US'));
    return response.statusCode == 200;
  } catch (e) {
    print('Server status check failed: $e');
    return false;
  }
}