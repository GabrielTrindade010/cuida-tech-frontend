import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'take_picture_screen.dart';
import 'liveness_camera_screen.dart';
import 'auth_gate.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageCtrl = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 5;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.registrationStep > 0 && auth.registrationStep < 5) {
      _currentStep = auth.registrationStep;
      _loadPreviousData();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageCtrl.jumpToPage(_currentStep);
      });
    }
  }

  Future<void> _loadPreviousData() async {
    final auth = context.read<AuthProvider>();
    final data = await auth.getProfile();
    if (data != null) {
      setState(() {
        _nameCtrl.text    = data['name'] ?? '';
        _emailCtrl.text   = data['email'] ?? '';
        _docCtrl.text     = data['document'] ?? '';
        _phoneCtrl.text   = data['phone'] ?? '';
        _category         = data['category'];
        _profRegCtrl.text = data['professionalRegister'] ?? '';
        _cepCtrl.text          = data['cep'] ?? '';
        _streetCtrl.text       = data['street'] ?? '';
        _neighborhoodCtrl.text = data['neighborhood'] ?? '';
        _cityCtrl.text         = data['city'] ?? '';
        _stateCtrl.text        = data['state'] ?? '';
        _numberCtrl.text       = data['addressNumber'] ?? '';
        _complementCtrl.text   = data['complement'] ?? '';
      });
    }
  }

  // ── Step 1: Dados Pessoais ──────────────────────────────────────────────
  final _step1Key    = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _docCtrl     = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _pwdCtrl     = TextEditingController();
  bool _docIsCpf     = true;
  bool _obscurePwd   = true;

  // ── Step 2: Especialidade ───────────────────────────────────────────────
  final _step2Key    = GlobalKey<FormState>();
  String? _category;
  final _profRegCtrl = TextEditingController();
  final List<String> _categories = ['Enfermeiro(a)', 'Técnico(a) em Enfermagem', 'Cuidador(a) de Idosos', 'Fisioterapeuta'];

  // ── Step 3: Endereço ───────────────────────────────────────────────────
  final _step3Key        = GlobalKey<FormState>();
  final _cepCtrl          = TextEditingController();
  final _streetCtrl       = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _cityCtrl         = TextEditingController();
  final _stateCtrl        = TextEditingController();
  final _numberCtrl       = TextEditingController();
  final _complementCtrl   = TextEditingController();
  bool _loadingCep        = false;
  String? _cepError;

  // ── Step 4: Selfie ────────────────────────────────────────────────────
  String? _selfiePath;

  // ── Step 5: Contrato ──────────────────────────────────────────────────
  bool _contractChecked = false;
  final SignatureController _sigCtrl = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : AppColors.secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  Future<void> _goNext() async {
    final auth = context.read<AuthProvider>();
    bool valid = false;

    switch (_currentStep) {
      case 0:
        valid = _step1Key.currentState!.validate();
        if (valid) {
          final success = await auth.register(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            document: _docCtrl.text,
            phone: _phoneCtrl.text,
            password: _pwdCtrl.text,
          );
          if (success) await auth.login(_emailCtrl.text.trim(), _pwdCtrl.text);
          else { _showSnack(auth.errorMessage ?? 'Erro ao criar conta.', isError: true); return; }
        }
        break;

      case 1:
        valid = _step2Key.currentState!.validate();
        if (valid) {
          final success = await auth.updateRegistrationStep({
            'category': _category,
            'professionalRegister': _profRegCtrl.text.trim(),
            'registrationStep': 2,
          });
          if (!success) { _showSnack(auth.errorMessage ?? 'Erro ao salvar especialidade.', isError: true); return; }
        }
        break;

      case 2:
        valid = _step3Key.currentState!.validate();
        if (valid) {
          if (_cityCtrl.text.isEmpty) { _showSnack('Valide o CEP antes de continuar.', isError: true); return; }
          final success = await auth.updateRegistrationStep({
            'cep': _cepCtrl.text, 'street': _streetCtrl.text, 'neighborhood': _neighborhoodCtrl.text,
            'city': _cityCtrl.text, 'state': _stateCtrl.text, 'addressNumber': _numberCtrl.text.trim(),
            'complement': _complementCtrl.text.trim(), 'registrationStep': 3,
          });
          if (!success) { _showSnack(auth.errorMessage ?? 'Erro ao salvar endereço.', isError: true); return; }
        }
        break;

      case 3:
        if (_selfiePath == null) { _showSnack('Tire a selfie com seu documento.', isError: true); return; }
        final url = await auth.uploadFile(_selfiePath!);
        if (url == null) { _showSnack(auth.errorMessage ?? 'Erro ao enviar foto.', isError: true); return; }
        final success = await auth.updateRegistrationStep({'selfieUrl': url, 'registrationStep': 4});
        if (success) valid = true;
        else { _showSnack(auth.errorMessage ?? 'Erro ao salvar progresso.', isError: true); return; }
        break;

      case 4:
        await _doRegister();
        return;
    }

    if (!valid) return;
    setState(() => _currentStep++);
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _goBack() {
    if (_currentStep == 0) { Navigator.of(context).pop(); return; }
    setState(() => _currentStep--);
    _pageCtrl.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  Future<void> _takeSelfie() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const LivenessCameraScreen()),
    );
    if (result != null) setState(() => _selfiePath = result);
  }

  Future<void> _doRegister() async {
    if (!_contractChecked) { _showSnack('Aceite o Termo de Adesão.', isError: true); return; }
    if (_sigCtrl.isEmpty) { _showSnack('Assine o contrato.', isError: true); return; }

    final auth = context.read<AuthProvider>();
    final signatureData = await _sigCtrl.toPngBytes();
    if (signatureData == null) return;

    final tempDir = await getTemporaryDirectory();
    final signatureFile = File('${tempDir.path}/sig_${DateTime.now().millisecondsSinceEpoch}.png');
    await signatureFile.writeAsBytes(signatureData);

    final signatureUrl = await auth.uploadFile(signatureFile.path);
    if (signatureUrl == null) { _showSnack('Erro no upload da assinatura.', isError: true); return; }

    final success = await auth.acceptContract(signatureUrl);
    if (success) {
      _showSnack('Cadastro finalizado! Aguarde aprovação.');
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthGate()), (r) => false);
    } else {
      _showSnack(auth.errorMessage ?? 'Falha ao finalizar cadastro.', isError: true);
    }
  }

  // ─── CEP Lookup ────────────────────────────────────────────────────────────

  Future<void> _lookupCep(String raw) async {
    final cep = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;
    setState(() { _loadingCep = true; _cepError = null; });
    try {
      final res = await Dio().get('https://viacep.com.br/ws/$cep/json/');
      final data = res.data as Map<String, dynamic>;
      if (data.containsKey('erro')) setState(() => _cepError = 'CEP não encontrado.');
      else {
        setState(() {
          _streetCtrl.text       = data['logradouro'] ?? '';
          _neighborhoodCtrl.text = data['bairro'] ?? '';
          _cityCtrl.text         = data['localidade'] ?? '';
          _stateCtrl.text        = data['uf'] ?? '';
        });
      }
    } catch (_) { setState(() => _cepError = 'Erro ao buscar CEP.'); }
    finally { setState(() => _loadingCep = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: _goBack,
        ),
        title: Text(_stepTitle(), style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(theme),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [ _buildStep1(), _buildStep2(), _buildStep3(), _buildStep4(), _buildStep5() ],
              ),
            ),
            _buildFooter(isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(children: [
        Row(
          children: List.generate(_totalSteps, (index) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              decoration: BoxDecoration(
                color: index < _currentStep ? AppColors.secondary : index == _currentStep ? AppColors.primary : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Passo ${_currentStep + 1} de $_totalSteps', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
            Text('${((_currentStep + 1) / _totalSteps * 100).toInt()}% completo', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ]),
    );
  }

  Widget _buildFooter(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, -10))]),
      child: ElevatedButton(
        onPressed: isLoading ? null : _goNext,
        child: isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(_currentStep == _totalSteps - 1 ? 'FINALIZAR CADASTRO' : 'CONTINUAR'),
      ),
    );
  }

  String _stepTitle() {
    const titles = ['Dados Pessoais', 'Especialidade', 'Endereço', 'Identidade', 'Contrato'];
    return titles[_currentStep];
  }

  // ── Step Widgets ───────────────────────────────────────────────────────────

  Widget _buildStep1() => _stepWrapper(
    child: Form(
      key: _step1Key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _stepInfo('Comece preenchendo seus dados de acesso e identificação.'),
        TextFormField(controller: _nameCtrl, textCapitalization: TextCapitalization.words, validator: _vName, decoration: _dec('Nome Completo', Icons.person_outline_rounded)),
        const SizedBox(height: 16),
        TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, validator: _vEmail, decoration: _dec('E-mail profissional', Icons.mail_outline_rounded)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _docCtrl, keyboardType: TextInputType.number, inputFormatters: [_DocFmt()], validator: _vDoc,
          onChanged: (v) => setState(() => _docIsCpf = v.replaceAll(RegExp(r'[^0-9]'), '').length <= 11),
          decoration: _dec('CPF / CNPJ', Icons.badge_outlined, hint: _docIsCpf ? '000.000.000-00' : '00.000.000/0000-00'),
        ),
        const SizedBox(height: 16),
        TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, inputFormatters: [_PhoneFmt()], validator: _vPhone, decoration: _dec('WhatsApp', Icons.phone_android_rounded, hint: '(00) 00000-0000')),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pwdCtrl, obscureText: _obscurePwd, validator: _vPwd, onChanged: (_) => setState(() {}),
          decoration: _dec('Senha de acesso', Icons.lock_outline_rounded).copyWith(
            suffixIcon: IconButton(icon: Icon(_obscurePwd ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscurePwd = !_obscurePwd)),
          ),
        ),
        const SizedBox(height: 12),
        _PasswordStrengthIndicator(password: _pwdCtrl.text),
      ]),
    ),
  );

  Widget _buildStep2() => _stepWrapper(
    child: Form(
      key: _step2Key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _stepInfo('Selecione sua principal categoria de atuação.'),
        DropdownButtonFormField<String>(
          value: _category, decoration: _dec('Especialidade', Icons.psychology_outlined),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _category = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(controller: _profRegCtrl, textCapitalization: TextCapitalization.characters, validator: (v) => (v ?? '').isEmpty ? 'Obrigatório' : null, decoration: _dec('Registro Profissional', Icons.assignment_ind_outlined, hint: 'Ex: COREN-SP 123.456')),
        const SizedBox(height: 32),
        _infoBox('Seu registro será validado por nossa equipe de auditoria.'),
      ]),
    ),
  );

  Widget _buildStep3() => _stepWrapper(
    child: Form(
      key: _step3Key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _stepInfo('Informe seu endereço para triagem de chamados próximos.'),
        TextFormField(
          controller: _cepCtrl, keyboardType: TextInputType.number, inputFormatters: [_CepFmt()],
          onChanged: (v) { if (v.replaceAll(RegExp(r'[^0-9]'), '').length == 8) _lookupCep(v); },
          decoration: _dec('CEP', Icons.location_on_outlined).copyWith(
            suffixIcon: _loadingCep ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(controller: _streetCtrl, readOnly: true, decoration: _dec('Rua', Icons.map_outlined).copyWith(filled: true, fillColor: Colors.grey.shade50)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(flex: 2, child: TextFormField(controller: _neighborhoodCtrl, readOnly: true, decoration: _dec('Bairro', Icons.layers_outlined).copyWith(filled: true, fillColor: Colors.grey.shade50))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: _stateCtrl, readOnly: true, decoration: _dec('UF', Icons.flag_outlined).copyWith(filled: true, fillColor: Colors.grey.shade50))),
        ]),
        const SizedBox(height: 16),
        TextFormField(controller: _cityCtrl, readOnly: true, decoration: _dec('Cidade', Icons.location_city_outlined).copyWith(filled: true, fillColor: Colors.grey.shade50)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: TextFormField(controller: _numberCtrl, decoration: _dec('Nº', Icons.tag))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: TextFormField(controller: _complementCtrl, decoration: _dec('Complemento', Icons.add_business_outlined))),
        ]),
      ]),
    ),
  );

  Widget _buildStep4() => _stepWrapper(
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _stepInfo('Precisamos validar sua identidade. Tire uma selfie segurando seu documento.'),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: _takeSelfie,
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _selfiePath != null ? AppColors.secondary : const Color(0xFFE2E8F0), width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: _selfiePath != null
              ? ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.file(File(_selfiePath!), fit: BoxFit.cover))
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.face_retouching_natural_rounded, size: 64, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 16),
                  const Text('Abrir Câmera de Validação', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                ]),
        ),
      ),
      const SizedBox(height: 24),
      _infoBox('Certifique-se de que o documento esteja legível ao lado do seu rosto.'),
    ]),
  );

  Widget _buildStep5() => _stepWrapper(
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _stepInfo('Leia o contrato e assine no campo abaixo.'),
      Container(
        height: 220, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: SingleChildScrollView(child: Text(_contractText(), style: const TextStyle(fontSize: 12, height: 1.6, color: AppColors.textSecondary))),
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        value: _contractChecked, onChanged: (v) => setState(() => _contractChecked = v!),
        title: const Text('Concordo com os termos do contrato', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, activeColor: AppColors.primary,
      ),
      const SizedBox(height: 24),
      const Text('Assinatura Digital', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Container(
        height: 160,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withOpacity(0.1))),
        child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Signature(controller: _sigCtrl, backgroundColor: Colors.white)),
      ),
      TextButton(onPressed: () => _sigCtrl.clear(), child: const Text('Limpar Assinatura')),
    ]),
  );

  // ── UI Components ─────────────────────────────────────────────────────────

  Widget _stepWrapper({required Widget child}) => SingleChildScrollView(padding: const EdgeInsets.all(24), child: child);

  Widget _stepInfo(String text) => Padding(padding: const EdgeInsets.only(bottom: 24), child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)));

  Widget _infoBox(String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
    ]),
  );

  InputDecoration _dec(String label, IconData icon, {String? hint}) => InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon));

  // Validators (Dummy for briefness, should be real logic)
  String? _vName(String? v) => (v ?? '').length < 3 ? 'Nome muito curto' : null;
  String? _vEmail(String? v) => !(v ?? '').contains('@') ? 'E-mail inválido' : null;
  String? _vDoc(String? v) => (v ?? '').isEmpty ? 'Obrigatório' : null;
  String? _vPhone(String? v) => (v ?? '').length < 10 ? 'Telefone inválido' : null;
  String? _vPwd(String? v) => (v ?? '').length < 6 ? 'Mínimo 6 caracteres' : null;

  String _contractText() => 'CONTRATO DE PRESTAÇÃO DE SERVIÇOS...\n\nPor meio deste, o prestador concorda em atuar de forma autônoma...';
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const _PasswordStrengthIndicator({required this.password});
  @override
  Widget build(BuildContext context) {
    bool length = password.length >= 6;
    bool upper = password.contains(RegExp(r'[A-Z]'));
    bool number = password.contains(RegExp(r'[0-9]'));
    return Row(children: [
      _dot(length), _txt('6+ char'), const SizedBox(width: 12),
      _dot(upper), _txt('ABC'), const SizedBox(width: 12),
      _dot(number), _txt('123'),
    ]);
  }
  Widget _dot(bool ok) => Icon(Icons.circle, size: 8, color: ok ? AppColors.secondary : Colors.grey.shade300);
  Widget _txt(String t) => Padding(padding: const EdgeInsets.only(left: 4), child: Text(t, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)));
}

