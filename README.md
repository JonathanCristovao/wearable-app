# AI Wearable Sensor

A Flutter mobile application that connects to **WT9011DCL-BT50 Bluetooth BLE IMU sensors** (WitMotion) and the smartphone's built-in sensors to record, analyze, and visualize human movement during physical activities such as walking, running, and cycling.

## Sensor

**WT9011DCL-BT50** — a 9-axis Bluetooth BLE 5.0 IMU with built-in Kalman filtering.

| Measurement | Range | Resolution |
|---|---|---|
| Accelerometer (3-axis) | ±16 g | 0.0005 g/LSB |
| Gyroscope (3-axis) | ±2000 °/s | 0.061 °/s/LSB |
| Magnetometer (3-axis) | ±2 Gauss | 0.0667 mGauss/LSB |
| Euler Angles | Roll ±180°, Pitch ±90° | 0.0055° |
| Quaternion | — | 4D rotation |

- Bluetooth range: up to 90 meters
- Operating current: ~16 mA, battery: 100 mAh (~20 h runtime)
- Up to **5 sensors** supported, each mapped to a body segment (thighs, calves, foot)

The app also reads the **smartphone's internal sensors** — accelerometer, gyroscope, magnetometer, barometer — plus **GPS** for outdoor activities.

## Protocol (WT9011DCL-BT50)

The sensor sends data in two packet formats:

**Combined Packet (20 bytes):**
- Header: `0x55` (1 byte)
- Type: `0x61` (1 byte)
- Acceleration X, Y, Z: 6 bytes (3 × int16, little-endian)
- Angular Velocity X, Y, Z: 6 bytes (3 × int16, little-endian)
- Euler Angles Roll, Pitch, Yaw: 6 bytes (3 × int16, little-endian)

**Individual Packets (11 bytes):**
- Type `0x51` — Acceleration, `0x52` — Gyroscope, `0x53` — Angle
- Each includes a checksum byte for validation

**Conversion Factors:**
- Acceleration: ±16 g range (16.0 / 32768.0)
- Gyroscope: ±2000 °/s range (2000.0 / 32768.0)
- Euler Angles: ±180° range (180.0 / 32768.0)

## Architecture

```
┌──────────────────────────────────┐
│           Flutter UI             │
│          19 screens               │
└───────────────┬──────────────────┘
                │ reads/writes
┌───────────────▼──────────────────┐
│        Provider (state)           │
│   SensorProvider                  │
│   LocaleProvider                  │
└───────────────┬──────────────────┘
                │ invokes
┌───────────────▼──────────────────┐
│           Services                │
│   BluetoothService                │
│   PhoneSensorService              │
│   ProtocolParser                  │
│   DatabaseHelper (SQLite v7)      │
│   LLMService (OpenAI GPT-4o-mini) │
│   ActivityAnalysisService         │
│   ExportService (ZIP/CSV)         │
│   StorageService (Firebase)       │
│   SensorUploadService             │
│   AuthService (Firebase Anon)     │
└──────┬──────────┬─────────────────┘
       │          │
┌──────▼──┐ ┌─────▼──────────────┐
│  BLE     │ │  Cloud / Local     │
│  Sensors │ │  Firebase Storage  │
│  (WT9011)│ │  + Firestore       │
└─────────┘ │  + OpenAI API      │
            │  + SQLite           │
            └────────────────────┘
```

- **State management:** Provider + ChangeNotifier
- **BLE communication:** flutter_blue_plus, proprietary WT9011DCL packet parser
- **Local storage:** SQLite v7 (activities, data points, user profiles, custom activity types)
- **Cloud storage:** Firebase Storage (GZIP-compressed JSONL), Firestore, Firebase Auth (anonymous)
- **AI analysis:** OpenAI GPT-4o-mini via HTTP with full activity context and inline charts
- **3D visualization:** Custom software-rendered 3D engine with 22-bone humanoid skeleton driven by sensor quaternion data

### Sensor-to-Body Mapping

| Slot | Body Segment |
|---|---|
| Sensor 1 | Left thigh |
| Sensor 2 | Right thigh |
| Sensor 3 | Left calf |
| Sensor 4 | Right calf |
| Sensor 5 | Right foot |

## Project Structure

