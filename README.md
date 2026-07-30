# CinemaNow — Premium Movie Ticket Booking App

CinemaNow is a feature-rich, high-fidelity Flutter application designed to provide users with a modern and seamless movie ticket booking experience. From dynamic movie showcases to an interactive 3D seat planner and real-time backend integration, this project demonstrates advanced Flutter development practices.

---

## Features Showcase

### 1. Secure Authentication & Profiles

- Firebase Auth: Robust login/signup system powered by Firebase.
- Google Sign-In: One-tap authentication for seamless onboarding.
- User Profiles: Personalized accounts with profile picture uploads using `image_picker`.
- Custom Button Animation: `AnimBtn` with progress filling and haptic feedback.

### 2. Dynamic Theme Engine

- Dual Mode Support: Fully optimized Light and Dark themes with smooth transitions.
- Custom Design Tokens: A curated palette (Gold, Cyan, Rose) ensuring consistent UI across components.
- Provider State Management: Global theme and user state handling.

### 3. Immersive Movie Showcase

- Real-time Catalog: Movie data synced from Cloud Firestore with support for Bollywood, Hollywood, and Tollywood.
- Trailer Playback: Integrated YouTube player for high-quality movie trailers.
- Wishlist System: Interactive heart animations to save movies for later.
- Shimmer Loaders: Skeleton loading states during content fetching.

### 4. Multiplex & Date Planner

- Calendar Slider: 7-day horizontal date slider for quick showtime selection.
- Multiplex Selection: Grouped showtimes from premium theaters like CineMax, PVR, and INOX.

### 5. Interactive Seat Layout

- 3D Perspective Floor: Custom floor painter (`TheaterFloorPainter`) providing realistic depth effects.
- Multi-Class Seats: Interactive matrix containing Regular, Premium, and Recliner sections.
- Live Pricing: Dynamic price calculation based on seat tiers and selections.

### 6. Digital Checkout & QR Tickets

- Secure Payments: Simulated payment models for UPI (GPay, PhonePe, Paytm), Credit Cards, and Net Banking.
- Smart QR Tickets: Real-time generation of scannable QR codes for ticket verification.
- Social Sharing: Share booking details with friends using `share_plus`.

---

## Technology Stack

- Framework: Flutter (v3.x)
- Backend: Firebase (Auth, Firestore)
- State Management: Provider
- Animations: `flutter_animate`, `lottie`, `confetti`
- Media: `youtube_player_flutter`, `cached_network_image`, `image_picker`
- Utilities: `intl`, `qr_flutter`, `share_plus`, `flutter_secure_storage`
- Typography: Poppins

---

## Project Structure

```text
CinemaNow/
├── android/, ios/, web/        # Platform-specific native directories
├── assets/                     # Application assets
│   ├── fonts/                  # Poppins typography files
│   ├── images/                 # UI image resources
│   ├── icons/                  # SVG and asset icons
│   └── animations/             # Lottie animation files
│
├── lib/
│   ├── main.dart               # Application entry point
│   ├── firebase_options.dart   # Firebase configuration
│   └── ...
│
└── pubspec.yaml                # Project dependencies and assets
