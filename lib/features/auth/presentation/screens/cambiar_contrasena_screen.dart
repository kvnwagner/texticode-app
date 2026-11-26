import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';

class CambiarContrasenaScreen extends StatefulWidget {
  final String? token;
  final String? correo;
  final Future<void> Function(String)? guardar;

  const CambiarContrasenaScreen({super.key, required String this.token})
      : correo = null,
        guardar = null;

  const CambiarContrasenaScreen.perfil({
    super.key,
    required String this.correo,
    required Future<void> Function(String) this.guardar,
  }) : token = null;

  @override
  State<CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _auth = AuthRepository();
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();

  static final _mayuscula = RegExp(r'[A-Z]');
  static final _minuscula = RegExp(r'[a-z]');
  static final _numero = RegExp(r'[0-9]');
  static final _simbolo = RegExp(r"""[!@#$%^&*()_+\-=\[\]{};:'"\\|,.<>/?]""");

  bool _validando = false;
  bool _enlaceValido = true;
  bool _errorEnlace = false;
  bool _guardando = false;
  bool _guardada = false;
  String? _error;

  List<({String texto, bool valido})> get _requisitos {
    final valor = _password.text;
    return [
      (texto: 'Mínimo 8 caracteres', valido: valor.length >= 8),
      (texto: 'Una mayúscula', valido: _mayuscula.hasMatch(valor)),
      (texto: 'Una minúscula', valido: _minuscula.hasMatch(valor)),
      (texto: 'Un número', valido: _numero.hasMatch(valor)),
      (texto: 'Un símbolo (!, #, *...)', valido: _simbolo.hasMatch(valor)),
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.token != null) _validarEnlace();
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _validarEnlace() async {
    final token = widget.token!;
    setState(() {
      _validando = true;
      _errorEnlace = false;
    });
    try {
      final valido = token.isNotEmpty &&
          await _auth.validarToken(token).timeout(const Duration(seconds: 20));
      if (mounted) setState(() => _enlaceValido = valido);
    } catch (_) {
      if (mounted) setState(() => _errorEnlace = true);
    } finally {
      if (mounted) setState(() => _validando = false);
    }
  }

  Future<void> _enviar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final guardar = widget.guardar;
      if (guardar != null) {
        await guardar(_password.text);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        await _auth.cambiarContrasena(widget.token!, _password.text);
        if (mounted) setState(() => _guardada = true);
      }
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.searchBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (widget.guardar != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Volver a Mi perfil',
                      onPressed:
                          _guardando ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  )
                else
                  const SizedBox(height: 42),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brandTint.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.lock_outline_rounded,
                        size: 28, color: AppColors.brandIcon),
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  'Crea tu nueva contraseña',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 25),
                ),
                if (widget.correo?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text('Para la cuenta ${widget.correo}',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
                const SizedBox(height: 17),
                _contenido(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_validando) return const Center(child: CircularProgressIndicator());
    if (_errorEnlace || !_enlaceValido || _guardada) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _guardada
                ? 'Contraseña actualizada.'
                : _errorEnlace
                    ? 'No se pudo validar el enlace. Revisa tu conexión.'
                    : 'Este enlace expiró o no es válido. Solicita uno nuevo desde el inicio de sesión.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _boton(
            _errorEnlace ? 'Intentar de nuevo' : 'Ir al inicio de sesión',
            _errorEnlace ? _validarEnlace : () => context.go(AppRoutes.login),
          ),
        ],
      );
    }

    final requisitos = _requisitos;
    final faltantes = requisitos.where((r) => !r.valido).length;
    final completos = requisitos.length - faltantes;
    final nivel = completos >= 4 ? completos - 1 : completos.clamp(0, 2);
    final color =
        nivel >= 3 ? AppColors.badgeOpGreenText : AppColors.iconClient;
    final estado = faltantes == 0
        ? 'Fuerte'
        : faltantes == 1 && !_simbolo.hasMatch(_password.text)
            ? 'Buena · le falta un símbolo para ser fuerte'
            : nivel >= 3
                ? 'Buena · falta un requisito'
                : 'Completa los requisitos de seguridad';

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _campo(
            'Nueva contraseña',
            _password,
            siguiente: true,
            validar: (_) =>
                faltantes == 0 ? null : 'Completa todos los requisitos.',
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < nivel ? color : AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          Text(estado,
              style: TextStyle(
                  color: completos == 0 ? AppColors.textMuted : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                for (final requisito in requisitos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          requisito.valido
                              ? Icons.check_rounded
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: requisito.valido
                              ? AppColors.iconActive
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            requisito.texto,
                            style: TextStyle(
                              color: requisito.valido
                                  ? AppColors.badgeOpGreenText
                                  : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _campo(
            'Confirmar contraseña',
            _confirmacion,
            validar: (valor) =>
                valor == _password.text && valor?.isNotEmpty == true
                    ? null
                    : 'Las contraseñas no coinciden.',
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: AppColors.errorText)),
          ],
          const SizedBox(height: 17),
          _boton('Guardar y entrar', _guardando ? null : _enviar),
        ],
      ),
    );
  }

  Widget _campo(
    String titulo,
    TextEditingController controller, {
    required FormFieldValidator<String> validar,
    bool siguiente = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !_guardando,
          textInputAction:
              siguiente ? TextInputAction.next : TextInputAction.done,
          onChanged: siguiente ? (_) => setState(() => _error = null) : null,
          onFieldSubmitted: siguiente ? null : (_) => _enviar(),
          validator: validar,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: AppColors.brandText),
            ),
          ),
        ),
      ],
    );
  }

  Widget _boton(String titulo, VoidCallback? accion) => FilledButton(
        onPressed: accion,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(51),
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.onBrand,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: _guardando
            ? const SizedBox.square(
                dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
      );
}
