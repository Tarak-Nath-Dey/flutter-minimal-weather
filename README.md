# Minimalist Weather App (Flutter & Dart)

A beautiful, modern, minimalist single-screen weather application built with Flutter and Dart. It is designed to be beginner-friendly, production-ready, and fully optimized for Web, Mobile, and Desktop deployment.

---

## 🎨 Design & Aesthetic Features

- **Minimalist Glassmorphism**: Center weather card styled with translucent frosting (`BackdropFilter` and frosted borders) to look premium.
- **Dynamic Background Gradients**: The background gradient smooth-transitions between warm soft-amber (sunny), slate-grey (cloudy), deep twilight-blue (rainy), dark charcoal (stormy), and silver-blue (snowy) depending on the weather conditions.
- **Responsive Layout**: Designed with layout constraints (`ConstrainedBox` limited to `460px` max width) ensuring a perfect presentation on wide web browsers, tablets, and desktop displays, while remaining native and snug on mobile devices.
- **Interactive Settings Drawer**: A gear icon in the top-right opens an advanced panel where developers can inspect/change the API Key and toggle/select web CORS proxies in real-time.

---

## 📁 Code Structure

The project has a clean, decoupled structure following best practices:

- **[`lib/main.dart`](file:///c:/25CSE134/flutter-minimal-weather/lib/main.dart)**
  - Application entry point (`main()` function).
  - Main screen widget (`WeatherHomeScreen` & state).
  - UI design elements, weather icon mapper, temperature styling, and settings drawer overlay.
  
- **[`lib/weather_model.dart`](file:///c:/25CSE134/flutter-minimal-weather/lib/weather_model.dart)**
  - Data model mapping weather fields: city name, temperature, main condition, detailed description, humidity, wind speed, and icon code.
  - Safe parsing factory method (`WeatherModel.fromJson`) handling numeric type safety (converting `int` to `double`) and null-safe defaults.

- **[`lib/weather_service.dart`](file:///c:/25CSE134/flutter-minimal-weather/lib/weather_service.dart)**
  - Networks request handler wrapper for the `http` client.
  - Handles the API Key fallback mechanism.
  - Implements **Web CORS Proxy Logic**: prepend-routing requests through CORS proxies like AllOrigins (`https://api.allorigins.win/raw?url=`) or CORS Anywhere whenever running on the Web (`kIsWeb` is true), while preserving direct HTTP client requests for mobile/desktop.

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
*(Alternatively, you can run the app directly and paste your key inside the on-screen Settings drawer).*

### 3. Run the App
To run the app in development mode on your desired platform:

#### Run on Web (Chrome/Edge):
```bash
flutter run -d chrome
```

#### Run on Windows Desktop:
```bash
flutter run -d windows
```

---

## 🚀 Production Build & Deployment

When deploying your Flutter application to the web, you need to compile a production release build.

### 1. Web Build Command
Run this command to build a release web bundle:
```bash
flutter build web --release
```
This generates the optimized, production-ready static assets in the **`build/web`** directory.

---

### 2. Deploy to Netlify (Recommended for Web)

Netlify is excellent for hosting Flutter web apps because it requires zero repository name changes or base-href overrides.

1. Install the Netlify CLI or use the web dashboard at [netlify.com](https://www.netlify.com).
2. Drag and drop the **`build/web`** folder into the Netlify deploy interface, or run:
   ```bash
   netlify deploy --prod --dir=build/web
   ```

---

### 3. Deploy to GitHub Pages

GitHub Pages serves sites from a nested repository URL: `https://<username>.github.io/<repository-name>/`. You must adjust Flutter's base path so files load correctly.

1. Build the release bundle by overriding the base-href path:
   ```bash
   flutter build web --release --base-href "/flutter-minimal-weather/"
   ```
   *(Replace `flutter-minimal-weather` with your actual GitHub repository name if it differs).*
2. Initialize git in the `build/web` directory or deploy using a package like `gh-pages`:
   ```bash
   # Example deployment workflow using Git in build/web
   cd build/web
   git init
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
   git checkout -b gh-pages
   git add .
   git commit -m "Deploy production web bundle"
   git push -f origin gh-pages
   ```

---

## 🛠️ Verification & Quality Checks

Ensure code quality remains pristine before committing:
```bash
# Run the Dart static analyzer
flutter analyze

# Verify local build compilation
flutter build web --release
```
