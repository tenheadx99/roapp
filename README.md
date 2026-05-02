# RO Manager

RO Manager is a Flutter-based field operations app for a residential RO service business. It manages customers, inventory, suppliers, technicians, service dispatch, notifications, and business insights using a local SQLite database.

## Current App Scope

- Authentication with a seeded local admin account
- Customer directory and service history
- Inventory tracking with low-stock awareness
- Supplier directory with contact actions and purchase-order counters
- Dispatch workflow with scheduling, assignment notes, and status progression
- Notifications generated from inventory and service data
- Insights generated from stored service history and operational load

## Default Local Login

- Email: `admin@roservice.com`
- Password: `password123`

The login screen can restore this local admin account if access is lost.

## Tech Stack

- Flutter
- `flutter_bloc`
- SQLite via `sqflite`
- Desktop/web SQLite adapters for Linux, Windows, and web

## Project Structure

- `lib/core`: database, constants, utilities
- `lib/features`: feature modules for auth, dashboard, customers, inventory, suppliers, dispatch, technicians, notifications, and insights
- `test`: repository and database sanity tests

## Getting Started

1. Install Flutter and platform prerequisites.
2. Run `flutter pub get`.
3. Start the app with `flutter run`.

## Notes

- The app currently uses a local on-device database, not a remote backend.
