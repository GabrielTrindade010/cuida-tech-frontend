import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/offer_provider.dart';
import '../../providers/availability_provider.dart';

class ProviderOfferDetailsScreen extends StatelessWidget {
  final dynamic offer;
  const ProviderOfferDetailsScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detalhes do Honorário'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(offer['category'].split(',')[0].toUpperCase(), style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              Text('R\$ ${offer['price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 24),
          Text(offer['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Text(offer['description'] ?? 'Sem descrição adicional.', style: const TextStyle(color: Colors.grey, height: 1.6, fontSize: 14)),
          const Divider(height: 48),
          _infoRow(Icons.calendar_today_rounded, 'Data Sugerida', offer['date']),
          const SizedBox(height: 16),
          _infoRow(Icons.access_time_rounded, 'Período Estimado', '${offer['startTime']} - ${offer['endTime']} (12h)'),
          const SizedBox(height: 16),
          _infoRow(Icons.location_on_rounded, 'Localização', '${offer['address']}, ${offer['neighborhood']}\n${offer['city']} - ${offer['state']}'),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _confirmAction(context, 'REFUSE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Color(0xFFFEE2E2)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('RECUSAR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _confirmAction(context, 'ACCEPT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('ACEITAR AGORA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmAction(BuildContext context, String action) {
    final bool isAccept = action == 'ACCEPT';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAccept ? 'Aceitar Plantão?' : 'Recusar Oferta?'),
        content: Text(isAccept 
          ? 'Ao aceitar, você se compromete a realizar este plantão na data e local informados.' 
          : 'Deseja realmente recusar esta oferta? Ela não aparecerá mais para você.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              bool success;
              if (isAccept) {
                success = await context.read<OfferProvider>().acceptOffer(offer['id']);
              } else {
                success = await context.read<OfferProvider>().refuseOffer(offer['id']);
              }

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isAccept ? 'Oferta aceita com sucesso!' : 'Oferta recusada.'),
                ));
                if (isAccept) {
                  context.read<AvailabilityProvider>().fetchMyOffers();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: isAccept ? AppColors.primary : Colors.redAccent),
            child: Text(isAccept ? 'Aceitar' : 'Recusar'),
          ),
        ],
      ),
    );
  }
}
