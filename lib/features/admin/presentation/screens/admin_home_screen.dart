import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/usuario_repository.dart';
import '../widgets/new_user_sheet.dart';
import '../widgets/user_action_sheet.dart';

/// Filtro activo elegido desde las cards de Total/Administradores/Operarios/
/// Clientes. Mismo patrón que _FiltroEstadoOrden en produccion_screen.
enum _FiltroUsuario { todos, administradores, operarios, clientes }

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

  /// Filtro activo elegido desde las cards de Total/Administradores/Operarios/
  /// Clientes. Las 4 cards siempre se muestran; solo cambia qué
  /// usuarios aparecen debajo.
  _FiltroUsuario _filtro = _FiltroUsuario.todos;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Parsea Usuario.fechaRegistro (String? ISO) a DateTime para poder
  /// ordenar. Si es nulo o no se puede parsear, se usa una fecha
  /// mínima para que ese usuario quede al final en vez de romper el
  /// sort o quedar primero por error.
  DateTime _fechaRegistroDt(Usuario u) {
    if (u.fechaRegistro == null || u.fechaRegistro!.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(u.fechaRegistro!) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getUsuarios();
      // Los más nuevos primero según Fecha_Registro, así el usuario
      // recién creado aparece de primeras en la lista sin necesidad
      // de scrollear hasta abajo. fechaRegistro es un String? ISO, se
      // parsea a DateTime para comparar bien (si viene nulo o
      // inválido, se manda al final con una fecha mínima).
      data.sort((a, b) => _fechaRegistroDt(b).compareTo(_fechaRegistroDt(a)));
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
    Iterable<Usuario> base = _usuarios;
    switch (_filtro) {
      case _FiltroUsuario.todos:
        break;
      case _FiltroUsuario.administradores:
        base = base.where((u) => u.isAdmin);
        break;
      case _FiltroUsuario.operarios:
        base = base.where((u) => u.isOperario);
        break;
      case _FiltroUsuario.clientes:
        base = base.where((u) => u.isCliente);
        break;
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      base = base.where((u) =>
      u.nombreCompleto.toLowerCase().contains(q) ||
          (u.correo ?? '').toLowerCase().contains(q));
    }
    return base.toList();
  }

  String get _tituloListaFiltrada {
    switch (_filtro) {
      case _FiltroUsuario.todos:
        return 'Todos los Usuarios';
      case _FiltroUsuario.administradores:
        return 'Administradores';
      case _FiltroUsuario.operarios:
        return 'Operarios';
      case _FiltroUsuario.clientes:
        return 'Clientes';
    }
  }

  void _toggleFiltro(_FiltroUsuario f) {
    setState(() => _filtro = _filtro == f ? _FiltroUsuario.todos : f);
  }

  @override
  Widget build(BuildContext context) {
    final total = _usuarios.length;
    final administradores = _usuarios.where((u) => u.isAdmin).length;
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
                _buildStats(total, administradores, operarios, clientes),
                _buildSectionHeader(_tituloListaFiltrada, _filtrados.length),
                if (_filtrados.isEmpty) _buildEmpty(),
                ..._filtrados.map(_buildUserTile),
                const SizedBox(height: 130),
              ],
            ),
          ),
          Positioned(
             bottom: 20,
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

  // ✅ FIX "universal": la altura fija de 78px funcionaba bien en un
  // celular, pero en otros (distinto tamaño de fuente del sistema,
  // distinta densidad de píxeles) el contenido de la card (número +
  // spacing + label) terminaba siendo más alto que esos 78px, causando
  // el RenderFlex overflow. Ahora la altura se calcula en base al
  // textScaler del dispositivo (MediaQuery), así crece si el usuario
  // tiene fuente grande y se mantiene compacta si no. Además, el
  // número dentro de cada card va envuelto en un FittedBox que lo
  // reduce automáticamente si por cualquier motivo no entra en el
  // espacio disponible, así que nunca puede generar overflow sin
  // importar el tamaño o densidad de pantalla del emulador/celular.
  Widget _buildStats(int total, int administradores, int operarios, int clientes) {
    final items = <_StatItem>[
      _StatItem('Total', total, Icons.people_outline, AppColors.iconTotal, _FiltroUsuario.todos),
      _StatItem('Administradores', administradores, Icons.admin_panel_settings_outlined,
          AppColors.iconActive, _FiltroUsuario.administradores),
      _StatItem('Operarios', operarios, Icons.shield_outlined, AppColors.iconOp, _FiltroUsuario.operarios),
      _StatItem('Clientes', clientes, Icons.person_outline, AppColors.iconClient, _FiltroUsuario.clientes),
    ];

    // Escala de fuente del dispositivo (accesibilidad / distintos celulares).
    // Se limita entre 1.0 y 1.3 para que la card crezca lo necesario sin
    // desarmar el layout en pantallas con textos muy agrandados.
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final cardHeight = 78 * textScale.clamp(1.0, 1.3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: cardHeight, // altura responsive, nunca fija
        ),
        itemBuilder: (context, index) => _buildStatCard(items[index]),
      ),
    );
  }

  Widget _buildStatCard(_StatItem s) {
    final activa = _filtro == s.filtro;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleFiltro(s.filtro),
          child: Container(
            decoration: BoxDecoration(
              color: activa ? s.color.withValues(alpha: 0.07) : AppColors.pageBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activa ? s.color : AppColors.cardBorder,
                width: activa ? 1.4 : 1,
              ),
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
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('${s.value}',
                                    style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: s.color)),
                              ),
                              const SizedBox(height: 3),
                              Text(s.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                            color: s.color.withValues(alpha: activa ? 0.16 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            activa ? Icons.check_rounded : s.icon,
                            size: 16,
                            color: s.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final filtroActivo = _filtro != _FiltroUsuario.todos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          if (filtroActivo) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)),
              child: Text('$count',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
          const Spacer(),
          if (filtroActivo)
            GestureDetector(
              onTap: () => setState(() => _filtro = _FiltroUsuario.todos),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.searchBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 11, color: AppColors.textMuted),
                    SizedBox(width: 4),
                    Text('Quitar filtro',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Usuario u) {
    final av = AppColors.avatarPalette[u.idUsuario % AppColors.avatarPalette.length];
    final isOp = u.isOperario;
    // Mismo gris que .badge-role.administrador en GestionUsuarios.vue (web),
    // para que el badge de Administrador se vea igual en ambas plataformas.
    const adminBadgeBg = Color(0xFFF3F4F6);
    const adminBadgeText = Color(0xFF374151);
    final badgeBg =
    isOp ? AppColors.badgeOpBlueBg : (u.isAdmin ? adminBadgeBg : AppColors.badgeClientBg);
    final badgeText = isOp
        ? AppColors.badgeOpBlueText
        : (u.isAdmin ? adminBadgeText : AppColors.badgeClientText);
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
                  Text(
                    u.nombreCompleto,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
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
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppColors.searchBg,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
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
  final _FiltroUsuario filtro;
  _StatItem(this.label, this.value, this.icon, this.color, this.filtro);
}