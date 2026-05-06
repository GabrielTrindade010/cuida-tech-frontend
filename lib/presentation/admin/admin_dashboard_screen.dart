import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_create_offer_screen.dart';
import 'admin_demands_screen.dart';
import 'admin_finance_screen.dart';
import 'admin_user_approvals_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildHeader(adminProv),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSummaryCards(adminProv),
                const SizedBox(height: 32),
                _buildSectionTitle('Ações Rápidas'),
                const SizedBox(height: 16),
                _buildQuickActions(),
                const SizedBox(height: 32),
                _buildSectionTitle('Pendências Recentes'),
                const SizedBox(height: 16),
                _buildRecentUsers(adminProv),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AdminProvider adminProv) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      actions: [
        IconButton(
          onPressed: () => context.read<AuthProvider>().logout(),
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
        ),
        IconButton(
          onPressed: () => adminProv.fetchAllData(),
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Dashboard Administrativo',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestão centralizada do Cuida Tech',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AdminProvider adminProv) {
    final pendingUsers = adminProv.users.where((u) => u['status'] == 'PENDING').length;
    final openOffers = adminProv.offers.where((o) => o['status'] == 'OPEN').length;

    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Candidatos', 
          value: '$pendingUsers', 
          color: Colors.orange, 
          icon: Icons.person_add_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserApprovalsScreen())),
        )),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(
          label: 'Vagas Abertas', 
          value: '$openOffers', 
          color: Colors.blue, 
          icon: Icons.assignment_outlined,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDemandsScreen())),
        )),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _ActionIcon(
          icon: Icons.add_circle_outline_rounded,
          label: 'Nova Oferta',
          color: AppColors.primary,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCreateOfferScreen())),
        ),
        _ActionIcon(
          icon: Icons.list_alt_rounded,
          label: 'Demandas',
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDemandsScreen())),
        ),
        _ActionIcon(
          icon: Icons.payments_rounded,
          label: 'Financeiro',
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFinanceScreen())),
        ),
      ],
    );
  }

  Widget _buildRecentUsers(AdminProvider adminProv) {
    final pendingUsers = adminProv.users.where((u) => u['status'] == 'PENDING').toList();
    
    if (pendingUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: const Center(child: Text('Nenhuma pendência crítica.', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: pendingUsers.take(3).map((u) => _AdminUserCard(
        user: u,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserApprovalsScreen())),
      )).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onTap;
  const _AdminUserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(user['name'][0], style: const TextStyle(color: AppColors.primary))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(user['category'] ?? 'Prestador', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
