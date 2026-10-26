import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../data/repositories/superadmin_repository.dart';

/// Filtro activo elegido desde las cards de Total/Activas/Inactivas.
/// Mismo patrón que _FiltroUsuario en AdminHomeScreen.
enum _Filtro { todos, activos, inactivos }

// Colores de estado (mismo criterio que los badges de rol en AdminHomeScreen).
const _verdeBadgeBg = Color(0xFFDCFCE7);
const _verdeBadgeText = Color(0xFF166534);
const _rojo = Color(0xFFDC2626);
const _rojoBadgeBg = Color(0xFFFEE2E2);
const _rojoBadgeText = Color(0xFF991B1B);

// Header: ajusta la ruta del logo a la que usa el header de Gestión de Usuarios
// (revisa la sección `assets:` de pubspec.yaml) y el título si quieres otro.
const _logoAsset = 'assets/images/logo.png';
const _tituloHeader = 'Panel Superadmin';

class SuperadminHomeScreen extends StatefulWidget {
  const SuperadminHomeScreen({super.key});

  @override
  State<SuperadminHomeScreen> createState() => _SuperadminHomeScreenState();
}

class _SuperadminHomeScreenState extends State<SuperadminHomeScreen> {
  final _repository = SuperadminRepository();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  int _section = 0; // 0 = Empresas, 1 = Roles
  List<Map<String, dynamic>> _items = [];
  String _query = '';
  _Filtro _filtro = _Filtro.todos;

  bool get _isEmpresa => _section == 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────── Datos ─────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = _isEmpresa
          ? await _repository.empresas()
          : await _repository.roles();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _cambiarSeccion(int i) {
    if (i == _section) return;
    _searchCtrl.clear();
    setState(() {
      _section = i;
      _query = '';
      _filtro = _Filtro.todos;
      _items = [];
    });
    _load();
  }

  bool _isActive(Map<String, dynamic> item) =>
      '${item['Estado'] ?? 'activo'}' == (_isEmpresa ? 'activa' : 'activo');

  int _idOf(Map<String, dynamic> item) =>
      ((_isEmpresa ? item['Id_Empresa'] : item['Id_Rol']) as num?)?.toInt() ??
      0;

  String _nameOf(Map<String, dynamic> item) =>
      '${item[_isEmpresa ? 'Nombre_Empresa' : 'Nombre_Rol'] ?? ''}';

  List<Map<String, dynamic>> get _filtrados {
    Iterable<Map<String, dynamic>> base = _items;
    switch (_filtro) {
      case _Filtro.todos:
        break;
      case _Filtro.activos:
        base = base.where(_isActive);
        break;
      case _Filtro.inactivos:
        base = base.where((i) => !_isActive(i));
        break;
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      base = base.where((i) =>
          _nameOf(i).toLowerCase().contains(q) ||
          '${i['Slug'] ?? ''}'.toLowerCase().contains(q));
    }
    return base.toList();
  }

  String get _tituloListaFiltrada {
    switch (_filtro) {
      case _Filtro.todos:
        return _isEmpresa ? 'Todas las Empresas' : 'Todos los Roles';
      case _Filtro.activos:
        return _isEmpresa ? 'Empresas Activas' : 'Roles Activos';
      case _Filtro.inactivos:
        return _isEmpresa ? 'Empresas Inactivas' : 'Roles Inactivos';
    }
  }

  void _toggleFiltro(_Filtro f) {
    setState(() => _filtro = _filtro == f ? _Filtro.todos : f);
  }

  void _snack(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', ''))));
  }

