import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../core/theme/app_theme.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _pixCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().fetchFinanceData().then((_) {
        _pixCtrl.text = context.read<FinanceProvider>().pixKey ?? '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final financeProv = context.watch<FinanceProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Financeiro'), centerTitle: true),
      body: financeProv.isLoading && financeProv.transactions.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBalanceCard(financeProv.totalGains, theme),
                const SizedBox(height: 32),
                _buildPixSection(financeProv),
                const SizedBox(height: 32),
                Text('Últimas Transações', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                ...financeProv.transactions.map((t) => _buildTransactionItem(t)),
              ],
            ),
          ),
    );
  }

  Widget _buildBalanceCard(double total, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text('Saldo Disponível', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text('R\$ ${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPixSection(FinanceProvider prov) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chave PIX para Recebimento', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _pixCtrl,
            decoration: InputDecoration(
              hintText: 'E-mail, CPF ou Aleatória',
              suffixIcon: IconButton(
                icon: const Icon(Icons.save_as_outlined, color: AppColors.primary),
                onPressed: () async {
                  final success = await prov.updatePixKey(_pixCtrl.text);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave PIX atualizada!')));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(dynamic t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: (t['status'] == 'PAID' ? Colors.green : Colors.orange).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(t['status'] == 'PAID' ? Icons.check_rounded : Icons.schedule_rounded, color: t['status'] == 'PAID' ? Colors.green : Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(t['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          Text('R\$ ${t['value'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
