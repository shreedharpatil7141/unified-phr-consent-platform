import 'api_service.dart';

class AIService {
  static Future<String> generateInsight(
    String title,
    List<double> values, {
    String unit = "",
    String rangeLabel = "",
  }) async {
    if (values.isEmpty) {
      return "No data available for $title.";
    }

    try {
      final response = await ApiService.generateInsight(
        metric: title,
        values: values,
        unit: unit,
        rangeLabel: rangeLabel,
      );

      return (response["insight"] ?? "AI insight unavailable.").toString();
    } catch (_) {
      final average = values.reduce((a, b) => a + b) / values.length;
      final minimum = values.reduce((a, b) => a < b ? a : b);
      final maximum = values.reduce((a, b) => a > b ? a : b);
      return "$title averaged ${average.toStringAsFixed(1)} $unit in $rangeLabel, ranging from ${minimum.toStringAsFixed(1)} to ${maximum.toStringAsFixed(1)} $unit.";
    }
  }
}
