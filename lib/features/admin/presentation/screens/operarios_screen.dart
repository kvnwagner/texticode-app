import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../operario/presentation/screens/operario_shared_widgets.dart'; // SearchBox / FilterDropdown
import '../../data/models/eficiencia_operario_model.dart';
import '../../data/models/carga_trabajo_model.dart';
import '../../data/repositories/eficiencia_repository.dart';
import '../../data/repositories/carga_trabajo_repository.dart';
import '../widgets/reassign_orders_view.dart';
import '../widgets/eficiencia_ranking_card.dart';
import '../widgets/eficiencia_detail_sheet.dart';
import '../widgets/carga_detail_sheet.dart';

enum _RendimientoFiltro { todos, alto, medio, bajo }

class OperariosScreen extends StatefulWidget {
  const OperariosScreen({super.key});

  @override
  State<OperariosScreen> createState() => _OperariosScreenState();
}

class _OperariosScreenState extends State<OperariosScreen> {
  // ── Carga de Trabajo (AHORA VIENE DEL BACKEND, igual que la web) ──
  final _cargaRepo = CargaTrabajoRepository();

  CargaTrabajoResultado? _cargaResultado;
  bool _loading = true;
  String? _error;

  // 0 = Rendimiento & Eficiencia · 1 = Carga Laboral (el diseño abre en Carga Laboral)
  int _tab = 1;

  // Si es true, el body completo de la pestaña se reemplaza por la vista
  // de "Reasignación de Órdenes" (ya no es un sheet emergente).
  bool _mostrarReasignacion = false;

  // ── Sugerencias de reasignación (solo se cargan al entrar a esa vista) ──
  List<SugerenciaCarga> _sugerencias = [];
  bool _loadingSugerencias = false;
  String? _errorSugerencias;

  // ── Eficiencia (sin cambios) ──
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

  // ── CARGA DE TRABAJO (ahora desde /api/carga-trabajo) ──
  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _cargaRepo.getCarga();
      if (!mounted) return;
      setState(() => _cargaResultado = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CargaOperario> get _operarios => _cargaResultado?.operarios ?? [];

  int get _totalOrdenesActivas =>
      _operarios.fold<int>(0, (a, o) => a + o.ordenesActivas);

  // ── SUGERENCIAS (solo cuando se entra a "Reasignar Órdenes") ──
  Future<void> _cargarSugerencias() async {
    setState(() {
      _loadingSugerencias = true;
      _errorSugerencias = null;
    });
    try {
      final data = await _cargaRepo.getSugerencias();
      if (!mounted) return;
      setState(() => _sugerencias = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorSugerencias = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingSugerencias = false);
    }
  }

  void _abrirReasignacion() {
    setState(() => _mostrarReasignacion = true);
    // Refresca también la carga (de ahí sale "disponibles"), no solo las
    // sugerencias: si el estado de los operarios cambió desde que se
    // cargó la pestaña (p. ej. alguien completó una fase, o se reasignó
    // algo desde la web), aquí es donde había quedado desactualizado.
    _cargar();
    _cargarSugerencias();
  }

  void _onCambioReasignacion() {
    // Tras reasignar, la carga y las sugerencias restantes cambian.
    _cargar();
    _cargarSugerencias();
  }

  // ── EFICIENCIA (sin cambios) ──
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
      return Container(
        color: AppColors.pageBg,
        child: _loadingSugerencias
            ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
            : _errorSugerencias != null
                ? _buildErrorSugerencias()
                : ReassignOrdersView(
                    sobrecargados: _cargaResultado?.sobrecargados ?? [],
                    sugerencias: _sugerencias,
                    disponibles: _cargaResultado?.disponibles ?? [],
                    onChanged: _onCambioReasignacion,
                    onBack: () => setState(() => _mostrarReasignacion = false),
                  ),
      );
    }

