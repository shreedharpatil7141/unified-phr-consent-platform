class DataSegregationService {

  static Map<String, String> segregate(String title) {

    switch(title){

      case "Blood Pressure":
        return {
          "category":"vitals",
          "type":"blood_pressure",
          "domain":"cardiac"
        };

      case "Pulse Rate":
        return {
          "category":"vitals",
          "type":"heart_rate",
          "domain":"cardiac"
        };

      case "Post Prandial Sugar":
      case "Fasting Blood Sugar":
      case "Random Blood Sugar":
        return {
          "category":"vitals",
          "type":"glucose",
          "domain":"metabolic"
        };

      case "Body Temperature":
        return {
          "category":"vitals",
          "type":"temperature",
          "domain":"general"
        };

      case "Weight":
        return {
          "category":"vitals",
          "type":"weight",
          "domain":"wellness"
        };

      case "Oxygen Saturation":
        return {
          "category":"vitals",
          "type":"spo2",
          "domain":"respiratory"
        };

      case "Respiration Rate":
        return {
          "category":"vitals",
          "type":"respiration",
          "domain":"respiratory"
        };

      case "Lab Reports":
        return {
          "category":"lab_report",
          "type":"pathology",
          "domain":"user_selected" // domain will come from dropdown
        };

      case "Upload Prescription":
        return {
          "category":"prescription",
          "type":"prescription",
          "domain":"general"
        };

      case "Doctor Notes":
        return {
          "category":"prescription",
          "type":"doctor_note",
          "domain":"general"
        };

      case "Medical Expense":
        return {
          "category":"expense",
          "type":"billing",
          "domain":"general"
        };

      case "Vaccination":
        return {
          "category":"vaccination",
          "type":"vaccine",
          "domain":"wellness"
        };

      default:
        return {
          "category":"other",
          "type":"unknown",
          "domain":"general"
        };
    }
  }
}