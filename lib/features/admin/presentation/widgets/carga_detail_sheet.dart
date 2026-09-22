import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/carga_trabajo_model.dart';
import '../../data/repositories/carga_trabajo_repository.dart';

class CargaDetailSheet extends StatefulWidget {
  final CargaOperario operario;
  final String estadoLabel;
  final Color estadoColor;
  final Color estadoBg;
  final Color avatarBg;
  final Color avatarText;

  const CargaDetailSheet({
    super.key,
    required this.operario,
    required this.estadoLabel,
    required this.estadoColor,
    required this.estadoBg,
    required this.avatarBg,
    required this.avatarText,
  });

  static Future<void> show(
    BuildContext context, {
    required CargaOperario operario,
    required String estadoLabel,
    required Color estadoColor,
    required Color estadoBg,
    required Color avatarBg,
    required Color avatarText,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CargaDetailSheet(
        operario: operario,
        estadoLabel: estadoLabel,
        estadoColor: estadoColor,
        estadoBg: estadoBg,
        avatarBg: avatarBg,
        avatarText: avatarText,
      ),
    );
  }

  @override
  State<CargaDetailSheet> createState() => _CargaDetailSheetState();
}

class _CargaDetailSheetState extends State<CargaDetailSheet> {
  final _repo = CargaTrabajoRepository();

  List<OrdenActivaDetalle> _ordenes = [];
  bool _loading = true;
  String? _error;

  static const _orange = Color(0xFFD97706);
  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];

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
      final data = await _repo.getDetalleOperario(widget.operario.idUsuario);
      if (!mounted) return;
      setState(() => _ordenes = _ordenar(data));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── helpers ──

  int _prioridadPeso(String? p) {
    switch ((p ?? '').toLowerCase()) {
      case 'alta':
        return 0;
      case 'media':
        return 1;
      default:
        return 2;
    }
  }

  DateTime? _parseFecha(String? s) {
    if (s == null || s.length < 10) return null;
    // Solo día/mes/año, sin conversión de zona horaria (evita correr un día).
    return DateTime.tryParse(s.substring(0, 10));
  }

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} de ${_meses[d.month - 1]} de ${d.year}';

  String _fmtEstado(String s) {
    final t = s.replaceAll('_', ' ').trim();
    if (t.isEmpty) return '';
    return t[0].toUpperCase() + t.substring(1);
  }

  /// Vencidas primero, luego prioridad (Alta > Media > Baja), luego fecha.
  List<OrdenActivaDetalle> _ordenar(List<OrdenActivaDetalle> list) {
    final l = [...list];
    l.sort((a, b) {
      if (a.vencida != b.vencida) return a.vencida ? -1 : 1;
      final p = _prioridadPeso(a.prioridad).compareTo(_prioridadPeso(b.prioridad));
      if (p != 0) return p;
      final fa = _parseFecha(a.fechaLimite), fb = _parseFecha(b.fechaLimite);
      if (fa == null || fb == null) return 0;
      return fa.compareTo(fb);
    });
    return l;
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final op = widget.operario;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.pageBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Cabecera ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AvatarWidget(
                      initials: op.initials, size: 52, bg: widget.avatarBg, text: widget.avatarText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(op.nombreCompleto,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('@${op.nombreUsuario}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration:
                              BoxDecoration(color: widget.estadoBg, borderRadius: BorderRadius.circular(20)),
                          child: Text(widget.estadoLabel,
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold, color: widget.estadoColor)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Métricas ──
              Row(
                children: [
                  Expanded(child: _metric('ÓRDENES ACTIVAS', op.ordenesActivas, widget.estadoColor)),
                  const SizedBox(width: 8),
                  Expanded(child: _metric('VENCIDAS', op.ordenesVencidas, AppColors.errorText)),
                  const SizedBox(width: 8),
                  Expanded(child: _metric('ALTA PRIORIDAD', op.ordenesAltaPrioridad, _orange)),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Órdenes activas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),

              _buildLista(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLista() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 36, color: AppColors.textFaint),
            const SizedBox(height: 10),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_ordenes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('Sin órdenes activas', style: TextStyle(fontSize: 13, color: AppColors.textFaint)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            for (int i = 0; i < _ordenes.length; i++)
              _ordenRow(_ordenes[i], isLast: i == _ordenes.length - 1),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 8.5, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _ordenRow(OrdenActivaDetalle o, {required bool isLast}) {
    final vencida = o.vencida;
    final fecha = _parseFecha(o.fechaLimite);
    final estado = _fmtEstado(o.estadoItem);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: vencida ? const Color(0xFFFFF1F1) : Colors.transparent,
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // # · Producto · Prioridad
          Row(
            children: [
              Text('#${o.idOrden}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(o.producto,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 8),
              if ((o.prioridad ?? '').isNotEmpty) _prioridadBadge(o.prioridad!),
            ],
          ),
          // Fase (solo si es fase)
          if (o.esFase) ...[
            const SizedBox(height: 3),
            Text(o.titulo, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 8),
          // Estado · Fecha límite
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (estado.isNotEmpty)
                Text(estado, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fecha == null ? '—' : _fmtFecha(fecha),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: vencida ? FontWeight.w700 : FontWeight.w500,
                      color: vencida ? AppColors.errorText : AppColors.textPrimary,
                    ),
                  ),
                  if (vencida) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorText,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('VENCIDA',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _prioridadBadge(String prioridad) {
    Color fg;
    Color bg;
    switch (prioridad.toLowerCase()) {
      case 'alta':
        fg = AppColors.errorText;
        bg = AppColors.errorBg;
        break;
      case 'media':
        fg = const Color(0xFF92400E);
        bg = const Color(0xFFFEF3C7);
        break;
      default:
        fg = AppColors.textSecondary;
        bg = const Color(0xFFF1F5F9);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(prioridad, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}