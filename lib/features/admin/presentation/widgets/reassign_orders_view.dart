import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/carga_trabajo_model.dart';
import '../../data/repositories/carga_trabajo_repository.dart';

const List<String> _kMesesCortos = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sept', 'oct', 'nov', 'dic',
];

String _formatFecha(String raw) {
  try {
    final d = DateTime.parse(raw);
    return '${d.day} de ${_kMesesCortos[d.month - 1]} de ${d.year}';
  } catch (_) {
    return raw;
  }
}

/// Vista completa de "Reasignación de Órdenes".
///
/// La lista de arriba ("OPERARIO SOBRECARGADO") viene de [sobrecargados]
/// (la clasificación real de GET /api/carga-trabajo).
///
/// Para el operario seleccionado, las órdenes que se muestran NO salen de
/// [sugerencias] (eso solo trae los movimientos que el algoritmo pudo
/// calcular con la capacidad libre del momento, y por eso antes se veían
/// incompletas). Se piden TODAS sus fases/órdenes activas con
/// GET /api/carga-trabajo/operarios/:id. El usuario elige manualmente a
/// qué operario disponible reasignar cada orden.
class ReassignOrdersView extends StatefulWidget {
  final List<CargaOperario> sobrecargados;
  final List<SugerenciaCarga> sugerencias;
  final List<CargaOperario> disponibles;
  final VoidCallback onChanged;
  final VoidCallback onBack;

  const ReassignOrdersView({
    super.key,
    required this.sobrecargados,
    required this.sugerencias,
    required this.disponibles,
    required this.onChanged,
    required this.onBack,
  });

  @override
  State<ReassignOrdersView> createState() => _ReassignOrdersViewState();
}

class _ReassignOrdersViewState extends State<ReassignOrdersView> {
  final _repo = CargaTrabajoRepository();

  int? _operarioSeleccionadoId;

  // Detalle completo de órdenes del operario seleccionado.
  List<OrdenActivaDetalle> _ordenesOperario = [];
  bool _loadingOrdenes = false;
  String? _errorOrdenes;

