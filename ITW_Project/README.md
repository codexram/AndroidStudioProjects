# 🔐 ITW_Project — Flutter Authentication System Demo

This is a Flutter-based user authentication application demonstrating the core components of modern mobile auth pipelines. It features custom-designed form validations, localized fields, interactive transitions, and a secure local authentication service store.

---

## ✨ Features Showcase

### 🔑 1. Interactive Auth Board (`AuthScreen`)
- **Fluid UI Switching**: Easily toggles between **Sign In**, **Sign Up**, and **Password Reset** modes.
- **Custom Synchronized Animations**: Utilizes a single `AnimationController` to coordinate concurrent fade and slide transitions during state transitions.

### 📝 2. User Signup Form (`SignupForm`)
- **Robust Field Validation**: Employs real-time field validation for username uniqueness, email format correctness, and password safety limits (minimum 6 characters).
- **Date-of-Birth Selection**: Integrated native Flutter calendar picker with format parsing.
- **Gender Selection Dropdown**: Formatted picker containing custom option tags.
- **Terms & Conditions Checkbox**: Requires agreement check before sign-up completion.

### 🚪 3. Login Panel (`LoginForm`)
- **Universal Input**: Allows sign-in with either Username or Email.
- **Human Verification**: A checkbox validator confirming that the user is not a bot.
- **Password Visibility Switch**: Toggleable visibility modifier for secure text input.

### 📬 4. Password Recovery Panel (`ForgotPassForm`)
- **Recovery Simulation**: Verifies input email format and presents visual feedback prompts.

### 🧠 5. Local Authentication Service (`UserService`)
- **Singleton Pattern Store**: Unified user store using thread-safe map structures to manage session profiles and credentials locally.

---

## 🛠 Technology Stack

- **Flutter**: Cross-platform mobile development framework.
- **Dart**: Programming language.
- **intl**: Helper for processing date and calendar localization.
- **Google Fonts (Poppins)**: Clean typography.

---

## 📂 Project Structure

```text
ITW_Project/
├── android/, ios/, web/    # Platform-specific native directories
├── lib/
│   ├── main.dart           # Application entry, UI layout, form validation, and UserService store
│   └── ...
│
└── pubspec.yaml            # Project dependencies
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
