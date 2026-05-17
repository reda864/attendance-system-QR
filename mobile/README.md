# AttendQR — Flutter Mobile App

A production-ready Flutter mobile application for QR Code-based student attendance, connected to the Django REST API backend.

---

## 📱 Overview

Students use this app to:
1. **Login** with their institutional email and password (JWT authentication)
2. **Scan** the teacher's QR Code using the device camera
3. **Submit** their identity (first name, last name, Code Massar)
4. **Receive** instant confirmation or a clear error message

---

## 🗂 Project Structure

```
lib/
├── constants/
│   ├── app_constants.dart      # API URLs, route names, SharedPreferences keys
│   └── app_theme.dart          # Material 3 light + dark themes (Poppins font)
│
├── models/
│   ├── user_model.dart         # User / teacher / admin model
│   ├── attendance_model.dart   # Attendance record + StudentDetail
│   └── auth_model.dart         # AuthResponse, ValidateAttendanceRequest, AttendanceResult
│
├── services/
│   ├── dio_client.dart         # Dio HTTP client + JWT interceptor + token refresh
│   ├── auth_service.dart       # Login, logout, session persistence (SharedPreferences)
│   ├── attendance_service.dart # POST /attendance/validate/, GET /attendance/my/
│   └── connectivity_service.dart # Real-time network monitoring
│
├── providers/                  # State management (Provider / ChangeNotifier)
│   ├── auth_provider.dart      # Authentication state machine
│   ├── attendance_provider.dart# QR token, validation flow, history
│   └── theme_provider.dart     # Light / dark mode toggle + persistence
│
├── screens/
│   ├── splash_screen.dart      # Animated logo + auto session check
│   ├── login_screen.dart       # Email / password form + JWT login
│   ├── home_screen.dart        # Welcome banner + Scan button + history list
│   ├── qr_scanner_screen.dart  # Camera feed + animated overlay (mobile_scanner)
│   ├── validation_screen.dart  # Auto-filled student form + submit
│   ├── success_screen.dart     # Animated confirmation + receipt details
│   └── error_screen.dart       # Typed error messages + contextual next steps
│
├── widgets/
│   ├── app_logo.dart           # Reusable branded logo widget
│   ├── custom_text_field.dart  # Styled TextFormField wrapper
│   ├── loading_button.dart     # ElevatedButton with loading spinner
│   └── connectivity_banner.dart# Slide-down offline notification banner
│
├── utils/
│   ├── validators.dart         # Form validation helpers
│   └── app_exceptions.dart     # Typed exception hierarchy
│
└── main.dart                   # App entry point, MultiProvider, named routes
```

---

## ⚙️ Tech Stack

| Concern | Package |
|---|---|
| UI Framework | Flutter 3.x + Material 3 |
| State Management | `provider ^6.1` |
| HTTP Client | `dio ^5.7` |
| Local Storage | `shared_preferences ^2.3` |
| QR Scanner | `mobile_scanner ^7.0` |
| Fonts | `google_fonts ^6.2` (Poppins) |
| Connectivity | `connectivity_plus ^6.1` |
| Device Info | `device_info_plus ^11.2` |

---

## 🚀 Setup & Run

### Prerequisites

- Flutter SDK ≥ 3.10
- Android Studio / Xcode for emulator/simulator
- The Django backend running (see `../backend/README.md`)

### 1. Install dependencies

```bash
cd mobile
flutter pub get
```

### 2. Configure the API base URL

Open `lib/constants/app_constants.dart` and set `baseUrl` to match your environment:

| Scenario | URL |
|---|---|
| Android Emulator | `http://10.0.2.2:8000/api` ✅ (default) |
| iOS Simulator | `http://localhost:8000/api` |
| Real device (LAN) | `http://192.168.x.x:8000/api` |

### 3. Run the app

```bash
# Android emulator
flutter run

# Specific device
flutter run -d <device-id>

# Release build
flutter build apk --release
flutter build ios --release
```

---

## 🔐 Authentication Flow

```
App Start
   │
   ▼
SplashScreen ──► check SharedPreferences
   │
   ├─ token found ──► HomeScreen
   └─ no token   ──► LoginScreen
                          │
                          ▼
                    POST /api/users/auth/login/
                    { email, password }
                          │
                          ▼
                    Store JWT (access + refresh)
                    Store UserModel as JSON
                          │
                          ▼
                    HomeScreen
```

The `DioClient` interceptor automatically:
- Attaches `Authorization: Bearer <token>` to every request
- Attempts a silent token refresh on `401 Unauthorized`
- Clears session and prompts re-login if refresh fails

---

## 📷 QR Scanner Flow

