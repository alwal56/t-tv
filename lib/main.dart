import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

// Conditional import: stub for Web, native impl for Android/Windows
import 'media_kit_init_stub.dart'
    if (dart.library.io) 'media_kit_init_native.dart';

import 'providers/channels_provider.dart';
import 'providers/player_provider.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // يعمل على Android/Windows فقط، stub على Web
  initMediaKit();

  await StorageService.init();

  runApp(const TTVApp());
}

class TTVApp extends StatelessWidget {
  const TTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChannelsProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = PlayerProvider();
          provider.init(); // WebVideoPlayer on Web, media_kit Player on native
          return provider;
        }),
      ],
      child: MaterialApp(
        title: 'T-TV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        // Show welcome screen only on first launch
        home: StorageService.isFirstLaunch
            ? const WelcomeScreen()
            : const HomeScreen(),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      ),
    );
  }
}