```
lib/
├── main.dart                          # Entry point and main navigation
├── firebase_options.dart              # Firebase configuration (auto-generated)
├── config/
│   └── app_config.dart                # Central configuration (sensor count, MACs, UUIDs, OpenAI key)
├── models/
│   ├── sensor_data.dart               # SensorData, SensorState
│   ├── sensor_slot.dart               # SensorSlot, SensorSlotsConfig
│   ├── activity_record.dart           # ActivityRecord, ActivityDataPoint, SensorSnapshot, ActivityType, SensorPosition
│   ├── activity_metadata.dart         # ActivityMetadata
│   ├── phone_sensor_data.dart         # PhoneSensorData, PhoneSensorSettings
│   ├── user_profile.dart              # UserProfile
│   ├── bluetooth_device_info.dart     # BluetoothDeviceInfo
│   └── imu_math.dart                  # IMUQuaternion, Bone, Skeleton, SensorMapper, IMUData
├── services/
│   ├── bluetooth_service.dart         # BLE scanning, connection, data streaming
│   ├── phone_sensor_service.dart      # Smartphone sensor reading (accel, gyro, mag, GPS, barometer)
│   ├── protocol_parser.dart           # WT9011DCL binary protocol parser
│   ├── database_helper.dart           # SQLite database (v7) CRUD operations
│   ├── activity_analysis_service.dart # Statistical analysis of recorded activities
│   ├── llm_service.dart               # OpenAI GPT-4o-mini chat integration
│   ├── export_service.dart            # ZIP/CSV export
│   ├── storage_service.dart           # Firebase Storage wrapper
│   ├── sensor_upload_service.dart     # Phone sensor data upload to Firebase
│   └── auth_service.dart              # Anonymous Firebase authentication
├── providers/
│   ├── sensor_provider.dart           # Central state hub (BLE sensors, phone sensors, activities, users)
│   └── locale_provider.dart           # Localization (pt_BR / en)
├── screens/
│   ├── main_screen.dart               # Bottom navigation host (Home, Graphs, 3D, Settings)
│   ├── home_screen.dart               # Dashboard with activity cards and AI space
│   ├── activities_screen.dart         # Activity type picker (built-in + custom)
│   ├── activity_config_screen.dart    # Create/edit custom activity types
│   ├── activity_check_screen.dart     # Pre-activity sensor connection verification
│   ├── activity_running_screen.dart   # Live activity recording with timer, checkpoints, fatigue
│   ├── activity_summary_screen.dart   # Post-activity summary
│   ├── activity_detail_screen.dart    # Full activity detail with export options
│   ├── activity_analysis_screen.dart  # Detailed statistical analysis
│   ├── activity_graphs_screen.dart    # Post-recording charts and GPS map
│   ├── activity_table_screen.dart     # Raw tabular data view
│   ├── graphs_screen.dart             # Real-time scrolling line charts
│   ├── model3d_screen.dart            # 3D humanoid skeleton visualization
│   ├── history_screen.dart            # Activity history list with Firebase upload
│   ├── llm_chat_screen.dart           # AI chat powered by GPT-4o-mini
│   ├── phone_sensors_screen.dart      # Toggle phone sensors on/off
│   ├── scanner_screen.dart            # Per-slot BLE scanner (legacy)
│   ├── universal_scanner_screen.dart  # Unified BLE scanner with auto slot detection
│   ├── settings_screen.dart           # App settings, sensor management, language
│   └── user_profile_screen.dart       # User profile management (CRUD)
├── engine3d/
│   ├── quaternion.dart                # Quat, Vec3, Mat4 math + SensorToBodyMapper
│   ├── skeleton.dart                  # 22-bone humanoid skeleton hierarchy
│   ├── humanoid.dart                  # Procedural cylinder/sphere mesh generation
│   ├── camera.dart                    # Spherical orbit camera
│   └── renderer.dart                  # Scene3D + ScenePainter (CustomPainter)
├── l10n/
│   ├── app_localizations.dart         # Typed localization facade (~200 strings)
│   ├── app_pt_br.dart                 # Brazilian Portuguese (359 entries)
│   └── app_en.dart                    # English (358 entries)
└── utils/
    ├── virtual_sensor_position.dart   # Motion integration and sensor placement presets
    ├── gzip_utils.dart                # GZIP compression/decompression
    └── json_utils.dart                # JSONL format utilities
```

## Features

### Core
- **BLE sensor scanning & connection** — scan and connect to pre-mapped WT9011DCL sensors across configurable slots (default: 5)
- **Real-time sensor data display** — live acceleration, angular velocity, Euler angles, and quaternions from all connected sensors
- **Real-time graphs** — time-series line charts for wearable and phone sensors (accel, gyro, mag, GPS, barometer), 100-point scrolling buffer
- **3D humanoid skeleton** — custom software-rendered 3D model (22 bones) with orbit/pan/zoom, animated by sensor quaternion rotations, no gimbal lock
- **Phone sensor integration** — accelerometer (m/s²), gyroscope (rad/s), magnetometer (µT), barometer (hPa), GPS (lat/lng/speed/altitude); individually toggleable
- **Battery level monitoring** — reads battery level via BLE Standard Battery Service (UUID 0x180F)

