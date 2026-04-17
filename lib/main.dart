import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'core/api/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/contract_provider.dart';
import 'providers/availability_provider.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/auth_gate.dart';
import 'presentation/contract/contract_gate_screen.dart';
import 'presentation/shell/main_shell.dart';
import 'presentation/admin/admin_panel_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  DioClient.setupInterceptors();
  runApp(const CuidaTechApp());
}

class CuidaTechApp extends StatelessWidget {
  const CuidaTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSession()),
        ChangeNotifierProvider(create: (_) => ContractProvider()),
        ChangeNotifierProvider(create: (_) => AvailabilityProvider()),
      ],
      child: MaterialApp(
        title: 'Cuida Tech',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}

// AuthGate agora reside em lib/presentation/auth/auth_gate.dart
