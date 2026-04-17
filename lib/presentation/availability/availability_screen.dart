import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/availability_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/logout_button.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final Map<int, List<String>> _selectedShifts = {};
  
  bool _includeSubstitute = false;
  final _substituteNameCtrl = TextEditingController();
  final _substituteDocumentCtrl = TextEditingController();

  // Simula 7 dias a partir de hoje
  final DateTime _startDate = DateTime.now();
  late final DateTime _endDate = _startDate.add(const Duration(days: 6));

  @override
  void dispose() {
    _substituteNameCtrl.dispose();
    _substituteDocumentCtrl.dispose();
    super.dispose();
  }

  void _toggleShift(int dayOffset, String shift) {
    setState(() {
      _selectedShifts.putIfAbsent(dayOffset, () => []);
      if (_selectedShifts[dayOffset]!.contains(shift)) {
        _selectedShifts[dayOffset]!.remove(shift);
      } else {
        _selectedShifts[dayOffset]!.add(shift);
      }
    });
  }

  void _showLegalDisclaimerPopup() {
    bool localDisclaimerCheck = false;

    // Constrói o DTO de turnos
    final List<Map<String, String>> mappedShifts = [];
    _selectedShifts.forEach((offset, shifts) {
      final dateStr = _startDate.add(Duration(days: offset)).toIso8601String().split('T').first;
      for (var shift in shifts) {
        mappedShifts.add({'date': dateStr, 'shiftTime': shift});
      }
    });

    if (mappedShifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione pelo menos um turno.')));
      return;
    }

    Map<String, String>? substituteData;
    if (_includeSubstitute && _substituteNameCtrl.text.isNotEmpty && _substituteDocumentCtrl.text.isNotEmpty) {
      substituteData = {
        'name': _substituteNameCtrl.text,
        'document': _substituteDocumentCtrl.text,
      };
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return AlertDialog(
              title: const Text('Confirmação de Autonomia Legal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ao enviar os turnos acima selecionados por VOCÊ, declaro irrevogavelmente que esta oferta é de exclusividade e iniciativa própria (livre vontade), isenta de qualquer vínculo de subordinação hierárquica à Cuida Tech ou à família.'),
                  const SizedBox(height: 15),
                  CheckboxListTile(
                    title: const Text('Concordo e confirmo o envio livre da oferta.'),
                    value: localDisclaimerCheck,
                    onChanged: (val) => setPopupState(() => localDisclaimerCheck = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: !localDisclaimerCheck ? null : () async {
                    Navigator.of(ctx).pop(); // fecha popup
                    await _submit(mappedShifts, substituteData);
                  },
                  child: const Text('ENVIAR OFERTA'),
                )
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _submit(List<Map<String, String>> shifts, Map<String, String>? substitute) async {
    final provider = context.read<AvailabilityProvider>();
    final success = await provider.submitAvailability(
      startDate: _startDate,
      endDate: _endDate,
      shifts: shifts,
      substitute: substitute,
      legalDisclaimerAccepted: true // Só roda após checkbox no popup
    );

    if (success && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sua agenda autônoma foi enviada para central e será listada aos parceiros!')));
       // Clear 
       setState(() {
         _selectedShifts.clear();
         _includeSubstitute = false;
         _substituteNameCtrl.clear();
         _substituteDocumentCtrl.clear();
       });
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Erro.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AvailabilityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oferta de Plantões'),
        backgroundColor: Colors.white,
        actions: const [LogoutButton(color: AppColors.primaryBlue)],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monte sua escala', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Selecione abaixo os plantões que você deseja oferecer nos próximos 7 dias.', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Gerador Visual de Linhas de Dias
                  ...List.generate(7, (index) {
                    final currDate = _startDate.add(Duration(days: index));
                    final day = currDate.day.toString().padLeft(2, '0');
                    final month = currDate.month.toString().padLeft(2, '0');
                    final dateLabel = '$day/$month';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60, 
                            child: Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue))
                          ),
                          Expanded(child: _buildShiftChip(index, 'MORNING', 'Manhã', Icons.wb_sunny_outlined)),
                          Expanded(child: _buildShiftChip(index, 'AFTERNOON', 'Tarde', Icons.wb_cloudy_outlined)),
                          Expanded(child: _buildShiftChip(index, 'NIGHT', 'Noite', Icons.nights_stay_outlined)),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      const Icon(Icons.group_add_outlined, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Text('Delegação Autônoma', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Irei enviar um substituto direto de minha equipe na minha ausência?', style: TextStyle(fontSize: 14)),
                      value: _includeSubstitute,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (val) => setState(() => _includeSubstitute = val),
                    ),
                  ),

                  if (_includeSubstitute) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _substituteNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nome do Substituto', prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _substituteDocumentCtrl,
                      decoration: const InputDecoration(labelText: 'CPF do Substituto', prefixIcon: Icon(Icons.badge_outlined)),
                    ),
                  ],

                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _showLegalDisclaimerPopup,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('REVISAR E ENVIAR MINHA AGENDA'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildShiftChip(int dayOffset, String shiftCode, String label, IconData icon) {
    final isSelected = _selectedShifts[dayOffset]?.contains(shiftCode) ?? false;
    return GestureDetector(
      onTap: () => _toggleShift(dayOffset, shiftCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
