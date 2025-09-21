import 'package:flutter/material.dart';
import '../widgets/indicator_info_dialog.dart';

class IndicatorTableWidget extends StatelessWidget {
  final Map<String, dynamic> indicators;
  final Function(String) onIndicatorTap;

  const IndicatorTableWidget({
    super.key,
    required this.indicators,
    required this.onIndicatorTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if (indicators.isEmpty) {
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
              '지표 데이터가 비어 있습니다',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final Map<String, List<String>> groupedIndicators = {
      'RSI': ['RSI'],
      'MACD': ['MACD'],
      'CCI': ['CCI'], // 추가
      'MFI': ['MFI'], // 추가
      'ADX': ['ADX'], // 추가
      'Stochastic': ['SlowK', 'SlowD'],
      'SMA': ['SMA10', 'SMA50'],
      'EMA': ['EMA20', 'EMA50'],
      'Bollinger Band': ['BB_upper', 'BB_lower'],
    };

    final List<String> orderedGroups = [
      'RSI',
      'MACD',
      'CCI', // 추가
      'MFI', // 추가
      'ADX', // 추가
      'Stochastic',
      'SMA',
      'EMA',
      'Bollinger Band',
    ];

    final List<String> validGroups = orderedGroups.where((group) {
      final keys = groupedIndicators[group]!;
      return keys.any((key) => indicators.containsKey(key) && indicators[key] != null);
    }).toList();

    if (validGroups.isEmpty) {
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
              '유효한 지표 데이터가 없습니다',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    Map<String, String> states = {};
    Map<String, Color> stateColors = {};
    Map<String, int> stateScores = {};

    for (var group in validGroups) {
      final keys = groupedIndicators[group]!;
      String state = '';
      Color color = Colors.yellow;
      int score = 0;

      if (group == 'RSI' || group == 'MFI') {
        final value = indicators[keys[0]]?.toDouble();
        if (value != null) {
          if (value >= 90) {
            state = '매우 부정';
            color = Colors.red[900]!;
            score = -2;
          } else if (value >= 80) {
            state = '부정';
            color = Colors.red;
            score = -1;
          } else if (value <= 10) {
            state = '매우 긍정';
            color = Colors.green[900]!;
            score = 2;
          } else if (value <= 30) {
            state = '긍정';
            color = Colors.green;
            score = 1;
          } else {
            state = '중립';
            color = Colors.yellow;
            score = 0;
          }
        }
      } else if (group == 'MACD') {
        final macd = indicators['MACD']?.toDouble();
        final macdPrev = indicators['MACD_prev']?.toDouble();
        if (macd != null && macdPrev != null) {
          if (macd >= 2) {
            state = '매우 긍정';
            color = Colors.green[900]!;
            score = 2;
          } else if (macd >= 0.5) {
            state = '긍정';
            color = Colors.green;
            score = 1;
          } else if (macd <= -2) {
            state = '매우 부정';
            color = Colors.red[900]!;
            score = -2;
          } else if (macd <= -0.5) {
            state = '부정';
            color = Colors.red;
            score = -1;
          } else {
            state = '중립';
            color = Colors.yellow;
            score = 0;
          }
        }
      } else if (group == 'CCI') { // 추가
        final value = indicators['CCI']?.toDouble();
        if (value != null) {
          if (value >= 200) {
            state = '매우 부정';
            color = Colors.red[900]!;
            score = -2;
          } else if (value >= 100) {
            state = '부정';
            color = Colors.red;
            score = -1;
          } else if (value <= -200) {
            state = '매우 긍정';
            color = Colors.green[900]!;
            score = 2;
          } else if (value <= -100) {
            state = '긍정';
            color = Colors.green;
            score = 1;
          } else {
            state = '중립';
            color = Colors.yellow;
            score = 0;
          }
        }
      } else if (group == 'ADX') { // 추가
        final value = indicators['ADX']?.toDouble();
        if (value != null) {
          if (value >= 50) {
            state = '매우 긍정';
            color = Colors.green[900]!;
            score = 2;
          } else if (value >= 25) {
            state = '긍정';
            color = Colors.green;
            score = 1;
          } else if (value <= 5) {
            state = '매우 부정';
            color = Colors.red[900]!;
            score = -2;
          } else if (value <= 15) {
            state = '부정';
            color = Colors.red;
            score = -1;
          } else {
            state = '중립';
            color = Colors.yellow;
            score = 0;
          }
        }
      } else if (group == 'Stochastic') {
        final slowK = indicators['SlowK']?.toDouble();
        final slowD = indicators['SlowD']?.toDouble();
        if (slowK != null && slowD != null) {
          if (slowK >= 90 && slowD >= 90) {
            state = '매우 부정';
            color = Colors.red[900]!;
            score = -2;
          } else if (slowK >= 80 && slowD >= 80) {
            state = '부정';
            color = Colors.red;
            score = -1;
          } else if (slowK <= 10 && slowD <= 10) {
            state = '매우 긍정';
            color = Colors.green[900]!;
            score = 2;
          } else if (slowK <= 20 && slowD <= 20) {
            state = '긍정';
            color = Colors.green;
            score = 1;
          } else {
            state = '중립';
            color = Colors.yellow;
            score = 0;
          }
        }
      } else if (group == 'SMA' || group == 'EMA') {
        final shortKey = group == 'SMA' ? 'SMA10' : 'EMA20';
        final longKey = group == 'SMA' ? 'SMA50' : 'EMA50';
        final short = indicators[shortKey]?.toDouble();
        final long = indicators[longKey]?.toDouble();
        if (short != null && long != null) {
          final diffPercent = ((short - long) / long) * 100;
          if (diffPercent >= 5) {
            state = '매우 긍정';
            color = Colors.green[900]!;
            score = 2;
          } else if (diffPercent >= 0) {
            state = '긍정';
            color = Colors.green;
            score = 1;
          } else if (diffPercent <= -5) {
            state = '매우 부정';
            color = Colors.red[900]!;
            score = -2;
          } else if (diffPercent <= 0) {
            state = '부정';
            color = Colors.red;
            score = -1;
          } else {
            state = '중립';
            color = Colors.yellow;
            score = 0;
          }
        }
      } else if (group == 'Bollinger Band') {
        final upper = indicators['BB_upper']?.toDouble();
        final lower = indicators['BB_lower']?.toDouble();
        final close = indicators['close']?.toDouble();
        if (upper != null && lower != null && close != null) {
          if (close > upper) {
            state = '매우 부정';
            color = Colors.red[900]!;
            score = -2;
          } else if (close > upper - (upper - lower) * 0.2) {
            state = '부정';
            color = Colors.red;
            score = -1;
          } else if (close < lower) {
            state = '매우 긍정';
            color = Colors.green[900]!;
            score = 2;
          } else if (close < lower + (upper - lower) * 0.2) {
            state = '긍정';
            color = Colors.green;
            score = 1;
          } else {
            state = '중립';
            color = Colors.yellow;
            score = 0;
          }
        }
      }

      states[group] = state;
      stateColors[group] = color;
      stateScores[group] = score;
    }

    return Column(
      children: validGroups.map((group) {
        final keys = groupedIndicators[group]!;
        final valueText = keys.map((key) => '${key}: ${indicators[key] ?? 'N/A'}').join(', ');
        final state = states[group] ?? '';
        final color = stateColors[group] ?? Colors.yellow;

        return Card(
          color: Colors.grey[850],
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => onIndicatorTap(group),
                      child: Row(
                        children: [
                          Text(
                            group,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  valueText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          state,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}