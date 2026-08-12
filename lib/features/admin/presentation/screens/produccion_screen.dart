import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/orden_model.dart';
import '../../data/repositories/orden_repository.dart';
import '../widgets/new_order_sheet.dart';

/// Pantalla "Gestión de Producción" — sigue EXACTAMENTE los mismos tokens
/// visuales que admin_home_screen.dart (Gestión de Usuarios): mismas cards
/// de stats, mismos bordes, mismo FAB, mismos avatares circulares.
class ProduccionScreen extends StatefulWidget {
  const ProduccionScreen({super.key});

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

class _ProduccionScreenState extends State<ProduccionScreen> {
  final _repo = OrdenRepository();
  List<Orden> _ordenes = [];
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
      final data = await _repo.getOrdenes();
      if (!mounted) return;
      setState(() => _ordenes = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _ordenes.length;
    final enProceso = _ordenes.where((o) => o.isEnProceso).length;
    final completadas = _ordenes.where((o) => o.isCompletada).length;
    final retrasadas = _ordenes.where((o) => o.isRetrasada).length;

    return Container(
      color: AppColors.pageBg,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              children: [
                _loading
                    ? const Center(
                    child: CircularProgressIndicator(color: AppColors.navy))
                    : _error != null
                    ? _buildError()
                    : RefreshIndicator(
                  color: AppColors.navy,
                  onRefresh: _cargar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _buildStats(total, enProceso, completadas, retrasadas),
                      _buildSectionHeader(_ordenes.length),
                      if (_ordenes.isEmpty) _buildEmpty(),
                      ..._ordenes.map(_buildOrderCard),
                      const SizedBox(height: 130),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 16,
                  child: FloatingActionButton(
                    backgroundColor: AppColors.navy,
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => NewOrderSheet(onCreated: _cargar),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⬅️ Campana de notificaciones ELIMINADA (sobraba, tal como pediste).
  // Se mantiene el logo real en vez del avatar de iniciales.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                AppConstants.logoAssetPath,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.checkroom, color: Colors.white, size: 18),
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
                Text('Gestión de Producción',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text('Órdenes activas',
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

  // Mismo patrón exacto que admin_home_screen._buildStats /
  // _buildStatCard: GridView.builder + mainAxisExtent fijo para evitar
  // overflow, barra lateral de color, número grande + icono a la derecha.
  Widget _buildStats(int total, int enProceso, int completadas, int retrasadas) {
    final items = <_StatItem>[
      _StatItem('Total Órdenes', total, Icons.assignment_outlined, AppColors.iconTotal),
      _StatItem('En Proceso', enProceso, Icons.autorenew_rounded, AppColors.purple),
      _StatItem('Completadas', completadas, Icons.verified_outlined, AppColors.iconActive),
      _StatItem('Retrasadas', retrasadas, Icons.warning_amber_rounded, AppColors.errorText),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 78,
        ),
        itemBuilder: (context, index) => _buildStatCard(items[index]),
      ),
    );
  }

  Widget _buildStatCard(_StatItem s) {
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
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: s.color)),
                          const SizedBox(height: 3),
                          Text(s.label,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: s.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon, size: 16, color: s.color),
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

  Widget _buildSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.settings_outlined, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          const Text('Órdenes de Producción',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const Spacer(),
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  (Color, Color) _prioridadColors(Orden o) {
    if (o.isAlta) return (AppColors.priorityHighBg, AppColors.priorityHighText);
    if (o.isBaja) return (AppColors.priorityLowBg, AppColors.priorityLowText);
    return (AppColors.priorityMediumBg, AppColors.priorityMediumText);
  }

  (Color, Color) _estadoColors(Orden o) {
    if (o.isEnProceso) return (AppColors.statusInProgressBg, AppColors.statusInProgressText);
    if (o.isCompletada) return (AppColors.statusCompletedBg, AppColors.statusCompletedText);
    if (o.isRetrasada) return (AppColors.statusDelayedBg, AppColors.statusDelayedText);
    return (AppColors.statusPendingBg, AppColors.statusPendingText);
  }

  Color _progresoColor(Orden o) {
    if (o.isRetrasada) return AppColors.errorText;
    if (o.isCompletada) return AppColors.iconActive;
    if (o.isEnProceso) return AppColors.purple;
    return AppColors.textFaint;
  }

  Widget _buildOrderCard(Orden o) {
    final (prioBg, prioText) = _prioridadColors(o);
    final (estadoBg, estadoText) = _estadoColors(o);
    final progresoColor = _progresoColor(o);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(o.codigoOrden,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textFaint)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: prioBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(o.prioridadLabel,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: prioText)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: estadoBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(o.estadoLabel,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: estadoText)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(o.producto,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(o.cliente,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 10),

            // ⬅️ nuevo — antes iba el avatar con iniciales del operario
            // (mostraba "??" cuando el nombre venía vacío desde el
            // backend). Ahora se muestran los MATERIALES seleccionados
            // de la orden, en vez de ese avatar.
            if (o.materiales.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: o.materiales
                    .map((m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.searchBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(m,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ))
                    .toList(),
              )
            else
              const Text('Sin materiales asignados',
                  style: TextStyle(fontSize: 10, color: AppColors.textFaint)),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Text(o.operario,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ),
                Text('Vence: ${o.fechaCorta}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textFaint)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${o.cantidadActual} de ${o.cantidadTotal} prendas',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text('${o.progresoPorcentaje}%',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: progresoColor)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                // o.progreso ya viene calculado como
                // cantidadActual / cantidadTotal (clampeado entre 0 y 1),
                // así que la barra siempre refleja lo realmente producido
                // por el operario contra el total pedido.
                value: o.progreso,
                minHeight: 6,
                backgroundColor: AppColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(progresoColor),
              ),
            ),
            // ⬅️ Selector de estado ELIMINADO (sobraba, tal como pediste).
            // El estado ya se ve arriba en el badge de la card.
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: const [
          Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.textFaint),
          SizedBox(height: 8),
          Text('No hay órdenes de producción',
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
            const SizedBox(height: 4),
            const Text(
              'Verifica que tu backend Express siga corriendo en el puerto 3001\ny que la IP en api_constants.dart sea correcta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textFaint, fontSize: 11),
            ),
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

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}