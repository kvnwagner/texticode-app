import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/models/eficiencia_operario_model.dart';
import '../../data/repositories/eficiencia_repository.dart';

class EficienciaDetailSheet extends StatefulWidget {
  final int idUsuario;
  const EficienciaDetailSheet({super.key, required this.idUsuario});

  static Future<void> show(BuildContext context, int idUsuario) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EficienciaDetailSheet(idUsuario: idUsuario),
    );
  }

  @override
  State<EficienciaDetailSheet> createState() => _EficienciaDetailSheetState();
}

class _EficienciaDetailSheetState extends State<EficienciaDetailSheet> {
  final _repo = EficienciaRepository();
  final _authRepo = AuthRepository();

  // ✅ FIX: antes era `const int _idAdminActual = 1;` (fijo, sin importar
  // quién iniciaba sesión). Si en la tabla `usuario` no existía una fila
  // con Id_Usuario = 1, el INSERT de la observación fallaba por foreign
  // key en el backend, y como no había feedback visible en la UI, parecía
  // que "no pasaba nada" al guardar. Ahora se carga el admin real desde
  // AuthRepository (mismo usuario que guardó el login).
  int? _idAdminActual;

  Map<String, dynamic>? _detalle;
  bool _loading = true;
  String? _error;

  String _periodo = 'semana'; // semana | mes | trimestre
  EficienciaHistorial? _historial;
  bool _loadingHistorial = true;

  final Map<int, TextEditingController> _obsControllers = {};
  final Set<int> _guardandoObs = {}; // Id_Orden en proceso de guardar
  final Set<int> _eliminandoObs = {}; // Id_Observacion en proceso de eliminar
  int? _ordenExpandida; // Id_Orden actualmente desplegada

  @override
  void initState() {
    super.initState();
    _cargarAdminActual();
    _cargar();
    _cargarHistorial();
  }

