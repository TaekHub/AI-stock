// indicator_table_widget.dart
import 'package:flutter/material.dart';

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
    if (indicators.isEmpty) {
      print('지표 테이블 오류: indicators가 비어 있습니다.');
      return const Center(
        child: Text(
          '지표 데이터를 불러올 수 없습니다.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // 그룹화된 지표 목록
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

    // 표시할 그룹 목록 (순서 지정)
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

    // 각 그룹별로 유효한 데이터가 있는지 확인
    final List<String> validGroups = orderedGroups.where((group) {
      final keys = groupedIndicators[group]!;
      return keys.any((key) => indicators.containsKey(key) && indicators[key] != null);
    }).toList();

    if (validGroups.isEmpty) {
      print('지표 테이블 오류: 유효한 지표 데이터가 없습니다.');
      return const Center(
        child: Text(
          '유효한 지표 데이터가 없습니다.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    Map<String, String> states = {};
    Map<String, Color> stateColors = {};

    // 각 그룹의 상태 계산
    for (var group in validGroups) {
      final keys = groupedIndicators[group]!;
      String state = '';
      Color color = Colors.yellow;

      if (group == 'RSI' || group == 'MFI') {
        double value = (indicators[keys[0]] as num).toDouble();
        if (value > 70) {
          state = '과매수';
          color = Colors.red;
        } else if (value < 30) {
          state = '과매도';
          color = Colors.green;
        } else {
          state = '중립';
        }
      } else if (group == 'MACD') {
        double value = (indicators[keys[0]] as num).toDouble();
        if (value > 0) {
          state = '상승 추세';
          color = Colors.green;
        } else if (value < 0) {
          state = '하락 추세';
          color = Colors.red;
        } else {
          state = '중립';
        }
      } else if (group == 'CCI') {
        double value = (indicators[keys[0]] as num).toDouble();
        if (value > 100) {
          state = '과매수';
          color = Colors.red;
        } else if (value < -100) {
          state = '과매도';
          color = Colors.green;
        } else {
          state = '중립';
        }
      } else if (group == 'ADX') {
        double value = (indicators[keys[0]] as num).toDouble();
        if (value > 25) {
          state = '강한 추세';
          color = Colors.green;
        } else {
          state = '약한 추세';
          color = Colors.red;
        }
      } else if (group == 'Stochastic') {
        double? slowK = indicators['SlowK'] != null ? (indicators['SlowK'] as num).toDouble() : null;
        double? slowD = indicators['SlowD'] != null ? (indicators['SlowD'] as num).toDouble() : null;
        if (slowK != null && slowD != null) {
          if (slowK > 80 && slowD > 80) {
            state = '과매수';
            color = Colors.red;
          } else if (slowK < 20 && slowD < 20) {
            state = '과매도';
            color = Colors.green;
          } else {
            state = '중립';
          }
        } else {
          state = '데이터 부족';
          color = Colors.grey;
        }
      } else if (group == 'SMA') {
        final sma10 = indicators['SMA10'] != null ? (indicators['SMA10'] as num).toDouble() : null;
        final sma50 = indicators['SMA50'] != null ? (indicators['SMA50'] as num).toDouble() : null;
        final sma10Prev = indicators['SMA10_prev'] != null ? (indicators['SMA10_prev'] as num).toDouble() : null;
        final sma50Prev = indicators['SMA50_prev'] != null ? (indicators['SMA50_prev'] as num).toDouble() : null;
        if (sma10 != null && sma50 != null) {
          if (sma10 > sma50) {
            state = '상승 추세 📈';
            color = Colors.green;
            if (sma10Prev != null && sma50Prev != null && sma10Prev <= sma50Prev) {
              state += '\n골든크로스 -> 상승 전환 🚀';
            }
          } else {
            state = '하락 추세 📉';
            color = Colors.red;
            if (sma10Prev != null && sma50Prev != null && sma10Prev >= sma50Prev) {
              state += '\n데드크로스 -> 하락 전환 📉';
            }
          }
        } else {
          state = '데이터 부족';
          color = Colors.grey;
        }
      } else if (group == 'EMA') {
        final ema20 = indicators['EMA20'] != null ? (indicators['EMA20'] as num).toDouble() : null;
        final ema50 = indicators['EMA50'] != null ? (indicators['EMA50'] as num).toDouble() : null;
        final ema20Prev = indicators['EMA20_prev'] != null ? (indicators['EMA20_prev'] as num).toDouble() : null;
        final ema50Prev = indicators['EMA50_prev'] != null ? (indicators['EMA50_prev'] as num).toDouble() : null;
        final close = indicators['Close'] != null ? (indicators['Close'] as num).toDouble() : null;
        if (ema20 != null && ema50 != null) {
          if (ema20 > ema50) {
            state = '상승 추세 📈';
            color = Colors.green;
            if (ema20Prev != null && ema50Prev != null && ema20Prev <= ema50Prev) {
              state += '\n골든크로스 -> 상승 전환 🚀';
            }
          } else {
            state = '하락 추세 📉';
            color = Colors.red;
            if (ema20Prev != null && ema50Prev != null && ema20Prev >= ema50Prev) {
              state += '\n데드크로스 -> 하락 전환 📉';
            }
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
        }
      } else if (group == 'Bollinger Band') {
        final bbUpper = indicators['BB_upper'] != null ? (indicators['BB_upper'] as num).toDouble() : null;
        final bbLower = indicators['BB_lower'] != null ? (indicators['BB_lower'] as num).toDouble() : null;
        final bbUpperPrev = indicators['BB_upper_prev'] != null ? (indicators['BB_upper_prev'] as num).toDouble() : null;
        final bbLowerPrev = indicators['BB_lower_prev'] != null ? (indicators['BB_lower_prev'] as num).toDouble() : null;
        final close = indicators['Close'] != null ? (indicators['Close'] as num).toDouble() : null;
        final closePrev = indicators['Close_prev'] != null ? (indicators['Close_prev'] as num).toDouble() : null;
        if (bbUpper != null && bbLower != null && close != null && closePrev != null && bbUpperPrev != null && bbLowerPrev != null) {
          if (close > bbUpper && closePrev <= bbUpperPrev) {
            state = '종가 > BB_upper -> 과열 주의 🟥';
            color = Colors.red;
          } else if (close < bbLower && closePrev >= bbLowerPrev) {
            state = '종가 < BB_lower -> 과냉 주의 🟦';
            color = Colors.green;
          } else {
            state = '안정 상태 ⚪';
            color = Colors.grey;
          }
        } else {
          state = '데이터 부족 ⚪';
          color = Colors.grey;
        }
      }

      states[group] = state;
      stateColors[group] = color;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
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

            // 그룹별 값 표시 문자열 생성
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
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: GestureDetector(
                onTap: () {
                  onIndicatorTap(group); // 클릭 시 그룹 전달
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              valueText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (state.isNotEmpty)
                          Row(
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
                              ),
                            ],
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