# Seva Finance

A sleek and modern personal finance mobile application built with Flutter. Seva Finance helps you track your expenses, manage wallets, set budgets, and gain insights into your spending habits through a beautiful and intuitive user interface.

## Features

- **Wallet Management**: Create and manage multiple digital wallets, each with its own balance and customizable color.
- **Expense Tracking**: Easily add and categorize your daily expenses.
- **Budgeting**: Set monthly budgets for your primary wallet to keep your spending in check.
- **Savings Goals**: Define savings goals to motivate you to save for what matters.
- **Spending Alerts**: Get notified when you're about to exceed your spending limits.
- **Receipt Scanning (OCR)**: Scan receipts with your camera to automatically extract and populate expense details.
- **Data Synchronization**: Securely syncs your financial data across devices using Firebase Firestore.
- **Insightful Dashboard**: A comprehensive dashboard that provides a clear overview of your wallets, recent expenses, and spending trends.
- **Cross-Platform**: Built with Flutter for a seamless experience on both iOS and Android.

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: [Dart](https://dart.dev/)
- **Database**: 
  - [Firebase Firestore](https://firebase.google.com/docs/firestore) for cloud data storage and synchronization.
  - [Hive](https://pub.dev/packages/hive) for fast, local on-device storage.
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Authentication**: [Firebase Auth](https://firebase.google.com/docs/auth)

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- A configured IDE (like VS Code or Android Studio)
- A connected device or emulator

### Installation & Setup

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/Frostube/seva-finance.git
    cd seva-finance
    ```

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

3.  **Set up Firebase:**
    - Follow the official FlutterFire documentation to create a new Firebase project and add it to this Flutter app: [Add Firebase to your Flutter app](https://firebase.google.com/docs/flutter/setup).
    - Ensure you add both an Android and an iOS app in the Firebase console and download the respective configuration files (`google-services.json` for Android and `GoogleService-Info.plist` for iOS).
    - Enable **Firestore Database** and **Firebase Authentication** (with the Email/Password sign-in method) in the Firebase console.

4.  **Run the app:**
    ```sh
    flutter run
    ```

## Screenshots

*(Coming Soon: Add some screenshots of your app here to make it even more appealing!)*
