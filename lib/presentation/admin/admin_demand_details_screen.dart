import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';

class AdminDemandDetailsScreen extends StatelessWidget {
  final dynamic offer;
  const AdminDemandDetailsScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final provider = offer['provider'];
    final bool hasProvider = provider != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detalhes da Demanda'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          if (!hasProvider)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildProviderSection(context, provider),
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
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(offer['category'].split(',')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              Text('R\$ ${offer['price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 20),
          Text(offer['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(offer['description'] ?? 'Sem descrição adicional.', style: const TextStyle(color: Colors.grey, height: 1.5)),
          const Divider(height: 40),
          _infoRow(Icons.calendar_today_rounded, 'Data', offer['date']),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time_rounded, 'Horário', '${offer['startTime']} - ${offer['endTime']}'),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on_rounded, 'Local', '${offer['address']}\n${offer['neighborhood']}, ${offer['city']}'),
        ],
      ),
    );
  }

  Widget _buildProviderSection(BuildContext context, dynamic provider) {
    if (provider == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.orange.withOpacity(0.1)),
        ),
        child: Column(
          children: const [
            Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 32),
            SizedBox(height: 12),
            Text('Aguardando Prestador', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.orange)),
            Text('Nenhum prestador aceitou este plantão ainda.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prestador Alocado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.secondary.withOpacity(0.1),
                child: Text(provider['name'][0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.secondary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text('Registro: ${provider['professionalRegister'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onPressed: () {
                  // TODO: Abrir perfil completo do prestador se necessário
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil detalhado em breve.')));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Demanda?'),
        content: const Text('Esta ação não pode ser desfeita. Deseja realmente excluir este plantão?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<AdminProvider>().deleteOffer(offer['id']);
              if (success && context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demanda excluída.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
