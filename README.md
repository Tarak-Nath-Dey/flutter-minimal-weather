# Minimalist Weather App (Flutter & Dart)

A beautiful, modern, minimalist single-screen weather application built with Flutter and Dart. It is designed to be beginner-friendly, production-ready, and fully optimized for Web, Mobile, and Desktop deployment.

---

## 🎨 Design & Aesthetic Features

- **Minimalist Glassmorphism**: Center weather card styled with translucent frosting (`BackdropFilter` and frosted borders) to look premium.
- **Dynamic Background Gradients**: The background gradient transitions smoothly between warm soft-amber (sunny), slate-grey (cloudy), deep twilight-blue (rainy), dark charcoal (stormy), and silver-blue (snowy) depending on the active weather conditions.
- **Responsive Layout**: Designed with layout constraints (`ConstrainedBox` limited to `460px` max width) ensuring a perfect presentation on wide web browsers, tablets, and desktop displays, while remaining native and snug on mobile devices.
- **Interactive Settings Drawer**: A gear icon in the top-right opens an advanced panel where developers and users can configure their OpenWeatherMap API Key in real-time.

---

## ⚡ Key Core Features (Refactored)

- **Automatic GPS Location Fetching**: On startup, the app requests location permissions via the `geolocator` package. If granted, it fetches the user's current coordinates and queries local weather. If denied, it falls back to loading "New York" (if an API Key is set) or displays a minimalist welcome card.
- **Smart Autocomplete Geolocation Engine**: The standard search bar utilizes an `Autocomplete<String>` widget linked directly to the OpenWeather Geocoding API, presenting a frosted type-ahead dropdown of suggested locations as you type.
- **Secure Credentials Storage**: All hardcoded API keys are removed for security. User-entered keys are persisted locally using the `shared_preferences` package so configurations survive application restarts or browser refreshes.
- **Direct HTTPS Queries**: All API calls route directly and securely to the official OpenWeatherMap servers over HTTPS.

---

## 📁 Code Structure

- **[`lib/main.dart`](file:///c:/25CSE134/flutter-minimal-weather/lib/main.dart)**
  - Application entry point (`main()` function).
  - Main screen widget (`WeatherHomeScreen` & state).
  - Implements geolocator setup, autocomplete widgets, preferences loading/saving, and settings drawer overlay.
  
- **[`lib/weather_model.dart`](file:///c:/25CSE134/flutter-minimal-weather/lib/weather_model.dart)**
  - Data model mapping weather fields: city name, temperature, main condition, detailed description, humidity, wind speed, and icon code.
  - Safe parsing factory constructor (`WeatherModel.fromJson`) handling numeric type safety (converting `int` to `double`) and null-safe defaults.

- **[`lib/weather_service.dart`](file:///c:/25CSE134/flutter-minimal-weather/lib/weather_service.dart)**
  - Networks request handler wrapper for the `http` client.
  - Queries OpenWeatherMap Current Weather and Geocoding APIs directly using the user's custom API key.

---

## ⚡ Setup & Run Locally

### Prerequisites
- Install the [Flutter SDK](https://flutter.dev/docs/get-started/install).
- Verify setup by running `flutter doctor` in your terminal.

### 1. Clone & Navigate
Navigate to the project root directory:
```bash
cd flutter-minimal-weather
```

### 2. Configure API Key
Open [`lib/weather_service.dart`](file:///c:/25CSE134/flutter-minimal-weather/lib/weather_service.dart) and replace `defaultApiKey` with your OpenWeatherMap API Key:
```dart
static const String defaultApiKey = 'YOUR_API_KEY_HERE';
```
*(Alternatively, you can run the app directly and paste your key inside the on-screen Settings drawer, which will save it to local storage).*

### 3. Run the App
To run the app in development mode on your desired platform:

#### Run on Web:
```bash
flutter run -d chrome
```

#### Run on Windows Desktop:
```bash
flutter run -d windows
```

---

## 🚀 Production Build & Deployment

### 1. Web Build Command
Run this command to build a release web bundle:
```bash
flutter build web --release
```
This generates the optimized static assets in the **`build/web`** directory.

### 2. Windows Desktop Build Command
Run this command to compile a native Windows runner executable:
```bash
flutter build windows
```
This generates release binaries in **`build/windows/x64/runner/Release/minimal_weather.exe`**.

### 3. Android Deployment APK Build Command
Run this command to compile an APK:
```bash
flutter build apk --release
```
This compiles the release APK file in **`build/app/outputs/flutter-apk/app-release.apk`**.

---

## 🛠️ Verification & Quality Checks

Ensure code quality remains pristine before committing:
```bash
# Run the Dart static analyzer
flutter analyze
```
