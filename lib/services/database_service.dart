import 'package:firebase_database/firebase_database.dart';

import '../data/indicator_info.dart';
import '../models/chart_data.dart';

class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<List<String>> getStockList() async {
    try {
      final snapshot = await _dbRef.child('stocks').get();
      if (snapshot.exists) {
        return List<String>.from(snapshot.value as List);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch stock list: $e');
    }
  }

  Future<Map<String, dynamic>> getIndicatorData(String symbol) async {
    try {
      final snapshot = await _dbRef.child('indicators/$symbol').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return {};
    } catch (e) {
      throw Exception('Failed to fetch indicator data: $e');
    }
  }

  Future<List<ChartData>> getChartData(String symbol, String interval) async {
    try {
      final snapshot = await _dbRef.child('charts/$symbol/$interval').get();
      if (snapshot.exists) {
        return List<Map<String, dynamic>>.from(snapshot.value as List)
            .map((e) => ChartData.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch chart data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNews(String symbol) async {
    try {
      final snapshot = await _dbRef.child('news/$symbol').get();
      if (snapshot.exists) {
        return List<Map<String, dynamic>>.from(snapshot.value as List);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchTicker(String query) async {
    try {
      final snapshot = await _dbRef.child('tickers').get();
      if (snapshot.exists) {
        final allTickers = List<Map<String, dynamic>>.from(snapshot.value as List);
        return allTickers
            .where((ticker) => 
                ticker['symbol'].toString().toLowerCase().contains(query.toLowerCase()) || 
                ticker['name'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search ticker: $e');
    }
  }

  Map<String, Map<String, String>> getIndicatorInfo() {
    return indicatorInfoMap;
  }
}