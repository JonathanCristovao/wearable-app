# Quick Start Guide - AI Wearable Sensor

## Prerequisites

- Flutter SDK 3.8.0+
- Android device with Bluetooth LE (API 31+) or iOS device
- WT9011DCL-BT50 sensor(s)
- Firebase project and OpenAI API key (see `lib/config/app_config.dart`)

## Installation

```bash
cd wearable-app
flutter pub get
flutter doctor
```

Ensure all checks pass (✓).

## Run

```bash
# Android (USB debugging enabled on device)
flutter run

# Release mode for better sensor performance
flutter run --release

# iOS (macOS only)
flutter run
```

## First Use Walkthrough

### 1. Grant Permissions
Accept Bluetooth, Location, and sensor permissions when prompted.

### 2. Power On Sensor
Turn on your WT9011DCL-BT50 — the LED should blink.

### 3. Scan and Connect
1. Tap the **Bluetooth** icon in the app bar
2. Tap **Scan** — sensors are auto-assigned to slots via MAC address map
3. Wait for connection (2–5 seconds per sensor)

### 4. Record an Activity
1. Tap **Activities** on the Home screen
2. Select an activity type (Walking, Running, Cycling, or custom)
3. On the check screen, connect any missing sensors via the **+** button
4. Tap **Start Activity**
5. Optionally mark fatigue levels (0–4) and set checkpoints
6. Tap **Finish** → view summary

### 5. Explore the Tabs
- **Graphs** — real-time scrolling charts from connected sensors and phone
- **3D** — 22-bone humanoid skeleton animated by sensor quaternion data (orbit with drag, zoom with pinch)
- **Settings** — manage sensors, language (EN/PT-BR), phone sensors, user profiles
- **History** — browse past activities, view details, analyze, export, upload to cloud

## Feature Testing Checklist

### Real-Time Graphs
1. Connect a sensor → Graphs tab
2. Move the sensor — lines should update in real time
3. Switch between Acceleration, Angular Velocity, and Angles charts

### 3D Skeleton
1. Connect sensors → 3D tab
2. Rotate sensors in all directions
3. Skeleton bones (thighs, calves, foot) should follow sensor movement
4. Drag to orbit, pinch to zoom

### Activity Recording
1. Connect all required sensors
2. Start an activity, move around, mark fatigue, add checkpoints
3. Finish → verify summary shows correct duration and data points

### Analysis
1. From History or Summary → View detailed analysis
2. Check per-sensor statistics (min/max/avg/median/stdDev)
3. Verify intensity level, peak detection, movement quality

### Export
1. Activity Detail → Export CSV (saves to Downloads)
2. History → ZIP export (structured archive with share sheet)

### LLM Chat
1. Home → LLM Context card → select an activity
2. Ask a question or tap a quick prompt chip
3. Verify AI generates chart or analysis with sensor context

### Phone Sensors
1. Settings → Phone Sensors
2. Toggle individual sensors (accelerometer, gyroscope, magnetometer, GPS, barometer)
3. Record an activity with phone sensors enabled
4. Verify GPS map appears in post-activity graphs

## Common Issues

| Issue | Solution |
|---|---|
| No devices found | Enable Location on phone (Android 12+), bring sensor closer |
| Connection fails | Power cycle sensor, restart Bluetooth, restart app |
| No data after connect | Verify UUID in `app_config.dart` matches sensor (try nRF Connect) |
| App crashes | `flutter clean && flutter pub get`, verify `google-services.json` |
| Wrong UUID | `SENSOR_DATA_CHARACTERISTIC_UUID` in `lib/config/app_config.dart` |

## Next Steps

- **Add more sensors**: increase `NUMBER_OF_SENSORS` in `app_config.dart`
- **Custom activities**: create activity types with specific sensor positions via Activities → Create
- **User profiles**: manage users (age, weight, height, injury) via the profile icon in the app bar
- **Cloud backup**: tap Send to Firebase on any activity in History
- **Full reference**: see `README.md` for architecture, protocol details, and configuration