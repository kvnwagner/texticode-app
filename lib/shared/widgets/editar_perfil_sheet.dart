import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../features/admin/data/repositories/usuario_repository.dart';

/// Bottom sheet reutilizable para editar el perfil del usuario logueado
/// (admin, operario o cliente). Llama directo a UsuarioRepository.actualizarUsuario,
/// que ya habla contra tu backend real (usuarios.js -> Supabase).
///
/// La nueva contraseña (opcional) sigue EXACTAMENTE la misma regla que el
/// formulario "Nuevo Usuario" de Gestión de Usuarios: mínimo 8 caracteres,
/// una mayúscula, un número y un carácter especial, sin espacios.
///
/// Uso:
/// ```dart
/// final actualizado = await showModalBottomSheet<Map<String, String>>(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => EditarPerfilSheet(
///     idUsuario: authUser.idUsuario,
///     idRol: authUser.idRol,
///     estado: authUser.estado,
///     nombreCompleto: _nombre,
///     nombreUsuario: _usuario,
///     correo: _correo,
///     telefono: _telefono,
///   ),
/// );
/// if (actualizado != null) {
///   setState(() {
///     _nombre = actualizado['nombreCompleto']!;
///     _correo = actualizado['correo']!;
///     _telefono = actualizado['telefono']!;
///     _usuario = actualizado['nombreUsuario']!;
///   });
/// }
/// ```
class EditarPerfilSheet extends StatefulWidget {
  final int idUsuario;
  final int idRol;
  final String estado;
  final String nombreCompleto;
  final String nombreUsuario;
  final String correo;
  final String telefono;

  const EditarPerfilSheet({
    super.key,
    required this.idUsuario,
    required this.idRol,
    required this.estado,
    required this.nombreCompleto,
    required this.nombreUsuario,
    required this.correo,
    required this.telefono,
  });

  @override
  State<EditarPerfilSheet> createState() => _EditarPerfilSheetState();
}

class _EditarPerfilSheetState extends State<EditarPerfilSheet> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioRepo = UsuarioRepository();

  late final TextEditingController _nombreCtrl =
      TextEditingController(text: widget.nombreCompleto);
  late final TextEditingController _usuarioCtrl =
      TextEditingController(text: widget.nombreUsuario);
  late final TextEditingController _correoCtrl =
      TextEditingController(text: widget.correo);
  late final TextEditingController _telefonoCtrl =
      TextEditingController(text: widget.telefono == '—' ? '' : widget.telefono);
  final TextEditingController _contrasenaCtrl = TextEditingController();

  bool _obscurePassword = true;

  bool _guardando = false;
  String? _error;

  // ── Validación de contraseña (misma regla que NewUserSheet) ───────────

  static final RegExp _mayuscula = RegExp(r'[A-Z]');
  static final RegExp _numero = RegExp(r'[0-9]');
  static final RegExp _especial = RegExp(r'[^A-Za-z0-9]');

  /// Devuelve null si la contraseña es válida. Aquí la contraseña es
  /// OPCIONAL: vacío = "conservar la actual", por eso vacío es válido.
  String? _validarContrasena(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return null;
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!_mayuscula.hasMatch(value)) return 'Debe tener al menos una mayúscula';
    if (!_numero.hasMatch(value)) return 'Debe tener al menos un número';
    if (!_especial.hasMatch(value)) {
      return 'Debe tener al menos un carácter especial (@, #, \$, etc.)';
    }
    return null;
  }

  List<_PwdHint> get _passwordHints {
    final pwd = _contrasenaCtrl.text;
    return [
      _PwdHint('Mínimo 8 caracteres', pwd.length >= 8),
      _PwdHint('Una mayúscula', _mayuscula.hasMatch(pwd)),
      _PwdHint('Un número', _numero.hasMatch(pwd)),
      _PwdHint('Un carácter especial (@#\$…)', _especial.hasMatch(pwd)),
    ];
  }

  bool get _contrasenaValida => _validarContrasena(_contrasenaCtrl.text) == null;

  @override
  void initState() {
    super.initState();
    // Refresca los chips de requisitos y el estado del botón en cada tecla.
    _contrasenaCtrl.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _contrasenaCtrl.removeListener(_onPasswordChanged);
    _nombreCtrl.dispose();
    _usuarioCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await _usuarioRepo.actualizarUsuario(
        id: widget.idUsuario,
        idRol: widget.idRol,
        nombreCompleto: _nombreCtrl.text.trim(),
        nombreUsuario: _usuarioCtrl.text.trim(),
        correo: _correoCtrl.text.trim().isEmpty ? null : _correoCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
        estado: widget.estado,
        // Si el campo quedó vacío, mandamos null: el backend interpreta
        // eso como "no cambiar la contraseña" (ver actualizarUsuario).
        contrasena: _contrasenaCtrl.text.trim().isEmpty ? null : _contrasenaCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop({
          'nombreCompleto': _nombreCtrl.text.trim(),
          'nombreUsuario': _usuarioCtrl.text.trim(),
          'correo': _correoCtrl.text.trim(),
          'telefono': _telefonoCtrl.text.trim().isEmpty ? '—' : _telefonoCtrl.text.trim(),
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text('Editar mi perfil',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 18),
                _field(_nombreCtrl, 'Nombre completo', requerido: true),
                const SizedBox(height: 12),
                _field(_usuarioCtrl, 'Nombre de usuario', requerido: true),
                const SizedBox(height: 12),
                _field(_correoCtrl, 'Correo', tipo: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field(_telefonoCtrl, 'Teléfono', tipo: TextInputType.phone),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contrasenaCtrl,
                  obscureText: _obscurePassword,
                  // Sin espacios, igual que al crear un usuario.
                  inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña (opcional)',
                    helperText: 'Déjalo vacío para conservar tu contraseña actual.',
                    helperMaxLines: 2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validarContrasena,
                ),
                _passwordHintsRow(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.errorText, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    // Deshabilitado mientras haya una contraseña nueva que
                    // aún no cumple la regla (vacía = válido, no se cambia).
                    onPressed: (_guardando || !_contrasenaValida) ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.35),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar cambios',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Chips de requisitos en vivo. Solo aparecen cuando el usuario empieza
  /// a escribir una contraseña nueva.
  Widget _passwordHintsRow() {
    if (_contrasenaCtrl.text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: _passwordHints.map((h) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: h.ok ? AppColors.badgeOpGreenBg : AppColors.searchBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${h.ok ? '✓' : '✗'} ${h.label}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: h.ok ? AppColors.badgeOpGreenText : AppColors.textFaint,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool requerido = false, TextInputType? tipo}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: requerido
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
          : null,
    );
  }
}

class _PwdHint {
  final String label;
  final bool ok;
  const _PwdHint(this.label, this.ok);
}