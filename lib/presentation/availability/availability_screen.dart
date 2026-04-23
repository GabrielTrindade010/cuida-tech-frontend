import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/availability_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/logout_button.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  // Map date without time -> list of shifts
  final Map<DateTime, List<String>> _selectedShifts = {};
  
  bool _includeSubstitute = false;
  final _substituteNameCtrl = TextEditingController();
  final _substituteDocumentCtrl = TextEditingController();
  String? _nameError;
  String? _cpfError;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalizeDate(DateTime.now());
  }

  @override
  void dispose() {
    _substituteNameCtrl.dispose();
    _substituteDocumentCtrl.dispose();
    super.dispose();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = _normalizeDate(selectedDay);
      _focusedDay = focusedDay;
    });
  }

  void _toggleShift(DateTime date, String shift) {
    setState(() {
      final key = _normalizeDate(date);
      _selectedShifts.putIfAbsent(key, () => []);
      if (_selectedShifts[key]!.contains(shift)) {
        _selectedShifts[key]!.remove(shift);
        if (_selectedShifts[key]!.isEmpty) {
          _selectedShifts.remove(key);
        }
      } else {
        _selectedShifts[key]!.add(shift);
      }
    });
  }

  void _showLegalDisclaimerPopup() {
    // Validate substitute if toggled on
    if (_includeSubstitute && !_validateSubstituteFields()) return;

    bool localDisclaimerCheck = false;

    // Constrói o DTO de turnos
    final List<Map<String, String>> mappedShifts = [];
    
    DateTime? minDate;
    DateTime? maxDate;

    _selectedShifts.forEach((date, shifts) {
      if (minDate == null || date.isBefore(minDate!)) minDate = date;
      if (maxDate == null || date.isAfter(maxDate!)) maxDate = date;

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      for (var shift in shifts) {
        mappedShifts.add({'date': dateStr, 'shiftTime': shift});
      }
    });

    if (mappedShifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione turnos em pelo menos uma data.')));
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
                     await _submit(mappedShifts, substituteData, minDate!, maxDate!);
                  },
                  child: const Text('ENVIAR OFERTA'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit(List<Map<String, String>> shifts, Map<String, String>? substitute, DateTime sDate, DateTime eDate) async {
    final provider = context.read<AvailabilityProvider>();
    final success = await provider.submitAvailability(
      startDate: sDate,
      endDate: eDate,
      shifts: shifts,
      substitute: substitute,
      legalDisclaimerAccepted: true 
    );

    if (success && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sua agenda autônoma foi enviada para central e será listada aos parceiros!')));
       setState(() {
         _selectedShifts.clear();
         _includeSubstitute = false;
         _substituteNameCtrl.clear();
         _substituteDocumentCtrl.clear();
         _selectedDay = _normalizeDate(DateTime.now());
       });
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Erro.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AvailabilityProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Oferta de Disponibilidade', style: theme.textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [LogoutButton(color: AppColors.primary)],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        const Text(
                          'Monte sua Agenda',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selecione as datas e turnos que deseja ofertar.',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // ── Modern Calendar ───────────────────────────────────────
                  Text('Selecione uma data', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 90)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                        leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                        rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), shape: BoxShape.circle),
                        todayTextStyle: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                        selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        markerDecoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                        outsideDaysVisible: false,
                      ),
                      eventLoader: (day) => _selectedShifts[_normalizeDate(day)] ?? [],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Shift Selection ───────────────────────────────────────
                  if (_selectedDay != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_selectedDay!),
                          style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildShiftChip(_selectedDay!, 'MORNING', 'Manhã', Icons.wb_sunny_rounded)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildShiftChip(_selectedDay!, 'AFTERNOON', 'Tarde', Icons.wb_cloudy_rounded)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildShiftChip(_selectedDay!, 'NIGHT', 'Noite', Icons.nights_stay_rounded)),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 32),
                  
                  // ── Delegation Section ────────────────────────────────────
                  Text('Delegação Autônoma', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _infoBox('Você pode indicar um colega de sua confiança para cobrir ausências eventuais.'),
                  const SizedBox(height: 16),
                  
                  Card(
                    child: SwitchListTile(
                      title: const Text('Vou indicar um substituto direto?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Sua equipe técnica de apoio.', style: TextStyle(fontSize: 12)),
                      value: _includeSubstitute,
                      activeColor: AppColors.secondary,
                      onChanged: (val) => setState(() => _includeSubstitute = val),
                    ),
                  ),

                  if (_includeSubstitute) ...[
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _substituteNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) { if (_nameError != null) setState(() => _nameError = null); },
                      decoration: _dec('Nome do Substituto', Icons.person_outline_rounded).copyWith(errorText: _nameError),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _substituteDocumentCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_CpfInputFormatter()],
                      onChanged: (_) { if (_cpfError != null) setState(() => _cpfError = null); },
                      decoration: _dec('CPF do Substituto', Icons.badge_outlined).copyWith(errorText: _cpfError, hintText: '000.000.000-00'),
                    ),
                  ],

                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _showLegalDisclaimerPopup,
                    child: const Text('REVISAR E ENVIAR OFERTA'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildShiftChip(DateTime date, String shiftCode, String label, IconData icon) {
    final key = _normalizeDate(date);
    final isSelected = _selectedShifts[key]?.contains(shiftCode) ?? false;
    
    return GestureDetector(
      onTap: () => _toggleShift(date, shiftCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
    ]),
  );

  InputDecoration _dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon));

  // ---------- Validation ----------
  bool _validateSubstituteFields() {
    bool valid = true;
    String? nameErr;
    String? cpfErr;

    final name = _substituteNameCtrl.text.trim();
    if (name.isEmpty) {
      nameErr = 'Informe o nome completo do substituto.';
      valid = false;
    } else if (name.split(' ').where((p) => p.isNotEmpty).length < 2) {
      nameErr = 'Informe o nome e sobrenome.';
      valid = false;
    } else if (RegExp(r'[0-9]').hasMatch(name)) {
      nameErr = 'O nome não pode conter números.';
      valid = false;
    }

    final cpfRaw = _substituteDocumentCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpfRaw.isEmpty) {
      cpfErr = 'Informe o CPF do substituto.';
      valid = false;
    } else if (cpfRaw.length != 11) {
      cpfErr = 'CPF inválido. Deve ter 11 dígitos.';
      valid = false;
    } else if (!_isValidCpf(cpfRaw)) {
      cpfErr = 'CPF inválido. Verifique os dígitos.';
      valid = false;
    }

    setState(() {
      _nameError = nameErr;
      _cpfError = cpfErr;
    });
    return valid;
  }

  bool _isValidCpf(String cpf) {
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
    int sum = 0;
    for (int i = 0; i < 9; i++) sum += int.parse(cpf[i]) * (10 - i);
    int rem = (sum * 10) % 11;
    if (rem == 10 || rem == 11) rem = 0;
    if (rem != int.parse(cpf[9])) return false;
    sum = 0;
    for (int i = 0; i < 10; i++) sum += int.parse(cpf[i]) * (11 - i);
    rem = (sum * 10) % 11;
    if (rem == 10 || rem == 11) rem = 0;
    return rem == int.parse(cpf[10]);
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digitsOnly.length > 11 ? digitsOnly.substring(0, 11) : digitsOnly;
    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('-');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
