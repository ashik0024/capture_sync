# CaptureSync

CaptureSync is a Flutter application for capturing images using the device camera and reliably uploading them to a server.

The application is designed to work reliably in environments with unstable or unavailable internet connectivity. Captured images are stored locally and added to an upload queue before synchronization. When a stable internet connection becomes available, the application automatically attempts to upload the queued images.

---

# 1. Project Title and Description

## CaptureSync

CaptureSync is an offline-first image capture and synchronization application built with Flutter.

The application provides a custom camera interface that allows users to capture multiple images as part of a batch. Each captured image is saved locally and added to a persistent upload queue.

The application is designed so that images are not lost when the device is offline or when an upload fails.

### Main Features

* Custom camera preview UI
* Camera image capture
* Pinch-to-zoom
* Zoom slider
* Zoom buttons such as `1x`, `2x`
* Manual tap-to-focus
* Visual focus indicator
* Multiple image capture in batches
* Local image storage
* Persistent upload queue
* Hive-based local storage
* Pending upload management
* Internet connectivity detection
* Automatic upload retry
* Background synchronization
* WorkManager integration
* Manual synchronization
* Upload status tracking
* Handling of network and API failures
* Offline-first upload architecture

---

# 2. Project Structure / Approaches

## Architectural Approach

The project follows a **feature-based layered architecture** that separates presentation, domain, data, and core infrastructure responsibilities.

The camera feature is responsible for image capture and camera operations, while the sync feature handles local queue management, upload processing, connectivity checks, and background synchronization.

### Project Structure

```text
lib/
│
├── app/
│   └── app.dart
│
├── core/
│   ├── di/
│   │   └── ServiceLocator.dart
│   │
│   ├── network/
│   │   └── connectivity_service.dart
│   │
│   ├── storage/
│   │   ├── file_storage.dart
│   │   └── hive_storage.dart
│   │
│   └── worker/
│       └── background_sync_service.dart
│
├── features/
│
│   ├── camera/
│   │   ├── data/
│   │   │   └── camera_service.dart
│   │   │
│   │   ├── domain/
│   │   │   └── ...
│   │   │
│   │   └── presentation/
│   │       ├── controller/
│   │       │   └── camera_controller.dart
│   │       │
│   │       └── screens/
│   │           └── CameraPreviewScreen.dart
│   │       └── widget/
│   │           └── cameraControls.dart
│   │           └── cameraPreviewWidget.dart
│   │           └── tapToFocusIndicator.dart
│   │
│   └── sync/
│       ├── data/
│       │   ├── mock_upload_api.dart
│       │   └── syncRepositoryImpl.dart
│       │
│       ├── domain/
│       │   ├── auto_sync_service.dart
│       │   ├── sync_engine.dart
│       │   ├── sync_repository.dart
│       │   └── upload_item.dart
│       │
│       └── presentation/
│           └── screens/
│               └── pendingUploadsScreen.dart
│           └── widget/
│               └── batchProgressSection.dart
│               └── syncActionButton.dart
│               └── uploadHeaderBar.dart
│               └── uploadItemCard.dart
│
└── main.dart
```

## Main Components

### CameraService

Handles low-level camera operations including:

* Camera initialization
* Camera controller management
* Taking pictures
* Zoom control
* Focus control
* Camera selection

### CameraScreenController

Acts as the interface between the camera UI and camera functionality. It manages camera-related operations such as initialization, zoom, focus, and image capture.

### SyncEngine

Responsible for processing queued uploads.

The sync engine:

1. Retrieves pending upload items.
2. Checks whether the local image exists.
3. Marks the item as uploading.
4. Attempts to upload the image.
5. Marks the item as uploaded after success.
6. Keeps the item pending when there is no internet.
7. Marks the item as failed when an upload fails.

### SyncRepository

Defines operations for managing upload items.

`SyncRepositoryImpl` provides the implementation using Hive as the local persistence layer.

### ConnectivityService

Checks the device's network and actual internet availability before attempting an upload.

### AutoSyncService

Monitors connectivity and triggers synchronization when connectivity becomes available.

### BackgroundSyncService

Uses WorkManager to register background synchronization tasks so pending uploads can be processed without requiring the user to manually start synchronization.

### HiveStorage

Provides persistent local storage for upload queue information.

### FileStorage

Handles saving captured images to local device storage.

---

# 3. Generative AI Usage

Generative AI was used during development as a development assistant for architecture planning, implementation, debugging, code generation, and refactoring.

