/// Data model representing the weather information fetched from the OpenWeatherMap API.
/// 
/// Designed to be clean, type-safe, and self-documenting for beginners.
class WeatherModel {
  final String cityName;
  final double temperature;
  final String condition;
  final String description;
  final int humidity;
  final double windSpeed;
  final String iconCode;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.iconCode,
  });

  /// Factory constructor to parse weather data from the JSON response safely.
  /// 
  /// Utilizes null safety checks and sensible fallback defaults.
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // OpenWeatherMap puts weather condition items inside a list
    final weatherList = json['weather'] as List?;
    final weatherItem = (weatherList != null && weatherList.isNotEmpty) 
        ? weatherList[0] as Map<String, dynamic> 
        : null;

    final mainData = json['main'] as Map<String, dynamic>?;
    final windData = json['wind'] as Map<String, dynamic>?;

    return WeatherModel(
      cityName: json['name'] as String? ?? 'Unknown City',
      // The API can return temp as int or double, so we parse it safely to double
      temperature: (mainData?['temp'] as num?)?.toDouble() ?? 0.0,
      condition: weatherItem?['main'] as String? ?? 'Unknown',
      description: weatherItem?['description'] as String? ?? 'no description',
      humidity: mainData?['humidity'] as int? ?? 0,
      windSpeed: (windData?['speed'] as num?)?.toDouble() ?? 0.0,
      iconCode: weatherItem?['icon'] as String? ?? '01d',
    );
  }
}
