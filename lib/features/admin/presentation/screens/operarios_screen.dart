import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../operario/presentation/screens/operario_shared_widgets.dart'; // SearchBox / FilterDropdown
import '../../data/models/usuario_model.dart';
import '../../data/models/orden_model.dart';
import '../../data/models/eficiencia_operario_model.dart';
import '../../data/repositories/usuario_repository.dart';
import '../../data/repositories/orden_repository.dart';
import '../../data/repositories/eficiencia_repository.dart';
import '../widgets/reassign_orders_view.dart';
import '../widgets/eficiencia_ranking_card.dart';
import '../widgets/eficiencia_detail_sheet.dart';


enum _RendimientoFiltro { todos, alto, medio, bajo }

class OperariosScreen extends StatefulWidget {
  const OperariosScreen({super.key});

  @override
  State<OperariosScreen> createState() => _OperariosScreenState();
}

class _OperariosScreenState extends State<OperariosScreen> {
  // ── Carga de Trabajo (SIN CAMBIOS) ──
  final _usuarioRepo = UsuarioRepository();
  final _ordenRepo = OrdenRepository();
  static const int _capacidadDefault = 5;

  List<Usuario> _operarios = [];
  List<Orden> _ordenes = [];
  bool _loading = true;
  String? _error;

  // 0 = Rendimiento & Eficiencia · 1 = Carga Laboral (el diseño abre en Carga Laboral)
  int _tab = 1;

  // Si es true, el body completo de la pestaña se reemplaza por la vista
  // de "Reasignación de Órdenes" (ya no es un sheet emergente).
  bool _mostrarReasignacion = false;

