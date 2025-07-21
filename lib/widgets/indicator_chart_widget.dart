// 파일명: indicator_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/indicator_info_dialog.dart';

class IndicatorChartWidget extends StatelessWidget {
  final List<String> dates;
  final Map<String, dynamic> indicators;
  final Map<String, List<double?>> indicatorsSeries;
  final List<String> selectedGroups;
  final Map<String, List<String>> groupedIndicators;

  const IndicatorChartWidget({
    super.key,
    required this.dates,
    required this.indicators,
    required this.indicatorsSeries,
    required this.selectedGroups,
    required this.groupedIndicators,
  });

  String getIndicatorStatus(String group, Map<String, dynamic> indicators) {
    if (group == 'RSI') {
      final value = indicators['RSI']?.toDouble();
      if (value == null) return 'RSI 현재상태: 데이터 부족';
      if (value > 70) return 'RSI 현재상태: $value -> 과매수 🟥';
      if (value < 30) return 'RSI 현재상태: $value -> 과매도 🟦';
      return 'RSI 현재상태: $value -> 중립 ⚪';
    } else if (group == 'MACD') {
      final macd = indicators['MACD']?.toDouble();
      final macdPrev = indicators['MACD_prev']?.toDouble();
      if (macd == null || macdPrev == null) return 'MACD 현재상태: 데이터 부족';
      if (macd > 0 && macdPrev <= 0) return 'MACD 현재상태: $macd -> 상승 추세 (매수 신호) 📈';
      if (macd < 0 && macdPrev >= 0) return 'MACD 현재상태: $macd -> 하락 추세 (매도 신호) 📉';
      return macd > 0
          ? 'MACD 현재상태: $macd -> 상승 추세 📈'
          : 'MACD 현재상태: $macd -> 하락 추세 📉';
    } else if (group == 'Stochastic') {
      final slowK = indicators['SlowK']?.toDouble();
      final slowD = indicators['SlowD']?.toDouble();
      final slowKPrev = indicators['SlowK_prev']?.toDouble();
      final slowDPrev = indicators['SlowD_prev']?.toDouble();
      if (slowK == null || slowD == null) return 'Stochastic 현재상태: 데이터 부족';
      String status = '';
      if (slowK > 80 && slowD > 80) {
        status = '과매수 🟥';
      } else if (slowK < 20 && slowD < 20) {
        status = '과매도 🟦';
      } else {
        status = '중립 ⚪';
      }
      if (slowKPrev != null && slowDPrev != null) {
        if (slowK > slowD && slowKPrev <= slowDPrev) {
          status += '\nSlowK > SlowD -> 매수 신호 🚀';
        } else if (slowK < slowD && slowKPrev >= slowDPrev) {
          status += '\nSlowK < SlowD -> 매도 신호 📉';
        }
      }
      return 'Stochastic 현재상태:\nSlowK: $slowK, SlowD: $slowD -> $status';
    } else if (group == 'SMA') {
      final sma10 = indicators['SMA10']?.toDouble();
      final sma50 = indicators['SMA50']?.toDouble();
      final sma10Prev = indicators['SMA10_prev']?.toDouble();
      final sma50Prev = indicators['SMA50_prev']?.toDouble();
      if (sma10 == null || sma50 == null) return 'SMA 현재상태: 데이터 부족';
      String status = '';
      if (sma10 > sma50) {
        status = '상승 추세 📈';
        if (sma10Prev != null && sma50Prev != null && sma10Prev <= sma50Prev) {
          status += '\n골든크로스 -> 상승 전환 🚀';
        }
      } else {
        status = '하락 추세 📉';
        if (sma10Prev != null && sma50Prev != null && sma10Prev >= sma50Prev) {
          status += '\n데드크로스 -> 하락 전환 📉';
        }
      }
      return 'SMA 현재상태:\nSMA10: $sma10, SMA50: $sma50 -> $status';
    } else if (group == 'EMA') {
      final ema20 = indicators['EMA20']?.toDouble();
      final ema50 = indicators['EMA50']?.toDouble();
      final ema20Prev = indicators['EMA20_prev']?.toDouble();
      final ema50Prev = indicators['EMA50_prev']?.toDouble();
      final close = indicators['Close']?.toDouble();
      if (ema20 == null || ema50 == null) return 'EMA 현재상태: 데이터 부족';
      String status = '';
      if (ema20 > ema50) {
        status = '상승 추세 📈';
        if (ema20Prev != null && ema50Prev != null && ema20Prev <= ema50Prev) {
          status += '\n골든크로스 -> 상승 전환 🚀';
        }
      } else {
        status = '하락 추세 📉';
        if (ema20Prev != null && ema50Prev != null && ema20Prev >= ema50Prev) {
          status += '\n데드크로스 -> 하락 전환 📉';
        }
      }
      if (close != null && ema20 != null) {
        if (close > ema20) {
          status += '\nClose > EMA20 -> 단기 상승 📈';
        } else {
          status += '\nClose < EMA20 -> 단기 하락 📉';
        }
      }
      return 'EMA 현재상태:\nEMA20: $ema20, EMA50: $ema50 -> $status';
    } else if (group == 'Bollinger Band') {
      final bbUpper = indicators['BB_upper']?.toDouble();
      final bbLower = indicators['BB_lower']?.toDouble();
      final bbUpperPrev = indicators['BB_upper_prev']?.toDouble();
      final bbLowerPrev = indicators['BB_lower_prev']?.toDouble();
      final close = indicators['Close']?.toDouble();
      final closePrev = indicators['Close_prev']?.toDouble();
      if (bbUpper == null || bbLower == null) return 'Bollinger Band 현재상태: 데이터 부족';
      String status = '';
      if (close != null && closePrev != null && bbUpperPrev != null && bbLowerPrev != null) {
        if (close > bbUpper && closePrev <= bbUpperPrev) {
          status = '종가 > BB_upper -> 과열 주의 🟥';
        } else if (close < bbLower && closePrev >= bbLowerPrev) {
          status = '종가 < BB_lower -> 과냉 주의 🟦';
        } else {
          status = '안정 상태 ⚪';
        }
      } else {
        status = '데이터 부족 ⚪';
      }
      return 'Bollinger Band 현재상태:\nBB_upper: $bbUpper, BB_lower: $bbLower -> $status';
    } else if (group == 'CCI') {
      final value = indicators['CCI']?.toDouble();
      if (value == null) return 'CCI 현재상태: 데이터 부족';
      if (value > 100) return 'CCI 현재상태: $value -> 과열 신호 🟥';
      if (value < -100) return 'CCI 현재상태: $value -> 저평가 신호 🟦';
      return 'CCI 현재상태: $value -> 중립 ⚪';
    } else if (group == 'MFI') {
      final value = indicators['MFI']?.toDouble();
      if (value == null) return 'MFI 현재상태: 데이터 부족';
      if (value > 80) return 'MFI 현재상태: $value -> 과매수 🟥';
      if (value < 20) return 'MFI 현재상태: $value -> 과매도 🟦';
      return 'MFI 현재상태: $value -> 중립 ⚪';
    } else if (group == 'ADX') {
      final value = indicators['ADX']?.toDouble();
      if (value == null) return 'ADX 현재상태: 데이터 부족';
      if (value > 25) return 'ADX 현재상태: $value -> 강한 추세 📈';
      if (value <= 25 && value > 0) return 'ADX 현재상태: $value -> 약한 추세 📉';
      return 'ADX 현재상태: $value -> 추세 미약 ⚪';
    }
    return '$group 현재상태: 데이터 없음';
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if (dates.isEmpty || selectedGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '선택된 지표 또는 날짜 데이터가 없습니다',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final Map<String, Color> indicatorColors = {
      'RSI': Colors.cyan,
      'MACD': Colors.orange,
      'SlowK': Colors.blue,
      'SlowD': Colors.red,
      'SMA10': Colors.pink,
      'SMA50': Colors.purple,
      'EMA20': Colors.green,
      'EMA50': Colors.orange,
      'BB_upper': Colors.red,
      'BB_lower': Colors.red,
      'CCI': Colors.green,
      'MFI': Colors.purple,
      'ADX': Colors.yellow,
    };

    List<Widget> chartWidgets = [];
    for (String group in selectedGroups) {
      final indicatorsInGroup = groupedIndicators[group] ?? [];
      if (indicatorsInGroup.isEmpty) continue;

      bool hasValidData = false;
      for (String indicator in indicatorsInGroup) {
        final series = indicatorsSeries[indicator];
        if (series != null && series.isNotEmpty && series.any((v) => v != null && v.isFinite)) {
          hasValidData = true;
          break;
        }
      }

      if (!hasValidData) {
        chartWidgets.add(
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                const SizedBox(height: 16),
                const Text(
                  '데이터를 불러올 수 없습니다',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '$group 데이터가 없습니다',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
        continue;
      }

      List<LineChartBarData> lineBarsData = [];
      double minY = double.infinity;
      double maxY = double.negativeInfinity;

      for (String indicator in indicatorsInGroup) {
        final series = indicatorsSeries[indicator];
        if (series == null || series.isEmpty) continue;

        final List<FlSpot> spots = [];
        for (int i = 0; i < series.length; i++) {
          final value = series[i];
          if (value != null && value.isFinite) {
            spots.add(FlSpot(i.toDouble(), value));
          }
        }

        if (spots.isEmpty) {
          continue;
        }

        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 2,
            color: indicatorColors[indicator] ?? Colors.cyanAccent,
            dotData: FlDotData(show: false),
          ),
        );

        final spotMinY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
        final spotMaxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
        if (spotMinY < minY) minY = spotMinY;
        if (spotMaxY > maxY) maxY = spotMaxY;
      }

      if (lineBarsData.isEmpty) {
        chartWidgets.add(
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                const SizedBox(height: 16),
                const Text(
                  '데이터를 불러올 수 없습니다',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '$group 차트 데이터가 없습니다',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
        continue;
      }

      double padding = (maxY - minY) * 0.1;
      minY -= padding;
      maxY += padding;

      chartWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Card(
            color: Colors.grey[850],
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        group,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      // 정보 아이콘 추가
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => IndicatorInfoDialog(
                              group: group,
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                            ),
                          );
                        },
                        child: Icon(
                          Icons.info,
                          color: Colors.blueAccent,
                          size: screenWidth * 0.06,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: lineBarsData,
                        minY: minY,
                        maxY: maxY,
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final int index = value.toInt();
                                if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                                if (index % 5 == 0) {
                                  return Text(
                                    dates[index].substring(5),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              reservedSize: 28,
                              interval: 1,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) => Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              reservedSize: 32,
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) =>
                              FlLine(color: Colors.grey[700]!, strokeWidth: 0.5),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey[600]!),
                        ),
                        extraLinesData: _buildThresholdLines(group),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final indicator = indicatorsInGroup[spot.barIndex];
                                return LineTooltipItem(
                                  '$indicator: ${spot.y.toStringAsFixed(2)}',
                                  TextStyle(
                                    color: indicatorColors[indicator]!,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Wrap(
                      spacing: 12.0,
                      children: indicatorsInGroup.map((indicator) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              color: indicatorColors[indicator],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              indicator,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      getIndicatorStatus(group, indicators),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: chartWidgets,
    );
  }

  ExtraLinesData _buildThresholdLines(String group) {
    if (group == 'RSI') {
      return ExtraLinesData(horizontalLines: [
        HorizontalLine(
          y: 70,
          color: Colors.red,
          strokeWidth: 1,
          dashArray: [5, 5],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: const TextStyle(color: Colors.red, fontSize: 12),
            labelResolver: (_) => '과매수',
          ),
        ),
        HorizontalLine(
          y: 30,
          color: Colors.green,
          strokeWidth: 1,
          dashArray: [5, 5],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.bottomRight,
            style: const TextStyle(color: Colors.green, fontSize: 12),
            labelResolver: (_) => '과매도',
          ),
        ),
      ]);
    } else if (group == 'Stochastic') {
      return ExtraLinesData(horizontalLines: [
        HorizontalLine(y: 80, color: Colors.red, strokeWidth: 1, dashArray: [5, 5]),
        HorizontalLine(y: 20, color: Colors.green, strokeWidth: 1, dashArray: [5, 5]),
      ]);
    } else {
      return ExtraLinesData(horizontalLines: []);
    }
  }
}