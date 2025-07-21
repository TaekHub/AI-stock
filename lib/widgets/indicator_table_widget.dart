import 'package:flutter/material.dart';

import '../../services/database_service.dart';
import 'indicator_info_dialog.dart';

class IndicatorTableWidget extends StatelessWidget {
  final Map<String, dynamic> indicators;
  final Function(String) onIndicatorTap;
  final DatabaseService dbService;

  const IndicatorTableWidget({
    super.key,
    required this.indicators,
    required this.onIndicatorTap,
    required this.dbService,
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
      'CCI': ['CCI'],
      'MFI': ['MFI'],
      'ADX': ['ADX'],
      'Stochastic': ['SlowK', 'SlowD'],
      'SMA': ['SMA10', 'SMA50'],
      'EMA': ['EMA20', 'EMA50'],
      'Bollinger Band': ['BB_upper', 'BB_lower'],
    };

    final List<String> orderedGroups = [
      'RSI',
      'MACD',
      'CCI',
      'MFI',
      'ADX',
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
        double value = (indicators[keys[0]] as num).toDouble();
        if (value >= 90) {
          state = '매우 부정';
          color = Colors.red;
          score = -2;
        } else if (value >= 80) {
          state = '부정';
          color = Colors.orange;
          score = -1;
        } else if (value >= 30) {
          state = '중립';
          color = Colors.yellow;
          score = 0;
        } else if (value >= 10) {
          state = '긍정';
          color = Colors.lightGreen[700]!;
          score = 1;
        } else {
          state = '매우 긍정';
          color = Colors.green;
          score = 2;
        }
      } else if (group == 'MACD') {
        double value = (indicators[keys[0]] as num).toDouble();
        if (value >= 2) {
          state = '매우 긍정';
          color = Colors.green;
          score = 2;
        } else if (value >= 0.5) {
          state = '긍정';
          color = Colors.lightGreen[700]!;
          score = 1;
        } else if (value >= -0.5) {
          state = '중립';
          color = Colors.yellow;
          score = 0;
        } else if (value >= -2) {
          state = '부정';
          color = Colors.orange;
          score = -1;
        } else {
          state = '매우 부정';
          color = Colors.red;
          score = -2;
        }
      } else if (group == 'CCI') {
        double value = (indicators[keys[0]] as num).toDouble();
        if (value >= 200) {
          state = '매우 부정';
          color = Colors.red;
          score = -2;
        } else if (value >= 100) {
          state = '부정';
          color = Colors.orange;
          score = -1;
        } else if (value >= -100) {
          state = '중립';
          color = Colors.yellow;
          score = 0;
        } else if (value >= -200) {
          state = '긍정';
          color = Colors.lightGreen[700]!;
          score = 1;
        } else {
          state = '매우 긍정';
          color = Colors.green;
          score = 2;
        }
      } else if (group == 'ADX') {
        double value = (indicators[keys[0]] as num).toDouble();
        if (value >= 50) {
          state = '매우 긍정';
          color = Colors.green;
          score = 2;
        } else if (value >= 25) {
          state = '긍정';
          color = Colors.lightGreen[700]!;
          score = 1;
        } else if (value >= 15) {
          state = '중립';
          color = Colors.yellow;
          score = 0;
        } else if (value >= 5) {
          state = '부정';
          color = Colors.orange;
          score = -1;
        } else {
          state = '매우 부정';
          color = Colors.red;
          score = -2;
        }
      } else if (group == 'Stochastic') {
        double? slowK = indicators['SlowK'] != null ? (indicators['SlowK'] as num).toDouble() : null;
        double? slowD = indicators['SlowD'] != null ? (indicators['SlowD'] as num).toDouble() : null;
        if (slowK != null && slowD != null) {
          if (slowK >= 90 && slowD >= 90) {
            state = '매우 부정';
            color = Colors.red;
            score = -2;
          } else if (slowK >= 80 && slowD >= 80) {
            state = '부정';
            color = Colors.orange;
            score = -1;
          } else if (slowK >= 20 && slowD >= 20) {
            state = '중립';
            color = Colors.yellow;
            score = 0;
          } else if (slowK >= 10 && slowD >= 10) {
            state = '긍정';
            color = Colors.lightGreen[700]!;
            score = 1;
          } else {
            state = '매우 긍정';
            color = Colors.green;
            score = 2;
          }
        } else {
          state = '데이터 부족';
          color = Colors.grey;
          score = 0;
        }
      } else if (group == 'SMA') {
        final sma10 = indicators['SMA10'] != null ? (indicators['SMA10'] as num).toDouble() : null;
        final sma50 = indicators['SMA50'] != null ? (indicators['SMA50'] as num).toDouble() : null;
        final sma10Prev = indicators['SMA10_prev'] != null ? (indicators['SMA10_prev'] as num).toDouble() : null;
        final sma50Prev = indicators['SMA50_prev'] != null ? (indicators['SMA50_prev'] as num).toDouble() : null;
        if (sma10 != null && sma50 != null) {
          double diffPercent = sma50 != 0 ? ((sma10 - sma50) / sma50 * 100) : 0;
          if (sma10 > sma50) {
            if (diffPercent >= 5) {
              state = '매우 긍정 📈';
              color = Colors.green;
              score = 2;
            } else {
              state = '긍정 📈';
              color = Colors.lightGreen[700]!;
              score = 1;
            }
            if (sma10Prev != null && sma50Prev != null && sma10Prev <= sma50Prev) {
              state += '\n골든크로스 -> 상승 전환 🚀';
            }
          } else {
            if (diffPercent <= -5) {
              state = '매우 부정 📉';
              color = Colors.red;
              score = -2;
            } else {
              state = '부정 📉';
              color = Colors.orange;
              score = -1;
            }
            if (sma10Prev != null && sma50Prev != null && sma10Prev >= sma50Prev) {
              state += '\n데드크로스 -> 하락 전환 📉';
            }
          }
          if (diffPercent > -1 && diffPercent < 1) {
            state = '중립';
            color = Colors.yellow;
            score = 0;
          }
        } else {
          state = '데이터 부족';
          color = Colors.grey;
          score = 0;
        }
      } else if (group == 'EMA') {
        final ema20 = indicators['EMA20'] != null ? (indicators['EMA20'] as num).toDouble() : null;
        final ema50 = indicators['EMA50'] != null ? (indicators['EMA50'] as num).toDouble() : null;
        final ema20Prev = indicators['EMA20_prev'] != null ? (indicators['EMA20_prev'] as num).toDouble() : null;
        final ema50Prev = indicators['EMA50_prev'] != null ? (indicators['EMA50_prev'] as num).toDouble() : null;
        final close = indicators['Close'] != null ? (indicators['Close'] as num).toDouble() : null;
        if (ema20 != null && ema50 != null) {
          double diffPercent = ema50 != 0 ? ((ema20 - ema50) / ema50 * 100) : 0;
          if (ema20 > ema50) {
            if (diffPercent >= 5) {
              state = '매우 긍정 📈';
              color = Colors.green;
              score = 2;
            } else {
              state = '긍정 📈';
              color = Colors.lightGreen[700]!;
              score = 1;
            }
            if (ema20Prev != null && ema50Prev != null && ema20Prev <= ema50Prev) {
              state += '\n골든크로스 -> 상승 전환 🚀';
            }
          } else {
            if (diffPercent <= -5) {
              state = '매우 부정 📉';
              color = Colors.red;
              score = -2;
            } else {
              state = '부정 📉';
              color = Colors.orange;
              score = -1;
            }
            if (ema20Prev != null && ema50Prev != null && ema20Prev >= ema50Prev) {
              state += '\n데드크로스 -> 하락 전환 📉';
            }
          }
          if (diffPercent > -1 && diffPercent < 1) {
            state = '중립';
            color = Colors.yellow;
            score = 0;
          }
          if (close != null) {
            if (close > ema20) {
              state += '\nClose > EMA20 -> 단기 상승 📈';
            } else {
              state += '\nClose < EMA20 -> 단기 하락 📉';
            }
          }
        } else {
          state = '데이터 부족';
          color = Colors.grey;
          score = 0;
        }
      } else if (group == 'Bollinger Band') {
        final bbUpper = indicators['BB_upper'] != null ? (indicators['BB_upper'] as num).toDouble() : null;
        final bbLower = indicators['BB_lower'] != null ? (indicators['BB_lower'] as num).toDouble() : null;
        final bbUpperPrev = indicators['BB_upper_prev'] != null ? (indicators['BB_upper_prev'] as num).toDouble() : null;
        final bbLowerPrev = indicators['BB_lower_prev'] != null ? (indicators['BB_lower_prev'] as num).toDouble() : null;
        final close = indicators['Close'] != null ? (indicators['Close'] as num).toDouble() : null;
        final closePrev = indicators['Close_prev'] != null ? (indicators['Close_prev'] as num).toDouble() : null;
        if (bbUpper != null && bbLower != null && close != null && closePrev != null && bbUpperPrev != null && bbLowerPrev != null) {
          double midBand = (bbUpper + bbLower) / 2;
          double bandWidth = (bbUpper - bbLower) / 2;
          if (close > bbUpper && closePrev <= bbUpperPrev) {
            state = '매우 부정 🟥';
            color = Colors.red;
            score = -2;
          } else if (close >= midBand + bandWidth * 0.5 && close < bbUpper) {
            state = '부정 🟥';
            color = Colors.orange;
            score = -1;
          } else if (close >= midBand - bandWidth * 0.5 && close < midBand + bandWidth * 0.5) {
            state = '중립 ⚪';
            color = Colors.grey;
            score = 0;
          } else if (close >= bbLower && close < midBand - bandWidth * 0.5) {
            state = '긍정 🟦';
            color = Colors.lightGreen[700]!;
            score = 1;
          } else if (close < bbLower && closePrev >= bbLowerPrev) {
            state = '매우 긍정 🟦';
            color = Colors.green;
            score = 2;
          } else {
            state = '안정 상태 ⚪';
            color = Colors.grey;
            score = 0;
          }
        } else {
          state = '데이터 부족 ⚪';
          color = Colors.grey;
          score = 0;
        }
      }

      states[group] = state;
      stateColors[group] = color;
      stateScores[group] = score;
    }