  Future<void> _logout() async {
    await AuthRepository().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  // ───────────────────────── Acciones ─────────────────────────

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    final isEmpresa = _isEmpresa;
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormSheet(isEmpresa: isEmpresa, item: item),
    );
    if (result == null) return;
    try {
      if (isEmpresa) {
        final empresa = {
          'Nombre_Empresa': result['name']!,
          'Slug': result['slug']!,
        };
        await _repository.guardarEmpresa(
          id: item?['Id_Empresa'],
          data: item == null
              ? {
                  'empresa': empresa,
                  'administrador': {
                    'Nombre_Completo': result['name']!,
                    'Nombre_Usuario': result['username']!,
                    'Correo': result['email']!,
                    'Contrasena': result['password']!,
                  }
                }
              : {
                  ...empresa,
                  'Nombre_Comercial': result['commercialName']!,
                  'Email_Notificaciones': result['notificationEmail']!,
                },
        );
      } else {
        await _repository.guardarRol(
            id: item?['Id_Rol'], nombre: result['name']!);
      }
      await _load();
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    final active = _isActive(item);
    try {
      if (_isEmpresa) {
        await _repository.cambiarEmpresa(item['Id_Empresa'], activar: !active);
      } else {
        await _repository.cambiarRol(item['Id_Rol'], activar: !active);
      }
      await _load();
    } catch (e) {
      _snack(e);
    }
  }

