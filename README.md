# Visits Tracker App

The **Visits Tracker App** is a Flutter-based mobile application that allows users to log customer visits offline and automatically sync them with a backend (Supabase) when online.

## Features

- **Offline-first support**: Save visits, customers, and activities without an internet connection.
- **Automatic sync**: Unsynced visits are pushed to the server when network becomes available.
- **Visit management**: Add visit details including location, time, activities done, and status.
- **Date range & status filters**: Filter visits by status (completed, pending, cancelled) or date.
- **Search visits**: Search visits by location or notes.
- **Local storage**: Customers, activities, and visits are cached in Hive for offline access.
- **Connectivity-aware**: Reacts to connectivity changes using `connectivity_plus`.

---

## Technologies Used

| Technology     | Purpose                                      |
|----------------|----------------------------------------------|
| Flutter        | Mobile UI toolkit                            |
| Riverpod       | State management                             |
| Hive           | Local/offline data storage                   |
| Supabase       | Backend-as-a-service (PostgreSQL + REST API) |
| Connectivity+  | Network connection monitoring                |

---

## Data Flow

1. **Customers & Activities**
    - Fetched from Supabase on startup (when online).
    - Stored locally using Hive (`customers`, `activities` boxes).
    - Read from Hive when offline.

2. **Visit Creation**
    - User fills a form to submit a visit.
    - If **online**, visit is uploaded to Supabase and marked as `isSynced: true`.
    - If **offline**, visit is saved locally with `isSynced: false`.

3. **Sync Logic**
    - `visitListProvider` syncs unsynced visits automatically when connectivity is restored.
    - Synced visits are fetched from Supabase and stored locally.

---

## Screenshots

<img src="https://github.com/Sam-scripter/solutech_visit_tracker/blob/b356cbc885bc4d6eeda2950cb67346ae65841f91/screenshot1.jpg" width="350" height="750">
<img src="https://github.com/Sam-scripter/solutech_visit_tracker/blob/b356cbc885bc4d6eeda2950cb67346ae65841f91/screenshot2.jpg" width="350" height="750">
<img src="https://github.com/Sam-scripter/solutech_visit_tracker/blob/b356cbc885bc4d6eeda2950cb67346ae65841f91/screenshot3.jpg" width="350" height="750">
<img src="https://github.com/Sam-scripter/solutech_visit_tracker/blob/b356cbc885bc4d6eeda2950cb67346ae65841f91/screenshot4.jpg" width="350" height="750">
<img src="https://github.com/Sam-scripter/solutech_visit_tracker/blob/b356cbc885bc4d6eeda2950cb67346ae65841f91/screenshot5.jpg" width="350" height="750">
<img src="https://github.com/Sam-scripter/solutech_visit_tracker/blob/b356cbc885bc4d6eeda2950cb67346ae65841f91/screenshot6.jpg" width="350" height="750">
<img src="https://github.com/Sam-scripter/solutech_visit_tracker/blob/b356cbc885bc4d6eeda2950cb67346ae65841f91/screenshot7.jpg" width="350" height="750">
<img src="https://github.com/Sam-scripter/solutech_visit_tracker/blob/b356cbc885bc4d6eeda2950cb67346ae65841f91/screenshot8.jpg" width="350" height="750">
<img src="https://github.com/Sam-scripter/solutech_visit_tracker/blob/b356cbc885bc4d6eeda2950cb67346ae65841f91/screenshot9.jpg" width="350" height="750">
<img src="https://github.com/Sam-scripter/solutech_visit_tracker/blob/b356cbc885bc4d6eeda2950cb67346ae65841f91/screenshot12.jpg" width="350" height="750">
<img src="https://github.com/Sam-scripter/solutech_visit_tracker/blob/b356cbc885bc4d6eeda2950cb67346ae65841f91/screenshot13.jpg" width="350" height="750"> 



---
## How to Run

### Prerequisites

- Flutter 3.x or newer
- Hive & Supabase credentials configured
- Android Studio or Visual Studio Code

### Setup Steps

1. Clone this repository:
   ```terminal
   git clone https://github.com/Sam-scripter/visits_tracker_app.git
   cd visits_tracker_app
2. Get packages:
   ```terminal
   flutter pub get
3. Generate Hive adapters(if not done):
   ```terminal
   flutter packages pub run build_runner build
4. Run the app:
   ```terminal
   flutter run
   
---
## Boxes and Models
| Box Name     | Model      | Purpose                 |
| ------------ | ---------- | ----------------------- |
| `visits`     | `Visit`    | Stores visit records    |
| `customers`  | `Customer` | Cached customer data    |
| `activities` | `Activity` | Cached visit activities |

---
## Sync Strategy
 - All visits are first saved to the visits Hive box.
 - On reconnect (e.g., Wi-Fi or mobile data), unsynced visits are uploaded to Supabase, in an instance where this fails, the user can manually sync the visits.
 - Synced visits are then reloaded from Supabase for consistency.
---
## Offline-First Considerations
 - App does not crash or degrade when offline.
 - Users can add visits anytime, which guarantees uninterrupted data entry.
 - Sync is handled automatically when the user comes back online.

---
## Assumptions and Limitations
 - Supabase is available and configured with required tables and API keys.
 - No authentication is currently implemented.
 - Users must manually retry syncing in some edge cases if automatic sync fails.
