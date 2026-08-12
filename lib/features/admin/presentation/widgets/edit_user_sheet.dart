import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/usuario_repository.dart';

class EditUserSheet extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onChanged;

  const EditUserSheet({super.key, required this.usuario, required this.onChanged});

  @override
  State<EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repo = UsuarioRepository();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _usuarioCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _telefonoCtrl;

  // ⚠️ Mismos Id_Rol que en new_user_sheet.dart — ajústalos si no coinciden
  // con tu tabla `rol` real en Supabase.
  final Map<String, int> _rolIds = {
    'administrador': 1,
    'operario': 2,
    'cliente': 3,
  };
  late String? _rolSeleccionado;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombreCtrl = TextEditingController(text: u.nombreCompleto);
    _usuarioCtrl = TextEditingController(text: u.nombreUsuario);
    _correoCtrl = TextEditingController(text: u.correo ?? '');
    _telefonoCtrl = TextEditingController(text: u.telefono ?? '');
    // Busca la key del mapa que coincida con el Id_Rol actual del usuario.
    _rolSeleccionado = _rolIds.entries
        .firstWhere(
          (e) => e.value == u.idRol,
      orElse: () => _rolIds.entries.first,
    )
        .key;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _usuarioCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rolSeleccionado == null) {
      setState(() => _error = 'Selecciona un rol');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.actualizarUsuario(
        id: widget.usuario.idUsuario,
        idRol: _rolIds[_rolSeleccionado]!,
        nombreCompleto: _nombreCtrl.text.trim(),
        nombreUsuario: _usuarioCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        estado: widget.usuario.estado, // no se toca desde este formulario
        contrasena: null, // null = no cambia la contraseña
      );
      if (!mounted) return;
      widget.onChanged();
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _labelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.6,
    color: AppColors.textMuted,
  );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.inputPlaceholder, fontSize: 13),
    filled: true,
    fillColor: AppColors.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
    ),
  );

  Widget _field({
    required String label,
    String? helper,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: _labelStyle,
            children: [
              TextSpan(text: label.toUpperCase()),
              if (helper != null)
                TextSpan(
                  text: '  $helper',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.normal,
                    letterSpacing: 0,
                    color: AppColors.textFaint,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _dec(hint),
          style: const TextStyle(fontSize: 13, color: AppColors.inputText),
          validator: validator,
        ),
      ],
    );
  }

  Widget _roleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ROL', style: _labelStyle),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _rolSeleccionado,
          decoration: _dec('Selecciona un rol'),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textFaint),
          style: const TextStyle(fontSize: 13, color: AppColors.inputText),
          items: _rolIds.keys
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() => _rolSeleccionado = v),
        ),
      ],
    );
  }

  Widget _summaryCard() {
    final u = widget.usuario;
    final av = AppColors.avatarPalette[u.idUsuario % AppColors.avatarPalette.length];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          AvatarWidget(initials: u.initials, size: 36, bg: av['bg']!, text: av['text']!),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Refleja en vivo lo que se está escribiendo, no el valor original.
                AnimatedBuilder(
                  animation: Listenable.merge([_nombreCtrl, _usuarioCtrl, _correoCtrl]),
                  builder: (_, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nombreCtrl.text.trim().isEmpty ? u.nombreCompleto : _nombreCtrl.text,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      Text('@${_usuarioCtrl.text.trim().isEmpty ? u.nombreUsuario : _usuarioCtrl.text}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text(
                        _correoCtrl.text.trim().isEmpty ? (u.correo ?? '') : _correoCtrl.text,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Editar Usuario',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.searchBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Icon(Icons.close, size: 15, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _field(
                    label: 'Nombre completo',
                    controller: _nombreCtrl,
                    hint: 'Nombre completo',
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El nombre es requerido' : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Nombre de usuario',
                    helper: '(para iniciar sesión)',
                    controller: _usuarioCtrl,
                    hint: 'Ej: juan.perez o juanito123',
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El nombre de usuario es requerido' : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Correo electrónico',
                    controller: _correoCtrl,
                    hint: 'correo@ejemplo.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Teléfono',
                    controller: _telefonoCtrl,
                    hint: '+57 300 000 0000',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _roleDropdown(),
                  const SizedBox(height: 16),
                  _summaryCard(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.errorBorder),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.errorText, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: _loading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.cardBorder),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Cancelar',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                                : const Text('Guardar Cambios',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}