  @override
  void dispose() {
    for (final c in _obsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Carga el Id_Usuario del admin realmente autenticado (guardado por
  /// AuthRepository durante el login) en vez de usar un valor fijo.
  Future<void> _cargarAdminActual() async {
    final usuario = await _authRepo.getUsuarioGuardado();
    if (!mounted) return;
    setState(() => _idAdminActual = usuario?.idUsuario);
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getOperarioDetalle(widget.idUsuario);
      if (!mounted) return;
      setState(() => _detalle = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarHistorial() async {
    setState(() => _loadingHistorial = true);
    try {
      final h = await _repo.getHistorial(widget.idUsuario, _periodo);
      if (!mounted) return;
      setState(() => _historial = h);
    } catch (_) {
      if (mounted) setState(() => _historial = null);
    } finally {
      if (mounted) setState(() => _loadingHistorial = false);
    }
  }

  void _cambiarPeriodo(String p) {
    if (p == _periodo) return;
    setState(() => _periodo = p);
    _cargarHistorial();
  }

  TextEditingController _controllerFor(int idOrden) {
    return _obsControllers.putIfAbsent(idOrden, () => TextEditingController());
  }

  Future<void> _guardarObservacion(int idOrden) async {
    final ctrl = _controllerFor(idOrden);
    final texto = ctrl.text.trim();
    if (texto.isEmpty) return;

    // ✅ FIX: si por alguna razón no hay sesión guardada, avisamos en vez
    // de mandar un Id_Admin inválido o nulo al backend.
    if (_idAdminActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar tu sesión de administrador.'),
        ),
      );
      return;
    }

    setState(() => _guardandoObs.add(idOrden));
    try {
      await _repo.crearObservacion(
        idOperario: widget.idUsuario,
        idAdmin: _idAdminActual!,
        idOrden: idOrden,
        observacion: texto,
      );
      ctrl.clear();
      await _cargar();
      // ✅ FIX: feedback de éxito visible — antes, si el guardado fallaba
      // silenciosamente en el backend, no había forma de saberlo desde la UI.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Observación guardada correctamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _guardandoObs.remove(idOrden));
    }
  }

  Future<void> _eliminarObservacion(ObservacionOperario obs) async {
    setState(() => _eliminandoObs.add(obs.idObservacion));
    try {
      await _repo.eliminarObservacion(obs.idObservacion);
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Observación eliminada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _eliminandoObs.remove(obs.idObservacion));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    final rendimiento = _detalle?['rendimiento'] as String?;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration:
                      BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(4)),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _detalle?['Nombre_Completo'] ?? 'Detalle del operario',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    if (rendimiento != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: eficienciaRendimientoBg(rendimiento),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(rendimiento,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: eficienciaRendimientoColor(rendimiento))),
                      ),
                    ],
                  ],
                ),
                if (_detalle?['Nombre_Usuario'] != null)
                  Text('@${_detalle!['Nombre_Usuario']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppColors.searchBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.close, size: 15, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.navy));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 12),
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

    final ordenes = (_detalle?['ordenes_detalle'] as List?) ?? [];

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // Métricas generales
        Row(
          children: [
            _chip('Prendas/día', '${_detalle?['prendas_por_dia']}'),
            const SizedBox(width: 8),
            _chip('Producidas', '${_detalle?['total_unidades_producidas']}'),
            const SizedBox(width: 8),
            _chip('En retraso', '${_detalle?['ordenes_en_retraso']}'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _chipEstado('Completadas', '${_detalle?['ordenes_completadas'] ?? 0}',
                AppColors.iconActive),
            const SizedBox(width: 8),
            _chipEstado('En Proceso', '${_detalle?['ordenes_en_proceso'] ?? 0}', AppColors.iconOp),
            const SizedBox(width: 8),
            _chipEstado('Pausadas', '${_detalle?['ordenes_pausadas'] ?? 0}', AppColors.iconClient),
          ],
        ),
        const SizedBox(height: 20),
        _buildTendencia(),
        const SizedBox(height: 20),
        const Text('Órdenes',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        if (ordenes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Sin órdenes asignadas', style: TextStyle(color: AppColors.textFaint)),
          ),
        ...ordenes.map((o) => _buildOrdenTile(OrdenEficienciaDetalle.fromJson(o as Map<String, dynamic>))),
      ],
    );
  }

  Widget _chip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.searchBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _chipEstado(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  // ── Tendencia de rendimiento ──
  Widget _buildTendencia() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Tendencia de rendimiento',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              _buildPeriodoSelector(),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingHistorial)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child:
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_historial == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No se pudo cargar la tendencia.',
                  style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
            )
          else
            _buildTendenciaContenido(_historial!),
        ],
      ),
    );
  }

  Widget _buildPeriodoSelector() {
    const opciones = [('semana', 'Semana'), ('mes', 'Mes'), ('trimestre', 'Trimestre')];
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: opciones.map((o) {
          final selected = _periodo == o.$1;
          return GestureDetector(
            onTap: () => _cambiarPeriodo(o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.navy : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(o.$2,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textMuted)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTendenciaContenido(EficienciaHistorial h) {
    final (icon, color, label) = switch (h.tendencia) {
      'subiendo' => (Icons.arrow_upward_rounded, AppColors.iconActive, 'Subiendo'),
      'bajando' => (Icons.arrow_downward_rounded, AppColors.errorText, 'Bajando'),
      _ => (Icons.remove_rounded, AppColors.textMuted, 'Estable'),
    };
    final diferenciaLabel = h.diferenciaPrendas == 0
        ? '0 prendas/día vs periodo anterior'
        : '${h.diferenciaPrendas > 0 ? '+' : ''}${h.diferenciaPrendas} prendas/día vs periodo anterior';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                    Text(diferenciaLabel,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (h.actual.retrasos > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.errorBg, borderRadius: BorderRadius.circular(999)),
                  child: Text('${h.actual.retrasos} retraso(s)',
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.errorText)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _periodoCard('ESTE PERIODO', h.actual)),
            const SizedBox(width: 10),
            Expanded(child: _periodoCard('PERIODO ANTERIOR', h.anterior)),
          ],
        ),
      ],
    );
  }

  Widget _periodoCard(String titulo, EficienciaHistorialPeriodo p) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textFaint)),
          const SizedBox(height: 4),
          Text('${p.prendasPorDia} prendas/día',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 11, color: AppColors.iconActive),
              const SizedBox(width: 3),
              Text('${p.completadas} completadas',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 11, color: p.retrasos > 0 ? AppColors.errorText : AppColors.textFaint),
              const SizedBox(width: 3),
              Text('${p.retrasos} retrasos',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Orden expandible + observaciones editables ──
  Widget _buildOrdenTile(OrdenEficienciaDetalle o) {
    final expanded = _ordenExpandida == o.idOrden;
    final accent = o.vencida ? AppColors.errorText : AppColors.navy;
    final ctrl = _controllerFor(o.idOrden);
    final guardando = _guardandoObs.contains(o.idOrden);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded
              ? accent.withValues(alpha: 0.45)
              : (o.vencida ? AppColors.errorBorder : AppColors.cardBorder),
          width: expanded ? 1.4 : 1,
        ),
        boxShadow: expanded
            ? [
                BoxShadow(
                    color: accent.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 6)),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (siempre visible, toca para expandir) ──
          InkWell(
            onTap: () => setState(() => _ordenExpandida = expanded ? null : o.idOrden),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(o.producto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                      if (o.tieneProblema) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.iconClient.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.report_problem_outlined,
                                  size: 11, color: AppColors.iconClient),
                              const SizedBox(width: 3),
                              Text('${o.observaciones.length}',
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.iconClient)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (o.vencida)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('Vencida',
                              style: TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.errorText)),
                        ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20, color: AppColors.textFaint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(o.estado,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                      Text('${(o.avance * 100).round()}%',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: o.avance,
                      minHeight: 5,
                      backgroundColor: AppColors.cardBorder,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenido expandido ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _miniInfo(
                              'Unidades', '${o.unidadesRealizadas} / ${o.unidades}')),
                      Expanded(
                          child: _miniInfo('Vence',
                              o.fechaLimiteCorta.isEmpty ? '—' : o.fechaLimiteCorta)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.forum_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text('Observaciones — Orden #${o.idOrden}',
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (o.observaciones.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('Sin observaciones registradas.',
                          style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
                    )
                  else
                    ...o.observaciones.map((obs) => _buildObservacionRow(obs)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ctrl,
                    maxLength: 500,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '',
                      hintText: 'Describe el problema de la orden #${o.idOrden}...',
                      hintStyle: const TextStyle(fontSize: 11, color: AppColors.textFaint),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: guardando ? null : () => _guardarObservacion(o.idOrden),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: guardando
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Guardar',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.4, color: AppColors.textFaint)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildObservacionRow(ObservacionOperario obs) {
    final eliminando = _eliminandoObs.contains(obs.idObservacion);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.iconClient.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iconClient.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.iconClient.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: const Icon(Icons.person_outline, size: 13, color: AppColors.iconClient),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(obs.admin,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ),
                    Text(obs.fechaCorta,
                        style: const TextStyle(fontSize: 9, color: AppColors.textFaint)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(obs.observacion,
                    style: const TextStyle(fontSize: 11.5, height: 1.3, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: eliminando ? null : () => _eliminarObservacion(obs),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: eliminando
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.errorText))
                  : const Icon(Icons.delete_outline, size: 14, color: AppColors.errorText),
            ),
          ),
        ],
      ),
    );
  }
}