  void _openActions(Map<String, dynamic> item) {
    final active = _isActive(item);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SheetShell(
        title: _nameOf(item),
        child: Column(
          children: [
            _ActionRow(
              icon: Icons.edit_outlined,
              label: _isEmpresa ? 'Editar empresa' : 'Editar rol',
              onTap: () {
                Navigator.pop(sheetContext);
                _openForm(item);
              },
            ),
            if (_isEmpresa)
              _ActionRow(
                icon: Icons.manage_accounts_outlined,
                label: 'Administradores',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _administradores(item);
                },
              ),
            _ActionRow(
              icon: active
                  ? Icons.block_outlined
                  : Icons.check_circle_outline,
              label: active ? 'Desactivar' : 'Activar',
              color: active ? _rojo : AppColors.iconActive,
              onTap: () {
                Navigator.pop(sheetContext);
                _toggle(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _administradores(Map<String, dynamic> empresa) async {
    final empresaId = (empresa['Id_Empresa'] as num).toInt();
    try {
      final admins = await _repository.administradores(empresaId);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _SheetShell(
          title: 'Administradores · ${empresa['Nombre_Empresa']}',
          child: Column(
            children: [
              if (admins.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Text('Esta empresa no tiene administradores.',
                      style:
                          TextStyle(color: AppColors.textFaint, fontSize: 13)),
                ),
              ...admins.map((admin) {
                final active = '${admin['Estado']}' == 'activo';
                final id = (admin['Id_Usuario'] as num).toInt();
                final av = AppColors
                    .avatarPalette[id % AppColors.avatarPalette.length];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.pageBg,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      AvatarWidget(
                          initials: _initials('${admin['Nombre_Completo']}'),
                          size: 38,
                          bg: av['bg']!,
                          text: av['text']!),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${admin['Nombre_Completo'] ?? ''}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text('${admin['Correo'] ?? ''}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            _badge(
                                active ? 'Activo' : 'Inactivo',
                                active ? _verdeBadgeBg : _rojoBadgeBg,
                                active ? _verdeBadgeText : _rojoBadgeText),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          try {
                            await _repository.cambiarAdministrador(
                                empresaId, id,
                                activar: !active);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                            await _administradores(empresa);
                          } catch (e) {
                            _snack(e);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.searchBg,
                            border: Border.all(color: AppColors.cardBorder),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                              active ? Icons.block_outlined : Icons.check,
                              size: 18,
                              color:
                                  active ? _rojo : AppColors.iconActive),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    } catch (e) {
      _snack(e);
    }
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pageBg,
      child: SafeArea(
        bottom: false,
        child: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: Stack(
              children: [
                _loading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.navy))
                    : _error != null
                        ? _buildError()
                        : RefreshIndicator(
                            color: AppColors.navy,
                            onRefresh: _load,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              children: [
                                _buildSearch(),
                                _buildStats(),
                                _buildSectionHeader(
                                    _tituloListaFiltrada, _filtrados.length),
                                if (_filtrados.isEmpty) _buildEmpty(),
                                ..._filtrados.asMap().entries.map(
                                    (e) => _buildTile(e.value, e.key)),
                                const SizedBox(height: 130),
                              ],
                            ),
                          ),
                Positioned(
                  bottom: 20,
                  right: 16,
                  child: FloatingActionButton(
                    backgroundColor: AppColors.navy,
                    onPressed: _loading ? null : () => _openForm(),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Header igual al de Gestión de Usuarios: logo + título + divisor inferior.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Image.asset(
            _logoAsset,
            height: 36,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text('TEXTICODE',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              _tituloHeader,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: _logout,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.searchBg,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout,
                  size: 18, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  /// Tabs de texto con subrayado, igual que Usuarios / Clientes / Operarios.
  Widget _buildTabs() {
    const labels = ['Empresas', 'Roles'];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _cambiarSeccion(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            _section == i ? FontWeight.w600 : FontWeight.w500,
                        color: _section == i
                            ? AppColors.textPrimary
                            : AppColors.textFaint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 3,
                      width: 28,
                      decoration: BoxDecoration(
                        color: _section == i
                            ? AppColors.navy
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
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
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText:
                      _isEmpresa ? 'Buscar empresas...' : 'Buscar roles...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                style:
                    const TextStyle(fontSize: 13, color: AppColors.inputText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cards de estadísticas. Si hay un número impar, la última ocupa todo el ancho.
  Widget _buildStats() {
    final total = _items.length;
    final activos = _items.where(_isActive).length;
    final inactivos = total - activos;

    final items = <_StatItem>[
      _StatItem('Total', total,
          _isEmpresa ? Icons.business_outlined : Icons.badge_outlined,
          AppColors.iconTotal, _Filtro.todos),
      _StatItem(_isEmpresa ? 'Activas' : 'Activos', activos,
          Icons.check_circle_outline, AppColors.iconActive, _Filtro.activos),
      _StatItem(_isEmpresa ? 'Inactivas' : 'Inactivos', inactivos,
          Icons.block_outlined, _rojo, _Filtro.inactivos),
    ];

    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final cardHeight = 78 * textScale.clamp(1.0, 1.3);

    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final pair = items.skip(i).take(2).toList();
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          height: cardHeight,
          child: Row(
            children: [
              for (var j = 0; j < pair.length; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(child: _buildStatCard(pair[j])),
              ],
            ],
          ),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(children: rows),
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
              color:
                  activa ? s.color.withValues(alpha: 0.07) : AppColors.pageBg,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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
                            color: s.color
                                .withValues(alpha: activa ? 0.16 : 0.08),
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
    final filtroActivo = _filtro != _Filtro.todos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          if (filtroActivo) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ],
          const Spacer(),
          if (filtroActivo)
            GestureDetector(
              onTap: () => setState(() => _filtro = _Filtro.todos),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildTile(Map<String, dynamic> item, int index) {
    final id = _idOf(item);
    final av = AppColors.avatarPalette[id % AppColors.avatarPalette.length];
    final active = _isActive(item);
    final name = _nameOf(item);

    final String subtitle = _isEmpresa
        ? '${item['Slug'] ?? ''}'
        : '${item['Total_Usuarios'] ?? 0} usuarios';
    final commercial = '${item['Nombre_Comercial'] ?? ''}'.trim();

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
            AvatarWidget(
                initials: _initials(name),
                size: 38,
                bg: av['bg']!,
                text: av['text']!),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (_isEmpresa && commercial.isNotEmpty) ...[
                        Flexible(
                          child: Text(commercial,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 6),
                        const Text('·',
                            style: TextStyle(color: AppColors.cardBorder)),
                        const SizedBox(width: 6),
                      ],
                      _badge(
                        _isEmpresa
                            ? (active ? 'Activa' : 'Inactiva')
                            : (active ? 'Activo' : 'Inactivo'),
                        active ? _verdeBadgeBg : _rojoBadgeBg,
                        active ? _verdeBadgeText : _rojoBadgeText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _openActions(item),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppColors.searchBg,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.more_vert,
                    size: 20, color: AppColors.textMuted),
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
        children: [
          const Icon(Icons.search_off, size: 32, color: AppColors.textFaint),
          const SizedBox(height: 8),
          Text(
              _isEmpresa
                  ? 'No se encontraron empresas'
                  : 'No se encontraron roles',
              style:
                  const TextStyle(color: AppColors.textFaint, fontSize: 13)),
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
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 4),
            const Text(
              'Verifica que tu backend Express siga corriendo en el puerto 3001\ny que la IP en api_constants.dart sea correcta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textFaint, fontSize: 11),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
              child: const Text('Reintentar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Helpers ─────────────────────────

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final _Filtro filtro;
  _StatItem(this.label, this.value, this.icon, this.color, this.filtro);
}

String _initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

Widget _badge(String text, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text,
        style:
            TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg)),
  );
}

/// Contenedor común de los bottom sheets (esquinas superiores redondeadas).
class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.pageBg,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formulario de crear/editar empresa o rol.
class _FormSheet extends StatefulWidget {
  final bool isEmpresa;
  final Map<String, dynamic>? item;
  const _FormSheet({required this.isEmpresa, this.item});

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  late final _name = TextEditingController(
      text: widget.item?[widget.isEmpresa ? 'Nombre_Empresa' : 'Nombre_Rol']
              ?.toString() ??
          '');
  late final _slug =
      TextEditingController(text: widget.item?['Slug']?.toString() ?? '');
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final _commercialName = TextEditingController(
      text: widget.item?['Nombre_Comercial']?.toString() ?? '');
  late final _notificationEmail = TextEditingController(
      text: widget.item?['Email_Notificaciones']?.toString() ?? '');
  String? _error;

  bool get _nuevo => widget.item == null;

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _commercialName.dispose();
    _notificationEmail.dispose();
    super.dispose();
  }

  void _save() {
    String? err;
    if (_name.text.trim().isEmpty) {
      err = widget.isEmpresa
          ? 'Ingresa el nombre de la empresa'
          : 'Ingresa el nombre del rol';
    } else if (widget.isEmpresa && _slug.text.trim().isEmpty) {
      err = 'Ingresa el slug';
    } else if (widget.isEmpresa &&
        _nuevo &&
        (_username.text.trim().isEmpty ||
            _email.text.trim().isEmpty ||
            _password.text.isEmpty)) {
      err = 'Completa los datos del administrador';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, {
      'name': _name.text.trim(),
      'slug': _slug.text.trim(),
      'username': _username.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'commercialName': _commercialName.text.trim(),
      'notificationEmail': _notificationEmail.text.trim(),
    });
  }

  Widget _field(TextEditingController c, String label,
      {bool obscure = false, TextInputType? type}) {
    OutlineInputBorder border(Color color, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: w),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: type,
        style: const TextStyle(fontSize: 13, color: AppColors.inputText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(fontSize: 12, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.searchBg,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: border(AppColors.cardBorder),
          focusedBorder: border(AppColors.navy, 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmpresa = widget.isEmpresa;
    final title = _nuevo
        ? (isEmpresa ? 'Nueva empresa' : 'Nuevo rol')
        : (isEmpresa ? 'Editar empresa' : 'Editar rol');

    return _SheetShell(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(_name, isEmpresa ? 'Nombre de la empresa' : 'Nombre del rol'),
          if (isEmpresa) ...[
            _field(_slug, 'Slug'),
            if (_nuevo) ...[
              _field(_username, 'Usuario administrador'),
              _field(_email, 'Correo administrador',
                  type: TextInputType.emailAddress),
              _field(_password, 'Contraseña temporal', obscure: true),
            ] else ...[
              _field(_commercialName, 'Nombre comercial'),
              _field(_notificationEmail, 'Correo de notificaciones',
                  type: TextInputType.emailAddress),
            ],
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: const TextStyle(color: _rojo, fontSize: 12)),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}