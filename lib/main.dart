import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'providers/sensor_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/universal_scanner_screen.dart';
import 'screens/graphs_screen.dart';
import 'screens/model3d_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_profile_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Authenticate anonymously so uploads can be scoped to the user's UID.
  // A network failure is non-fatal — the app continues and can retry later.
  try {
    await AuthService().signInAnonymously();
  } catch (e) {
    debugPrint('Auth warning (will retry later): $e');
  }

  // Request Bluetooth + location permissions.
  await _requestPermissions();

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
    Permission.locationWhenInUse,
    Permission.sensors,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          final appLocalizations = localeProvider.localizations;
          return MaterialApp(
            title: 'AI Wearable Sensor',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            home: MainScreen(localizations: appLocalizations),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final AppLocalizations localizations;
  const MainScreen({super.key, required this.localizations});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    GraphsScreen(),
    Model3DScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = widget.localizations;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Wearable Sensor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // User profile button
          Consumer<SensorProvider>(
            builder: (context, provider, _) {
              final selected = provider.selectedUser;
              return IconButton(
                tooltip: selected != null
                    ? 'Usuário: ${selected.name}'
                    : 'Usuários',
                icon: selected != null
                    ? CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        child: Text(
                          selected.name.isNotEmpty
                              ? selected.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserProfileScreen(),
                    ),
                  );
                },
              );
            },
          ),
          // Bluetooth status button
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () => _showBluetoothStatusModal(context),
          ),

        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home), label: l10n.home),
          NavigationDestination(
            icon: const Icon(Icons.show_chart),
            label: l10n.graphs,
          ),
          const NavigationDestination(icon: Icon(Icons.view_in_ar), label: '3D'),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }

  void _showBluetoothStatusModal(BuildContext context) {
    final provider = Provider.of<SensorProvider>(context, listen: false);
    final numberOfSensors = provider.numberOfSensors;
    final l10n = widget.localizations;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sensorStatus),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 1; i <= numberOfSensors; i++)
                _buildSensorStatusTile(
                  '${l10n.sensor} $i',
                  provider.getSensorState(i).status,
                ),
              if (provider.phoneSensorSettings.anyEnabled)
                _buildSensorStatusTile(
                  l10n.smartphone,
                  provider.isPhoneSensorRunning ? l10n.active : l10n.inactive,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UniversalScannerScreen(),
                ),
              );
            },
            child: Text(l10n.connect),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorStatusTile(String label, String status) {
    final isConnected = status == 'Conectado' || status == 'Ativo';
    return ListTile(
      leading: Icon(
        isConnected ? Icons.check_circle : Icons.cancel,
        color: isConnected ? Colors.green : Colors.grey,
        size: 28,
      ),
      title: Text(label),
      subtitle: Text(
        status,
        style: TextStyle(
          color: isConnected ? Colors.green : Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
