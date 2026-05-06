import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';

class AdminFinanceScreen extends StatelessWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gestão Financeira'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: adminProv.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : adminProv.financeReports.isEmpty
          ? const Center(child: Text('Nenhum relatório disponível no momento.'))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: adminProv.financeReports.length,
              itemBuilder: (context, index) {
                final report = adminProv.financeReports[index];
                return _ModernFinanceCard(report: report);
              },
            ),
    );
  }
}

class _ModernFinanceCard extends StatelessWidget {
  final dynamic report;
  const _ModernFinanceCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Text('PIX: ${report['pixKey'] ?? 'Não cadastrada'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      'R\$ ${report['total'].toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Detalhamento do Período', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B))),
                    TextButton.icon(
                      onPressed: () => _handleDownload(context),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('BAIXAR RELATÓRIO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...report['days'].map<Widget>((day) => _DayRow(day: day)).toList(),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9).withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _handleUploadReceipt(context),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('ENVIAR COMPROVANTE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context) async {
    final providerId = report['providerId'];
    final url = await context.read<AdminProvider>().downloadReport(providerId);
    if (url != null) {
      final uri = Uri.parse(url);
      // Simulação: Apenas mostra a URL ou abre se possível
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Relatório gerado: $url')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao gerar relatório.')));
    }
  }

  Future<void> _handleUploadReceipt(BuildContext context) async {
    // Simulação de upload (já que não temos o plugin de picker agora)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar Comprovante'),
        content: const Text('Selecione o arquivo do comprovante de pagamento para este prestador.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<AdminProvider>().uploadReceipt(report['providerId'], 'https://storage.com/receipt_001.png');
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comprovante enviado com sucesso!')));
              }
            },
            child: const Text('Simular Envio'),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final dynamic day;
  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(day['offer']['title'], style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
          Text(day['offer']['date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
