class ChartData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  ChartData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      date: DateTime.parse(json['date']),
      open: json['open'].toDouble(),
      high: json['high'].toDouble(),
      low: json['low'].toDouble(),
      close: json['close'].toDouble(),
      volume: json['volume'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
}