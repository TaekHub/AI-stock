// 파일명: volume_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class VolumeChartWidget extends StatelessWidget {
  final List<String> dates;
  final List<double> volumes;

  const VolumeChartWidget({
    super.key,
    required this.dates,
    required this.volumes,
  });

  @override
  Widget build(BuildContext context) {
    if (dates.length != volumes.length || dates.isEmpty) {
      return const Text(
        '📊 유효한 거래량 데이터를 불러올 수 없습니다.',
        style: TextStyle(color: Colors.white),
      );
    }

    final bars = List.generate(volumes.length, (index) {
      return BarChartRodData(
        toY: volumes[index],
        color: Colors.blueAccent,
        width: 2,
      );
    });

    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: volumes.reduce((a, b) => a > b ? a : b) * 1.1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[800]!, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                  if (index % 14 == 0) {
                    return Text(
                      dates[index],
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 30,
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    (value / 1000000).toStringAsFixed(0) + 'M',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  );
                },
                reservedSize: 35,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey),
          ),
          barGroups: List.generate(volumes.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [bars[index]],
            );
          }),
        ),
      ),
    );
  }
}