// Formatters stay the same as they are functional logic
class _DocFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll(RegExp(r'[^0-9]'), '');
    final l = d.length > 14 ? d.substring(0, 14) : d;
    final b = StringBuffer();
    if (l.length <= 11) {
      for (int i = 0; i < l.length; i++) {
        b.write(l[i]);
        if (i == 2 || i == 5) b.write('.');
        if (i == 8) b.write('-');
      }
    } else {
      for (int i = 0; i < l.length; i++) {
        b.write(l[i]);
        if (i == 1 || i == 4) b.write('.');
        if (i == 7) b.write('/');
        if (i == 11) b.write('-');
      }
    }
    final f = b.toString();
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

class _PhoneFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll(RegExp(r'[^0-9]'), '');
    final l = d.length > 11 ? d.substring(0, 11) : d;
    final b = StringBuffer();
    for (int i = 0; i < l.length; i++) {
      if (i == 0) b.write('(');
      b.write(l[i]);
      if (i == 1) b.write(') ');
      if (i == (l.length <= 10 ? 5 : 6)) b.write('-');
    }
    final f = b.toString();
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

class _CepFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll(RegExp(r'[^0-9]'), '');
    final l = d.length > 8 ? d.substring(0, 8) : d;
    final b = StringBuffer();
    for (int i = 0; i < l.length; i++) {
      b.write(l[i]);
      if (i == 4) b.write('-');
    }
    final f = b.toString();
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}
