# 📱 DevByRam — Flutter App Portfolio

Welcome to **DevByRam**, a curated collection of high-quality mobile applications built using the **Flutter** SDK. This repository showcases real-world mobile development practices, premium UI/UX designs, interactive animations, and responsive layouts.

---

## 🚀 Projects Overview

| Project | Description | Platform Support | Tech Highlights |
| :--- | :--- | :--- | :--- |
| **[CinemaNow](./CinemaNow)** | A feature-rich movie ticket booking application featuring authentication, interactive seat selection, and digital tickets. | Android, iOS, Web, Windows, macOS, Linux | `flutter_animate`, `shimmer`, `cached_network_image`, `confetti` |
| **[ITW_Project](./ITW_Project)** | A security-focused authentication framework demonstration with deep field validation and smooth transitions. | Android, iOS, Web, Windows, macOS, Linux | `intl`, Custom Animation Controllers |

---

## 🎬 1. CinemaNow — Movie Ticket Booking App

**CinemaNow** is a premium, state-of-the-art movie booking application designed to deliver a smooth and engaging booking experience.

### Key Screens & Flow
1. **Security & Authentication (`AuthScreen`)**
   - Elegant gradient background (`#6A11CB` to `#2575FC`) with a custom logo.
   - Fluid slide and fade animations between **Sign In**, **Sign Up**, and **Password Reset** modes.
   - Interactive, custom animated login buttons (`AnimBtn`) that show confirmation progress upon completion.
   - Custom field validation, password visibility toggles, and an "I am human" checkbox verification.
2. **Dynamic Movie Showcase (`HomeScreen`)**
   - Immersive nested scroll experience (`NestedScrollView`) with custom silver app bar.
   - Tab navigation for **Now Playing** (dynamic rating overlays, genre badges) and **Coming Soon** movies.
   - Seamless shimmer loading transitions using the `shimmer` package.
   - Bottom navigation menu to browse Home, Search, Tickets, and Profile.
3. **Comprehensive Movie Detail Screen (`MovieDetailScreen`)**
   - Parallax banner backdrop, bookmark, and social share buttons.
   - Detailed cast carousel displaying actors' avatars and info.
   - One-click trailer launcher and immediate booking redirection.
4. **Interactive Seat Planner (`SeatSelectionScreen`)**
   - Dynamic 3D-perspective theater layout using custom matrix transformations.
   - Interactive seat grid categorized into **Regular**, **Premium**, and **Recliner** classes.
   - Live ticket counter and price updates based on selected tiers.
   - Visual status indicators (Available, Selected, Booked, Reserved).
5. **Express Checkout & Payment (`CheckoutScreen`)**
   - Detailed order summaries with dynamic calculation.
   - Multi-channel support (Credit/Debit Card, PayPal, UPI, Google Pay, PhonePe, Paytm, and Net Banking).
   - Form-field validation for CVV, expiry dates, and cardholder info.
6. **Digital Ticket Confirmation (`ConfirmationScreen`)**
   - Success animation overlay.
   - Visual ticket card complete with custom dashed separators and realistic side-punched ticket edges.
   - Scannable QR code generator mock for digital scanning.
   - Quick sharing and local ticket downloading capabilities.
7. **Personalized Profile Hub (`ProfileScreen`)**
   - Centralized avatar, display name, and user email.
   - Modular navigation to edit profiles, notification settings, booking history, reviews, and safe logout.

### Tech Stack
- **Languages**: Dart
- **Framework**: Flutter
- **Key Packages**:
  - `cached_network_image` — Seamless network image caching.
  - `flutter_animate` — Stunning micro-interactions.
  - `google_fonts` — Premium typography (Poppins).
  - `shimmer` — Skeleton loaders during data fetch.
  - `confetti` — Success celebration animation.
  - `page_transition` — Elegant screen switching.
  - `intl` — Localized dates, numbers, and currency formatting.

---

## 🔐 2. ITW_Project — User Authentication System

Developed as a structured academic project focusing on the core principles of web/app authentication pipelines and client-side verification.

### Key Screens & Flow
1. **Interactive Auth Pipeline (`AuthScreen`)**
   - State-driven login and registration toggle with custom animations.
   - Single Ticker Provider coordination for synchronizing slide and fade effects.
2. **User Registration Form (`SignupForm`)**
   - Advanced field validations (regex-based email, minimum character lengths, matching password confirmation).
   - Localized date-of-birth picker and gender selection widgets.
3. **Password Recovery Flow (`ForgotPassForm`)**
   - Simulation of reset email routing with prompt UI feedback.
4. **Local Authentication Store (`UserService`)**
   - Thread-safe singleton user registry managing active authentication states.

### Tech Stack
- **Languages**: Dart
- **Framework**: Flutter
- **Key Packages**:
  - `intl` — Format Date of Birth selection.

---

## 📂 Repository Structure

```text
DevByRam/
├── CinemaNow/                  # Feature-rich movie booking application
│   ├── android/, ios/, web/    # Platform-specific builds
│   ├── assets/                 # Fonts (Poppins), Icons, Images
│   ├── lib/
│   │   └── main.dart           # Unified app entry & components
│   └── pubspec.yaml            # CinemaNow dependencies
│
├── ITW_Project/                # Academic Auth Demo
│   ├── android/, ios/, web/    # Platform-specific builds
│   ├── lib/
│   │   └── main.dart           # Authentication logic & forms
│   └── pubspec.yaml            # ITW_Project dependencies
│
└── README.md                   # Portfolio documentation (this file)
```

---

## 🛠 Getting Started

### Prerequisites

Ensure you have the Flutter SDK installed on your system. Run `flutter doctor` to verify your setup:

```bash
flutter doctor
```

### Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/yourusername/DevByRam.git
   cd DevByRam
   ```

2. **Run CinemaNow:**
   ```bash
   cd CinemaNow
   flutter pub get
   flutter run
   ```

3. **Run ITW_Project:**
   ```bash
   cd ../ITW_Project
   flutter pub get
   flutter run
   ```

---

## 🧠 About the Developer

I'm **Ram**, a passionate mobile developer focused on crafting responsive, scalable, and visually stunning cross-platform applications using **Flutter**. This collection represents my expertise in UI/UX architecture, state patterns, animation design, and clean code practices.

📫 **Let's Connect:**
- **Email:** [bt23cse026@iiitn.ac.in](mailto:bt23cse026@iiitn.ac.in)
