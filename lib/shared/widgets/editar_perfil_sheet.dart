import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/admin/data/repositories/usuario_repository.dart';

/// Bottom sheet reutilizable para editar el perfil del usuario logueado
/// (admin, operario o cliente). Llama directo a UsuarioRepository.actualizarUsuario,
/// que ya habla contra tu backend real (usuarios.js -> Supabase).
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

  @override
  void dispose() {
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
                  validator: (v) {
                    if (v == null || v.isEmpty) return null; // vacío = no cambiar, válido
                    if (v.trim().length < 6) return 'Debe tener al menos 6 caracteres';
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.errorText, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
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