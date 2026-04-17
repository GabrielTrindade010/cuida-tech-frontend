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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aspectos Legais'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: const [LogoutButton(color: AppColors.primaryBlue)],
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

          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gavel_rounded, color: AppColors.primaryBlue, size: 28),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Contrato Autônomo - $version',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: SingleChildScrollView(
                      child: Text(content, style: const TextStyle(height: 1.5, color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'Declaro estar ciente de que atuo como autônomo, não havendo subordinação, horários fixos impostos ou exclusividade.',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      value: _agreedToTerms,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (val) {
                        setState(() => _agreedToTerms = val ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Sua Assinatura Digital:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.grey.shade300, width: 2)
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Signature(
                      controller: _signatureController,
                      height: 160,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Limpar traços'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                      onPressed: () => _signatureController.clear(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _submitAcceptance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 2,
                    ),
                    icon: provider.isLoading ? const SizedBox() : const Icon(Icons.check_circle_outline),
                    label: provider.isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ASSINAR E FIRMAR CONTRATO'),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
