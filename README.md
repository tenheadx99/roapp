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

## Google Drive Backup

The app can back up / restore its SQLite database to a visible **"RO App Backups"** folder in the
user's Google Drive (Profile → backup section). It uses a single OAuth2 loopback flow so it works on
both Android and Windows/Linux desktop.

**One-time Google Cloud setup (required):**

1. Create a Google Cloud project and **enable the Google Drive API**.
2. Configure the **OAuth consent screen** (External): add the scope
   `https://www.googleapis.com/auth/drive.file` and add your Google account under **Test users**.
3. Create an **OAuth client ID of type "Desktop app"** → note the **client ID** and **client secret**.
4. Run the app with the credentials passed in:

   ```
   flutter run \
     --dart-define=GDRIVE_CLIENT_ID=<your-client-id> \
     --dart-define=GDRIVE_CLIENT_SECRET=<your-client-secret>
   ```

On **Linux desktop**, `flutter_secure_storage` needs `libsecret-1-dev` / gnome-keyring installed at
runtime. A daily auto-upload runs at launch when an account is connected (fails silently otherwise).

## Notes

- The app uses a local on-device SQLite database; Google Drive is used only for backup/restore.