### Activity Recording
- **Activity types** — walking, running, cycling (indoor/outdoor) + user-defined custom activities with names, emojis (57 options), and configurable body positions (22 positions)
- **Live recording** — 50 Hz data collection (20 ms interval) with pause/resume, checkpoint system (save segment, switch activity mid-recording), fatigue level marking (0–4, applied retroactively)
- **Post-activity summary** — success animation, duration, data points count, sensor count, quick actions
- **Activity history** — user-filterable list with date, duration, data point count; individual delete or ZIP export all

### Analysis
- **Statistical analysis** — per-sensor vector statistics (min, max, avg, median, stdDev) for acceleration, gyroscope, and orientation; movement intensity, peak detection, smoothness (jerk-based), data quality assessment
- **Post-activity charts** — tabbed interface with wearable sensor charts, phone sensor charts, and GPS route map (OpenStreetMap with route polyline, start/end markers, distance, avg speed, altitude gain)
- **Data table view** — horizontally + vertically scrollable raw data table with all sensor columns
- **CSV export** — full row-per-data-point CSV for single activity, with dynamic sensor columns
- **ZIP export** — structured archive of all activities grouped by user (usuarios.json + per-user metadata + activity JSON files), shareable via system share sheet

### AI & LLM
- **LLM chat** — OpenAI GPT-4o-mini chat with full activity context; model can generate inline fl_chart charts for single or overlaid multi-sensor visualization; quick prompt chips for common analyses (summary, problems, movement analysis, training quality, peaks/valleys, sensor comparison)
- AI feature cards (Federated Learning, GANs, Activity Classification — coming soon)

### Cloud
- **Firebase Authentication** — anonymous sign-in with session reuse across app restarts; graceful degradation if unavailable
- **Firebase Storage** — upload activities as GZIP-compressed JSONL; phone sensor data uploaded automatically during recording
- **Firebase Firestore** — activity backup to cloud from history screen

### User & Settings
- **User profiles** — create, edit, delete, select active user (name, age, weight, height, injury, activity frequency, disease)
- **Multi-language** — English and Portuguese (Brazil), persisted locale selection in SQLite
- **Dynamic sensor count** — number of BLE slots configurable via `NUMBER_OF_SENSORS` in `app_config.dart`; UI and services adapt automatically

## Prerequisites

- Flutter SDK 3.8.0 or higher
- Android Studio or VS Code with Flutter extensions
- Android device with Bluetooth LE (API 31+ for Bluetooth permissions) or iOS device
- WT9011DCL-BT50 sensor(s)
- Firebase project (for cloud features)
- OpenAI API key (for LLM chat)

## Getting Started

### 1. Clone and Install

```bash
git clone <repository-url>
cd wearable-app
flutter pub get
```

### 2. Verify Setup

```bash
flutter doctor
```

Ensure all checks pass (✓ green).

### 3. Configure

Edit `lib/config/app_config.dart`:

- Set your sensor MAC addresses in `SENSOR_MAC_ADDRESS_MAP`
- Set your OpenAI API key in `OPENAI_API_KEY` (or in `.env`)
- Adjust `NUMBER_OF_SENSORS` if needed (default: 5)
- Verify `SENSOR_DATA_CHARACTERISTIC_UUID` matches your sensors (default: `ffe1`)

For Firebase, place `google-services.json` in `android/app/`.

### 4. Run

```bash
# Debug mode
flutter run

# Release mode (better performance for sensors)
flutter run --release
```

## First Use

### Step 1: Grant Permissions
The app will request Bluetooth and Location permissions on first launch. **Accept all** for full functionality.

### Step 2: Power On Sensors
Turn on your WT9011DCL-BT50 sensors. The LED should start blinking.

### Step 3: Scan and Connect
1. Tap the **Bluetooth** icon in the app bar
2. Tap **Scan** to discover nearby sensors
3. Each sensor will be auto-assigned to its slot based on the MAC address map
4. Wait for connection (2–5 seconds per sensor)

### Step 4: Record an Activity
1. From the Home screen, tap **Activities**
2. Choose an activity type (Walking, Running, Cycling or a custom type)
3. Verify all required sensors are connected on the check screen
4. Tap **Start Activity** to begin recording
5. Mark fatigue levels and set checkpoints as needed
6. Tap **Finish** to stop and view the summary

