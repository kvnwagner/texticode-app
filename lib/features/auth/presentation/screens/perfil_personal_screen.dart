import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/editar_perfil_sheet.dart';
import '../../../../shared/widgets/theme_toggle.dart';
import '../../../admin/data/models/usuario_model.dart';
import '../../../admin/data/repositories/calendar_repository.dart';
import '../../../admin/data/repositories/usuario_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/google_auth_repository.dart';
import 'cambiar_contrasena_screen.dart';

class PerfilPersonalScreen extends StatefulWidget {
  final String rol;
  final VoidCallback? onLogout;

  const PerfilPersonalScreen({super.key, required this.rol, this.onLogout});

  @override
  State<PerfilPersonalScreen> createState() => _PerfilPersonalScreenState();
}

class _PerfilPersonalScreenState extends State<PerfilPersonalScreen> {
  final _authRepo = AuthRepository();
  final _usuarioRepo = UsuarioRepository();
  final _calendarRepo = CalendarRepository();
  final _googleAuthRepo = GoogleAuthRepository();
  static const _storage = FlutterSecureStorage();

  Usuario? _usuario;
  int? _empresaId;
  bool _notificaciones = true;
  bool _guardandoNotificaciones = false;
  bool? _calendarVinculado;
  bool _calendarOcupado = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
    _cargarCalendar();
  }

  String _claveNotificaciones(int usuarioId) =>
      'texticode.notificaciones.${_empresaId ?? 0}.$usuarioId';

  Future<void> _cargarPerfil() async {
    final sesion = await _authRepo.getUsuarioGuardado();
    if (!mounted) return;
    if (sesion == null) {
      context.go(AppRoutes.login);
      return;
    }

    setState(() {
      _empresaId = sesion.idEmpresa;
      _usuario = Usuario(
        idUsuario: sesion.idUsuario,
        nombreCompleto: sesion.nombreCompleto,
        nombreUsuario: sesion.nombreUsuario,
        correo: sesion.correo,
        estado: sesion.estado,
        rol: sesion.rol,
        idRol: sesion.idRol,
      );
    });
    await Future.wait([
      _cargarDatos(sesion.idUsuario),
      _cargarNotificaciones(sesion.idUsuario),
    ]);
  }

  Future<void> _cargarDatos(int id) async {
    try {
      final usuario = await _usuarioRepo.getUsuario(id);
      if (mounted) setState(() => _usuario = usuario);
    } catch (_) {
      // Los datos de la sesión permiten mostrar el perfil sin conexión.
    }
  }

  Future<void> _cargarNotificaciones(int id) async {
    try {
      final valor = await _storage.read(key: _claveNotificaciones(id));
      if (mounted && !_guardandoNotificaciones) {
        setState(() => _notificaciones = valor != 'false');
      }
    } catch (_) {
      // Conserva la preferencia de la pantalla si el almacenamiento falla.
    }
  }

  Future<void> _cambiarNotificaciones(bool valor) async {
    final usuario = _usuario;
    if (usuario == null || _guardandoNotificaciones) return;
    setState(() => _guardandoNotificaciones = true);
    try {
      await _storage.write(
          key: _claveNotificaciones(usuario.idUsuario), value: '$valor');
      if (mounted) setState(() => _notificaciones = valor);
    } catch (_) {
      if (mounted) _mensaje('No se pudo guardar la preferencia.');
    } finally {
      if (mounted) setState(() => _guardandoNotificaciones = false);
    }
  }

  Future<void> _cargarCalendar() => _ejecutarCalendar(() async {
        final estado = await _calendarRepo.getStatus();
        if (mounted) setState(() => _calendarVinculado = estado.connected);
      });

  Future<void> _cambiarVinculoCalendar() {
    final vinculado = _calendarVinculado;
    if (vinculado == null) return _cargarCalendar();

    return _ejecutarCalendar(() async {
      if (vinculado) {
        await _calendarRepo.disconnect();
        if (!mounted) return;
        setState(() => _calendarVinculado = false);
        _mensaje('Google Calendar desvinculado correctamente.');
        await _googleAuthRepo.signOutGoogle();
      } else {
        final codigo = await _googleAuthRepo.requestCalendarServerAuthCode();
        await _calendarRepo.connect(codigo);
        if (!mounted) return;
        setState(() => _calendarVinculado = true);
        _mensaje('Google Calendar vinculado correctamente.');
      }
    });
  }

  Future<void> _sincronizarCalendar() => _ejecutarCalendar(() async {
        final result = await _calendarRepo.syncAllOrdenes();
        if (!mounted) return;
        _mensaje('Órdenes sincronizadas: ${result.total} '
            '(${result.creados} nuevas, ${result.actualizados} actualizadas).');
      });

  Future<void> _ejecutarCalendar(Future<void> Function() ejecutar) async {
    if (_calendarOcupado) return;
    setState(() => _calendarOcupado = true);
    try {
      await ejecutar();
    } catch (error) {
      if (mounted) _mensaje(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _calendarOcupado = false);
    }
  }

  Future<void> _editar(Usuario usuario) async {
    final resultado = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditarPerfilSheet(
        idUsuario: usuario.idUsuario,
        idRol: usuario.idRol,
        estado: usuario.estado,
        nombreCompleto: usuario.nombreCompleto,
        nombreUsuario: usuario.nombreUsuario,
        correo: usuario.correo ?? '',
        telefono: usuario.telefono ?? '',
      ),
    );
    if (!mounted || resultado == null) return;
    setState(() {
      _usuario = Usuario(
        idUsuario: usuario.idUsuario,
        idRol: usuario.idRol,
        rol: usuario.rol,
        estado: usuario.estado,
        nombreCompleto: resultado['nombreCompleto']!,
        nombreUsuario: resultado['nombreUsuario']!,
        correo: resultado['correo'],
        telefono: resultado['telefono'],
      );
    });
    _mensaje('Perfil actualizado correctamente.');
  }

  Future<void> _cambiarContrasena(Usuario usuario) async {
    final guardada =
        await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => CambiarContrasenaScreen.perfil(
          correo: usuario.correo?.trim().isNotEmpty == true
              ? usuario.correo!
              : usuario.nombreUsuario,
          guardar: (contrasena) async {
            final actual = await _usuarioRepo.getUsuario(usuario.idUsuario);
            await _usuarioRepo.actualizarUsuario(
              id: actual.idUsuario,
              idRol: actual.idRol,
              nombreCompleto: actual.nombreCompleto,
              nombreUsuario: actual.nombreUsuario,
              correo: actual.correo,
              telefono: actual.telefono,
              estado: actual.estado,
              contrasena: contrasena,
            );
          },
        ),
      ),
    );
    if (mounted && guardada == true) _mensaje('Contraseña actualizada.');
  }

  Future<void> _logout() async {
    await _authRepo.logout();
    if (!mounted) return;
    final onLogout = widget.onLogout;
    if (onLogout == null) {
      context.go(AppRoutes.login);
    } else {
      onLogout();
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Widget _accionCalendar() {
    if (_calendarOcupado) {
      return const SizedBox.square(
        dimension: 17,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final vinculado = _calendarVinculado;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (vinculado == true)
          IconButton(
            tooltip: 'Sincronizar órdenes',
            onPressed: _sincronizarCalendar,
            icon: Icon(Icons.sync, size: 18, color: AppColors.brandIcon),
          ),
        Text(
          switch (vinculado) {
            true => 'Desvincular',
            false => 'Vincular',
            null => 'Reintentar',
          },
          style: TextStyle(
            color:
                vinculado == true ? AppColors.errorText : AppColors.brandText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;
    return ColoredBox(
      color: AppColors.searchBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'Mi perfil',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (usuario == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            _TarjetaPerfil(
                usuario: usuario,
                rol: widget.rol,
                editar: () => _editar(usuario)),
            const SizedBox(height: 14),
            const ThemeModeSelector(),
            const SizedBox(height: 14),
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: AppColors.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _OpcionPerfil(
                    icono: Icons.lock_outline_rounded,
                    nombre: 'Cambiar contraseña',
                    accion: () => _cambiarContrasena(usuario),
                    finalFila:
                        const Icon(Icons.chevron_right_rounded, size: 19),
                  ),
                  Divider(height: 1, color: AppColors.cardBorder),
                  _OpcionPerfil(
                    icono: Icons.notifications_none_rounded,
                    nombre: 'Notificaciones',
                    finalFila: Switch(
                      value: _notificaciones,
                      activeThumbColor: AppColors.onBrand,
                      activeTrackColor: AppColors.iconActive,
                      onChanged: _guardandoNotificaciones
                          ? null
                          : _cambiarNotificaciones,
                    ),
                  ),
                  Divider(height: 1, color: AppColors.cardBorder),
                  _OpcionPerfil(
                    icono: Icons.calendar_today_outlined,
                    nombre: 'Google Calendar',
                    accion: _calendarOcupado ? null : _cambiarVinculoCalendar,
                    finalFila: _accionCalendar(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.errorBg,
                foregroundColor: AppColors.errorText,
                side: BorderSide(color: AppColors.errorBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout, size: 19),
              label: const Text('Cerrar sesión',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaPerfil extends StatelessWidget {
  final Usuario usuario;
  final String rol;
  final VoidCallback editar;

  const _TarjetaPerfil(
      {required this.usuario, required this.rol, required this.editar});

  @override
  Widget build(BuildContext context) {
    const blanco = AppColors.onBrand;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.perfilCardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.perfilCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.perfilCardShadow,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 57,
                height: 57,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(colors: AppColors.perfilAvatarGradient),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: blanco.withValues(alpha: 0.32), width: 2),
                ),
                child: Text(
                  usuario.initials,
                  style: const TextStyle(
                      color: blanco, fontWeight: FontWeight.w800, fontSize: 19),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      style: const TextStyle(
                          color: blanco,
                          fontSize: 17,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                          color: AppColors.badgeClientBg,
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      child: Text(
                        rol,
                        style: TextStyle(
                            color: AppColors.badgeClientText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: editar,
                tooltip: 'Editar mi perfil',
                icon: const Icon(Icons.edit_outlined, color: blanco, size: 19),
                style: IconButton.styleFrom(
                  backgroundColor: blanco.withValues(alpha: 0.12),
                  side: BorderSide(color: blanco.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                    child:
                        _DatoPerfil(titulo: 'CORREO', valor: usuario.correo)),
                const SizedBox(width: 8),
                Expanded(
                    child: _DatoPerfil(
                        titulo: 'TELÉFONO', valor: usuario.telefono)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoPerfil extends StatelessWidget {
  final String titulo;
  final String? valor;

  const _DatoPerfil({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    const blanco = AppColors.onBrand;
    final texto = valor?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: blanco.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                  color: blanco.withValues(alpha: 0.72),
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(texto == null || texto.isEmpty ? '—' : texto,
              style: const TextStyle(
                  color: blanco, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _OpcionPerfil extends StatelessWidget {
  final IconData icono;
  final String nombre;
  final Widget finalFila;
  final VoidCallback? accion;

  const _OpcionPerfil(
      {required this.icono,
      required this.nombre,
      required this.finalFila,
      this.accion});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      minTileHeight: 52,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      horizontalTitleGap: 12,
      onTap: accion,
      leading: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.brandTint.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono, size: 17, color: AppColors.brandIcon),
      ),
      title: Text(
        nombre,
        style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14),
      ),
      trailing: finalFila,
    );
  }
}
