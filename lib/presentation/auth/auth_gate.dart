import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';
import '../contract/contract_gate_screen.dart';
import '../shell/main_shell.dart';
import '../admin/admin_panel_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.health_and_safety, size: 80, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Cuida Tech',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 32),
                  CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ],
              ),
            ),
          );
        }

        if (auth.isAuthenticated) {
          return ContractGateScreen(
            onAccepted: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('jwt_token');
              String role = 'PRESTADOR';
              if (token != null && !JwtDecoder.isExpired(token)) {
                final decoded = JwtDecoder.decode(token);
                role = decoded['role'] ?? 'PRESTADOR';
              }
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => role == 'ADMIN'
                      ? const AdminPanelScreen()
                      : const MainShell(),
                ),
                (route) => false,
              );
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
