import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _docCtrl = TextEditingController(); // CPF/CNPJ
  final _profRegCtrl = TextEditingController(); // COREN, etc
  final _pwdCtrl = TextEditingController();

  Future<void> _doRegister() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      document: _docCtrl.text,
      professionalRegister: _profRegCtrl.text,
      password: _pwdCtrl.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Conta criada com sucesso! Faça seu login.'),
        backgroundColor: AppColors.primaryGreen,
      ));
      Navigator.of(context).pop(); // Volta para a tela de login
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Falha ao registrar'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SafeArea(child: SizedBox(height: 10)),
                const Icon(Icons.person_add_alt_1_rounded, size: 70, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  'Seja um Cuidador',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Crie sua conta', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Nome Completo', prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryBlue)),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryBlue)),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _docCtrl,
                          decoration: const InputDecoration(labelText: 'CPF / CNPJ', prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryBlue)),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _profRegCtrl,
                          decoration: const InputDecoration(labelText: 'Registro (Ex: COREN)', prefixIcon: Icon(Icons.medical_information_outlined, color: AppColors.primaryBlue)),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _pwdCtrl,
                          decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryBlue)),
                          obscureText: true,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: isLoading ? null : _doRegister,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('REGISTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
