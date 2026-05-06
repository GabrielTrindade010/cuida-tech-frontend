import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/offer_provider.dart';
import '../../providers/availability_provider.dart';
import '../../core/theme/app_theme.dart';

class MyAcceptedServicesScreen extends StatefulWidget {
  const MyAcceptedServicesScreen({super.key});

  @override
  State<MyAcceptedServicesScreen> createState() => _MyAcceptedServicesScreenState();
}

class _MyAcceptedServicesScreenState extends State<MyAcceptedServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfferProvider>().fetchMyAcceptedOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final offerProv = context.watch<OfferProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meus Serviços'),
        centerTitle: true,
      ),
      body: offerProv.isLoading && offerProv.myOffers.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : offerProv.myOffers.isEmpty
          ? const Center(child: Text('Você não tem serviços aceitos.'))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: offerProv.myOffers.length,
              itemBuilder: (context, index) {
                final offer = offerProv.myOffers[index];
                return _ServiceActionCard(offer: offer);
              },
            ),
    );
  }
}

class _ServiceActionCard extends StatefulWidget {
  final dynamic offer;
  const _ServiceActionCard({required this.offer});

  @override
  State<_ServiceActionCard> createState() => _ServiceActionCardState();
}

class _ServiceActionCardState extends State<_ServiceActionCard> {
  final _reportCtrl = TextEditingController();

  @override
  void dispose() {
    _reportCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(offer['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text('${offer['date']} • ${offer['startTime']} - ${offer['endTime']}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Câmera de vídeo iniciada (Simulado)')));
                  },
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('VÍDEO'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Container()),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Relatório de Visita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _reportCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Descreva os cuidados realizados...',
              fillColor: Colors.grey.shade50,
              filled: true,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await context.read<OfferProvider>().checkIn(widget.offer['id'], -23.5505, -46.6333);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in realizado com sucesso!')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('CHECK-IN'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_reportCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha o relatório antes do check-out.')));
                      return;
                    }
                    final success = await context.read<OfferProvider>().checkOut(widget.offer['id'], -23.5505, -46.6333, _reportCtrl.text);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-out realizado e relatório salvo!')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('CHECK-OUT'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleSubstitute(context, offer),
              icon: const Icon(Icons.people_outline_rounded, size: 18),
              label: const Text('INDICAR SUBSTITUTO'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueGrey,
                side: BorderSide(color: Colors.blueGrey.shade100),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubstitute(BuildContext context, dynamic offer) {
    final offerDate = DateTime.parse(offer['date']);
    final now = DateTime.now();
    final difference = offerDate.difference(now).inHours;

    if (difference < 72) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Substituições só podem ser feitas com 72h de antecedência.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    _showSubstituteDialog(context);
  }

  void _showSubstituteDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final docCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Indicar Substituto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome do Substituto')),
            const SizedBox(height: 12),
            TextField(controller: docCtrl, decoration: const InputDecoration(labelText: 'CPF do Substituto')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || docCtrl.text.isEmpty) return;
              Navigator.pop(context);
              final success = await context.read<OfferProvider>().indicateSubstitute(widget.offer['id'], nameCtrl.text, docCtrl.text);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Substituto indicado com sucesso!')));
                context.read<OfferProvider>().fetchMyAcceptedOffers();
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }
}
