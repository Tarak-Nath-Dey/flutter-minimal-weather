import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'weather_model.dart';

/// Service class to handle network operations for fetching weather data.
/// 
/// Integrates OpenWeatherMap APIs and handles web CORS issues dynamically.
class WeatherService {
  // Default API Key set to empty string for security compliance (no hardcoded keys).
  static const String defaultApiKey = '';

  // Base API URL for OpenWeatherMap.
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // Available CORS proxies for Web platform testing.
  static const String allOriginsProxy = 'https://api.allorigins.win/raw?url=';
  static const String corsAnywhereProxy = 'https://cors-anywhere.herokuapp.com/';

  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches weather data for a given [city].
  /// 
  /// Optionally accepts a [customApiKey]. If not provided, [defaultApiKey] is used.
  /// If [useProxy] is true and we are on the web, requests will route through [proxyPrefix].
  Future<WeatherModel> fetchWeather(
    String city, {
    String? customApiKey,
    bool useProxy = true,
    String proxyPrefix = allOriginsProxy,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.trim().isNotEmpty)
        ? customApiKey.trim()
        : defaultApiKey;

    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('API Key is missing or invalid. Please configure your OpenWeatherMap API key.');
    }

    final trimmedCity = city.trim();
    if (trimmedCity.isEmpty) {
      throw Exception('City name cannot be empty.');
    }

    // 1. Build the direct OpenWeatherMap URL
    final String targetUrl = '$baseUrl?q=${Uri.encodeComponent(trimmedCity)}&appid=$apiKey&units=metric';

    Uri requestUri;

    // 2. Dynamic CORS handling for Web
    if (kIsWeb && useProxy) {
      if (proxyPrefix == allOriginsProxy) {
        requestUri = Uri.parse('$proxyPrefix${Uri.encodeComponent(targetUrl)}');
      } else {
        requestUri = Uri.parse('$proxyPrefix$targetUrl');
      }
      debugPrint('Web build detected: Routing request through CORS proxy: $requestUri');
    } else {
      requestUri = Uri.parse(targetUrl);
      debugPrint('Direct request routing: $requestUri');
    }

    try {
      final response = await _client.get(requestUri).timeout(const Duration(seconds: 10));
      return _parseWeatherResponse(response, city: city);
    } catch (e) {
      _handleNetworkError(e, useProxy);
      rethrow;
    }
  }

  /// Fetches weather data for specified coordinates [lat] and [lon].
  Future<WeatherModel> fetchWeatherByCoordinates(
    double lat,
    double lon, {
    String? customApiKey,
    bool useProxy = true,
    String proxyPrefix = allOriginsProxy,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.trim().isNotEmpty)
        ? customApiKey.trim()
        : defaultApiKey;

    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('API Key is missing or invalid. Please configure your OpenWeatherMap API key.');
    }

    // 1. Build direct URL
    final String targetUrl = '$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

    Uri requestUri;

    // 2. Dynamic CORS handling for Web
    if (kIsWeb && useProxy) {
      if (proxyPrefix == allOriginsProxy) {
        requestUri = Uri.parse('$proxyPrefix${Uri.encodeComponent(targetUrl)}');
      } else {
        requestUri = Uri.parse('$proxyPrefix$targetUrl');
      }
      debugPrint('Web build detected: Routing request through CORS proxy: $requestUri');
    } else {
      requestUri = Uri.parse(targetUrl);
      debugPrint('Direct request routing: $requestUri');
    }

    try {
      final response = await _client.get(requestUri).timeout(const Duration(seconds: 10));
      return _parseWeatherResponse(response);
    } catch (e) {
      _handleNetworkError(e, useProxy);
      rethrow;
    }
  }

  /// Fetches city suggestions matching the [query] using the OpenWeather Geocoding API.
  /// 
  /// Returns a list of suggestions formatted as "City Name, State, Country" or "City Name, Country".
  Future<List<String>> fetchCitySuggestions(
    String query, {
    String? customApiKey,
    bool useProxy = true,
    String proxyPrefix = allOriginsProxy,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.trim().isNotEmpty)
        ? customApiKey.trim()
        : defaultApiKey;

    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      return [];
    }

    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty || trimmedQuery.length < 2) {
      return [];
    }

    // 1. Build target URL
    final String targetUrl = 'https://api.openweathermap.org/geo/1.0/direct?q=${Uri.encodeComponent(trimmedQuery)}&limit=5&appid=$apiKey';

    Uri requestUri;

    // 2. Dynamic CORS proxy logic for Web geocoding
    if (kIsWeb && useProxy) {
      if (proxyPrefix == allOriginsProxy) {
        requestUri = Uri.parse('$proxyPrefix${Uri.encodeComponent(targetUrl)}');
      } else {
        requestUri = Uri.parse('$proxyPrefix$targetUrl');
      }
    } else {
      requestUri = Uri.parse(targetUrl);
    }

    try {
      final response = await _client.get(requestUri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> listData = [];

        // Support both direct list responses and wrapped proxy responses
        if (decoded is Map<String, dynamic> && decoded.containsKey('contents')) {
          final contents = decoded['contents'];
          if (contents is String) {
            listData = jsonDecode(contents) as List<dynamic>;
          } else if (contents is List<dynamic>) {
            listData = contents;
          }
        } else if (decoded is List<dynamic>) {
          listData = decoded;
        }

        final List<String> suggestions = [];
        for (var item in listData) {
          if (item is Map<String, dynamic>) {
            final String name = item['name'] as String? ?? '';
            final String country = item['country'] as String? ?? '';
            final String? state = item['state'] as String?;

            if (name.isNotEmpty) {
              if (state != null && state.trim().isNotEmpty) {
                suggestions.add('$name, $state, $country');
              } else {
                suggestions.add('$name, $country');
              }
            }
          }
        }
        return suggestions;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Geocoding autocomplete suggestion error: $e');
      return [];
    }
  }

  /// Unified response parser implementing resilient wrapping checks.
  WeatherModel _parseWeatherResponse(http.Response response, {String? city}) {
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      Map<String, dynamic> weatherJson;

      // Extract nested contents if wrapped by a proxy server
      if (decoded is Map<String, dynamic> && decoded.containsKey('contents')) {
        final contents = decoded['contents'];
        if (contents is String) {
          weatherJson = jsonDecode(contents) as Map<String, dynamic>;
        } else if (contents is Map<String, dynamic>) {
          weatherJson = contents;
        } else {
          throw Exception('Invalid contents format in proxy response.');
        }
      } else if (decoded is Map<String, dynamic>) {
        weatherJson = decoded;
      } else {
        throw Exception('Unexpected response format.');
      }

      return WeatherModel.fromJson(weatherJson);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized API Key. Please verify your OpenWeatherMap API Key.');
    } else if (response.statusCode == 404) {
      if (city != null) {
        throw Exception('City "$city" not found. Please check your spelling and try again.');
      }
      throw Exception('Location not found. Please check spelling or coordinates.');
    } else {
      throw Exception('Failed to load weather (Status Code: ${response.statusCode}).');
    }
  }

  /// Clean network error formatter helper.
  void _handleNetworkError(dynamic error, bool useProxy) {
    if (error is http.ClientException) {
      if (kIsWeb && useProxy) {
        throw Exception(
          'Network request blocked or proxy server offline.\n'
          'Please verify internet access or toggle your web CORS proxy in developer settings.'
        );
      }
      throw Exception('Network error: Unable to reach the server. Please check your internet connection.');
    }
  }
}
