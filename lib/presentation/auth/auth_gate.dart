import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../contract/contract_gate_screen.dart';
import '../shell/main_shell.dart';
import '../admin/admin_panel_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isCheckingSession) {
          return Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          );
        }

        if (auth.isAuthenticated) {
          // ADMIN bypasses everything
          if (auth.role == 'ADMIN') {
            return const AdminPanelScreen();
          }

          // Se o cadastro estiver incompleto, redireciona para o Registro
          if (auth.registrationStep < 5) {
            return const RegisterScreen();
          }

          return const MainShell();
        }

        return const LoginScreen();
      },
    );
  }
}
