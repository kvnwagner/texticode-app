import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OperarioHomeScreen extends StatelessWidget {
  const OperarioHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Operario'),
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
        child: Text('Bienvenido, Operario 👋\n(pantalla en construcción)',
            textAlign: TextAlign.center),
      ),
    );
  }
}