import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository.dart';

/// Pantalla que abre el deep link texticode://cambiar-contrasena?token=xxx.
/// Replica las mismas reglas de contraseña que el backend (auth.route.js
/// -> validarContrasena): 8+ caracteres, mayúscula, número y carácter especial.
class CambiarContrasenaScreen extends StatefulWidget {
  final String token;
  const CambiarContrasenaScreen({super.key, required this.token});

  @override
  State<CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _validandoToken = true;
  bool _tokenValido = false;
  bool _enviando = false;
  bool _exito = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _validarTokenInicial();
  }

  Future<void> _validarTokenInicial() async {
    final valido = await _authRepository.validarToken(widget.token);
    if (!mounted) return;
    setState(() {
      _tokenValido = valido;
      _validandoToken = false;
    });
  }

  String? _validarPassword(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Debe tener al menos 8 caracteres.';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Debe tener una mayúscula.';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Debe tener un número.';
    if (!RegExp(r'''[!@#$%^&*()_+\-=\[\]{};:'"\\|,.<>/?]''').hasMatch(v)) {
      return 'Debe tener un carácter especial (@, #, \$, etc.).';
    }
    return null;
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await _authRepository.cambiarContrasena(
        widget.token,
        _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _exito = true;
        _enviando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildContenido(),
      ),
    );
  }

  Widget _buildContenido() {
    if (_validandoToken) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_tokenValido) {
      return const Center(
        child: Text(
          'Este enlace es inválido o ya expiró.\nSolicita uno nuevo desde la pantalla de inicio de sesión.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_exito) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 56),
            const SizedBox(height: 16),
            const Text('¡Contraseña actualizada!', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ir al login'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            validator: _validarPassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: true,
            decoration:
                const InputDecoration(labelText: 'Confirmar contraseña'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cambiar contraseña'),
          ),
        ],
      ),
    );
  }
}