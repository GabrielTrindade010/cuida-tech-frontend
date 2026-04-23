import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/availability_provider.dart';
import '../../providers/contract_provider.dart';
import '../availability/availability_screen.dart';
import '../availability/my_offers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AvailabilityProvider>().fetchMyOffers();
      context.read<ContractProvider>().fetchLatestContract();
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null && !JwtDecoder.isExpired(token)) {
      final decoded = JwtDecoder.decode(token);
      setState(() => _userName = decoded['name'] ?? 'Prestador');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bom dia,' : hour < 18 ? 'Boa tarde,' : 'Boa noite,';

    final availabilityProvider = context.watch<AvailabilityProvider>();
    final contractProvider = context.watch<ContractProvider>();

    final int pendingCount = availabilityProvider.myOffers.where((o) => o['status'] == 'PENDING').length;
    final int confirmedCount = availabilityProvider.myOffers.where((o) => o['status'] == 'ACCEPTED').length;
    final String contractVersion = contractProvider.latestContract?['version'] ?? 'V1.0';
    
    final bool isAnyLoading = contractProvider.isLoading || availabilityProvider.isLoadingOffers;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Premium Modern Header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                ),
              ),
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting ${_userName.split(' ')[0]}',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.secondary, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'PRESTADOR ATIVO',
                          style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Quick Actions Grid ────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_task_rounded,
                      label: 'Ofertar\nPlantão',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvailabilityScreen())),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.history_rounded,
                      label: 'Ver Minhas\nOfertas',
                      color: AppColors.accent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOffersScreen())),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Summary Section ────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text('Resumo de Atividades', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  Icon(Icons.tune_rounded, size: 20, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _SummaryItem(
                    icon: Icons.hourglass_empty_rounded,
                    title: 'Ofertas Pendentes',
                    value: '$pendingCount',
                    color: Colors.orange,
                    isLoading: isAnyLoading,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOffersScreen(initialFilter: 'PENDING'))),
                  ),
                  const SizedBox(height: 12),
                  _SummaryItem(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Serviços Confirmados',
                    value: '$confirmedCount',
                    color: AppColors.secondary,
                    isLoading: isAnyLoading,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOffersScreen(initialFilter: 'ACCEPTED'))),
                  ),
                  const SizedBox(height: 12),
                  _SummaryItem(
                    icon: Icons.description_outlined,
                    title: 'Contrato Digital',
                    value: contractVersion,
                    color: AppColors.primary,
                    isLoading: isAnyLoading,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.2, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _SummaryItem({required this.icon, required this.title, required this.value, required this.color, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
            const Spacer(),
            isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
}
