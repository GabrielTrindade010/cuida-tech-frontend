import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/logout_button.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List _availabilities = [];
  List _users = [];
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  String _filter = 'PENDING';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailabilities();
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailabilities() async {
    setState(() => _isLoading = true);
    try {
      final queryParams = _filter.isNotEmpty ? {'status': _filter} : <String, dynamic>{};
      final r = await DioClient.instance
          .get('/admin/availabilities', queryParameters: queryParams);
      setState(() => _availabilities = r.data is List ? r.data : []);
    } catch (e) {
      debugPrint('Erro ao carregar ofertas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final r = await DioClient.instance.get('/admin/users');
      setState(() => _users = r.data is List ? r.data : []);
    } catch (e) {
      debugPrint('Erro ao carregar users: $e');
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _updateStatus(int id, String action) async {
    try {
      await DioClient.instance.post('/admin/availabilities/$id/$action');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(action == 'accept' ? '✅ Oferta aceita' : '❌ Oferta recusada'),
        backgroundColor: action == 'accept' ? AppColors.primaryGreen : Colors.redAccent,
      ));
      _loadAvailabilities();
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.response?.data['message'] ?? 'Erro'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  String _shiftLabel(String s) =>
      s == 'MORNING' ? '☀️ Manhã' : s == 'AFTERNOON' ? '🌤 Tarde' : '🌙 Noite';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            actions: const [LogoutButton(color: Colors.white)],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Central de Gestão',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_availabilities.length} ofertas pendentes · ${_users.length} prestadores',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.secondary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: const Color(0xFF94A3B8),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'OFERTAS DE SERVIÇO'),
                    Tab(text: 'PRESTADORES'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: Container(
          color: Colors.white,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAvailabilitiesTab(),
              _buildUsersTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilitiesTab() {
    return Column(
      children: [
        // ── Filter Section ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FilterChip(
                  label: 'Pendentes',
                  selected: _filter == 'PENDING',
                  color: Colors.orange,
                  onTap: () { setState(() => _filter = 'PENDING'); _loadAvailabilities(); }),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Aceitas',
                  selected: _filter == 'ACCEPTED',
                  color: AppColors.secondary,
                  onTap: () { setState(() => _filter = 'ACCEPTED'); _loadAvailabilities(); }),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Recusadas',
                  selected: _filter == 'REJECTED',
                  color: Colors.redAccent,
                  onTap: () { setState(() => _filter = 'REJECTED'); _loadAvailabilities(); }),
            ]),
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _availabilities.isEmpty
                  ? _buildEmptyState('Nenhuma oferta $_filter')
                  : RefreshIndicator(
                      onRefresh: _loadAvailabilities,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: _availabilities.length,
                        itemBuilder: (_, i) {
                          final a = _availabilities[i];
                          final user = a['user'] ?? {};
                          final shifts = (a['shifts'] as List?) ?? [];
                          final sub = a['substitute'];
                          final status = a['status'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.05),
                                      radius: 20,
                                      child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(user['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                          Text(user['professionalRegister'] ?? 'Sem registro', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    _StatusBadge(status: status),
                                  ]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),

                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: shifts.map<Widget>((s) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                                        child: Text(
                                          '${s['date']} · ${_shiftLabel(s['shiftTime'])}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  if (sub != null) ...[
                                    const SizedBox(height: 12),
                                    _infoBox('Substituto: ${sub['name']} · ${sub['document']}'),
                                  ],

                                  if (status == 'PENDING') ...[
                                    const SizedBox(height: 20),
                                    Row(children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _updateStatus(a['id'], 'reject'),
                                          style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Color(0xFFFEE2E2))),
                                          child: const Text('RECUSAR'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _updateStatus(a['id'], 'accept'),
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                                          child: const Text('ACEITAR'),
                                        ),
                                      ),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    if (_isLoadingUsers) return const Center(child: CircularProgressIndicator());
    if (_users.isEmpty) return _buildEmptyState('Nenhum prestador cadastrado');

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: _users.length,
        itemBuilder: (_, i) {
          final u = _users[i];
          final isAdmin = u['role'] == 'ADMIN';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isAdmin ? AppColors.primary.withOpacity(0.05) : AppColors.secondary.withOpacity(0.05),
                child: Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_outline_rounded, color: isAdmin ? AppColors.primary : AppColors.secondary),
              ),
              title: Text(u['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text('${u['email']}\n${u['professionalRegister'] ?? 'Sem registro'}', style: const TextStyle(fontSize: 12, height: 1.4)),
              isThreeLine: true,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: isAdmin ? AppColors.primary.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(u['role'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isAdmin ? AppColors.primary : AppColors.secondary)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade200),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    ),
  );

  Widget _infoBox(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
    ]),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : const Color(0xFFE2E8F0)),
          boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(color: selected ? Colors.white : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> map = {
      'PENDING': {'label': 'PENDENTE', 'color': Colors.orange},
      'ACCEPTED': {'label': 'ACEITA', 'color': AppColors.secondary},
      'REJECTED': {'label': 'RECUSADA', 'color': Colors.redAccent},
    };
    final data = map[status] ?? {'label': status, 'color': Colors.grey};
    final color = data['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(data['label'], style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}
