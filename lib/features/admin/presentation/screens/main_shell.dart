import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'operarios_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import 'admin_home_screen.dart';
import 'perfil_screen.dart'; // ⬅️ nuevo (compañero)
import 'produccion_screen.dart'; // ⬅️ nuevo — Gestión de Producción (compañero)
import 'clientes_screen.dart'; // ⬅️ nuevo (tu rama)
import 'inventario_screen.dart'; // ⬅️ nuevo — Gestión de Inventario
import 'reportes_screen.dart'; // ⬅️ nuevo — Reportes

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

  // Mientras arrastras el dedo por el dock:
  // - _dragX es la posición X real del dedo (para que la píldora lo
  //   siga de forma continua, no a saltos de ícono en ícono).
  // - _dragIndex es a qué ícono corresponde esa posición (para saber
  //   cuál pintar de blanco/resaltado).
  // Ambos son null cuando no hay un arrastre en curso. El contenido de
  // la pantalla (_bottomIndex) solo se actualiza al soltar el dedo.
  double? _dragX;
  int? _dragIndex;

  static const _bottomIcons = [
    Icons.people_alt_rounded,
    Icons.inventory_2_outlined,
    Icons.bar_chart_rounded,
    Icons.settings_outlined,
    Icons.person_outline_rounded,
  ];

  // Controla el deslizamiento de contenido entre Usuarios / Clientes /
  // Operarios (las 3 sub-pestañas de arriba). Sincronizado con
  // _topIndex en ambas direcciones: deslizar cambia _topIndex, y tocar
  // una pestaña anima el PageView hasta ella.
  final _topPageController = PageController();

  @override
  void dispose() {
    _topPageController.dispose();
    super.dispose();
  }

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
        // Deslizable: PageView en vez de un switch fijo. onPageChanged
        // mantiene _topIndex sincronizado con la página visible cuando
        // el cambio viene de deslizar (no de tocar la pestaña).
        return PageView(
          controller: _topPageController,
          onPageChanged: (i) => setState(() => _topIndex = i),
          children: const [
            AdminHomeScreen(),
            ClientesScreen(),
            OperariosScreen(),
          ],
        );
      case 1:
        return const ProduccionScreen();
      case 2:
        return const ReportesScreen(); // ⬅️ nuevo — antes era _SectionPlaceholder(Estadísticas)
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
              // Al tocar una pestaña, el PageView se desliza animado
              // hasta ella (en vez de solo saltar con setState). El
              // propio onPageChanged del PageView actualiza _topIndex
              // cuando la animación termina.
              onTap: () => _topPageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
              ),
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
    const dockHeight = 62.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: dockHeight,
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
        // El LayoutBuilder va DENTRO del Container (después del borde),
        // no afuera. En Flutter, un Border dentro de una BoxDecoration
        // sí le agrega un padding implícito al Container igual a su
        // grosor (border.dimensions) — si el LayoutBuilder mide el
        // ancho ANTES de esa reducción, el cálculo de iconWidth queda
        // más grande de lo real y el Row termina desbordado por esos
        // mismos pixeles del borde (justo el "overflowed by 2.0
        // pixels" que salía). Midiendo aquí adentro, coincide 1:1 con
        // el espacio que el Row realmente tiene disponible.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final iconWidth = width / _bottomIcons.length;

            // Tamaño de la píldora en reposo vs. mientras arrastras
            // ("modo burbuja" — se ensancha un poco al mover el dedo).
            const pillWidthIdle = 44.0;
            const pillWidthDragging = 60.0;
            const pillHeight = 42.0;

            int indexForX(double x) =>
                (x / iconWidth).floor().clamp(0, _bottomIcons.length - 1);

            void updateDrag(Offset localPosition) {
              final x = localPosition.dx.clamp(0.0, width - 0.01);
              final index = indexForX(x);
              if (index != _dragIndex) HapticFeedback.selectionClick();
              setState(() {
                _dragX = x;
                _dragIndex = index;
              });
            }

            // Al soltar: la píldora "cae" en el ícono elegido y ahí sí
            // se confirma la navegación real.
            void commitSelection() {
              if (_dragIndex == null) {
                setState(() => _dragX = null);
                return;
              }
              setState(() {
                _bottomIndex = _dragIndex!;
                if (_bottomIndex == 0) _topIndex = 0;
                _dragIndex = null;
                _dragX = null;
              });
            }

            final dragging = _dragX != null;
            final displayIndex = _dragIndex ?? _bottomIndex;
            final pillWidth = dragging ? pillWidthDragging : pillWidthIdle;

            // Mientras arrastras, la píldora sigue el dedo de forma
            // continua (no salta de ícono en ícono). En reposo (o justo
            // después de soltar), queda centrada bajo el ícono activo.
            final pillLeft = dragging
                ? (_dragX! - pillWidth / 2).clamp(0.0, width - pillWidth)
                : (displayIndex * iconWidth + (iconWidth - pillWidth) / 2)
                    .clamp(0.0, width - pillWidth);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (details) => updateDrag(details.localPosition),
              onPanUpdate: (details) => updateDrag(details.localPosition),
              onPanEnd: (_) => commitSelection(),
              onPanCancel: () => setState(() {
                _dragIndex = null;
                _dragX = null;
              }),
              child: Stack(
                children: [
                  // Píldora ovalada de fondo — se mueve suave y continua
                  // (AnimatedPositioned) y se ensancha al arrastrar
                  // (AnimatedContainer con curva rápida tipo burbuja).
                  AnimatedPositioned(
                    duration: Duration(milliseconds: dragging ? 60 : 220),
                    curve: Curves.easeOut,
                    left: pillLeft,
                    top: (dockHeight - 2 - pillHeight) / 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      width: pillWidth,
                      height: pillHeight,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(pillHeight / 2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_bottomIcons.length, (i) {
                      final selected = i == displayIndex;
                      return IgnorePointer(
                        // El toque ya lo maneja el GestureDetector de
                        // arriba (para que el arrastre funcione en todo
                        // el panel, no solo dentro de cada ícono).
                        child: SizedBox(
                          width: iconWidth,
                          height: double.infinity,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 120),
                              child: Icon(
                                _bottomIcons[i],
                                key: ValueKey(selected),
                                size: 20,
                                color: selected ? Colors.white : AppColors.textFaint,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}