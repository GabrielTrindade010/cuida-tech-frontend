import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/auth_gate.dart';

/// Botão de logout reutilizável para AppBar (actions) ou qualquer lugar.
class LogoutButton extends StatelessWidget {
  final Color color;

  const LogoutButton({super.key, this.color = Colors.white});

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar Sessão?'),
        content: const Text('Você precisará entrar novamente para acessar seus plantões e agenda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('SAIR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sair da conta',
      icon: Icon(Icons.logout_rounded, color: color),
      onPressed: () => _confirm(context),
    );
  }
}
