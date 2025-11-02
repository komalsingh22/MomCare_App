

# 👩‍🍼 MomCare App

A comprehensive **mobile healthcare application** designed to support mothers throughout their **pregnancy journey and beyond**.  
Built with **Flutter (frontend)** and **Go (backend)**, MomCare provides tools for tracking health, receiving AI-powered insights, and managing healthcare data securely.

---

## 🚀 Features

### 🩺 **Health Tracking**
- Track pregnancy progress and milestones
- Monitor vital signs (weight, blood pressure, temperature)
- Manage health reports and documents
- Schedule medical appointments
- Receive medication and check-up reminders

### 🤖 **AI-Powered Assistance**
- Smart health recommendations using **Google Generative AI**
- Personalized insights based on user health data
- Interactive question–answer support for maternal health queries

### 💾 **Data Management**
- Secure cloud data storage via **Go backend APIs**
- Local data caching and persistence
- Encrypted credentials using **Flutter Secure Storage**
- User preferences stored securely

### 🎨 **Advanced UI Components**
- Custom-designed, intuitive UI built with Flutter
- Interactive charts and progress bars
- Integrated calendar and reminder views
- Dynamic list views with slidable actions
- **SVG** and **Markdown** support for clean visuals and rich content
- Staggered grids and custom cards for modern layouts

### 💡 **Smart Features**
- Access to hospital contact directories
- Real-time health alerts and reminders

---

## 🛠️ **Technical Stack**

### **Frontend (Flutter)**
- **Framework:** Flutter 3.7+
- **Language:** Dart
- **State Management:** Provider (Native Flutter State Management)
- **UI Toolkit:** Material Design + Cupertino
- **HTTP Client:** `http` package
- **Secure Storage:** `flutter_secure_storage`
- **Local Database:** `sqflite` (for caching and offline support)

### **Backend (Go)**
- **Framework:** Go (Golang)
- **Hosting:** Render Cloud
- **API Architecture:** RESTful APIs
- **Database:** PostgreSQL (for centralized health data)
- **Security:** CORS-enabled, token-based access (JWT-ready)
- **Integration:** Exposed APIs for Flutter frontend via  
  `const String backendUrl = 'https://momcare-backend.onrender.com';`

---

## 🧠 **Core Design Principles**

- **Modular Architecture:** Organized by features (health tracking, reports, AI assistant)
- **Separation of Concerns:** Independent layers for models, services, and views
- **Reusability:** Shared widgets and components for consistent UI
- **Scalability:** Backend built to support high concurrency using Go’s goroutines
- **Future-Ready:** Easy to integrate chat modules, baby growth tracking, and doctor consultations

---

## 🔐 **Security and Privacy**
- All sensitive data is encrypted locally using **AES encryption**
- API communication is secured via HTTPS
- No third-party data sharing — privacy-first design

---

## ⚙️ **Setup & Installation**

### **1️⃣ Clone the Repository**
```bash
git clone https://github.com/komalsingh22/MomCare_App.git
cd MomCare_App


## 📱 Platform Support

- Android
- iOS

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (version 3.7 or higher)
- Dart SDK
- Android Studio / Xcode (for platform-specific development)
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/komalsingh22/MomCare_App.git
   ```

2. Navigate to the project directory:
   ```bash
   cd MomCare_App
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── constants/     # App constants and configurations
├── models/        # Data models
├── screens/       # UI screens
├── services/      # Business logic and services
├── theme/         # App theming
├── utils/         # Utility functions
├── widgets/       # Reusable UI components
└── main.dart      # App entry point
```

## 🔒 Security Features

- Secure data storage
- Encrypted user preferences
- Offline data access
- Protected health information

  ##  Images
  <img width="339" alt="Screenshot 2025-04-16 at 7 36 53 PM" src="https://github.com/user-attachments/assets/b0b2fc19-e49b-47be-8935-31db8ec828b9" />
<img width="339" alt="Screenshot 2025-04-16 at 7 37 05 PM" src="https://github.com/user-attachments/assets/03532e31-3069-416c-a332-ce6dbb98a5bc" />

  <img width="339" alt="Screenshot 2025-04-16 at 7 37 10 PM" src="https://github.com/user-attachments/assets/db556819-b08c-4ffc-bfa6-b19e22ff112b" />
<img width="339" alt="Screenshot 2025-04-16 at 7 37 18 PM" src="https://github.com/user-attachments/assets/3cdead6c-82b5-4b8c-854b-a501e3e3b390" />


<img width="339" alt="Screenshot 2025-04-16 at 7 37 33 PM" src="https://github.com/user-attachments/assets/640c8567-8664-40bf-903b-b0fef299fe01" />
<img width="339" alt="Screenshot 2025-04-16 at 7 37 37 PM" src="https://github.com/user-attachments/assets/19c956f3-0e04-414a-ad24-e0fd14d917c2" />
<img width="339" alt="Screenshot 2025-04-16 at 7 37 42 PM" src="https://github.com/user-attachments/assets/6eee4eaa-3489-424f-ae2c-5cff93d65670" />


