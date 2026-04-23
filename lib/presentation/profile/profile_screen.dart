import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/auth_gate.dart';
import '../availability/my_offers_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null && !JwtDecoder.isExpired(token)) {
      final decoded = JwtDecoder.decode(token);
      setState(() {
        _userName = decoded['name'] ?? 'Prestador';
        _userEmail = decoded['email'] ?? '';
        _userRole = decoded['role'] ?? 'PRESTADOR';
      });
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar Sessão?'),
        content: const Text('Você precisará entrar novamente para acessar seus plantões.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthGate()), (r) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Premium Header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40)),
              ),
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 40),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                        ),
                        child: const Center(child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 40)),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                            Text(_userEmail, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(100)),
                              child: Text(
                                _userRole == 'ADMIN' ? 'ADMINISTRADOR' : 'PRESTADOR ATIVO',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── Menu Content ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gerenciamento', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildMenuCard([
                    _MenuItem(
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Termo de Adesão',
                      subtitle: 'Contrato legal e autonomia',
                      color: AppColors.primary,
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.history_edu_rounded,
                      label: 'Histórico de Atividades',
                      subtitle: 'Registros de plantões ofertados',
                      color: AppColors.accent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOffersScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notificações',
                      subtitle: 'Preferências de comunicação',
                      color: Colors.orange,
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 32),
                  Text('Suporte', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildMenuCard([
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Central de Ajuda',
                      subtitle: 'Fale conosco via WhatsApp',
                      color: AppColors.secondary,
                      onTap: () async {
                        final url = Uri.parse('whatsapp://send?phone=+5511999999999&text=Olá, preciso de ajuda com o app Cuida Tech.');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                    ),
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      label: 'Sobre o Aplicativo',
                      subtitle: 'Versão 1.0.0 (Premium Build)',
                      color: const Color(0xFF64748B),
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('ENCERRAR SESSÃO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Color(0xFFFEE2E2)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              ListTile(
                onTap: item.onTap,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: item.color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
              ),
              if (i < items.length - 1) Divider(height: 1, indent: 76, color: Colors.grey.shade50),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  _MenuItem({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});
}
