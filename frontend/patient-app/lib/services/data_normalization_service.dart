class DataNormalizationService {

  static String normalizeType(String type) {

    switch (type.toLowerCase()) {

      case "pulse rate":
      case "heart rate":
      case "hr":
        return "heart_rate";

      case "blood pressure":
      case "bp":
        return "blood_pressure";

      case "body temperature":
      case "temperature":
        return "temperature";

      case "oxygen saturation":
      case "spo2":
        return "spo2";

      case "weight":
        return "weight";

      default:
        return type.toLowerCase();
    }
  }

}