  // ── Eficiencia (NUEVO) ──
  final _eficienciaRepo = EficienciaRepository();
  List<EficienciaOperario> _eficienciaOperarios = [];
  bool _loadingEficiencia = true;
  String? _errorEficiencia;
  String _queryEficiencia = '';
  _RendimientoFiltro _filtroRendimiento = _RendimientoFiltro.todos;

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarEficiencia();
  }

  // ── CARGA (usuarios + ordenes, sin cambios) ──
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

  // ── EFICIENCIA (nuevo) ──
  Future<void> _cargarEficiencia() async {
    setState(() {
      _loadingEficiencia = true;
      _errorEficiencia = null;
    });
    try {
      final data = await _eficienciaRepo.getOperarios();
      if (!mounted) return;
      setState(() => _eficienciaOperarios = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorEficiencia = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingEficiencia = false);
    }
  }

  bool _matchRendimiento(EficienciaOperario o) {
    switch (_filtroRendimiento) {
      case _RendimientoFiltro.todos:
        return true;
      case _RendimientoFiltro.alto:
        return o.rendimiento == 'Alto';
      case _RendimientoFiltro.medio:
        return o.rendimiento == 'Medio';
      case _RendimientoFiltro.bajo:
        return o.rendimiento == 'Bajo';
    }
  }

  List<EficienciaOperario> get _eficienciaFiltrados {
    final q = _queryEficiencia.trim().toLowerCase();
    return _eficienciaOperarios.where((o) {
      final matchQ = q.isEmpty ||
          o.nombreCompleto.toLowerCase().contains(q) ||
          o.nombreUsuario.toLowerCase().contains(q);
      return matchQ && _matchRendimiento(o);
    }).toList();
  }

  double get _maxPrendasPorDia {
    if (_eficienciaOperarios.isEmpty) return 1;
    return _eficienciaOperarios
        .map((o) => o.prendasPorDia)
        .fold<double>(1, (a, b) => b > a ? b : a);
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrarReasignacion) {
      final cargas = _cargas;
      return Container(
        color: AppColors.pageBg,
        child: ReassignOrdersView(
          sobrecargados: cargas.where((c) => c.isSobrecargado).map((c) => c.usuario).toList(),
          disponibles: cargas.where((c) => !c.isSobrecargado).map((c) => c.usuario).toList(),
          ordenes: _ordenes,
          onChanged: _cargar,
          onBack: () => setState(() => _mostrarReasignacion = false),
        ),
      );
    }

    return Container(
      color: AppColors.pageBg,
      child: _tab == 0 ? _buildEficienciaBody() : _buildCargaBody(),
    );
  }

  // ════════════════════════════════════════════
  // VISTA EFICIENCIA (nueva, réplica de la web)
  // ════════════════════════════════════════════

  Widget _buildEficienciaBody() {
    return _loadingEficiencia
        ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
        : _errorEficiencia != null
            ? _buildErrorEficiencia()
            : RefreshIndicator(
                color: AppColors.navy,
                onRefresh: _cargarEficiencia,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 16),
                    _buildSegmented(),
                    const SizedBox(height: 16),
                    _buildBusquedaYFiltro(),
                    const SizedBox(height: 16),
                    _buildStatsEficiencia(),
                    const SizedBox(height: 20),
                    _buildSectionHeaderEficiencia(_eficienciaFiltrados.length),
                    const SizedBox(height: 10),
                    if (_eficienciaFiltrados.isEmpty) _buildEmptyEficiencia(),
                    ...List.generate(_eficienciaFiltrados.length, (i) {
                      final op = _eficienciaFiltrados[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EficienciaRankingCard(
                          operario: op,
                          rank: i + 1,
                          maxPrendasPorDia: _maxPrendasPorDia,
                          onVerDetalle: () => EficienciaDetailSheet.show(context, op.idUsuario),
                        ),
                      );
                    }),
                  ],
                ),
              );
  }

  Widget _buildBusquedaYFiltro() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SearchBox(
            hint: 'Buscar operario...',
            onChanged: (v) => setState(() => _queryEficiencia = v),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FilterDropdown<_RendimientoFiltro>(
            value: _filtroRendimiento,
            items: const {
              _RendimientoFiltro.todos: 'Todos',
              _RendimientoFiltro.alto: 'Alto',
              _RendimientoFiltro.medio: 'Medio',
              _RendimientoFiltro.bajo: 'Bajo',
            },
            onChanged: (v) => setState(() => _filtroRendimiento = v),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsEficiencia() {
    final total = _eficienciaOperarios.length;
    final alto = _eficienciaOperarios.where((o) => o.rendimiento == 'Alto').length;
    final bajo = _eficienciaOperarios.where((o) => o.rendimiento == 'Bajo').length;
    final retrasos = _eficienciaOperarios.fold<int>(0, (a, o) => a + o.ordenesEnRetraso);

    final items = <_EficienciaStatItem>[
      _EficienciaStatItem('Total Operarios', total, Icons.groups_outlined, AppColors.navy),
      _EficienciaStatItem('Rendimiento Alto', alto, Icons.emoji_events_outlined, AppColors.iconActive),
      _EficienciaStatItem('Órdenes en Retraso', retrasos, Icons.warning_amber_rounded, AppColors.errorText),
      _EficienciaStatItem('Rendimiento Bajo', bajo, Icons.trending_down_rounded, AppColors.iconClient),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 78,
      ),
      itemBuilder: (context, index) => _buildStatCardEficiencia(items[index]),
    );
  }

  Widget _buildStatCardEficiencia(_EficienciaStatItem s) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(width: 3.5, color: s.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${s.value}',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: s.color)),
                          const SizedBox(height: 3),
                          Text(s.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 9.5, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration:
                          BoxDecoration(color: s.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                      child: Icon(s.icon, size: 15, color: s.color),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeaderEficiencia(int count) {
    return Row(
      children: [
        const Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        const Text('Ranking de Operarios',
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

  Widget _buildEmptyEficiencia() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 32, color: AppColors.textFaint),
          SizedBox(height: 8),
          Text('No se encontraron operarios', style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorEficiencia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(_errorEficiencia!,
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarEficiencia,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // VISTA CARGA DE TRABAJO — SIN CAMBIOS (solo se movió a este método)
  // ════════════════════════════════════════════

  Widget _buildCargaBody() {
    final cargas = _cargas;
    final disponibles = cargas.where((c) => !c.isSobrecargado).length;
    final sobrecargados = cargas.where((c) => c.isSobrecargado).length;
    final ordenesActivas = _ordenes.where((o) => !o.isCompletada).length;

    return _loading
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
                    ...cargas.map(_buildCargaCard),
                  ],
                ),
              );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Eficiencia',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        SizedBox(height: 2),
        Text('Gestión de Operarios',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: sobrecargados.isEmpty
            ? null
            : () => setState(() => _mostrarReasignacion = true),
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

class _EficienciaStatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _EficienciaStatItem(this.label, this.value, this.icon, this.color);
}

/// Métricas de carga calculadas en el cliente a partir de
/// Usuario (rol Operario) + las Ordenes asignadas a él. Sin cambios.
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