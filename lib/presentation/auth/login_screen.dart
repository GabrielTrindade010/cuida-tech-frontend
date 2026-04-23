import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  Future<void> _doLogin() async {
    final success = await context.read<AuthProvider>().login(_emailCtrl.text, _pwdCtrl.text);
    if (!success && mounted) {
      final msg = context.read<AuthProvider>().errorMessage ?? 'Falha no login';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.05),
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo & Brand
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.health_and_safety_rounded, size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Cuida Tech',
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Portal do Prestador Autônomo',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Login Form
                  Text('Entrar', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Bem-vindo de volta! Use suas credenciais para acessar sua conta.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Seu e-mail',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _pwdCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Sua senha',
                      prefixIcon: Icon(Icons.lock_open_rounded),
                    ),
                    obscureText: true,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Esqueceu a senha?',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: isLoading ? null : _doLogin,
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('ACESSAR CONTA'),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Register Redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ainda não tem conta?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Cadastre-se',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
