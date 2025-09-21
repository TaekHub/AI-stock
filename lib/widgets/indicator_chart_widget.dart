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
    } else if (group == 'CCI') {
      final value = indicators['CCI']?.toDouble();
      if (value == null) return 'CCI 현재상태: 데이터 부족';
      if (value > 100) return 'CCI 현재상태: $value -> 과매수 🟥';
      if (value < -100) return 'CCI 현재상태: $value -> 과매도 🟦';
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
      return 'ADX 현재상태: $value -> 약한 추세 ⚪';
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
      return 'EMA 현재상태:\nEMA20: $ema20, EMA50: $ema50 -> $status';
    } else if (group == 'Bollinger Band') {
      final bbUpper = indicators['BB_upper']?.toDouble();
      final bbLower = indicators['BB_lower']?.toDouble();
      final close = indicators['close']?.toDouble();
      if (bbUpper == null || bbLower == null || close == null) return 'Bollinger Band 현재상태: 데이터 부족';
      if (close > bbUpper) {
        return 'Bollinger Band 현재상태: 종가 > 상단 -> 과매수 🟥';
      } else if (close < bbLower) {
        return 'Bollinger Band 현재상태: 종가 < 하단 -> 과매도 🟦';
      } else {
        return 'Bollinger Band 현재상태: 중립 ⚪';
      }
    }
    return '$group 현재상태: 데이터 부족';
  }

  @override
  Widget build(BuildContext context) {
    print('IndicatorChartWidget build: dates.length=${dates.length}, selectedGroups=$selectedGroups, indicators=$indicators, indicatorsSeries keys=${indicatorsSeries.keys}');

    if (dates.isEmpty || selectedGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            SizedBox(height: 16),
            Text(
              '지표 차트를 렌더링할 수 없습니다',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '날짜 데이터 또는 선택된 지표가 비어 있습니다',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final List<Widget> chartWidgets = [];
    final Map<String, Color> indicatorColors = {
      'RSI': Colors.blue,
      'MACD': Colors.green,
      'CCI': Colors.purple,
      'MFI': Colors.orange,
      'ADX': Colors.cyan,
      'SlowK': Colors.yellow,
      'SlowD': Colors.red,
      'SMA10': Colors.blue,
      'SMA50': Colors.green,
      'EMA20': Colors.yellow,
      'EMA50': Colors.red,
      'BB_upper': Colors.blue,
      'BB_lower': Colors.green,
    };

    for (final group in selectedGroups) {
      final indicatorsInGroup = groupedIndicators[group] ?? [];
      final validIndicators = indicatorsInGroup.where((indicator) {
        final series = indicatorsSeries[indicator];
        return series != null && series.isNotEmpty; // 필터링 완화
      }).toList();

      print('Group $group: indicatorsInGroup=$indicatorsInGroup, validIndicators=$validIndicators');

      if (validIndicators.isEmpty) {
        print('Skipping group $group: no valid indicators');
        continue;
      }

      final List<LineChartBarData> lineBarsData = validIndicators.map((indicator) {
        final data = indicatorsSeries[indicator] ?? [];
        final spots = data.asMap().entries.where((e) => e.value != null).map((e) {
          return FlSpot(e.key.toDouble(), e.value!);
        }).toList();

        print('Indicator $indicator: spots.length=${spots.length}');

        return LineChartBarData(
          spots: spots,
          isCurved: true,
          color: indicatorColors[indicator] ?? Colors.blue,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        );
      }).toList();

      if (lineBarsData.isEmpty) {
        print('No lineBarsData for group $group');
        continue;
      }

      chartWidgets.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info, color: Colors.blueAccent),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => IndicatorInfoDialog(
                          group: group,
                          screenWidth: MediaQuery.of(context).size.width,
                          screenHeight: MediaQuery.of(context).size.height,
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 200,
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
                              value.toStringAsFixed(0),
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
                          interval: dates.length > 10 ? dates.length / 10 : 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= dates.length) {
                              return const SizedBox.shrink();
                            }
                            try {
                              final date = DateTime.parse(dates[index]);
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  '${date.month}/${date.day}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            } catch (e) {
                              print('Date parsing error for index $index: $e');
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: lineBarsData,
                    extraLinesData: _buildThresholdLines(group),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.asMap().entries.map((entry) {
                            final index = entry.key;
                            final spot = entry.value;
                            return LineTooltipItem(
                              '${validIndicators[index]}: ${spot.y.toStringAsFixed(2)}',
                              const TextStyle(
                                color: Colors.white,
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
                  children: validIndicators.asMap().entries.map((entry) {
                    final indicator = entry.value;
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
      );
    }

    if (chartWidgets.isEmpty) {
      print('No chart widgets generated');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            SizedBox(height: 16),
            Text(
              '지표 차트를 생성할 수 없습니다',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '선택된 지표에 유효한 데이터가 없습니다',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
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
    } else if (group == 'CCI') {
      return ExtraLinesData(horizontalLines: [
        HorizontalLine(y: 100, color: Colors.red, strokeWidth: 1, dashArray: [5, 5]),
        HorizontalLine(y: -100, color: Colors.green, strokeWidth: 1, dashArray: [5, 5]),
      ]);
    } else if (group == 'MFI') {
      return ExtraLinesData(horizontalLines: [
        HorizontalLine(y: 80, color: Colors.red, strokeWidth: 1, dashArray: [5, 5]),
        HorizontalLine(y: 20, color: Colors.green, strokeWidth: 1, dashArray: [5, 5]),
      ]);
    } else if (group == 'ADX') {
      return ExtraLinesData(horizontalLines: [
        HorizontalLine(y: 25, color: Colors.blue, strokeWidth: 1, dashArray: [5, 5]),
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