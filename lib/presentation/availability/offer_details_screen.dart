import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class OfferDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> offer;

  const OfferDetailsScreen({super.key, required this.offer});

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

  String _translateShiftTime(String shiftCode) {
    switch (shiftCode) {
      case 'MORNING': return 'Manhã';
      case 'AFTERNOON': return 'Tarde';
      case 'NIGHT': return 'Noite';
      default: return shiftCode;
    }
  }

  IconData _getShiftIcon(String shiftCode) {
    switch (shiftCode) {
      case 'MORNING': return Icons.wb_sunny_outlined;
      case 'AFTERNOON': return Icons.wb_cloudy_outlined;
      case 'NIGHT': return Icons.nights_stay_outlined;
      default: return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(offer['status']);
    final shifts = offer['shifts'] as List<dynamic>? ?? [];
    final substitute = offer['substitute'];

    final Map<String, List<dynamic>> groupedShifts = {};
    for (var shift in shifts) {
      final date = shift['date'] as String;
      groupedShifts.putIfAbsent(date, () => []).add(shift);
    }
    final sortedDates = groupedShifts.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Detalhes da Oferta', style: theme.textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status Banner ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Text(
                    _translateStatus(offer['status']).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Referência #${offer['id'].toString().padLeft(4, '0')}',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Summary Card ────────────────────────────────────────────────
            Text('Resumo da Agenda', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _detailItem(Icons.calendar_today_rounded, 'Período', '${_formatDate(offer['startDate'])} — ${_formatDate(offer['endDate'])}'),
                  const Divider(height: 32, color: Color(0xFFF1F5F9)),
                  _detailItem(Icons.history_rounded, 'Total de Turnos', '${shifts.length} selecionados'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Detailed Shifts ─────────────────────────────────────────────
            Text('Turnos Selecionados', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            ...sortedDates.map((dateStr) {
              final dailyShifts = groupedShifts[dateStr]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(DateTime.parse(dateStr)),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dailyShifts.map((shift) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(100)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getShiftIcon(shift['shiftTime']), size: 14, color: const Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Text(
                                _translateShiftTime(shift['shiftTime']),
                                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),

            // ── Substitute Section ──────────────────────────────────────────
            if (substitute != null) ...[
              const SizedBox(height: 32),
              Text('Delegação Autônoma', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    _detailItem(Icons.person_outline_rounded, 'Substituto', substitute['name'] ?? ''),
                    const Divider(height: 32, color: Color(0xFFF1F5F9)),
                    _detailItem(Icons.badge_outlined, 'Documento', substitute['document'] ?? ''),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
