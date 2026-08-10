import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Placeholder temporal — aquí se conectará la vista real de Administrador
/// (Personas / Inventario / Reportes / Producción / Perfil) siguiendo
/// el mismo patrón feature-first que auth/.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false),
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenido, Administrador 👋\n(pantalla en construcción)',
            textAlign: TextAlign.center),
      ),
    );
  }
}