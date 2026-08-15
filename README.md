# 🧾 IntelliReceipt (Receipt Intelligence)

> **AI-Powered Smart Receipt Processing, Expense Tracking, & Financial Intelligence Application**

IntelliReceipt is a state-of-the-art, cross-platform mobile & desktop application built with **Flutter**, **Riverpod**, and **Clean Architecture (Feature-First pattern)**. It enables users to capture receipt images, extract text using Google ML Kit on-device OCR, auto-classify line items using smart categorization algorithms, track category budgets, analyze spending trends, and export financial data to PDF/CSV.

---

## 🌟 Key Features

### 📸 **Smart Receipt Scanning & OCR**
- **Camera & Gallery Capture**: Capture receipts using standard grid camera guidelines or select images from gallery.
- **Cropping & Pre-processing**: Interactive image cropper with automatic aspect-ratio adjustment (`image_cropper`).
- **On-Device ML Kit OCR**: Extract store name, invoice number, purchase date, line items, prices, subtotal, tax, and total instantly on-device using `google_mlkit_text_recognition`.
- **Interactive Full-Screen Receipt Viewer**: High-resolution zoom & pan viewer (`InteractiveViewer`) supporting both local file paths and remote network URLs.

### 🤖 **Automated Item Classification & Price Intelligence**
- **Smart Auto-Categorization**: Intelligent regex-driven keyword classification matching item names to financial categories (*Groceries, Dining, Transport & Fuel, Health & Beauty, Shopping, Utilities*).
- **Price Tracking**: Track historical item price changes across multiple stores over time.
- **Store Comparison**: Compare product pricing across different merchants.

### 📊 **Analytics & Spending Dashboards**
- **Visual Analytics**: Interactive pie charts for category spending and bar charts for monthly trends using `fl_chart`.
- **Financial Summaries**: Total monthly spend, weekly averages, budget remaining progress bars, and recent transaction history.

### 💰 **Budget Management & Notifications**
- **Category Limits**: Set monthly spending caps for individual categories.
- **Budget Threshold Alerts**: Visual progress indicators and FCM push notifications when spending reaches 80% and 100% thresholds.

### 🔍 **Search & Multi-Format Data Export**
- **Advanced Query Search**: Search receipts by merchant, item name, date range, payment method, or category.
- **Export Capabilities**: Generate structured **PDF** and **CSV** expense reports for accounting and tax filing (`pdf`, `csv`, `share_plus`).

### 🌐 **Cross-Platform & Offline-First**
- **Full Platform Support**: Runs seamlessly on **Android**, **iOS**, **Web**, **Windows**, **macOS**, and **Linux**.
- **Offline Persistence**: Local receipt caching with **Hive** DB allowing offline receipt creation, offline OCR processing, and background sync when connection resumes.

---

## 🏛 Architecture & Project Structure

The project follows **Clean Architecture with Feature-First Folder Organization**:

```
intellireceipt/
├── lib/
│   ├── core/                       # Shared app-wide infrastructure
│   │   ├── constants/              # API endpoints, Hive box keys, storage keys
│   │   ├── error/                  # Domain failures & data exceptions
│   │   ├── network/                # Dio HTTP client, JWT interceptor, Token storage
│   │   ├── router/                 # GoRouter navigation & auth guards
│   │   ├── storage/                # Hive DB initialization & wrappers
│   │   ├── theme/                  # Theme tokens, typography, dark/light palette
│   │   ├── utils/                  # Local OCR parser, date & currency formatters
│   │   └── widgets/                # SmartImage, CategoryBadge, PrimaryButton, AppTextField
│   │
│   ├── features/                   # Business Feature Modules
│   │   ├── analytics/              # Category spending breakdown & chart views
│   │   ├── auth/                   # Login, Register, Google Sign-In & Token refresh
│   │   ├── budget/                 # Budget limits, sheets, and threshold monitors
│   │   ├── dashboard/              # Home overview & summary cards
│   │   ├── insights/               # AI financial recommendations & anomalies
│   │   ├── notifications/          # Push & in-app notifications
│   │   ├── ocr/                    # Camera capture, cropper & OCR processing
│   │   ├── product/                # Product price history & store comparisons
│   │   ├── profile/                # User profile, export data & theme toggles
│   │   ├── receipt/                # Receipt list, detail screen, item edit sheet
│   │   └── search/                 # Multi-filter search interface
│   │
│   └── main.dart                   # Application entry point & Hive initialization
│
├── backend/                        # Optional FastAPI / Python Backend Pipeline
│   └── .env.example                # PostgreSQL, Redis, OpenAI & Google Vision config
│
├── android/                        # Native Android platform code
├── ios/                            # Native iOS platform code
├── web/                            # Web platform entry point
├── windows/                        # Windows C++ desktop runner
├── macos/                          # macOS Swift desktop runner
├── linux/                          # Linux C++ desktop runner
└── pubspec.yaml                    # Flutter dependencies & metadata
```

Each feature module is structured into three clean layers:
1. **Presentation Layer**: Riverpod Notifiers, UI Screens, and Custom Widgets.
2. **Domain Layer**: Pure Dart Entities, Repository Contracts, and Use Cases.
3. **Data Layer**: DTO Models (`fromJson`/`toJson`), Remote/Local Data Sources, and Repository Implementations.

---

## 🛠 Technology Stack

* **Framework**: [Flutter](https://flutter.dev) (Dart SDK ^3.12.2)
* **State Management**: [Flutter Riverpod](https://riverpod.dev) (^2.6.1)
* **Routing**: [GoRouter](https://pub.dev/packages/go_router) (^17.4.0)
* **HTTP Client**: [Dio](https://pub.dev/packages/dio) (^5.11.0) with Pretty Dio Logger
* **Local Storage**: [Hive](https://pub.dev/packages/hive) (^2.2.3) & Hive Flutter
* **Secure Storage**: [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) (^11.0.0)
* **On-Device OCR**: [Google ML Kit Text Recognition](https://pub.dev/packages/google_mlkit_text_recognition) (^0.13.0)
* **Image Utilities**: `image_picker`, `image_cropper`, `flutter_image_compress`
* **Charts & Analytics**: [fl_chart](https://pub.dev/packages/fl_chart) (^1.2.0)
* **Exporting & Sharing**: `pdf`, `csv`, `share_plus`
* **Authentication**: Email/Password + [Google Sign-In](https://pub.dev/packages/google_sign_in) (^7.2.0)

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19.0 or newer)
- Dart SDK (^3.12.2)
- Android Studio / VS Code with Flutter extension
- Xcode (for iOS/macOS development)

### Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/madewarabhishek966529-wq/IntelliReceipt.git
   cd intellireceipt
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Code Generation** (if updating models or riverpod annotations):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run Application**:
   - **Chrome / Web**:
     ```bash
     flutter run -d chrome
     ```
   - **Android Emulator / Device**:
     ```bash
     flutter run -d android
     ```
   - **Windows Desktop**:
     ```bash
     flutter run -d windows
     ```

---

## 🔧 Environment Configuration

You can customize the API base URL at build time using `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api-domain.com/api/v1
```

Default Base URL: `http://10.0.2.2:8000/api/v1` (Android Emulator loopback)

---

## 🧪 Verification & Static Analysis

To run static analysis and verify zero code lint errors:

```bash
flutter analyze
```

To run unit and widget tests:

```bash
flutter test
```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