    int totalScore = 0;
    int validIndicatorCount = 0;
    stateScores.forEach((group, score) {
      if (states[group] != '데이터 부족') {
        totalScore += score;
        validIndicatorCount++;
      }
    });

    String overallAssessment;
    Color overallColor;
    IconData overallIcon;
    if (totalScore >= 5) {
      overallAssessment = '매우 긍정';
      overallColor = Colors.green;
      overallIcon = Icons.trending_up;
    } else if (totalScore >= 2) {
      overallAssessment = '긍정';
      overallColor = Colors.lightGreen[700]!;
      overallIcon = Icons.trending_up;
    } else if (totalScore >= -1) {
      overallAssessment = '중립';
      overallColor = Colors.yellow;
      overallIcon = Icons.remove;
    } else if (totalScore >= -4) {
      overallAssessment = '부정';
      overallColor = Colors.orange;
      overallIcon = Icons.trending_down;
    } else {
      overallAssessment = '매우 부정';
      overallColor = Colors.red;
      overallIcon = Icons.trending_down;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Card(
              color: Colors.grey[850],
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: overallColor.withOpacity(0.5), width: 2),
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      overallColor.withOpacity(0.2),
                      Colors.grey[850]!.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      overallIcon,
                      color: overallColor,
                      size: screenWidth * 0.08,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '종합 평가',
                            style: TextStyle(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.005),
                          Row(
                            children: [
                              Text(
                                overallAssessment,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                  color: overallColor,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                '(점수: $totalScore)',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Text(
              '내 기술적 지표 (최근 기준)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ...validGroups.map((group) {
            final keys = groupedIndicators[group]!;
            final state = states[group] ?? '';
            final color = stateColors[group] ?? Colors.transparent;

            String valueText = '';
            if (group == 'SMA') {
              double? sma10 = indicators['SMA10'] != null ? (indicators['SMA10'] as num).toDouble() : null;
              double? sma50 = indicators['SMA50'] != null ? (indicators['SMA50'] as num).toDouble() : null;
              valueText = 'SMA10: ${sma10?.toStringAsFixed(2) ?? 'N/A'}, SMA50: ${sma50?.toStringAsFixed(2) ?? 'N/A'}';
            } else if (group == 'EMA') {
              double? ema20 = indicators['EMA20'] != null ? (indicators['EMA20'] as num).toDouble() : null;
              double? ema50 = indicators['EMA50'] != null ? (indicators['EMA50'] as num).toDouble() : null;
              valueText = 'EMA20: ${ema20?.toStringAsFixed(2) ?? 'N/A'}, EMA50: ${ema50?.toStringAsFixed(2) ?? 'N/A'}';
            } else if (group == 'Bollinger Band') {
              double? bbUpper = indicators['BB_upper'] != null ? (indicators['BB_upper'] as num).toDouble() : null;
              double? bbLower = indicators['BB_lower'] != null ? (indicators['BB_lower'] as num).toDouble() : null;
              valueText = 'Upper: ${bbUpper?.toStringAsFixed(2) ?? 'N/A'}, Lower: ${bbLower?.toStringAsFixed(2) ?? 'N/A'}';
            } else if (group == 'Stochastic') {
              double? slowK = indicators['SlowK'] != null ? (indicators['SlowK'] as num).toDouble() : null;
              double? slowD = indicators['SlowD'] != null ? (indicators['SlowD'] as num).toDouble() : null;
              valueText = 'SlowK: ${slowK?.toStringAsFixed(2) ?? 'N/A'}, SlowD: ${slowD?.toStringAsFixed(2) ?? 'N/A'}';
            } else if (group == 'MACD') {
              double? value = indicators[keys[0]] != null ? (indicators[keys[0]] as num).toDouble() : null;
              valueText = value?.toStringAsFixed(3) ?? 'N/A';
            } else {
              double? value = indicators[keys[0]] != null ? (indicators[keys[0]] as num).toDouble() : null;
              valueText = value?.toStringAsFixed(2) ?? 'N/A';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
              child: GestureDetector(
                onTap: () {
                  onIndicatorTap(group);
                },
                child: Card(
                  color: Colors.grey[850],
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
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
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => IndicatorInfoDialog(
                                          group: group,
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          info: dbService.getIndicatorInfo()[group]!,
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
                            ],
                          ),
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
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}