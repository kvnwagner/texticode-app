import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'perfil_screen.dart';

/// Home / shell del rol cliente.
///
/// TODO PARA EL EQUIPO: cada tab de abajo (menos "Perfil", que ya está
/// terminado) es un PLACEHOLDER "En construcción". Cuando alguien vaya a
/// construir esa pantalla:
///   1. Crea el archivo en lib/features/cliente/presentation/screens/
///   2. Reemplaza el `_SectionPlaceholder(...)` correspondiente en
///      `_buildBody()` por tu widget real (mismo patrón que se hizo con
///      `AdminHomeScreen` dentro de `MainShell`).
/// No borres el dock ni los íconos: son la guía de qué falta por hacer.
class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  int _bottomIndex = 0; // 0 Pedidos · 1 Seguimiento · 2 Historial · 3 Configuración · 4 Perfil

  // ⚠️ Nombres/íconos tentativos — el equipo los puede ajustar según
  // las pantallas reales que se definan para el rol Cliente.
  static const _bottomIcons = [
    Icons.shopping_bag_outlined,
    Icons.local_shipping_outlined,
    Icons.receipt_long_outlined,
    Icons.settings_outlined,
    Icons.person_outline_rounded,
  ];

  static const _bottomLabels = [
    'Pedidos',
    'Seguimiento',
    'Historial',
    'Configuración',
    'Perfil',
  ];

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        bottom: false,
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildDock(),
    );
  }

  Widget _buildBody() {
    if (_bottomIndex == 4) return const PerfilScreen();
    return _SectionPlaceholder(
      title: _bottomLabels[_bottomIndex],
      icon: _bottomIcons[_bottomIndex],
      onLogout: _logout,
    );
  }

  // Mismo dock (tamaño, radios, animación) que usa MainShell en Admin,
  // para que la navegación se sienta igual entre roles.
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
          children: List.generate(_bottomIcons.length, (i) {
            final selected = i == _bottomIndex;
            return GestureDetector(
              onTap: () => setState(() => _bottomIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _bottomIcons[i],
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

/// Placeholder "En construcción" para los tabs que todavía no tiene el
/// rol cliente. Incluye el mismo botón de cerrar sesión que tenía la
/// pantalla anterior, para no perder esa función mientras se construyen
/// las vistas reales.
class _SectionPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onLogout;

  const _SectionPlaceholder({
    required this.title,
    required this.icon,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                GestureDetector(
                  onTap: onLogout,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.errorBorder),
                    ),
                    child: const Icon(Icons.logout, size: 16, color: AppColors.errorText),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: AppColors.textFaint),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textFaint)),
                  const SizedBox(height: 4),
                  const Text('En construcción',
                      style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}