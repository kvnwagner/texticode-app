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

  @override
  Widget build(BuildContext context) {
    final pages = [
      ClienteDashboardScreen(
        onGoOrders: () => setState(() => _tab = 1),
        onLogout: _logout,
      ),
      ClientePedidosScreen(onLogout: _logout),
      ClienteSoporteScreen(onLogout: _logout),
      ClientePerfilScreen(onLogout: _logout),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(index: _tab, children: pages),
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: _FloatingTabBar(active: _tab, onTap: (i) => setState(() => _tab = i)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  final int active;
  final ValueChanged<int> onTap;
  const _FloatingTabBar({required this.active, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Inicio'),
    (Icons.shopping_bag_outlined, Icons.shopping_bag, 'Pedidos'),
    (Icons.support_agent_outlined, Icons.support_agent, 'Soporte'),
    (Icons.person_outline, Icons.person, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xEBF9FAFB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final on = active == i;
          final (outline, filled, _) = _items[i];
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: on ? AppColors.navy.withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(on ? filled : outline, size: 21, color: on ? AppColors.navy : AppColors.textFaint),
            ),
          );
        }),
      ),
    );
  }
}