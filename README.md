# 🎬 CinemaNow — Premium Movie Ticket Booking App

CinemaNow is a feature-rich, high-fidelity Flutter application designed to offer users a modern and seamless movie ticket booking journey. From dynamic home screens to an interactive 3D-perspective seat planner and real-time backend integration, this project represents state-of-the-art Flutter development practices.

---

## ✨ Features Showcase

### 🔐 1. Secure Authentication & Profiles
- **Firebase Auth**: Robust login/signup system powered by Firebase.
- **Google Sign-In**: One-tap authentication for a frictionless onboarding experience.
- **User Profiles**: Personalized accounts with profile picture uploads via `image_picker`.
- **Custom Button Animation**: `AnimBtn` with progress filling and haptic feedback.

### 🌗 2. Dynamic Theme Engine
- **Dual Mode Support**: Fully optimized Light and Dark themes with smooth transitions.
- **Custom Design Tokens**: A curated palette (Gold, Cyan, Rose) ensuring consistent UI across all components.
- **Provider State Management**: Global theme and user state handling.

### 🏠 3. Immersive Movie Showcase
- **Real-time Catalog**: Movie data synced from **Cloud Firestore** with support for Bollywood, Hollywood, and Tollywood.
- **Trailer Playback**: Integrated YouTube player for high-quality movie trailers.
- **Wishlist System**: Interactive heart animations to save movies for later.
- **Shimmer Loaders**: Visual skeleton loading states during content fetch.

### 🗓 4. Multiplex & Date Planner
- **Calendar Slider**: 7-day horizontal date slider for quick showtime selection.
- **Multiplex Selection**: Grouped showtimes by premium theaters (CineMax, PVR, INOX).

### 🪑 5. Interactive Seat Layout
- **3D perspective floor**: A custom floor painter (`TheaterFloorPainter`) providing depth of view.
- **Multiclass seats**: Interactive matrix containing **Regular**, **Premium**, and **Recliner** sections.
- **Live Pricing**: Dynamic price calculation based on seat tier and selection.

### 💳 6. Digital Checkout & QR Tickets
- **Secure Payments**: Simulated payment models for UPI (GPay, PhonePe, Paytm), Credit Cards, and Net Banking.
- **Smart QR Tickets**: Real-time generation of scannable QR codes for ticket verification.
- **Social Sharing**: Share booking details with friends via `share_plus`.

---

## 🛠 Technology Stack

- **Framework**: [Flutter](https://flutter.dev) (v3.x)
- **Backend**: [Firebase](https://firebase.google.com) (Auth, Firestore)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Animations**: `flutter_animate`, `lottie`, `confetti`
- **Media**: `youtube_player_flutter`, `cached_network_image`, `image_picker`
- **Utilities**: `intl`, `qr_flutter`, `share_plus`, `flutter_secure_storage`
- **Typography**: [Poppins](https://fonts.google.com/specimen/Poppins)

---

## 📂 Project Structure

```text
CinemaNow/
├── android/, ios/, web/    # Platform-specific native directories
├── assets/                 # App assets directory
│   ├── fonts/              # Poppins typography files
│   ├── images/             # UI image resources
│   ├── icons/              # SVG and asset icon packs
│   └── animations/         # Lottie JSON files
│
├── lib/
│   ├── main.dart           # Primary application logic (Services, Models, UI)
│   ├── firebase_options.dart # Firebase configuration for all platforms
│   └── ...
│
└── pubspec.yaml            # Project dependencies and asset definitions
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Firebase Project**: Set up a Firebase project and add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).

### Build and Run

1. **Clone & Fetch:**
   ```bash
   git clone https://github.com/your-username/CinemaNow.git
   cd CinemaNow
   flutter pub get
   ```

2. **Initialize Firebase:**
   Ensure you have the [Firebase CLI](https://firebase.google.com/docs/cli) installed.
   ```bash
   flutterfire configure
   ```

3. **Run on Target Device:**
   ```bash
   flutter run
   ```