    return Container(
      color: AppColors.pageBg,
      child: _tab == 0 ? _buildEficienciaBody() : _buildCargaBody(),
    );
  }

  Widget _buildErrorSugerencias() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(_errorSugerencias!,
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => setState(() => _mostrarReasignacion = false),
                  child: const Text('Volver'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _cargarSugerencias,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
                  child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // VISTA EFICIENCIA (sin cambios)
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
  // VISTA CARGA DE TRABAJO — AHORA USA CargaOperario DEL BACKEND
  // ════════════════════════════════════════════

  Widget _buildCargaBody() {
    final resumen = _cargaResultado?.resumen;
    final disponibles = resumen?.disponibles ?? 0;
    final sobrecargados = resumen?.sobrecargados ?? 0;
    final ordenesActivas = _totalOrdenesActivas;

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
                    _buildSegmented(),
                    const SizedBox(height: 16),
                    _buildStats(disponibles, sobrecargados, ordenesActivas),
                    const SizedBox(height: 16),
                    _buildReasignarButton(sobrecargados),
                    const SizedBox(height: 20),
                    _buildSectionHeader(_operarios.length),
                    const SizedBox(height: 4),
                    if (_operarios.isEmpty) _buildEmpty(),
                    ..._operarios.map(_buildCargaCard),
                  ],
                ),
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
          _segmentButton('Carga de Trabajo', 1),
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

  Widget _buildReasignarButton(int sobrecargados) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: sobrecargados == 0 ? null : _abrirReasignacion,
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

  Color _estadoColor(CargaOperario c) {
    if (c.esSobrecargado) return AppColors.errorText;
    if (c.esDisponible) return AppColors.iconActive;
    return AppColors.iconOp; // normal
  }

  Color _estadoBg(CargaOperario c) {
    if (c.esSobrecargado) return AppColors.errorBg;
    if (c.esDisponible) return AppColors.badgeOpGreenBg;
    return AppColors.badgeOpBlueBg; // normal
  }

  String _estadoLabel(CargaOperario c) {
    if (c.esSobrecargado) return 'Sobrecargado';
    if (c.esDisponible) return 'Disponible';
    return 'Normal';
  }

  /// Abre el detalle del operario (mismo contenido que el modal de la web).
  void _verDetalle(CargaOperario c) {
    final av = AppColors.avatarPalette[c.idUsuario % AppColors.avatarPalette.length];
    CargaDetailSheet.show(
      context,
      operario: c,
      estadoLabel: _estadoLabel(c),
      estadoColor: _estadoColor(c),
      estadoBg: _estadoBg(c),
      avatarBg: av['bg']!,
      avatarText: av['text']!,
    );
  }

  Widget _buildCargaCard(CargaOperario c) {
    final av = AppColors.avatarPalette[c.idUsuario % AppColors.avatarPalette.length];
    final estadoColor = _estadoColor(c);
    final estadoBg = _estadoBg(c);
    final estadoLabel = _estadoLabel(c);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.pageBg,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(18),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3.5, color: estadoColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Fila 1: avatar · nombre + resumen · ojo ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AvatarWidget(initials: c.initials, size: 42, bg: av['bg']!, text: av['text']!),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    c.nombreCompleto,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${c.ordenesActivas} órdenes activas · ${c.fasesActivas} fases',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _verDetalleButton(c),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ── Fila 2: estado · vencidas · alta prioridad (en línea) ──
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _miniBadge(estadoLabel, estadoColor, estadoBg),
                            if (c.ordenesVencidas > 0)
                              _miniBadge(
                                '${c.ordenesVencidas} vencida${c.ordenesVencidas == 1 ? '' : 's'}',
                                AppColors.errorText,
                                AppColors.errorBg,
                              ),
                            if (c.ordenesAltaPrioridad > 0)
                              _miniBadge(
                                '${c.ordenesAltaPrioridad} alta prioridad',
                                AppColors.iconClient,
                                AppColors.badgeOpBlueBg,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Botón circular del ojo (mismo estilo que el de las órdenes de producción).
  Widget _verDetalleButton(CargaOperario c) {
    return Material(
      color: AppColors.pageBg,
      shape: const CircleBorder(side: BorderSide(color: AppColors.cardBorder)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _verDetalle(c),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.visibility_outlined, size: 18, color: AppColors.navy),
        ),
      ),
    );
  }

  Widget _miniBadge(String texto, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: fg)),
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