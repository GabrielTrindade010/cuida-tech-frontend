import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/availability_provider.dart';
import '../../core/theme/app_theme.dart';
import 'offer_details_screen.dart';

class MyOffersScreen extends StatefulWidget {
  final String? initialFilter;
  const MyOffersScreen({super.key, this.initialFilter});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AvailabilityProvider>().fetchMyOffers();
    });
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoString;
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'PENDING': return 'Em Análise';
      case 'ACCEPTED': return 'Confirmado';
      case 'REJECTED': return 'Recusado';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'ACCEPTED': return AppColors.primaryGreen;
      case 'REJECTED': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AvailabilityProvider>();
    
    List<dynamic> displayOffers = provider.myOffers;
    if (widget.initialFilter != null) {
      displayOffers = provider.myOffers.where((o) => o['status'] == widget.initialFilter).toList();
    }

    final title = widget.initialFilter == 'PENDING' 
        ? 'Ofertas Pendentes' 
        : widget.initialFilter == 'ACCEPTED' 
            ? 'Serviços Confirmados' 
            : 'Meu Histórico';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: theme.textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoadingOffers
          ? const Center(child: CircularProgressIndicator())
          : displayOffers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: displayOffers.length,
                  itemBuilder: (context, index) {
                    final offer = displayOffers[index];
                    return _buildOfferCard(offer);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 40)],
            ),
            child: Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text('Nenhuma oferta encontrada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Suas agendas aparecerão aqui.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildOfferCard(dynamic offer) {
    final status = offer['status'] as String;
    final color = _getStatusColor(status);
    final hasSubstitute = offer['substitute'] != null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OfferDetailsScreen(offer: offer))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            // Card Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                    child: Text(
                      _translateStatus(status).toUpperCase(),
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${offer['id'].toString().padLeft(4, '0')}',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            
            // Card Body
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Período do Plantão',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(offer['startDate'])} — ${_formatDate(offer['endDate'])}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _infoBadge(Icons.calendar_today_rounded, '${(offer['shifts'] as List).length} turnos'),
                      if (hasSubstitute) ...[
                        const SizedBox(width: 8),
                        _infoBadge(Icons.people_outline_rounded, 'Equipe'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
