# 🎬 CinemaNow — Premium Movie Ticket Booking App

CinemaNow is a feature-rich, high-fidelity Flutter application designed to offer users a modern and seamless movie ticket booking journey. From dynamic home screens to an interactive 3D-perspective seat planner and mock digital checkout pipelines, this project represents state-of-the-art Flutter development practices.

---

## ✨ Features Showcase

### 🔐 1. Smart Authentication & Security
- **Multi-flow Authorization**: Supports **Sign In**, **Sign Up**, and **Forgot Password** transitions.
- **Custom Button Animation**: Custom `AnimBtn` that animates filling progress bar on tap to indicate successful submission.
- **Form Verification**: Regex-based email format validation, age checks, password strength verification, and a "I am human" checkbox handler.
- **Visual transition**: Sleek gradient background (`#6A11CB` to `#2575FC`) with slide and fade animation transitions.

### 🏠 2. Immersive Movie Showcase
- **Nested Scroll Experience**: Uses a customized `NestedScrollView` containing a sliver app bar with a dynamic banner backdrop.
- **Tab-based Cataloging**: Split tab views displaying **Now Playing** and **Coming Soon** movies.
- **Premium Cards**: Movie cards with loading/error handlers, ratings overlays, and hero widgets for smooth transitions.
- **Shimmer Loaders**: Visual skeleton loading states during content load.

### 🎭 3. Rich Movie Detail View
- **Media Backdrops**: Shows high-resolution posters and backdrop images.
- **Cast Carousel**: Horizontal cast listings showing actor initials in custom avatars.
- **Synopsis section**: Expanded synopsis detailing movie descriptions.
- **Quick Booking**: Prominent "Book Tickets" action button linked directly to showtime selection.

### 🗓 4. Multiplex & Date Planner
- **Calendar Slider**: 7-day horizontal date slider dynamically displaying days of the week, dates, and months.
- **Showtime Matcher**: Groups showtimes by multiplex theaters (CineMax Multiplex, PVR Cinemas, INOX Movies, Grand Cinemas) for the selected date.

### 🪑 5. Interactive Seat Layout
- **3D perspective floor**: A custom floor painter (`TheaterFloorPainter`) providing depth of view.
- **Multiclass seats**: Interactive seat matrix containing **Regular**, **Premium**, and **Recliner** sections.
- **Dynamic pricing**: Live seat selection calculations adjusting pricing based on the chosen seat tier.
- **Visual legends**: Categorized available, selected, booked, and reserved indicators.

### 💳 6. Digital Checkout & Ticket Generation
- **Order Breakdown**: Summary including selected theater, seats, showtime, and final price.
- **Multi-channel Payments**: Simulated payment models for Credit Card, PayPal, Net Banking, and popular UPI services (GPay, PhonePe, Paytm).
- **Ticket Generator**: A realistic visual digital ticket featuring rounded ticket-punches, dashed dividers, detailed info, and a mock scannable QR code.

---

## 🛠 Technology Stack

- **Flutter**: Cross-platform mobile development framework.
- **Dart**: Programming language.
- **Google Fonts (Poppins)**: Sleek typography.
- **shimmer**: Smooth loading state animations.
- **cached_network_image**: Remote poster caching for offline availability and performance.
- **flutter_animate**: Fluid custom micro-interactions.
- **confetti**: Celebratory success screen effect.
- **page_transition**: Fluid route page animations.
- **intl**: Date, time, and currency formatting helper.

---

## 📂 Project Structure

```text
CinemaNow/
├── android/, ios/, web/    # Platform-specific native directories
├── assets/                 # App assets directory
│   ├── fonts/              # Custom typography files (Poppins)
│   ├── images/             # Visual image resources
│   └── icons/              # SVG and asset icon packs
│
├── lib/
│   ├── main.dart           # Unified application source (All components, screens, services)
│   └── ...
│
└── pubspec.yaml            # Project dependencies and asset definitions
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: Ensure Flutter is installed on your development machine. Set it up using the official [Flutter installation guide](https://docs.flutter.dev/get-started/install).

### Build and Run

1. **Get Dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run on Target Device:**
   ```bash
   flutter run
   ```