  // Llave = "<item.key>-<idOperarioDestino>": identifica exactamente el
  // botón "Reasignar" presionado.
  String? _reasignandoKey;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.sobrecargados.isNotEmpty) {
      _operarioSeleccionadoId = widget.sobrecargados.first.idUsuario;
      _cargarOrdenesOperario(_operarioSeleccionadoId!);
    }
  }

  @override
  void didUpdateWidget(covariant ReassignOrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sigueExistiendo = _operarioSeleccionadoId != null &&
        widget.sobrecargados.any((o) => o.idUsuario == _operarioSeleccionadoId);
    if (!sigueExistiendo) {
      final nuevoId = widget.sobrecargados.isNotEmpty ? widget.sobrecargados.first.idUsuario : null;
      _operarioSeleccionadoId = nuevoId;
      if (nuevoId != null) {
        _cargarOrdenesOperario(nuevoId);
      } else {
        setState(() => _ordenesOperario = []);
      }
    }
  }

  void _seleccionarOperario(int id) {
    if (id == _operarioSeleccionadoId) return;
    setState(() => _operarioSeleccionadoId = id);
    _cargarOrdenesOperario(id);
  }

  Future<void> _cargarOrdenesOperario(int idOperario) async {
    setState(() {
      _loadingOrdenes = true;
      _errorOrdenes = null;
    });
    try {
      final data = await _repo.getDetalleOperario(idOperario);
      if (!mounted || idOperario != _operarioSeleccionadoId) return;
      setState(() => _ordenesOperario = data);
    } catch (e) {
      if (!mounted || idOperario != _operarioSeleccionadoId) return;
      setState(() => _errorOrdenes = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && idOperario == _operarioSeleccionadoId) {
        setState(() => _loadingOrdenes = false);
      }
    }
  }

  String _keyDe(OrdenActivaDetalle item, CargaOperario destino) => '${item.key}-${destino.idUsuario}';

  Future<void> _reasignar(OrdenActivaDetalle item, CargaOperario destino) async {
    final key = _keyDe(item, destino);
    setState(() {
      _reasignandoKey = key;
      _error = null;
    });
    try {
      await _repo.reasignar(
        idOrdenOperario: item.esFase ? item.idOrdenOperario : null,
        idOrden: item.esFase ? null : item.idOrden,
        idOperarioDestino: destino.idUsuario,
      );
      widget.onChanged();
      if (_operarioSeleccionadoId != null) {
        // Refresca la lista de este operario (la orden reasignada debe desaparecer).
        _cargarOrdenesOperario(_operarioSeleccionadoId!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Orden reasignada correctamente.')));
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && _reasignandoKey == key) {
        setState(() => _reasignandoKey = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seleccionado = widget.sobrecargados
        .cast<CargaOperario?>()
        .firstWhere((o) => o?.idUsuario == _operarioSeleccionadoId, orElse: () => null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildHeader(),
        if (_error != null) _buildErrorBanner(),
        const Text(
          'OPERARIO SOBRECARGADO',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textFaint, letterSpacing: 0.4),
        ),
        const SizedBox(height: 10),
        if (widget.sobrecargados.isEmpty) _buildSinSobrecargados(),
        ...widget.sobrecargados.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildOperarioCard(o, seleccionado: o.idUsuario == _operarioSeleccionadoId),
          ),
        ),
        if (seleccionado != null) ...[
          const SizedBox(height: 10),
          _buildSectionHeader(
              'Órdenes de ${seleccionado.nombreCompleto.split(' ').first}', _ordenesOperario.length),
          const SizedBox(height: 10),
          if (_loadingOrdenes)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator(color: AppColors.navy)),
            )
          else if (_errorOrdenes != null)
            _buildErrorOrdenes()
          else if (_ordenesOperario.isEmpty)
            _buildSinMovimientos()
          else
            ..._ordenesOperario.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildOrdenCard(item),
              ),
            ),
        ],
      ],
    );
  }

  // ── HEADER ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.searchBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 15, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Reasignación de Órdenes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.cardBorder),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Text(_error!, style: const TextStyle(color: AppColors.errorText, fontSize: 12)),
    );
  }

  Widget _buildErrorOrdenes() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 30, color: AppColors.textFaint),
          const SizedBox(height: 8),
          Text(_errorOrdenes!,
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _cargarOrdenesOperario(_operarioSeleccionadoId!),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // ── OPERARIOS SOBRECARGADOS ──

  Widget _buildOperarioCard(CargaOperario o, {required bool seleccionado}) {
    final av = AppColors.avatarPalette[o.idUsuario % AppColors.avatarPalette.length];
    return GestureDetector(
      onTap: () => _seleccionarOperario(o.idUsuario),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.errorBorder,
            width: seleccionado ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            AvatarWidget(initials: o.initials, size: 38, bg: av['bg']!, text: av['text']!),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.nombreCompleto,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('${o.ordenesActivas} órdenes activas',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (seleccionado) const Icon(Icons.check_circle, size: 22, color: AppColors.errorText),
          ],
        ),
      ),
    );
  }

  Widget _buildSinSobrecargados() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded, size: 30, color: AppColors.textFaint),
          SizedBox(height: 8),
          Text('No hay operarios sobrecargados en este momento.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
        ],
      ),
    );
  }

  // ── ÓRDENES DEL OPERARIO SELECCIONADO ──

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
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

  Widget _buildSinMovimientos() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Text(
        'Este operario no tiene fases u órdenes activas en este momento.',
        style: TextStyle(color: AppColors.textFaint, fontSize: 12),
      ),
    );
  }

  Widget _buildOrdenCard(OrdenActivaDetalle m) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(m.producto,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration:
                    BoxDecoration(color: AppColors.badgeOpBlueBg, borderRadius: BorderRadius.circular(20)),
                child: Text('ORD-${m.idOrden}',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.badgeOpBlueText)),
              ),
            ],
          ),
          if (m.esFase) ...[
            const SizedBox(height: 2),
            Text(m.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 4),
          Text(
            m.fechaLimite != null && m.fechaLimite!.isNotEmpty
                ? 'Vence: ${_formatFecha(m.fechaLimite!)}${m.vencida ? ' · Vencida' : ''}'
                : (m.vencida ? 'Vencida' : ''),
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),
          const Text(
            'REASIGNAR A',
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textFaint, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          if (widget.disponibles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('No hay operarios con capacidad disponible.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textFaint)),
            )
          else
            ...widget.disponibles.map(
              (u) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSugerenciaRow(m, u),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSugerenciaRow(OrdenActivaDetalle m, CargaOperario u) {
    final av = AppColors.avatarPalette[u.idUsuario % AppColors.avatarPalette.length];
    final key = _keyDe(m, u);
    final loading = _reasignandoKey == key;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AvatarWidget(initials: u.initials, size: 30, bg: av['bg']!, text: av['text']!),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.nombreCompleto,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('${u.ordenesActivas} órdenes',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textFaint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: loading ? null : () => _reasignar(m, u),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Reasignar',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}