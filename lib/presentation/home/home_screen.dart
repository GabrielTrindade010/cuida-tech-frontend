import 'package:flutter/material.dart';
import 'package:mobile/providers/offer_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/availability_provider.dart';
import '../../providers/contract_provider.dart';
import '../availability/availability_screen.dart';
import '../availability/my_offers_screen.dart';
import 'my_accepted_services_screen.dart';
import 'finance_screen.dart';
import 'provider_offer_details_screen.dart';

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
      context.read<OfferProvider>().fetchAvailableOffers();
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
                      const Text(
                        'Cuida Tech',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você não tem novas notificações.')));
                        },
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '$greeting ${_userName.split(' ')[0]}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 16),
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
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Meus\nServiços',
                      color: AppColors.secondary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAcceptedServicesScreen())),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Financeiro\ne PIX',
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen())),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Spacer(),
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

          // ── Available Offers Section ───────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text('Honorários Próximos', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  const Text('SP', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          Consumer<OfferProvider>(
            builder: (context, offerProv, _) {
              if (offerProv.isLoading && offerProv.availableOffers.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())));
              }
              if (offerProv.availableOffers.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Nenhuma nova oferta no momento.', style: TextStyle(color: Colors.grey)))),
                );
              }
              return SliverList(
                delegate: SliverChildListDelegate(
                  offerProv.availableOffers.map((offer) => InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderOfferDetailsScreen(offer: offer))),
                    child: _OfferCard(offer: offer),
                  )).toList(),
                ),
              );
            },
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

class _OfferCard extends StatelessWidget {
  final dynamic offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(offer['category'].split(',')[0], style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text('R\$ ${offer['price']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 16),
            Text(offer['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${offer['address']}, ${offer['neighborhood']}\n${offer['city']} - ${offer['state']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final success = await context.read<OfferProvider>().refuseOffer(offer['id']);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oferta removida.')));
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Color(0xFFFFEBEE)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('RECUSAR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await context.read<OfferProvider>().acceptOffer(offer['id']);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oferta aceita com sucesso!')));
                        context.read<AvailabilityProvider>().fetchMyOffers();
                      }
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('ACEITAR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

