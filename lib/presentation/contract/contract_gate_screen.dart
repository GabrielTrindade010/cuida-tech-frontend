import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../../providers/contract_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/logout_button.dart';

class ContractGateScreen extends StatefulWidget {
  final VoidCallback onAccepted;
  const ContractGateScreen({super.key, required this.onAccepted});

  @override
  State<ContractGateScreen> createState() => _ContractGateScreenState();
}

class _ContractGateScreenState extends State<ContractGateScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final ScrollController _contractScrollController = ScrollController();

  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ContractProvider>();
      // Verifica primeiro se já assinou — se sim, pula direto para próxima tela
      final alreadyAccepted = await provider.checkIfAlreadyAccepted();
      if (alreadyAccepted && mounted) {
        widget.onAccepted();
        return;
      }
      // Caso contrário, carrega o contrato para exibir
      provider.fetchLatestContract();
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _contractScrollController.dispose();
    super.dispose();
  }

  Future<void> _submitAcceptance() async {
    final contractProvider = context.read<ContractProvider>();
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve aceitar a cláusula de não-subordinação primeiro.')),
      );
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, assine o documento na caixa branca para validar judicialmente.')),
      );
      return;
    }

    final exportedImage = await _signatureController.toPngBytes();
    final base64Signature = base64Encode(exportedImage!);

    final success = await contractProvider.acceptContract(base64Signature);
    
    if (success && mounted) {
      widget.onAccepted();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(contractProvider.errorMessage ?? 'Erro no aceite.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Aspectos Legais', style: theme.textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: const [LogoutButton(color: AppColors.primary)],
      ),
      body: Consumer<ContractProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.latestContract == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.latestContract == null) {
            return Center(child: Text(provider.errorMessage!));
          }

          final content = provider.latestContract?['content'] ?? 'Nenhum termo gerado.';
          final version = provider.latestContract?['version'] ?? 'V-?';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Card ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gavel_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Contrato Autônomo',
                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Versão do Termo: $version',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Contract Content ──────────────────────────────────────
                Text('Termos de Adesão', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Scrollbar(
                    controller: _contractScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _contractScrollController,
                      child: Text(
                        content,
                        style: const TextStyle(height: 1.6, color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Disclaimer Checkbox ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _agreedToTerms ? AppColors.secondary.withOpacity(0.05) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _agreedToTerms ? AppColors.secondary.withOpacity(0.2) : const Color(0xFFF1F5F9)),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      'Declaro estar ciente de minha autonomia profissional, isenta de vínculo empregatício ou subordinação.',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    value: _agreedToTerms,
                    activeColor: AppColors.secondary,
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Signature Area ────────────────────────────────────────
                Text('Assinatura Digital', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Signature(
                        controller: _signatureController,
                        height: 180,
                        backgroundColor: Colors.white,
                      ),
                      Container(
                        color: const Color(0xFFF8FAFC),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('LIMPAR'),
                              onPressed: () => _signatureController.clear(),
                              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // ── Submit Button ─────────────────────────────────────────
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _submitAcceptance,
                  child: provider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ASSINAR E FIRMAR CONTRATO'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
