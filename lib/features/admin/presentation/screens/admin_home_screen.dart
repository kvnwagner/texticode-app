import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/usuario_repository.dart';
import '../widgets/new_user_sheet.dart';
import '../widgets/user_action_sheet.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _repo = UsuarioRepository();
  List<Usuario> _usuarios = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getUsuarios();
      if (!mounted) return;
      setState(() => _usuarios = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Usuario> get _filtrados {
    if (_query.trim().isEmpty) return _usuarios;
    final q = _query.toLowerCase();
    return _usuarios
        .where((u) =>
    u.nombreCompleto.toLowerCase().contains(q) ||
        (u.correo ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = _usuarios.length;
    final activos = _usuarios.where((u) => u.isActivo).length;
    final operarios = _usuarios.where((u) => u.isOperario).length;
    final clientes = _usuarios.where((u) => u.isCliente).length;

    return Container(
      color: AppColors.pageBg,
      child: Stack(
        children: [
          _loading
              ? const Center(
              child: CircularProgressIndicator(color: AppColors.navy))
              : _error != null
              ? _buildError()
              : RefreshIndicator(
            color: AppColors.navy,
            onRefresh: _cargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _buildSearch(),
                _buildStats(total, activos, operarios, clientes),
                _buildSectionHeader(
                    'Operarios y Clientes', _filtrados.length),
                if (_filtrados.isEmpty) _buildEmpty(),
                ..._filtrados.map(_buildUserTile),
                const SizedBox(height: 130),
              ],
            ),
          ),
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppColors.navy,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => NewUserSheet(onCreated: _cargar),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.searchBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 18, color: AppColors.textFaint),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar usuarios...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.inputText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIX: se cambió GridView.count(childAspectRatio: 2.5) por
  // GridView.builder con SliverGridDelegateWithFixedCrossAxisCount y
  // mainAxisExtent fijo (78px). Antes, la altura de cada card dependía
  // del ancho disponible (childAspectRatio), y en ciertos tamaños de
  // pantalla esa altura calculada quedaba por debajo del contenido real
  // (número + spacing + label), causando el RenderFlex overflow de 2.5px.
  // Con mainAxisExtent la altura es fija y predecible sin importar el
  // ancho de pantalla.
  Widget _buildStats(int total, int activos, int operarios, int clientes) {
    final items = <_StatItem>[
      _StatItem('Total', total, Icons.people_outline, AppColors.iconTotal),
      _StatItem('Activos', activos, Icons.verified_user_outlined, AppColors.iconActive),
      _StatItem('Operarios', operarios, Icons.shield_outlined, AppColors.iconOp),
      _StatItem('Clientes', clientes, Icons.person_outline, AppColors.iconClient),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 78, // altura fija de cada card
        ),
        itemBuilder: (context, index) => _buildStatCard(items[index]),
      ),
    );
  }

  Widget _buildStatCard(_StatItem s) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(width: 3.5, color: s.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${s.value}',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: s.color)),
                          const SizedBox(height: 3),
                          Text(s.label,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: s.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon, size: 16, color: s.color),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)),
            child: Text('$count',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Usuario u) {
    final av = AppColors.avatarPalette[u.idUsuario % AppColors.avatarPalette.length];
    final isOp = u.isOperario;
    final badgeBg =
    isOp ? AppColors.badgeOpBlueBg : (u.isAdmin ? AppColors.badgeAdminBg : AppColors.badgeClientBg);
    final badgeText = isOp
        ? AppColors.badgeOpBlueText
        : (u.isAdmin ? AppColors.badgeAdminText : AppColors.badgeClientText);
    final roleLabel = u.isAdmin ? 'Administrador' : (isOp ? 'Operario' : 'Cliente');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(initials: u.initials, size: 38, bg: av['bg']!, text: av['text']!),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          u.nombreCompleto,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration:
                        BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                        child: Text(roleLabel,
                            style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.bold, color: badgeText)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    u.correo ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(u.telefono ?? '',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      const Text('·', style: TextStyle(color: AppColors.cardBorder)),
                      const SizedBox(width: 6),
                      Text(u.fechaCorta,
                          style: const TextStyle(fontSize: 9, color: AppColors.textFaint)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => UserActionSheet(usuario: u, onChanged: _cargar),
              ),
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppColors.searchBg,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.more_vert, size: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: const [
          Icon(Icons.search_off, size: 32, color: AppColors.textFaint),
          SizedBox(height: 8),
          Text('No se encontraron usuarios',
              style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 4),
            const Text(
              'Verifica que tu backend Express siga corriendo en el puerto 3001\ny que la IP en api_constants.dart sea correcta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textFaint, fontSize: 11),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}