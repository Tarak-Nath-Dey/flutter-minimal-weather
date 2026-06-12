import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_model.dart';
import 'weather_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimalist Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const WeatherHomeScreen(),
    );
  }
}

class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  // Service instance for API requests
  final WeatherService _weatherService = WeatherService();

  // State variables
  WeatherModel? _weather;
  bool _isLoading = false;
  String? _errorMessage;

  // Local configuration settings (loaded/saved via SharedPreferences)
  String _customApiKey = WeatherService.defaultApiKey;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initial app setup sequence: load configurations, ask for location permissions, or fall back gracefully.
  Future<void> _initializeApp() async {
    // 1. Load saved preferences
    await _loadPreferences();

    // 2. Short-circuit if API key is not entered
    if (_customApiKey.trim().isEmpty) {
      debugPrint('App initialized: No API Key present. Prompting welcome card.');
      return;
    }

    // 3. Try fetching live location
    setState(() {
      _isLoading = true;
    });

    final position = await _determinePosition();
    if (position != null) {
      debugPrint('Location permission granted: Fetching coordinates (${position.latitude}, ${position.longitude})');
      await _fetchWeatherByCoordinates(position.latitude, position.longitude);
    } else {
      debugPrint('Location permission denied/failed: Falling back to default city (New York)');
      await _fetchWeatherForCity('New York');
    }
  }

  /// Load Developer Settings from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _customApiKey = prefs.getString('api_key') ?? '';
      });
    } catch (e) {
      debugPrint('SharedPreferences load error: $e');
    }
  }

  /// Save Developer Settings to SharedPreferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_key', _customApiKey);
    } catch (e) {
      debugPrint('SharedPreferences save error: $e');
    }
  }

  /// Queries the Geolocator package for runtime GPS permissions and current position.
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are active
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Fetch location with a strict 5-second timeout to prevent infinite freezes on slow hardware
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 5),
      );
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } catch (e) {
      debugPrint('Geolocator location determination error: $e');
      return null;
    }
  }

  /// Calls the weather service to fetch weather data for the specified [city].
  Future<void> _fetchWeatherForCity(String city) async {
    final trimmedCity = city.trim();
    if (trimmedCity.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = await _weatherService.fetchWeather(
        trimmedCity,
        customApiKey: _customApiKey,
      );

      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Calls the weather service to fetch weather data by [lat] and [lon] coordinates.
  Future<void> _fetchWeatherByCoordinates(double lat, double lon) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = await _weatherService.fetchWeatherByCoordinates(
        lat,
        lon,
        customApiKey: _customApiKey,
      );

      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Helper to map weather condition strings to Material icons.
  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'rain':
        return Icons.umbrella_rounded;
      case 'drizzle':
        return Icons.water_drop_rounded;
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
      case 'squall':
      case 'tornado':
        return Icons.cloud_queue_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  /// Helper to get weather icon colors.
  Color _getWeatherIconColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return const Color(0xFFFFD54F);
      case 'clouds':
        return Colors.white70;
      case 'rain':
      case 'drizzle':
        return const Color(0xFF90CAF9);
      case 'thunderstorm':
        return const Color(0xFFFFD54F);
      case 'snow':
        return const Color(0xFFE0F7FA);
      default:
        return const Color(0xFFFFD54F);
    }
  }

  /// Helper to fetch dynamic background gradients based on weather condition.
  List<Color> _getWeatherGradient(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return [
          const Color(0xFFFAD961),
          const Color(0xFFF76B1C),
        ];
      case 'clouds':
        return [
          const Color(0xFF757F9A),
          const Color(0xFFD7DDE8),
        ];
      case 'rain':
      case 'drizzle':
        return [
          const Color(0xFF2b5876),
          const Color(0xFF4e4376),
        ];
      case 'thunderstorm':
        return [
          const Color(0xFF0F2027),
          const Color(0xFF203A43),
          const Color(0xFF2C5364),
        ];
      case 'snow':
        return [
          const Color(0xFFE0EAFC),
          const Color(0xFFCFDEF3),
        ];
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return [
          const Color(0xFF3E5151),
          const Color(0xFFDECBA4),
        ];
      default:
        return [
          const Color(0xFF2193b0),
          const Color(0xFF6dd5ed),
        ];
    }
  }

  /// Capitalizes the first letter of each word in a string.
  String _capitalizeDescription(String text) {
    if (text.isEmpty) return '';
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final String currentCondition = _weather?.condition ?? 'default';
    final List<Color> backgroundGradient = _getWeatherGradient(currentCondition);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main Weather UI Content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Smart Autocomplete geocoded search bar
                        if (_customApiKey.trim().isNotEmpty) ...[
                          _buildAutocompleteSearchBar(),
                          const SizedBox(height: 24),
                        ],

                        // Main display card (Glassmorphic)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                              ),
                              padding: const EdgeInsets.all(32.0),
                              child: _customApiKey.trim().isEmpty
                                  ? _buildWelcomeCardWidget()
                                  : _isLoading
                                      ? const _LoadingWidget()
                                      : _errorMessage != null
                                          ? _buildErrorWidget()
                                          : _weather != null
                                              ? _buildWeatherContentWidget()
                                              : const _InitialStateWidget(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Settings Panel Overlay (Runtime customizations)
              if (_showSettings) _buildSettingsDrawer(),

              // Gear button to toggle settings in top-right corner
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(
                    _showSettings ? Icons.close_rounded : Icons.settings_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSettings = !_showSettings;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a modern, geocoding autocomplete search bar using OpenWeather APIs.
  Widget _buildAutocompleteSearchBar() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final query = textEditingValue.text;
        if (query.trim().length < 2) {
          return const Iterable<String>.empty();
        }
        try {
          return await _weatherService.fetchCitySuggestions(
            query,
            customApiKey: _customApiKey,
          );
        } catch (e) {
          debugPrint('Failed to query suggestions: $e');
          return const Iterable<String>.empty();
        }
      },
      onSelected: (String selection) {
        _fetchWeatherForCity(selection);
      },
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              // Scale options dropdown width responsively (matching 460 constrained container)
              width: MediaQuery.of(context).size.width > 460 ? 412 : MediaQuery.of(context).size.width - 48,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: textEditingController,
            focusNode: focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search city (e.g. London, Paris)...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
                onPressed: () {
                  _fetchWeatherForCity(textEditingController.text);
                  focusNode.unfocus();
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            onSubmitted: (value) {
              onFieldSubmitted();
              _fetchWeatherForCity(value);
            },
          ),
        );
      },
    );
  }

  /// Builds a beautiful, minimalist welcome card prompting API Key input.
  Widget _buildWelcomeCardWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.wb_sunny_rounded,
          color: Color(0xFFFFD54F),
          size: 72,
        ),
        const SizedBox(height: 24),
        Text(
          'Minimalist Weather',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'To begin displaying atmospheric data, click the settings gear in the top right and enter your OpenWeatherMap API key.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _showSettings = true;
            });
          },
          icon: const Icon(Icons.key_rounded, color: Colors.white, size: 18),
          label: const Text('Configure API Key', style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Builds the error state widget with spellchecking/connectivity suggestions.
  Widget _buildErrorWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Colors.redAccent,
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          'Fetch Attempt Failed',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage ?? 'An unknown error occurred.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                _initializeApp();
              },
              icon: const Icon(Icons.location_searching_rounded, color: Colors.black87, size: 16),
              label: const Text('Retry GPS', style: TextStyle(color: Colors.black87)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                _fetchWeatherForCity('New York');
              },
              icon: const Icon(Icons.home_work_rounded, color: Colors.white, size: 16),
              label: const Text('Default City', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the detailed weather content display.
  Widget _buildWeatherContentWidget() {
    final weather = _weather!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // City Name
        Text(
          weather.cityName,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Date Label
        Text(
          'Atmospheric Snapshot',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.65),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 24),

        // Beautifully stylized Weather Icon
        Hero(
          tag: 'weather_icon',
          child: Icon(
            _getWeatherIcon(weather.condition),
            size: 96,
            color: _getWeatherIconColor(weather.condition),
          ),
        ),
        const SizedBox(height: 20),

        // Temperature
        Text(
          '${weather.temperature.toStringAsFixed(1)}°C',
          style: GoogleFonts.outfit(
            fontSize: 64,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),

        // Weather Condition Text
        Text(
          _capitalizeDescription(weather.description),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Divider
        Divider(color: Colors.white.withValues(alpha: 0.15), thickness: 1),
        const SizedBox(height: 20),

        // Extra details Row (Humidity and Wind Speed)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDetailItem(
              icon: Icons.water_drop_outlined,
              label: 'HUMIDITY',
              value: '${weather.humidity}%',
            ),
            _buildDetailItem(
              icon: Icons.air_rounded,
              label: 'WIND SPEED',
              value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
            ),
          ],
        ),
      ],
    );
  }

  /// Detail item widget helper.
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Builds the custom settings panel drawer overlay.
  Widget _buildSettingsDrawer() {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.65),
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Developer & Key Settings',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Configurations are saved in local storage and survive application restarts.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),

                // API Key Textfield
                const Text(
                  'OpenWeatherMap API Key',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (val) {
                    _customApiKey = val.trim();
                  },
                  controller: TextEditingController(text: _customApiKey),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    hintText: 'Enter OpenWeather API Key',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showSettings = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Close', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _showSettings = false;
                          });

                          // Save values permanently
                          await _savePreferences();

                          // Refresh app state
                          if (_customApiKey.isNotEmpty) {
                            if (_weather != null) {
                              _fetchWeatherForCity(_weather!.cityName);
                            } else {
                              _initializeApp();
                            }
                          } else {
                            // If empty, return to initial Welcome screen
                            setState(() {
                              _weather = null;
                              _errorMessage = null;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Apply & Save',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
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
  }
}

/// Frosted Loading widget helper.
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Connecting to Satellite...',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Fallback / Initial blank state widget.
class _InitialStateWidget extends StatelessWidget {
  const _InitialStateWidget();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_outlined, color: Colors.white38, size: 64),
        SizedBox(height: 16),
        Text(
          'Fetching local details...',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