### Step 5: Explore Data
- **Graphs tab**: Real-time scrolling charts from all connected sensors
- **3D tab**: Humanoid skeleton animated by sensor movements
- **Settings tab**: Manage connections, language, phone sensors, and user profiles
- **History**: Browse past activities, analyze, export, or upload to cloud
- **LLM Chat**: Ask AI to analyze your activities with full sensor context

## Permissions

### Android
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.BODY_SENSORS" />

<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

### iOS
Add to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to sensors</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to connect to sensors</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location for Bluetooth scanning and GPS tracking</string>
<key>NSMotionUsageDescription</key>
<string>This app uses motion sensors to record activity data</string>
```

## Dependencies

| Package | Purpose |
|---|---|
| provider | State management (ChangeNotifier) |
| flutter_blue_plus | BLE scanning, connection, characteristics |
| permission_handler | Runtime permissions (BT, location, storage, sensors) |
| sensors_plus | Phone accelerometer, gyroscope, magnetometer, barometer |
| geolocator | GPS positioning |
| fl_chart | Real-time and historical line/bar charts |
| sqflite | Local SQLite database |
| firebase_core / _auth / _storage / cloud_firestore | Cloud storage, auth, and database |
| flutter_map + latlong2 | OpenStreetMap GPS route display |
| http | OpenAI API calls |
| archive | ZIP compression for export |
| share_plus | System share sheet for exports |
| intl | Date/time formatting |
| vector_math | 3D vector and matrix math |
| path_provider | App directories for file storage |

## Troubleshooting

### Bluetooth does not find devices
- Verify Bluetooth is enabled on the phone
- Ensure permissions were granted (check system settings)
- On Android 12+, Location must be enabled for BLE scanning
- Bring the sensor closer to the phone

### Sensor does not connect
- Verify the sensor is powered on (LED blinking)
- Try power cycling the sensor
- Ensure no other device is connected to the sensor
- Check the MAC address in `app_config.dart` matches your sensor

### Sensor connects but no data received
The characteristic UUID may differ from the default `ffe1`:
1. Install nRF Connect (Google Play / App Store)
2. Connect to your sensor and browse Services and Characteristics
3. Find the UUID of the characteristic that sends notifications
4. Update `SENSOR_DATA_CHARACTERISTIC_UUID` in `lib/config/app_config.dart`

### App crashes on startup
- Run `flutter clean` then `flutter pub get`
- Verify `google-services.json` is in `android/app/`
- Check that the minimum Android SDK is 31+ in `android/app/build.gradle`

## Useful Commands

```bash
# Clean build artifacts
flutter clean

# Update dependencies
flutter pub upgrade

# View real-time logs
flutter logs

# Build release APK
flutter build apk --release

# Build iOS (macOS only)
flutter build ios --release

# Static code analysis
flutter analyze

# Run tests
flutter test
```

## Configuration Reference (`app_config.dart`)

| Constant | Default | Description |
|---|---|---|
| `NUMBER_OF_SENSORS` | 5 | Number of simultaneously supported BLE sensors |
| `SENSOR_DATA_CHARACTERISTIC_UUID` | `ffe1` | BLE characteristic UUID for data notifications |
| `BLUETOOTH_SCAN_TIMEOUT_SECONDS` | 15 | Scan duration before timeout |
| `BLUETOOTH_CONNECTION_TIMEOUT_SECONDS` | 10 | Connection attempt timeout |
| `SENSOR_MAC_ADDRESS_MAP` | 5 entries | Maps sensor MAC addresses to slot tags (s1–s5) |
| `DATA_COLLECTION_INTERVAL_MS` | 20 | Sampling interval (20 ms = 50 Hz) |
| `OPENAI_API_KEY` | — | OpenAI API key for LLM features |
| `OPENAI_MODEL` | `gpt-4o-mini` | OpenAI model used for chat |

## License

This project maintains the same license as the original Kotlin project.

## Cite:

```bibtex
@misc{silva2026wearableapp,
  author       = {Silva, Jonathan Crist{\'o}v{\~a}o Ferreira},
  title        = {Wearable Sensor Motion: Application for capturing, analyzing, and visualizing human movements in real time using wearable IMU sensors and smartphone sensors.},
  year         = {2026},
  howpublished = {\url{https://github.com/JonathanCristovao/wearable-app}},
  note         = {Repositório do GitHub. Acesso em: {day} {month}. {year}}
}
```