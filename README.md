# WorkoutApp - AI-Powered Fitness Platform

An intelligent, AI-driven mobile platform that delivers personalized fitness experiences through advanced workout generation, real-time progress tracking, and comprehensive exercise management.

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.19.0+
- Dart SDK 3.8.1+
- Node.js 20+ (for Firebase Functions)
- Firebase CLI
- Git

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd workout_app
   ```

2. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

3. **Set up Firebase**

   ```bash
   # Install Firebase CLI if not already installed
   npm install -g firebase-tools

   # Login to Firebase
   firebase login

   # Install Firebase Functions dependencies
   cd firebase/functions
   npm install
   cd ../..
   ```

4. **Configure environment**

   ```bash
   # Copy environment template
   cp firebase/functions/.env.example firebase/functions/.env

   # Edit .env file with your API keys
   # GEMINI_API_KEY=your_gemini_api_key
   ```

## 🏃‍♂️ Running the Application

### Development Mode

```bash
# Run on Chrome (Web)
flutter run -d chrome --web-port 3000

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
```

### Firebase Functions (Local Development)

```bash
cd firebase
firebase emulators:start
```

## 🚀 Deployment

### Build for Production

**Web Deployment:**

```bash
# Build web application
flutter build web --release --dart-define=ENVIRONMENT=production

# Deploy to Firebase Hosting
cd firebase
firebase deploy --only hosting
```

**Mobile Deployment:**

```bash
# Android
flutter build apk --release --dart-define=ENVIRONMENT=production
flutter build appbundle --release --dart-define=ENVIRONMENT=production

# iOS
flutter build ios --release --dart-define=ENVIRONMENT=production
```

### Firebase Functions Deployment

```bash
cd firebase

# Deploy to staging
firebase use staging
firebase deploy --only functions

# Deploy to production
firebase use production
firebase deploy --only functions
```

## 📱 Features

- **AI-Powered Workout Generation:** Personalized workouts using Google Gemini AI
- **Real-Time Session Tracking:** Live workout monitoring with progress analytics
- **Comprehensive Exercise Library:** Extensive database with detailed instructions
- **Cross-Platform Support:** Web, Android, iOS, Windows, macOS, Linux
- **Advanced Analytics:** Progress tracking and performance insights
- **Secure Authentication:** Firebase Auth with comprehensive security rules

## 🏗️ Architecture

### Technology Stack

- **Frontend:** Flutter 3.19.0 with Dart 3.8.1
- **Backend:** Firebase Functions (Node.js 20)
- **Database:** Cloud Firestore with real-time sync
- **Authentication:** Firebase Auth
- **AI Integration:** Google Gemini 1.5 Flash
- **State Management:** Provider pattern

### Key Optimizations

- **TOON Format:** 30-60% AI token cost reduction
- **Intelligent Caching:** Multi-layer caching strategy
- **Performance Monitoring:** Real-time metrics and alerts
- **Security:** Comprehensive input validation and Firebase rules

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Firebase Functions tests
cd firebase/functions
npm test
```

## 📊 Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
├── providers/                # State management
├── screens/                  # UI screens
├── services/                 # Business logic
├── utils/                    # Utilities and constants
└── widgets/                  # Reusable components

firebase/
├── functions/                # Firebase Functions
│   ├── src/                  # Source code
│   └── package.json          # Dependencies
├── firestore.rules           # Security rules
└── firebase.json             # Firebase configuration
```

## 🔧 Configuration

### Environment Variables

Create `firebase/functions/.env`:

```env
GEMINI_API_KEY=your_gemini_api_key
ENVIRONMENT=development
DEBUG_MODE=true
```

### Firebase Projects

- **Development:** exerciselist-dev-da299
- **Staging:** exerciselist-staging-da299
- **Production:** exerciselist-da299

## 🛠️ Development Workflow

1. **Feature Development**

   ```bash
   git checkout -b feature/new-feature
   # Make changes
   flutter test
   git commit -m "feat: add new feature"
   git push origin feature/new-feature
   ```

2. **Code Quality**

   ```bash
   # Analyze code
   flutter analyze

   # Format code
   dart format .

   # Check Firebase Functions
   cd firebase/functions
   npm run lint
   ```

3. **Deployment Pipeline**
   - Push to `develop` → Auto-deploy to staging
   - Push to `main` → Auto-deploy to production

## 📈 Monitoring

### Performance Monitoring

- Firebase Performance Monitoring
- Custom metrics tracking
- Real-time error reporting

### Analytics

- User engagement metrics
- Feature usage analytics
- Performance insights

## 🔒 Security

- Firebase Security Rules for data protection
- Input validation and sanitization
- Rate limiting for API endpoints
- Automated vulnerability scanning

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Documentation:** Check the inline code documentation
- **Issues:** Create an issue on GitHub
- **Discussions:** Use GitHub Discussions for questions

## 🎯 Keywords

AI-Powered, Flutter, Firebase, Personalization, Cross-Platform, TOON Optimization, Real-Time, Scalable, Security, Performance
