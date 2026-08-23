import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'cliente_dashboard_screen.dart';
import 'cliente_pedidos_screen.dart';
import 'cliente_soporte_screen.dart';
import 'cliente_perfil_screen.dart';

class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  int _tab = 0;

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  static const _icons = [
    Icons.home_outlined,
    Icons.shopping_bag_outlined,
    Icons.support_agent_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      ClienteDashboardScreen(onGoOrders: () => setState(() => _tab = 1)),
      const ClientePedidosScreen(),
      const ClienteSoporteScreen(),
      ClientePerfilScreen(onLogout: _logout),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: _buildDock(),
    );
  }

  /// Dock inferior — mismo diseño exacto que el de
  /// operario/presentation/screens/operario_home_screen.dart:
  /// contenedor blanco flotante con borde, sombra suave, icono
  /// seleccionado dentro de una caja navy redondeada con animación.
  Widget _buildDock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_icons.length, (i) {
            final selected = i == _tab;
            return GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _icons[i],
                  size: 20,
                  color: selected ? Colors.white : AppColors.textFaint,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}