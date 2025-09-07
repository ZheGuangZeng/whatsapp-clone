import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/config/environment_config.dart';
import 'core/constants/app_constants.dart';
import 'core/monitoring/monitoring_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  EnvironmentConfig.initialize();

  // Initialize Firebase (required for monitoring services)
  if (!EnvironmentConfig.isDevelopment) {
    await Firebase.initializeApp();
  }

  // Initialize monitoring service first
  final monitoringService = MonitoringService();
  await monitoringService.initialize();

  // Initialize Supabase with environment-specific configuration
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    debug: AppConstants.isDevelopment,
  );

  runApp(
    const ProviderScope(
      child: WhatsAppCloneApp(),
    ),
  );
}

class WhatsAppCloneApp extends ConsumerWidget {
  const WhatsAppCloneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'WhatsApp Clone',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
