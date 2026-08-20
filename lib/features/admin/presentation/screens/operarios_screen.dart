import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/orden_model.dart';
import '../../data/repositories/usuario_repository.dart';
import '../../data/repositories/orden_repository.dart';
import '../widgets/reassign_orders_sheet.dart';

/// Pantalla "Eficiencia" / Gestión de Operarios.
/// Cruza en el cliente los datos de GET /api/usuarios (rol Operario) y
/// GET /api/ordenes (Supabase, vía tu backend Express) para calcular
/// carga de trabajo y eficiencia en tiempo real. Mismo patrón exacto que
/// ClientesScreen/ProduccionScreen: dos repos, Future.wait, pull-to-refresh.
class OperariosScreen extends StatefulWidget {
  const OperariosScreen({super.key});

  @override
  State<OperariosScreen> createState() => _OperariosScreenState();
}

class _OperariosScreenState extends State<OperariosScreen> {
  final _usuarioRepo = UsuarioRepository();
  final _ordenRepo = OrdenRepository();

  // ⚠️ El backend actual no expone una "capacidad" configurable por
  // operario (no hay columna Capacidad en `usuario`). Se asume una
  // capacidad fija de 5 órdenes activas simultáneas — el mismo valor
  // que se ve en el diseño (3/5 = 60%, 2/5 = 40%). Cuando exista esa
  // columna en Supabase, reemplaza esta constante por el valor real.
  static const int _capacidadDefault = 5;

  List<Usuario> _operarios = [];
  List<Orden> _ordenes = [];
  bool _loading = true;
  String? _error;

