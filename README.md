# Meza Restaurant

Restaurant management app for **MezaHub** — the restaurant-side companion to the MezaHub customer app. Restaurants use this app to manage menus, orders, and operations, while customers interact through the MezaHub customer app.

## Author

**NELSON**  
[nelsonapidi75@gmail.com](mailto:nelsonapidi75@gmail.com)

## Overview

Meza Restaurant is a Flutter-based mobile application built for restaurant owners and staff. It connects to **MezaHub** (the customer-facing app) to provide a complete food ordering ecosystem. Restaurants can manage their menu, receive and fulfill orders, and communicate with customers through the MezaHub platform.

### Key Features

- **Authentication** — Sign in and sign up with Firebase Auth
- **Menu Management** — Upload and manage dishes
- **Order Management** — View and process orders from MezaHub customers
- **Order History** — Track past orders and fulfillment
- **Profile & Settings** — Manage restaurant profile and preferences
- **Notifications** — Push notifications for new orders and updates
- **Delivery** — Delivery tracking and directions support

## Tech Stack

- **Flutter** — Cross-platform UI framework
- **Firebase** — Auth, Realtime Database, Firestore, Cloud Messaging
- **Supabase** — Backend services
- **Hive** — Local storage
- **Provider** — State management
- **Go Router** — Navigation
- **Dio** — HTTP client

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (^3.9.2)
- Firebase project configured for your app
- Supabase project (for backend)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd meza_restaurant-RESTAURANT-APP-FOR-MEZAHUB

# Install dependencies
flutter pub get

# Run code generation (for Hive models)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Platform Support

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## Configuration

1. Add your Firebase configuration (`google-services.json` for Android, `GoogleService-Info.plist` for iOS).
2. Configure Supabase connection in your environment.
3. Ensure Firebase and Supabase are set up to integrate with the MezaHub customer app.

## License

This project is intended for use with the MezaHub ecosystem.

---

*For questions or support, contact [nelsonapidi75@gmail.com](mailto:nelsonapidi75@gmail.com).*