Generated code was reviewed, tested, and modified according to the requirements of the application.

### Areas Where Generative AI Was Used

* Designing the project architecture
* Planning the feature-based folder structure
* Implementing camera functionality
* Implementing pinch-to-zoom
* Implementing zoom controls and slider
* Implementing tap-to-focus
* Designing the local upload queue
* Implementing Hive storage
* Designing the synchronization flow
* Implementing connectivity checking
* Implementing automatic synchronization
* Integrating WorkManager
* Debugging network failures
* Debugging initialization and runtime errors
* Improving error handling
* Refactoring project components

### Essential Prompts Used

Some of the prompts used during development included:

```text
Build a Flutter custom camera preview screen with pinch-to-zoom,
zoom buttons, zoom slider and manual tap-to-focus.
```

```text
Implement an offline-first image upload queue in Flutter using Hive.
Images should remain locally stored when there is no internet connection.
```

```text
Create a resilient sync engine that retries pending image uploads
when internet connectivity becomes available.
```

```text
Implement background synchronization using WorkManager in Flutter.
Register a one-time worker when an image is captured.
```

```text
The upload fails with SocketException when there is no internet.
Keep the image in the local queue and show an appropriate message
to the user.
```

```text
How can I automatically retry pending image uploads when internet
connectivity becomes available without user intervention?
```

Generative AI was primarily used as a **development and debugging assistant**, while the implementation was tested and adapted within the project.

---

# 4. How to Run

## Prerequisites

Make sure the following are installed:

* Flutter SDK
* Dart SDK
* Android Studio or VS Code
* Android device/emulator or iOS device/simulator
* Git

Check the Flutter installation:

```bash
flutter doctor
```

---

## Clone the Repository

Clone the project:

```bash
git clone <YOUR_REPOSITORY_URL>
```

Navigate to the project directory:

```bash
cd capture_sync
```

---

## Install Dependencies

Run:

```bash
flutter pub get
```

---

## Check Connected Devices

Run:

```bash
flutter devices
```

Make sure an Android or iOS device/emulator is available.

---

## Run the Application

Run:

```bash
flutter run
```

Alternatively, open the project in Android Studio or VS Code and run it on the desired device.

---

# Offline Synchronization Flow

The application's upload process works as follows:

```text
                 Capture Image
                      │
                      ▼
              Save Image Locally
                      │
                      ▼
              Create UploadItem
                      │
                      ▼
                Store in Hive
                      │
                      ▼
          Register Background Worker
                      │
              ┌───────┴───────┐
              │               │
           Offline           Online
              │               │
              ▼               ▼
       Keep in Queue      Upload Image
                              │
                       ┌──────┴──────┐
                       │             │
                    Success        Failure
                       │             │
                       ▼             ▼
                   Uploaded     Keep in Queue
                                     │
                                     ▼
                              Retry Automatically
```

The important part of the design is that the image is **saved locally before synchronization is attempted**.

Therefore, if the device has no internet connection or the upload API fails, the captured image remains available in the local queue.

---

# Upload Status

Each upload item can have one of the following statuses:

```text
Pending
Uploading
Uploaded
Failed
```

### Pending

The image is stored locally and waiting to be uploaded.

### Uploading

The synchronization engine is currently attempting to upload the image.

### Uploaded

The image has been successfully uploaded.

### Failed

The upload attempt failed. The item remains available for another synchronization attempt.

---

# Background Synchronization

The application uses a background worker to process pending uploads.

When an image is captured, a background synchronization task can be registered.

The synchronization process checks the local upload queue and attempts to upload pending images.

If the device is offline, the image remains in the queue. Once connectivity becomes available, synchronization can run automatically without requiring the user to manually upload the image.

---

# Build APK

To generate a release APK:

```bash
flutter build apk --release
```

The generated APK will be available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---
# Apk & Screen Shot
https://drive.google.com/drive/folders/1Y61OFLUk6YzBf0lb1EiYHhPMeKCML3W1?dmr=1&ec=wgc-drive-%5Bmodule%5D-goto

# Technologies Used

* Flutter
* Dart
* Camera
* Hive CE
* Connectivity Plus
* WorkManager
* UUID
* Local File Storage

---

# Project Goal

The main goal of CaptureSync is to demonstrate a reliable **offline-first image capture and synchronization workflow**.

The application ensures that captured images are persisted locally and can be synchronized automatically when network connectivity becomes available, reducing the risk of data loss caused by unstable network conditions.
