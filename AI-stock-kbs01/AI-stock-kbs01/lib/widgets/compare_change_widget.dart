// 파일명: compare_change_widget.dart
import 'package:flutter/material.dart';
import 'package:test01/services/api.dart';

class CompareChangeWidget extends StatefulWidget {
  final String ticker;
  final String market;
  const CompareChangeWidget({super.key, required this.ticker, required this.market});

  @override
  State<CompareChangeWidget> createState() => _CompareChangeWidgetState();
}

class _CompareChangeWidgetState extends State<CompareChangeWidget> {
  Map<String, double>? changes;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadChanges();
  }

  Future<void> loadChanges() async {
    try {
      final result = await fetchChangeComparison(widget.ticker, widget.market);
      setState(() {
        changes = result;
        isLoading = false;
      });
    } catch (e) {
      print('변동률 데이터 불러오기 실패: $e');
      setState(() {
        changes = {};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    if (changes == null || changes!.isEmpty) {
      return const Text(
        "📉 비교할 수 있는 변동률 데이터가 없습니다.",
        style: TextStyle(color: Colors.white),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          "📊 변동률 비교 결과",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Table(
          border: TableBorder.all(color: Colors.grey),
          children: [
            const TableRow(children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text("지수/종목", style: TextStyle(color: Colors.white)),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text("변동률", style: TextStyle(color: Colors.white)),
              ),
            ]),
            ...changes!.entries.map((e) => TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(e.key, style: const TextStyle(color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text("${e.value.toStringAsFixed(2)}%",
                    style: TextStyle(
                        color: e.value >= 0 ? Colors.greenAccent : Colors.redAccent)),
              )
            ]))
          ],
        )
      ],
    );
  }
}