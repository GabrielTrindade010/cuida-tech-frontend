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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            actions: const [LogoutButton(color: Colors.white)],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient),
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 24,
                    right: 24,
                    bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Row(children: [
                      Icon(Icons.admin_panel_settings_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text('Painel Admin',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 6),
                    Text('${_availabilities.length} oferta(s) · ${_users.length} prestador(es)',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryGreen,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Ofertas de Plantão'),
                Tab(text: 'Prestadores'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAvailabilitiesTab(),
            _buildUsersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitiesTab() {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(16),
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
                color: AppColors.primaryGreen,
                onTap: () { setState(() => _filter = 'ACCEPTED'); _loadAvailabilities(); }),
            const SizedBox(width: 8),
            _FilterChip(
                label: 'Recusadas',
                selected: _filter == 'REJECTED',
                color: Colors.redAccent,
                onTap: () { setState(() => _filter = 'REJECTED'); _loadAvailabilities(); }),
          ]),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
              : _availabilities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Nenhuma oferta $_filter',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAvailabilities,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _availabilities.length,
                        itemBuilder: (_, i) {
                          final a = _availabilities[i];
                          final user = a['user'] ?? {};
                          final shifts = (a['shifts'] as List?) ?? [];
                          final sub = a['substitute'];
                          final status = a['status'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.person_rounded,
                                          color: AppColors.primaryBlue, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(user['name'] ?? '-',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15)),
                                          Text(user['professionalRegister'] ?? 'Sem registro',
                                              style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    _StatusBadge(status: status),
                                  ]),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),

                                  // Turnos
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: shifts.map<Widget>((s) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue.withOpacity(0.07),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${s['date']}  ${_shiftLabel(s['shiftTime'])}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  if (sub != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryGreen.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(children: [
                                        const Icon(Icons.swap_horiz_rounded,
                                            color: AppColors.primaryGreen, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Substituto: ${sub['name']} · ${sub['document']}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primaryGreen,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ]),
                                    ),
                                  ],

                                  // Ações (só PENDING)
                                  if (status == 'PENDING') ...[
                                    const SizedBox(height: 14),
                                    Row(children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _updateStatus(a['id'], 'reject'),
                                          icon: const Icon(Icons.close_rounded,
                                              size: 16, color: Colors.redAccent),
                                          label: const Text('Recusar',
                                              style: TextStyle(
                                                  color: Colors.redAccent)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                                color: Colors.redAccent),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _updateStatus(a['id'], 'accept'),
                                          icon: const Icon(Icons.check_rounded,
                                              size: 16),
                                          label: const Text('Aceitar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryGreen,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
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
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Nenhum prestador cadastrado',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (_, i) {
                final u = _users[i];
                final isAdmin = u['role'] == 'ADMIN';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppColors.primaryBlue.withOpacity(0.1)
                            : AppColors.primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAdmin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.person_rounded,
                        color: isAdmin
                            ? AppColors.primaryBlue
                            : AppColors.primaryGreen,
                        size: 22,
                      ),
                    ),
                    title: Text(u['name'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${u['email']}\n${u['professionalRegister'] ?? 'Sem registro'}',
                        style: const TextStyle(fontSize: 12)),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppColors.primaryBlue.withOpacity(0.1)
                            : AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        u['role'],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAdmin
                                ? AppColors.primaryBlue
                                : AppColors.primaryGreen),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : color,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
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
      'PENDING': {'label': 'Pendente', 'color': Colors.orange},
      'ACCEPTED': {'label': 'Aceita', 'color': AppColors.primaryGreen},
      'REJECTED': {'label': 'Recusada', 'color': Colors.redAccent},
    };
    final data = map[status] ?? {'label': status, 'color': Colors.grey};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (data['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(data['label'],
          style: TextStyle(
              color: data['color'] as Color,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }
}
