import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';

class AdminCreateOfferScreen extends StatefulWidget {
  const AdminCreateOfferScreen({super.key});

  @override
  State<AdminCreateOfferScreen> createState() => _AdminCreateOfferScreenState();
}

class _AdminCreateOfferScreenState extends State<AdminCreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController(text: 'SP');
  final _numberCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();
  
  String _category = 'Cuidador(a) de Idosos';
  final List<String> _categories = [
    'Cuidador(a) de Idosos',
    'Auxiliar de Enfermagem',
    'Técnico(a) em Enfermagem',
    'Enfermeiro(a)'
  ];

  bool _isLoadingCep = false;

  Future<void> _lookupCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return;

    setState(() => _isLoadingCep = true);
    try {
      final response = await Dio().get('https://viacep.com.br/ws/$cleanCep/json/');
      final data = response.data;
      if (data != null && data['erro'] != true) {
        setState(() {
          _addressCtrl.text = data['logradouro'] ?? '';
          _neighborhoodCtrl.text = data['bairro'] ?? '';
          _cityCtrl.text = data['localidade'] ?? '';
          _stateCtrl.text = data['uf'] ?? 'SP';
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar CEP: $e');
    } finally {
      setState(() => _isLoadingCep = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nova Demanda'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Defina os detalhes do plantão para os prestadores.', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 32),
              
              _buildFieldLabel('Título do Serviço'),
              TextFormField(
                controller: _titleCtrl,
                decoration: _inputDec('Ex: Plantão 12h - Particular'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 20),

              _buildFieldLabel('Categoria Necessária'),
              DropdownButtonFormField<String>(
                value: _category,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration: _inputDec(''),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Valor (R\$)'),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec('0.00'),
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Data do Início'),
                        TextFormField(
                          controller: _dateCtrl,
                          readOnly: true,
                          onTap: _selectDate,
                          decoration: _inputDec('Selecionar Data').copyWith(
                            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                          ),
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildFieldLabel('CEP (Auto-completar)'),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: _inputDec('00000-000').copyWith(
                  suffixIcon: _isLoadingCep 
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search_rounded, color: AppColors.primary),
                ),
                onChanged: (v) => _lookupCep(v),
              ),
              const SizedBox(height: 20),

              _buildFieldLabel('Endereço (Rua)'),
              TextFormField(
                controller: _addressCtrl,
                readOnly: true,
                decoration: _inputDec('').copyWith(filled: true, fillColor: const Color(0xFFF1F5F9)),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Número'),
                        TextFormField(
                          controller: _numberCtrl, 
                          decoration: _inputDec('Ex: 123'),
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Complemento'),
                        TextFormField(controller: _complementCtrl, decoration: _inputDec('Apto 42')),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: adminProv.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: adminProv.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('PUBLICAR DEMANDA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final success = await context.read<AdminProvider>().createOffer({
      'title': _titleCtrl.text,
      'description': 'Plantão solicitado via painel administrativo.',
      'category': _category,
      'price': double.parse(_priceCtrl.text),
      'date': _dateCtrl.text,
      'startTime': '08:00',
      'endTime': '20:00',
      'address': "${_addressCtrl.text}, ${_numberCtrl.text}",
      'neighborhood': _neighborhoodCtrl.text,
      'city': _cityCtrl.text,
      'state': _stateCtrl.text,
      'complement': _complementCtrl.text,
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demanda publicada com sucesso!')));
      Navigator.pop(context);
    }
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
    );
  }

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1)),
    );
  }
}
