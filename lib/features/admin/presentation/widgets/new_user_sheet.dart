import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/usuario_repository.dart';

class NewUserSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const NewUserSheet({super.key, required this.onCreated});

  @override
  State<NewUserSheet> createState() => _NewUserSheetState();
}

class _NewUserSheetState extends State<NewUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repo = UsuarioRepository();

  final _nombreCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // ⚠️ AJUSTA ESTO: son los Id_Rol reales de tu tabla `rol` en Supabase.
  // Confírmalos con: SELECT * FROM rol;  — asumí Administrador=1, Operario=2, Cliente=3.
  String? _rolSeleccionado;
  final Map<String, int> _rolIds = {
    'administrador': 1,
    'operario': 2,
    'cliente': 3,
  };

  bool _loading = false;
  bool _obscurePass = true;
  String? _error;

  // ── Validación (mismos criterios que GestionUsuarios.vue) ─────────────

  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$",
  );
  static final RegExp _telefonoRegex = RegExp(r'^\d{1,10}$');
  static final RegExp _mayuscula = RegExp(r'[A-Z]');
  static final RegExp _numero = RegExp(r'[0-9]');
  static final RegExp _especial = RegExp(r'[^A-Za-z0-9]');

  String? _validarNombre(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'El nombre es requerido';
    if (_numero.hasMatch(value)) return 'El nombre no puede contener números';
    return null;
  }

  String? _validarUsuario(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'El nombre de usuario es requerido';
    if (value.contains(' ')) return 'No puede contener espacios';
    if (RegExp(r'^\d+$').hasMatch(value)) return 'No puede contener solo números';
    return null;
  }

  String? _validarCorreo(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'El correo es requerido';
    if (!_emailRegex.hasMatch(value)) {
      return 'Ingresa un correo válido (ej: nombre@dominio.com)';
    }
    return null;
  }

  String? _validarTelefono(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return null; // el teléfono es opcional
    if (!_telefonoRegex.hasMatch(value)) {
      return 'Teléfono inválido (solo números, máximo 10 dígitos)';
    }
    return null;
  }

  String? _validarContrasena(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!_mayuscula.hasMatch(value)) return 'Debe tener al menos una mayúscula';
    if (!_numero.hasMatch(value)) return 'Debe tener al menos un número';
    if (!_especial.hasMatch(value)) {
      return 'Debe tener al menos un carácter especial (@, #, \$, etc.)';
    }
    return null;
  }

  List<_PwdHint> get _passwordHints {
    final pwd = _passCtrl.text;
    return [
      _PwdHint('Mínimo 8 caracteres', pwd.length >= 8),
      _PwdHint('Una mayúscula', _mayuscula.hasMatch(pwd)),
      _PwdHint('Un número', _numero.hasMatch(pwd)),
      _PwdHint('Un carácter especial (@#\$…)', _especial.hasMatch(pwd)),
    ];
  }

  // El botón "Crear Usuario" queda deshabilitado mientras algún campo
  // no cumpla su validación — igual que `tieneErrores` en el Vue.
  bool get _formValido =>
      _validarNombre(_nombreCtrl.text) == null &&
      _validarUsuario(_usuarioCtrl.text) == null &&
      _validarCorreo(_correoCtrl.text) == null &&
      _validarTelefono(_telefonoCtrl.text) == null &&
      _validarContrasena(_passCtrl.text) == null &&
      _rolSeleccionado != null;

  @override
  void initState() {
    super.initState();
    // Reconstruye en cada tecla para refrescar los hints de contraseña,
    // los errores en vivo y el estado habilitado/deshabilitado del botón.
    for (final c in [_nombreCtrl, _usuarioCtrl, _correoCtrl, _telefonoCtrl, _passCtrl]) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _usuarioCtrl, _correoCtrl, _telefonoCtrl, _passCtrl]) {
      c.removeListener(_onFieldChanged);
    }
    _nombreCtrl.dispose();
    _usuarioCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _passCtrl.dispose();
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
      await _repo.crearUsuario(
        idRol: _rolIds[_rolSeleccionado]!,
        nombreCompleto: _nombreCtrl.text.trim(),
        nombreUsuario: _usuarioCtrl.text.trim(),
        contrasena: _passCtrl.text,
        correo: _correoCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
      );
      if (!mounted) return;
      widget.onCreated();
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

  InputDecoration _dec(String hint, {Widget? suffixIcon}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.inputPlaceholder, fontSize: 13),
    filled: true,
    fillColor: AppColors.inputBg,
    suffixIcon: suffixIcon,
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
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.errorText, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.errorText, width: 1.5),
    ),
  );

  Widget _field({
    required String label,
    String? helper,
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
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
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: _dec(hint, suffixIcon: suffixIcon),
          style: const TextStyle(fontSize: 13, color: AppColors.inputText),
          validator: validator,
        ),
      ],
    );
  }

  Widget _passwordHintsRow() {
    if (_passCtrl.text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 7),
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
          hint: const Text('Selecciona un rol',
              style: TextStyle(color: AppColors.inputPlaceholder, fontSize: 13)),
          items: _rolIds.keys
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() => _rolSeleccionado = v),
        ),
      ],
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
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nuevo Usuario',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          SizedBox(height: 2),
                          Text('Completa los datos del usuario',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
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
                    // Impide teclear números directamente, igual que
                    // @keypress="soloLetras" en el Vue.
                    inputFormatters: [FilteringTextInputFormatter.deny(_numero)],
                    validator: _validarNombre,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Nombre de usuario',
                    helper: '(para iniciar sesión)',
                    controller: _usuarioCtrl,
                    hint: 'Ej: juan.perez o juanito123',
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                    validator: _validarUsuario,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Correo electrónico',
                    controller: _correoCtrl,
                    hint: 'correo@ejemplo.com',
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                    validator: _validarCorreo,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Teléfono',
                    helper: '(opcional)',
                    controller: _telefonoCtrl,
                    hint: '3001234567',
                    keyboardType: TextInputType.phone,
                    // Solo dígitos, y no deja escribir más de 10.
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: _validarTelefono,
                  ),
                  const SizedBox(height: 14),
                  _roleDropdown(),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Contraseña',
                    controller: _passCtrl,
                    hint: '••••••••',
                    obscure: _obscurePass,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      icon: Icon(
                        _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.textFaint,
                      ),
                    ),
                    validator: _validarContrasena,
                  ),
                  _passwordHintsRow(),
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
                            onPressed: (_loading || !_formValido) ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.35),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                                : const Text('Crear Usuario',
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

class _PwdHint {
  final String label;
  final bool ok;
  const _PwdHint(this.label, this.ok);
}