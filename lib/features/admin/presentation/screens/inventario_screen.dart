import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/material_model.dart';
import '../../data/repositories/material_repository.dart';
import '../widgets/new_material_sheet.dart';

const _categoriasFiltro = ['Todas', 'Accesorios', 'Telas', 'Hilos', 'Herramientas'];

/// Pantalla "Gestión de Inventario" — sigue EXACTAMENTE los mismos
/// tokens visuales que admin_home_screen.dart / produccion_screen.dart:
/// mismas cards de stats, mismos bordes, mismo patrón de header.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _repo = MaterialRepository();
  List<MaterialItem> _materiales = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String _catFiltro = 'Todas';

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
      final data = await _repo.getMateriales();
      if (!mounted) return;
      setState(() => _materiales = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MaterialItem> get _alertas => _materiales.where((m) => m.isLow).toList();

  List<MaterialItem> get _filtrados {
    return _materiales.where((m) {
      final matchQ = m.nombre.toLowerCase().contains(_query.toLowerCase());
      final matchCat = _catFiltro == 'Todas' || m.categoria == _catFiltro;
      return matchQ && matchCat;
    }).toList();
  }

  Future<void> _eliminar(MaterialItem m) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar material'),
        content: Text('¿Seguro que quieres eliminar "${m.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.errorText)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _repo.eliminarMaterial(m.idMaterial);
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: EdgeInsets.zero,
                    children: [
                      _buildHeader(),
                      _buildSearchAndFilter(),
                      _buildMetrics(),
                      if (_alertas.isNotEmpty) _buildAlertBanner(),
                      _buildSectionHeader('Inventario de Materiales', _filtrados.length),
                      if (_filtrados.isEmpty) _buildEmpty(),
                      ..._filtrados.map(_buildMaterialCard),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                AppConstants.logoAssetPath,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.navy, Color(0xFF2D5478)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gestión de Inventario',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('Controla stock, niveles y alertas de materiales en tiempo real',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.searchBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: AppColors.textFaint),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Buscar materiales...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.searchBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _catFiltro,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: AppColors.textFaint),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary),
                      items: _categoriasFiltro
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c == 'Todas' ? 'Todas las categorías' : c)))
                          .toList(),
                      onChanged: (v) => setState(() => _catFiltro = v ?? 'Todas'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => NewMaterialSheet(onCreated: _cargar),
                ),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.navy, Color(0xFF2D5478)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Agregar',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    final categorias = _materiales.map((m) => m.categoria).toSet().length;
    final items = <_StatItem>[
      _StatItem('Total Materiales', _materiales.length, Icons.inventory_2_outlined, AppColors.navy),
      _StatItem('Alertas de Stock', _alertas.length, Icons.error_outline, AppColors.errorText),
      _StatItem('Categorías', categorias, Icons.filter_list, AppColors.iconOp),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 78, // misma altura fija que Gestión de Usuarios
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
                                  fontSize: 26, fontWeight: FontWeight.bold, color: s.color)),
                          const SizedBox(height: 3),
                          Text(s.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                        color: s.color.withValues(alpha: 0.08),
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

  Widget _buildAlertBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.iconClient.withValues(alpha: 0.35), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: AppColors.priorityMediumBg,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: AppColors.iconClient),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Alertas de Inventario',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.errorText, borderRadius: BorderRadius.circular(20)),
                      child: Text('${_alertas.length}',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              ..._alertas.map((m) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.priorityMediumBg,
                      border: Border(top: BorderSide(color: Color(0x30F59E0B))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: AppColors.iconClient, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(m.nombre,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF78350F))),
                        ),
                        Text('${m.stockActual} ${m.unidad}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.priorityMediumBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x40F59E0B))),
                          child: const Text('Stock Bajo',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.iconClient)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.navy),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
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

  (Color, Color) _categoriaColors(String categoria) {
    switch (categoria) {
      case 'Accesorios':
        return (AppColors.badgeOpBlueBg, AppColors.badgeOpBlueText);
      case 'Telas':
        return (AppColors.purpleBg, AppColors.purple);
      case 'Hilos':
        return (AppColors.badgeOpGreenBg, AppColors.badgeOpGreenText);
      case 'Herramientas':
        return (AppColors.priorityMediumBg, AppColors.priorityMediumText);
      default:
        return (AppColors.searchBg, AppColors.textMuted);
    }
  }

  Widget _buildMaterialCard(MaterialItem m) {
    final low = m.isLow;
    final (catBg, catText) = _categoriaColors(m.categoria);
    final barColor = low ? AppColors.iconClient : AppColors.iconActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          border: Border.all(
              color: low ? AppColors.iconClient.withValues(alpha: 0.4) : AppColors.cardBorder,
              width: low ? 1.5 : 1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: low
                        ? AppColors.iconClient.withValues(alpha: 0.12)
                        : AppColors.searchBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      size: 17, color: low ? AppColors.iconClient : AppColors.navy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(m.nombre,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration:
                                BoxDecoration(color: catBg, borderRadius: BorderRadius.circular(20)),
                            child: Text(m.categoria,
                                style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.bold, color: catText)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text('${m.stockActual} ${m.unidad}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: low ? AppColors.iconClient : AppColors.navy)),
                          const SizedBox(width: 6),
                          Icon(low ? Icons.error_outline : Icons.trending_up,
                              size: 12, color: low ? AppColors.iconClient : AppColors.iconActive),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Min ${m.stockMinimo} / Max ${m.stockMaximo}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: AppColors.textFaint)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: low ? AppColors.priorityMediumBg : AppColors.badgeOpGreenBg,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(low ? 'Stock Bajo' : 'En Stock',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: low ? AppColors.iconClient : AppColors.badgeOpGreenText)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                NewMaterialSheet(onCreated: _cargar, material: m),
                          ),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                                color: AppColors.navy.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.edit_outlined, size: 12, color: AppColors.navy),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _eliminar(m),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                                color: AppColors.errorBg,
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.delete_outline,
                                size: 12, color: AppColors.errorText),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: m.stockPct,
                minHeight: 6,
                backgroundColor: AppColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(m.nombreCliente ?? 'Sin cliente asignado',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: AppColors.textFaint)),
                Text('${(m.stockPct * 100).round()}%',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: barColor)),
              ],
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
          Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.textFaint),
          SizedBox(height: 8),
          Text('No se encontraron materiales',
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