  // 0 = Rendimiento & Eficiencia · 1 = Carga Laboral (el diseño abre en Carga Laboral)
  int _tab = 1;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resultados = await Future.wait([
        _usuarioRepo.getUsuarios(),
        _ordenRepo.getOrdenes(),
      ]);
      if (!mounted) return;
      setState(() {
        _operarios =
            (resultados[0] as List<Usuario>).where((u) => u.isOperario).toList();
        _ordenes = resultados[1] as List<Orden>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_CargaOperario> get _cargas {
    return _operarios.map((op) {
      final asignadas =
          _ordenes.where((o) => o.idOperario == op.idUsuario).toList();
      final activas = asignadas.where((o) => !o.isCompletada).length;
      final completadas = asignadas.where((o) => o.isCompletada).length;
      return _CargaOperario(
        usuario: op,
        activas: activas,
        completadas: completadas,
        totalAsignadas: asignadas.length,
        capacidad: _capacidadDefault,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cargas = _cargas;
    final disponibles = cargas.where((c) => !c.isSobrecargado).length;
    final sobrecargados = cargas.where((c) => c.isSobrecargado).length;
    final ordenesActivas = _ordenes.where((o) => !o.isCompletada).length;

    return Container(
      color: AppColors.pageBg,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.navy,
                  onRefresh: _cargar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 16),
                      _buildSegmented(),
                      const SizedBox(height: 16),
                      _buildStats(disponibles, sobrecargados, ordenesActivas),
                      const SizedBox(height: 16),
                      _buildReasignarButton(cargas),
                      const SizedBox(height: 20),
                      _buildSectionHeader(cargas.length),
                      const SizedBox(height: 4),
                      if (cargas.isEmpty) _buildEmpty(),
                      if (_tab == 1)
                        ...cargas.map(_buildCargaCard)
                      else
                        ...cargas.map(_buildEficienciaCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Eficiencia',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        SizedBox(height: 2),
        Text('Gestión de Operarios',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        SizedBox(height: 2),
        Text('Monitorea el rendimiento y carga de trabajo en tiempo real.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildSegmented() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _segmentButton('Rendimiento & Eficiencia', 0),
          _segmentButton('Carga Laboral', 1),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, int index) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats(int disponibles, int sobrecargados, int ordenesActivas) {
    return Row(
      children: [
        Expanded(
          child: _StatMiniCard(
            icon: Icons.person_outline,
            iconColor: AppColors.iconActive,
            value: '$disponibles',
            label: 'Disponibles',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatMiniCard(
            icon: Icons.error_outline,
            iconColor: AppColors.errorText,
            value: '$sobrecargados',
            label: 'Sobrecargados',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatMiniCard(
            icon: Icons.assignment_outlined,
            iconColor: AppColors.iconOp,
            value: '$ordenesActivas',
            label: 'Órdenes activas',
          ),
        ),
      ],
    );
  }

  Widget _buildReasignarButton(List<_CargaOperario> cargas) {
    final sobrecargados = cargas.where((c) => c.isSobrecargado).toList();
    final disponibles = cargas.where((c) => !c.isSobrecargado).toList();
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: sobrecargados.isEmpty
            ? null
            : () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ReassignOrdersSheet(
                    sobrecargados: sobrecargados.map((c) => c.usuario).toList(),
                    disponibles: disponibles.map((c) => c.usuario).toList(),
                    ordenes: _ordenes,
                    onChanged: _cargar,
                  ),
                ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text('Reasignar Órdenes',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        const Text('Operarios',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
          child: Text('$count',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildCargaCard(_CargaOperario c) {
    final av = AppColors.avatarPalette[c.usuario.idUsuario % AppColors.avatarPalette.length];
    final estadoColor = c.isSobrecargado ? AppColors.errorText : AppColors.iconActive;
    final estadoBg = c.isSobrecargado ? AppColors.errorBg : AppColors.badgeOpGreenBg;
    final estadoLabel = c.isSobrecargado ? 'Sobrecargado' : 'Disponible';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(initials: c.usuario.initials, size: 40, bg: av['bg']!, text: av['text']!),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.usuario.nombreCompleto,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration:
                            BoxDecoration(color: estadoBg, borderRadius: BorderRadius.circular(20)),
                        child: Text(estadoLabel,
                            style:
                                TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: estadoColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${c.activas} órdenes · capacidad ${c.capacidad}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (c.percent / 100).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: AppColors.cardBorder,
                      valueColor: AlwaysStoppedAnimation(estadoColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('${c.percent}% capacidad',
                        style: const TextStyle(fontSize: 10, color: AppColors.textFaint)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEficienciaCard(_CargaOperario c) {
    final av = AppColors.avatarPalette[c.usuario.idUsuario % AppColors.avatarPalette.length];
    final eficiencia = c.eficiencia;
    final color = eficiencia >= 80
        ? AppColors.iconActive
        : (eficiencia >= 50 ? AppColors.iconClient : AppColors.errorText);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(initials: c.usuario.initials, size: 40, bg: av['bg']!, text: av['text']!),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.usuario.nombreCompleto,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                      Text('$eficiencia%',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${c.completadas} completadas de ${c.totalAsignadas} asignadas',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (eficiencia / 100).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: AppColors.cardBorder,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.engineering_outlined, size: 32, color: AppColors.textFaint),
          SizedBox(height: 8),
          Text('No hay operarios registrados',
              style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatMiniCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: iconColor)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Métricas de carga/eficiencia calculadas en el cliente a partir de
/// Usuario (rol Operario) + las Ordenes asignadas a él.
class _CargaOperario {
  final Usuario usuario;
  final int activas;
  final int completadas;
  final int totalAsignadas;
  final int capacidad;

  _CargaOperario({
    required this.usuario,
    required this.activas,
    required this.completadas,
    required this.totalAsignadas,
    required this.capacidad,
  });

  int get percent => capacidad == 0 ? 0 : ((activas / capacidad) * 100).round();
  bool get isSobrecargado => activas > capacidad;
  int get eficiencia => totalAsignadas == 0 ? 0 : ((completadas / totalAsignadas) * 100).round();
} 