```
HomeScreen → [Scan QR Code]
     │
     ▼
QrScannerScreen (mobile_scanner)
     │  ← camera feed with animated overlay
     │  ← validates UUID format client-side
     ▼
AttendanceProvider.setScannedToken(token)
     │
     ▼
ValidationScreen
     │  ← auto-filled from logged-in user
     │  ← firstName, lastName, codeMassar
     ▼
POST /api/attendance/validate/
{
  "qr_token": "uuid",
  "first_name": "...",
  "last_name": "...",
  "code_massar": "...",
  "device_id": "..."
}
     │
     ├─ 201 Created ──► SuccessScreen
     └─ 400 Error   ──► ErrorScreen (typed message)
```

---

## 🎨 Screens

### Splash Screen
- Animated logo with elastic scale + fade
- Pulsing loading indicator
- Auto-redirects after session check

### Login Screen
- Email + password with show/hide toggle
- "Continue as Guest" for anonymous scanning
- Error snack bar with backend message

### Home Screen
- Time-aware greeting ("Good morning / afternoon / evening")
- Student avatar with initials
- Large "Scan QR Code" card (also FAB at bottom)
- Quick-tip chips (Wi-Fi, timer, duplicate prevention)
- Pull-to-refresh attendance history list
- Dark mode toggle + logout with confirmation dialog

### QR Scanner Screen
- Full-screen camera preview via `mobile_scanner`
- Custom painted corner-bracket frame overlay
- Animated blue scan line
- Torch (flashlight) toggle
- Camera flip (front/back)
- UUID format validated before proceeding

### Validation Screen
- Fields pre-filled from logged-in user profile
- QR token badge showing truncated UUID + "Valid" chip
- Warning card about exact name matching
- Submit → API → navigate to Success or Error

### Success Screen
- Animated check icon with concentric pulse rings
- Attendance receipt card:
  - Attendance ID
  - Session number
  - Date & exact validation time
  - "CONFIRMED" badge
- "Back to Home" and "Scan Another QR" actions

### Error Screen
- Color-coded icon per error type (expired = amber, already registered = blue, etc.)
- Contextual "What to do next" tips (3 per error type)
- Error code badge (e.g. `ERR_QR_EXPIRED`)
- Smart action button (retry scan vs. go home depending on error)

---

## 🌐 API Integration

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/api/users/auth/login/` | None | Returns JWT tokens + user |
| `POST` | `/api/users/auth/refresh/` | None | Refresh access token |
| `GET` | `/api/users/auth/me/` | Bearer | Current user profile |
| `POST` | `/api/attendance/validate/` | None | Register attendance via QR |
| `GET` | `/api/attendance/my/` | Bearer | Student's attendance history |

---

## 🔒 Security Features

| Feature | Implementation |
|---|---|
| JWT storage | `SharedPreferences` (not hardcoded) |
| Token refresh | `DioClient` interceptor with queue |
| Auto-logout | On 401 after failed refresh |
| Duplicate scan | Backend enforces `unique_together` constraint |
| UUID validation | Client-side format check before API call |
| Device ID | Sent with every validation request |
| HTTPS ready | Only `localhost` / LAN exempted in `Info.plist` |

---

## 🌙 Dark Mode

- Persisted in `SharedPreferences` via `ThemeProvider`
- Toggle button in `HomeScreen` app bar
- Full Material 3 dark color scheme
- All custom widgets and screens respect `Theme.of(context).brightness`

---

## 📦 Typed Error Handling

Every attendance error from the backend maps to an `AttendanceErrorType`:

| Backend message | Type | Color |
|---|---|---|
| `expired` | `AttendanceErrorType.expired` | Amber |
| `already` | `AttendanceErrorType.alreadyValidated` | Blue |
| `invalid qr` / `invalid token` | `AttendanceErrorType.invalidQr` | Red |
| `no longer active` | `AttendanceErrorType.sessionClosed` | Purple |
| `not found` | `AttendanceErrorType.studentNotFound` | Red |
| `name does not match` | `AttendanceErrorType.nameMismatch` | Orange |

Network and timeout errors are also typed and displayed with proper messages.

---

## 📱 Platform Configuration

### Android (`android/app/src/main/AndroidManifest.xml`)
- `INTERNET`, `ACCESS_NETWORK_STATE` — API calls
- `CAMERA`, `FLASHLIGHT` — QR scanning
- `android:usesCleartextTraffic="true"` — local dev HTTP

### iOS (`ios/Runner/Info.plist`)
- `NSCameraUsageDescription` — camera permission dialog
- `NSAppTransportSecurity` exceptions for `localhost` and `10.0.2.2`
- Portrait-only orientation lock

---

## 🛠 Development Notes

- Run `flutter pub upgrade --major-versions` to update all packages
- Run `flutter analyze` after `pub get` to check for lints
- The `DioClient` is a singleton — call `DioClient.reset()` in tests
- All screens use `SingleTickerProviderStateMixin` for entry animations
- The `ConnectivityBanner` widget can be dropped into any `Column` for offline detection

---

## 📄 License

Private — for PFE (Final Year Project) use only.