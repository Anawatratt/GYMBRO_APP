# GymBro — Feature Design Context

## Project Summary

GymBro is a fitness gamification mobile app built with **Flutter + Firebase + Riverpod**. This document describes 4 features: Authentication, Friend System, In-App Notifications, and Notes CRUD. All users share the same role (no member/trainer distinction).

---

## Tech Stack

- **Frontend:** Flutter (Dart)
- **State Management:** Riverpod
- **Backend/Database:** Firebase (Auth + Firestore)
- **No push notifications** — in-app only via Firestore streams

---

## Firestore Data Model

### `users/{uid}` (Document)

| Field | Type | Description |
|---|---|---|
| displayName | String | User display name |
| email | String | From Firebase Auth |
| photoUrl | String | Profile photo URL (empty default) |
| bio | String | Short user bio |
| fitnessLevel | String | `beginner` \| `intermediate` \| `advanced` |
| gymName | String | Default: "CMU Gym" |
| profileComplete | Boolean | `false` until profile setup is done |
| createdAt | Timestamp | Account creation time |
| lastLoginAt | Timestamp | Last login time |

### `users/{uid}/friends/{friendUid}` (Subcollection)

| Field | Type | Description |
|---|---|---|
| status | String | `pending_sent` \| `pending_received` \| `accepted` |
| displayName | String | Cached friend name |
| email | String | Cached friend email |
| addedAt | Timestamp | When request was sent |
| acceptedAt | Timestamp? | Null until accepted |

### `users/{uid}/notes/{noteId}` (Subcollection)

| Field | Type | Description |
|---|---|---|
| title | String | Note title |
| content | String | Note body text |
| createdAt | Timestamp | Creation time |
| updatedAt | Timestamp | Last edit time |

### `users/{uid}/notifications/{notificationId}` (Subcollection)

| Field | Type | Description |
|---|---|---|
| type | String | `friend_request` \| `friend_accepted` \| `workout_complete` |
| fromUserId | String | UID of sender |
| fromUserName | String | Cached sender name |
| title | String | Notification title |
| message | String | Notification body |
| read | Boolean | `false` until opened |
| actionDone | Boolean | For friend requests: already accepted/declined? |
| createdAt | Timestamp | When created |

---

## Feature 1: Authentication

**Method:** Email/Password only (Google Sign-In planned for later)

### Flow

```
App Launch
  ├─ Logged in + profileComplete == true  → Home Screen
  ├─ Logged in + profileComplete == false → Profile Setup Screen
  └─ Not logged in                        → Login Screen
       ├─ Login → Home
       └─ Register → Create Auth + Firestore doc (profileComplete: false) → Profile Setup
```

### Registration Steps

1. User enters display name, email, password
2. `FirebaseAuth.createUserWithEmailAndPassword()`
3. Create Firestore `users/{uid}` doc with `profileComplete: false`
4. Redirect to Profile Setup

### Profile Setup Screen

- **Required:** Display name (pre-filled), fitness level (beginner/intermediate/advanced)
- **Optional:** Bio, gym name (defaults to "CMU Gym")
- On save: update Firestore doc, set `profileComplete: true` → redirect to Home

### Riverpod Architecture

- `StreamProvider` wrapping `FirebaseAuth.authStateChanges()` — source of truth for login state
- `Provider` for AuthService class with `signIn()`, `register()`, `signOut()`
- `StreamProvider` listening to Firestore user document for `profileComplete` flag
- Router checks: not auth → Login | auth + !complete → Setup | auth + complete → Home

---

## Feature 2: Friend System (View Other Profile)

### Search

- **Exact email match only**: `users.where('email', isEqualTo: searchInput)`
- Returns the matching user's profile for the "Add Friend" action

### Send Friend Request (3 Firestore writes)

1. Write `users/{A}/friends/{B}` → `{ status: "pending_sent", displayName, email, addedAt }`
2. Write `users/{B}/friends/{A}` → `{ status: "pending_received", displayName, email, addedAt }`
3. Write `users/{B}/notifications/{newId}` → `{ type: "friend_request", fromUserId: A, ... }`

### Accept Friend Request (3 Firestore writes)

1. Update `users/{B}/friends/{A}` → `status: "accepted"`, set `acceptedAt`
2. Update `users/{A}/friends/{B}` → `status: "accepted"`, set `acceptedAt`
3. Write `users/{A}/notifications/{newId}` → `{ type: "friend_accepted", fromUserId: B, ... }`

### Decline Friend Request (2 deletes)

1. Delete `users/{B}/friends/{A}`
2. Delete `users/{A}/friends/{B}`

### View-Only Profile

