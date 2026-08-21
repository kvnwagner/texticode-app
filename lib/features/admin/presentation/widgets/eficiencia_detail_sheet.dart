import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
  Map<String, dynamic>? _detalle;
  bool _loading = true;
  String? _error;

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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
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
                Text(
                  _detalle?['Nombre_Completo'] ?? 'Detalle del operario',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 28,
              height: 28,
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
        Row(
          children: [
            _chip('Prendas/día', '${_detalle?['prendas_por_dia']}'),
            const SizedBox(width: 8),
            _chip('Total unidades', '${_detalle?['total_unidades_producidas']}'),
            const SizedBox(width: 8),
            _chip('Rendimiento', '${_detalle?['rendimiento']}'),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Órdenes',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        if (ordenes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Sin órdenes asignadas', style: TextStyle(color: AppColors.textFaint)),
          ),
        ...ordenes.map((o) => _buildOrdenTile(o as Map<String, dynamic>)),
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

  Widget _buildOrdenTile(Map<String, dynamic> o) {
    final vencida = o['vencida'] == true;
    final tieneProblema = o['tiene_problema'] == true;
    final observaciones = (o['observaciones'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        border: Border.all(color: vencida ? AppColors.errorBorder : AppColors.cardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${o['Producto'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
              if (vencida)
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.errorText),
              if (tieneProblema) ...[
                const SizedBox(width: 6),
                const Icon(Icons.report_problem_outlined, size: 16, color: AppColors.iconClient),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text('${o['Unidades_Realizadas'] ?? 0} / ${o['Unidades'] ?? 0} unidades · ${o['Estado'] ?? ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (observaciones.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...observaciones.map((obs) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• ${obs['Observacion']} (${obs['Admin'] ?? ''})',
                      style: const TextStyle(fontSize: 11, color: AppColors.iconClient)),
                )),
          ],
        ],
      ),
    );
  }
}