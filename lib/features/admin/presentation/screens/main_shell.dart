import 'package:flutter/material.dart';
import 'operarios_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import 'admin_home_screen.dart';
import 'perfil_screen.dart'; // ⬅️ nuevo (compañero)
import 'produccion_screen.dart'; // ⬅️ nuevo — Gestión de Producción (compañero)
import 'clientes_screen.dart'; // ⬅️ nuevo (tu rama)
import 'inventario_screen.dart'; // ⬅️ nuevo — Gestión de Inventario

/// Contenedor principal del panel admin: header + sub-tabs superiores
/// (Usuarios | Clientes | Operarios) + dock inferior de 5 iconos.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _bottomIndex = 0; // 0 Usuarios/Clientes/Operarios · 1 Producción · 2 Estadísticas · 3 Inventario · 4 Perfil
  int _topIndex = 0; // 0 Usuarios · 1 Clientes · 2 Operarios (solo aplica si _bottomIndex == 0)

  static const _bottomIcons = [
    Icons.people_alt_rounded,
    Icons.inventory_2_outlined,
    Icons.bar_chart_rounded,
    Icons.settings_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_bottomIndex == 0) _buildHeader(),
            if (_bottomIndex == 0) _buildTopTabs(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _buildDock(),
    );
  }

  // ⬅️ Botón de cerrar sesión ELIMINADO del header (ya vive en
  // PerfilScreen, tal como pediste).
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo_texticode.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const AvatarWidget(
                  initials: 'TC',
                  size: 38,
                  bg: AppColors.navy,
                  text: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gestión de Usuarios',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text('Administración y control de accesos',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_bottomIndex) {
      case 0:
        switch (_topIndex) {
          case 0:
            return const AdminHomeScreen();
          case 1:
            return const ClientesScreen();
          case 2:
          default:
            return const OperariosScreen(); // ⬅️ corregido: antes era _SectionPlaceholder
        }
      case 1:
        return const ProduccionScreen();
      case 2:
        return const _SectionPlaceholder(
            title: 'Estadísticas', icon: Icons.bar_chart_rounded);
      case 3:
        return const InventarioScreen();
      case 4:
      default:
        return const PerfilScreen();
    }
  }

  Widget _buildTopTabs() {
    const tabs = ['Usuarios', 'Clientes', 'Operarios'];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(tabs.length, (i) {
          final selected = i == _topIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _topIndex = i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? AppColors.navy : AppColors.textFaint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2.5,
                    width: 28,
                    color: selected ? AppColors.navy : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

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
              onTap: () => setState(() {
                _bottomIndex = i;
                if (i == 0) _topIndex = 0;
              }),
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

class _SectionPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionPlaceholder({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}