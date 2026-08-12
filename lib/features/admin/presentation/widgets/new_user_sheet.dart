import 'package:flutter/material.dart';
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
  String? _error;

  @override
  void dispose() {
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
    bool obscure = false,
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
          obscureText: obscure,
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
                  const SizedBox(height: 14),
                  _field(
                    label: 'Contraseña',
                    controller: _passCtrl,
                    hint: '••••••••',
                    obscure: true,
                    validator: (v) =>
                    (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
                  ),
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