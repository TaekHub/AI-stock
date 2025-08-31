class ChartData {
  final List<String> dates;
  final List<double> closes;

  ChartData({required this.dates, required this.closes});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      dates: List<String>.from(json['dates']),
      closes: List<double>.from(json['closes'].map((x) => x.toDouble())),
    );
  }
}