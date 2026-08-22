import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/repositories/usuario_repository.dart';

/// Pantalla "Mi Perfil" del rol admin (último ícono del dock inferior).
///
/// Ya NO usa datos placeholder: carga el usuario real que guardó
/// AuthRepository durante el login (nombre, correo, usuario, rol), y
/// complementa el teléfono consultando UsuarioRepository (el login no
/// devuelve teléfono, pero la tabla de usuarios sí lo tiene).
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _authRepo = AuthRepository();
  final _usuarioRepo = UsuarioRepository();

  String _nombre = '...';
  String _correo = '...';
  String _telefono = '—';
  String _usuario = '...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final authUser = await _authRepo.getUsuarioGuardado();
    if (authUser == null) {
      // No debería pasar (llegaste aquí porque ya iniciaste sesión),
      // pero por seguridad mandamos de vuelta al login si no hay sesión.
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      return;
    }

    if (mounted) {
      setState(() {
        _nombre = authUser.nombreCompleto;
        _correo = authUser.correo;
        _usuario = authUser.nombreUsuario;
        _loading = false;
      });
    }

    // El teléfono no viene en la respuesta del login — lo buscamos en
    // la lista completa de usuarios (mismo endpoint que usa Gestión de
    // Usuarios). Si falla (sin internet, etc.) simplemente se queda "—".
    try {
      final usuarios = await _usuarioRepo.getUsuarios();
      final match = usuarios.where((u) => u.idUsuario == authUser.idUsuario);
      if (match.isNotEmpty && mounted) {
        setState(() => _telefono = match.first.telefono ?? '—');
      }
    } catch (_) {
      // Silencioso a propósito: el teléfono es complementario, no debe
      // bloquear ni ensuciar la pantalla de perfil con un error.
    }
  }

  String get _initials {
    final parts = _nombre.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '??';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _logout(BuildContext context) async {
    await _authRepo.logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileCard(
                            nombre: _nombre,
                            correo: _correo,
                            telefono: _telefono,
                            usuario: _usuario,
                            initials: _initials),
                        const SizedBox(height: 16),
                        _ActionButton(
                          icon: _GoogleIcon(),
                          label: 'Vincular con Google',
                          onTap: () {
                            // TODO: conectar con el flujo real de Google Sign-In.
                          },
                        ),
                        const SizedBox(height: 10),
                        _ActionButton(
                          icon: const Icon(Icons.sync_rounded, size: 18, color: Colors.white),
                          label: 'Sincronizar Ahora',
                          onTap: () {
                            // TODO: disparar sincronización real contra el backend.
                          },
                        ),
                        const SizedBox(height: 28),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        const SizedBox(height: 20),
                        _LogoutButton(onTap: () => _logout(context)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo_texticode.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => AvatarWidget(
                  initials: _initials,
                  size: 38,
                  bg: AppColors.navy,
                  text: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mi Perfil',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('Administrador',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String nombre;
  final String correo;
  final String telefono;
  final String usuario;
  final String initials;

  const _ProfileCard({
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.usuario,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.badgeAdminBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Administrador',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.badgeAdminText)),
                    ),
                  ],
                ),
              ),
              _EditButton(onTap: () {
                // TODO: abrir un sheet de "Editar mi perfil" (reutilizando el
                // patrón de EditUserSheet cuando exista el endpoint de perfil).
              }),
            ],
          ),
          const SizedBox(height: 18),
          _InfoTile(icon: Icons.mail_outline, label: 'EMAIL', value: correo),
          const SizedBox(height: 10),
          _InfoTile(icon: Icons.phone_outlined, label: 'TELÉFONO', value: telefono),
          const SizedBox(height: 10),
          _InfoTile(icon: Icons.alternate_email, label: 'USUARIO', value: usuario),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 13, color: Colors.white),
            SizedBox(width: 5),
            Text('Editar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: Colors.white.withValues(alpha: 0.55))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF34A853)]),
      ),
      alignment: Alignment.center,
      child: const Text('G',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.errorBg,
          side: const BorderSide(color: AppColors.errorBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close, size: 15, color: AppColors.errorText),
            SizedBox(width: 8),
            Text('Cerrar sesión',
                style: TextStyle(color: AppColors.errorText, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}