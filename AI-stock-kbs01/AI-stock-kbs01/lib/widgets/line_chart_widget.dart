// 파일명: line_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class LineChartWidget extends StatelessWidget {
  final List<String> dates;
  final List<double> closes;
  final List<double> volumes;
  final bool isKoreanMarket;

  const LineChartWidget({
    super.key,
    required this.dates,
    required this.closes,
    required this.volumes,
    required this.isKoreanMarket,
  });

  @override
  Widget build(BuildContext context) {
    if (closes.isEmpty || dates.isEmpty) {
      print('차트 데이터 오류: closes 또는 dates가 비어 있습니다.');
      return const Center(
        child: Text(
          '차트 데이터를 불러올 수 없습니다.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final spots = closes.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final volumeSpots = volumes.asMap().entries.map((entry) {
      final maxVolume = volumes.reduce((a, b) => a > b ? a : b);
      final maxClose = closes.reduce((a, b) => a > b ? a : b);
      final scaledVolume = maxVolume > 0 ? (entry.value / maxVolume) * maxClose * 0.2 : 0.0;
      return FlSpot(entry.key.toDouble(), scaledVolume);
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850], // 배경 색상 조정
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[700]!,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    isKoreanMarket
                        ? value.toInt().toString()
                        : value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 14,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= dates.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % 14 == 0) {
                    try {
                      final date = DateFormat('yyyy-MM-dd').parse(dates[index]);
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    } catch (e) {
                      print('날짜 파싱 오류: $e');
                      return const SizedBox.shrink();
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue[400]!, // 파란색 계열로 변경
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[400]!.withOpacity(0.3),
                    Colors.blue[400]!.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            LineChartBarData(
              spots: volumeSpots,
              isCurved: false,
              color: Colors.grey[400]!.withOpacity(0.3),
              barWidth: 1,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.grey[400]!.withOpacity(0.3),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  if (spot.barIndex == 0) {
                    return LineTooltipItem(
                      isKoreanMarket
                          ? spot.y.toInt().toString()
                          : spot.y.toStringAsFixed(2),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}