- When `status == "accepted"`, user can tap friend to view their profile
- Reads from `users/{friendUid}` in **read-only mode** (no writes)
- Displays: displayName, bio, fitnessLevel, gymName, and any workout data the workout team stores

### Friends List UI Sections

- **Friend Requests:** `status == "pending_received"` → Accept / Decline
- **Sent Requests:** `status == "pending_sent"` → Cancel (optional)
- **My Friends:** `status == "accepted"` → View Profile / Remove

---

## Feature 3: In-App Notifications

**No FCM/push.** All notifications are Firestore documents streamed in real-time.

### Notification Types

| Type | Trigger | Example Message |
|---|---|---|
| `friend_request` | A sends request to B | "Natapon wants to be your friend" |
| `friend_accepted` | B accepts A's request | "Somchai accepted your friend request" |
| `workout_complete` | Friend finishes workout | "Natapon completed Full Body Workout" |

### How It Works

1. **Writing:** Flutter client writes notification doc to target user's `notifications` subcollection
2. **Reading:** `StreamProvider` listens to `users/{myUid}/notifications` ordered by `createdAt` desc
3. **Unread Badge:** Count where `read == false`, show on bell icon
4. **Mark Read:** On tap, update `read: true`
5. **Action Handling:** For `friend_request`, `actionDone` tracks if already accepted/declined

### Trade-off

Users won't receive notifications when the app is closed. They see all pending notifications when they reopen the app.

---

## Feature 4: Notes (CRUD)

Personal notes stored under each user. No cross-user interaction.

### Operations

| Op | Action | Firestore |
|---|---|---|
| Create | Tap FAB → fill title + content | `collection.add()` with `serverTimestamp()` |
| Read | Stream notes list | `collection.orderBy('updatedAt', descending: true).snapshots()` |
| Update | Tap note → edit → save | `doc.update()` with new `updatedAt` |
| Delete | Swipe-to-delete + confirm dialog | `doc.delete()` |

### UI

- List view with cards (title + first ~50 chars preview)
- FAB for creating new notes
- Confirmation dialog before delete

---

## Firestore Security Rules

| Path | Read | Write |
|---|---|---|
| `users/{uid}` | Any authenticated user | Only owner (uid) |
| `users/{uid}/friends/{fid}` | Only owner (uid) | Owner OR the friend (fid) |
| `users/{uid}/notes/{nid}` | Only owner (uid) | Only owner (uid) |
| `users/{uid}/notifications/{nid}` | Only owner (uid) | Owner OR any authenticated user (create only) |

**Why user docs are readable by all auth users:** Friend search by email requires querying other users' documents.

**Why friends subcollection allows friend writes:** When A sends a request, A needs to write to B's `friends/{A}` subcollection.

**Why notifications allows external creates:** Other users need to create notification docs in your subcollection.

---

## Dart Models

```dart
class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final String bio;
  final String fitnessLevel; // beginner, intermediate, advanced
  final String gymName;
  final bool profileComplete;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  // Include: fromMap(), toMap(), copyWith()
}

class Friend {
  final String friendUid;
  final String status; // pending_sent, pending_received, accepted
  final String displayName;
  final String email;
  final DateTime addedAt;
  final DateTime? acceptedAt;
  // Include: fromMap(), toMap(), copyWith()
}

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Include: fromMap(), toMap(), copyWith()
}

class AppNotification {
  final String id;
  final String type; // friend_request, friend_accepted, workout_complete
  final String fromUserId;
  final String fromUserName;
  final String title;
  final String message;
  final bool read;
  final bool actionDone;
  final DateTime createdAt;
  // Include: fromMap(), toMap(), copyWith()
}
```

---

## Feature Integration Map

```
Auth ──→ creates user doc in Firestore
  │
  ├── Friend System
  │     ├─ Search users (query users collection by email)
  │     ├─ Send request (write to BOTH users' friends subcollection)
  │     ├─ Creates notification → write to target's notifications subcollection
  │     └─ View friend profile (read friend's user doc, READ-ONLY)
  │
  ├── Notifications
  │     ├─ StreamProvider on own notifications subcollection
  │     └─ Triggered by: friend requests, friend accepts, workout completions
  │
  └── Notes
        └─ Standalone CRUD under own user path, no cross-user interaction
```

---

## Key Design Decisions

- **No FCM/push notifications** — in-app Firestore streams only
- **Exact email search** — no fuzzy/prefix matching for friend search
- **Subcollection approach for friends** — stored under each user, requires dual writes
- **Cached/denormalized names** — friend docs and notification docs store display names to avoid extra reads
- **profileComplete flag** — handles edge case of user closing app before finishing profile setup
- **Same role for all users** — no member/trainer distinction in auth
