import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/orden_operario_model.dart';
import '../../data/models/orden_model.dart';
import '../../data/repositories/orden_repository.dart';
import '../../data/repositories/orden_material_repository.dart';
import '../../data/repositories/orden_operario_repository.dart';
import '../widgets/new_order_sheet.dart';

/// Pantalla "Gestión de Producción" — sigue EXACTAMENTE los mismos tokens
/// visuales que admin_home_screen.dart (Gestión de Usuarios): mismas cards
/// de stats, mismos bordes, mismo FAB, mismos avatares circulares, y ahora
/// también el mismo encabezado (logo 55x55, sin descripción).
///
/// Las cards de la lista ahora muestran solo lo esencial (código,
/// producto, fecha de vencimiento y progreso) más dos botones: uno de
/// ojo que abre TODA la información de la orden en un sheet, y uno de
/// lápiz que abre el formulario de edición (como ya existía).
class ProduccionScreen extends StatefulWidget {
  const ProduccionScreen({super.key});

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

/// Filtro activado al tocar una de las 4 cards de estadísticas.
/// [todos] es el estado inicial (ninguna card seleccionada, se ven
/// todas las órdenes).
enum _FiltroEstadoOrden { todos, enProceso, completadas, retrasadas }

class _ProduccionScreenState extends State<ProduccionScreen> {
  final _repo = OrdenRepository();
  final _ordenMaterialRepo = OrdenMaterialRepository();
  final _ordenOperarioRepo = OrdenOperarioRepository();
  List<Orden> _ordenes = [];

  /// Materiales reales asignados a cada orden (Id_Orden -> lista de
  /// nombres para mostrar en la card), obtenidos de la tabla intermedia
  /// orden_material vía GET /api/orden-material/orden/:idOrden.
  Map<int, List<String>> _materialesPorOrden = {};
  Map<int, List<OrdenOperario>> _fasesPorOrden = {};

  bool _loading = true;
  String? _error;

  /// Filtro activo elegido desde las cards de Total/En Proceso/
  /// Completadas/Retrasadas. Las 4 cards siempre se muestran; solo
  /// cambia qué órdenes aparecen debajo.
  _FiltroEstadoOrden _filtro = _FiltroEstadoOrden.todos;

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
      // No bloquea el loading principal: los materiales se pintan en
      // cuanto llegan, la lista de órdenes ya se muestra antes.
      _cargarMaterialesDeOrdenes(data);
      _cargarFasesDeOrdenes(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Trae los materiales reales de cada orden desde orden_material
  /// (tabla intermedia que soporta varios materiales por orden).
  /// Si el backend no puede resolver el nombre del material en algún
  /// registro, se muestra un fallback con el Id_Producto para no dejar
  /// la card vacía silenciosamente.
  Future<void> _cargarMaterialesDeOrdenes(List<Orden> ordenes) async {
    final mapa = <int, List<String>>{};
    for (final o in ordenes) {
      try {
        final materiales =
            await _ordenMaterialRepo.getMaterialesDeOrden(o.idOrden);
        mapa[o.idOrden] = materiales
            .map((m) {
              final nombre = m['Nombre_Material'] ??
                  m['nombre_material'] ??
                  m['Nombre_Producto'] ??
                  m['NombreMaterial'];
              final cantidad = m['Cantidad_Usada'] ?? m['cantidad_usada'];
              if (nombre != null) {
                return cantidad != null ? '$nombre ($cantidad)' : '$nombre';
              }
              return 'Material #${m['Id_Producto'] ?? ''}';
            })
            .where((s) => s.trim().isNotEmpty)
            .toList();
      } catch (_) {
        mapa[o.idOrden] = const [];
      }
      if (mounted) setState(() => _materialesPorOrden = Map.of(mapa));
    }
  }

  Future<void> _cargarFasesDeOrdenes(List<Orden> ordenes) async {
    final mapa = <int, List<OrdenOperario>>{};
    for (final o in ordenes) {
      try {
        mapa[o.idOrden] = await _ordenOperarioRepo.getFasesDeOrden(o.idOrden);
      } catch (_) {
        mapa[o.idOrden] = const [];
      }
      if (mounted) setState(() => _fasesPorOrden = Map.of(mapa));
    }
  }

  /// Órdenes que se muestran en la lista, según la card seleccionada.
  List<Orden> get _ordenesFiltradas {
    switch (_filtro) {
      case _FiltroEstadoOrden.todos:
        return _ordenes;
      case _FiltroEstadoOrden.enProceso:
        return _ordenes.where((o) => o.isEnProceso).toList();
      case _FiltroEstadoOrden.completadas:
        return _ordenes.where((o) => o.isCompletada).toList();
      case _FiltroEstadoOrden.retrasadas:
        return _ordenes.where((o) => o.isRetrasada).toList();
    }
  }

  String get _tituloListaFiltrada {
    switch (_filtro) {
      case _FiltroEstadoOrden.todos:
        return 'Órdenes de Producción';
      case _FiltroEstadoOrden.enProceso:
        return 'Órdenes en Proceso';
      case _FiltroEstadoOrden.completadas:
        return 'Órdenes Completadas';
      case _FiltroEstadoOrden.retrasadas:
        return 'Órdenes Retrasadas';
    }
  }

  void _toggleFiltro(_FiltroEstadoOrden f) {
    setState(() => _filtro = _filtro == f ? _FiltroEstadoOrden.todos : f);
  }

  @override
  Widget build(BuildContext context) {
    final total = _ordenes.length;
    final enProceso = _ordenes.where((o) => o.isEnProceso).length;
    final completadas = _ordenes.where((o) => o.isCompletada).length;
    final retrasadas = _ordenes.where((o) => o.isRetrasada).length;
    final ordenesFiltradas = _ordenesFiltradas;

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
                                _buildStats(
                                    total, enProceso, completadas, retrasadas),
                                _buildSectionHeader(),
                                if (ordenesFiltradas.isEmpty)
                                  _buildEmpty()
                                else
                                  ...ordenesFiltradas.map(_buildOrderCard),
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

  /// Encabezado igual al de "Gestión de Usuarios" (main_shell.dart):
  /// contenedor de logo 55x55, título único sin subtítulo/descripción.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            height: 55,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                AppConstants.logoAssetPath,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.checkroom,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gestión de Producción',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mismo patrón exacto que admin_home_screen._buildStats /
  // _buildStatCard: GridView.builder + mainAxisExtent fijo para evitar
  // overflow, barra lateral de color, número grande + icono a la derecha.
  Widget _buildStats(
      int total, int enProceso, int completadas, int retrasadas) {
    final items = <_StatItem>[
      _StatItem('Total Órdenes', total, Icons.assignment_outlined,
          AppColors.iconTotal, _FiltroEstadoOrden.todos),
      _StatItem('En Proceso', enProceso, Icons.autorenew_rounded,
          AppColors.purple, _FiltroEstadoOrden.enProceso),
      _StatItem('Completadas', completadas, Icons.verified_outlined,
          AppColors.iconActive, _FiltroEstadoOrden.completadas),
      _StatItem('Retrasadas', retrasadas, Icons.warning_amber_rounded,
          AppColors.errorText, _FiltroEstadoOrden.retrasadas),
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
    // "Total Órdenes" está seleccionada tanto cuando el filtro es
    // explícitamente `todos` (estado inicial) como referencia visual
    // por defecto; el resto solo se resalta si coincide exactamente.
    final activa = _filtro == s.filtro;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleFiltro(s.filtro),
          child: Container(
            decoration: BoxDecoration(
              color: activa
                  ? s.color.withValues(alpha: 0.07)
                  : AppColors.pageBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activa ? s.color : AppColors.cardBorder,
                width: activa ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(width: 3.5, color: s.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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
                            color: s.color.withValues(
                                alpha: activa ? 0.16 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            activa ? Icons.check_rounded : s.icon,
                            size: 16,
                            color: s.color,
                          ),
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

  // ⬅️ Ya sin la burbuja con el conteo total de órdenes: solo el ícono
  // y el título de la sección. El título cambia según la card de
  // estadísticas seleccionada, y si hay un filtro activo aparece un
  // botón para quitarlo y volver a ver todas las órdenes.
  Widget _buildSectionHeader() {
    final filtroActivo = _filtro != _FiltroEstadoOrden.todos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.settings_outlined,
              size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(_tituloListaFiltrada,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
          if (filtroActivo)
            GestureDetector(
              onTap: () =>
                  setState(() => _filtro = _FiltroEstadoOrden.todos),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.searchBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 11, color: AppColors.textMuted),
                    SizedBox(width: 4),
                    Text('Quitar filtro',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
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

  /// Orden de prioridad visual corregido: una orden vencida SIEMPRE se
  /// muestra como "Retrasada" (badge rojo), sin importar que su Estado
  /// en la base de datos siga siendo "En Proceso". Antes se evaluaba
  /// isEnProceso primero, así que una orden vencida pero aún "En
  /// Proceso" nunca llegaba a pintarse como retrasada.
  (Color, Color) _estadoColors(Orden o) {
    if (o.isRetrasada) {
      return (AppColors.statusDelayedBg, AppColors.statusDelayedText);
    }
    if (o.isCompletada) {
      return (AppColors.statusCompletedBg, AppColors.statusCompletedText);
    }
    if (o.isEnProceso) {
      return (AppColors.statusInProgressBg, AppColors.statusInProgressText);
    }
    return (AppColors.statusPendingBg, AppColors.statusPendingText);
  }

  Color _progresoColor(Orden o) {
    if (o.isRetrasada) return AppColors.errorText;
    if (o.isCompletada) return AppColors.iconActive;
    if (o.isEnProceso) return AppColors.purple;
    return AppColors.textFaint;
  }

  // ── Card resumida: código, producto, vence y progreso + botones de
  // ver detalle (ojo) y editar (lápiz). Toda la info adicional
  // (cliente, fases, materiales, prioridad, estado, descripción, etc.)
  // vive ahora en el sheet de detalle. ──────────────────────────────
  Widget _buildOrderCard(Orden o) {
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
                Expanded(
                  child: Text(o.codigoOrden,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textFaint)),
                ),
                GestureDetector(
                  onTap: () => _mostrarDetalleOrden(o),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.searchBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(Icons.visibility_outlined,
                        size: 14, color: AppColors.navy),
                  ),
                ),
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => NewOrderSheet(orden: o, onCreated: _cargar),
                  ),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.searchBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 14, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(o.producto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                  'Vence: ${o.fechaCorta.isEmpty ? 'Sin fecha' : o.fechaCorta}',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textFaint)),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${o.cantidadActual} de ${o.cantidadTotal} prendas',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text('${o.progresoPorcentaje}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: progresoColor)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: o.progreso,
                minHeight: 6,
                backgroundColor: AppColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(progresoColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sheet de detalle: TODA la información de la orden, sin
  // excepción (código, producto, descripción, cliente, material
  // principal, dificultad, prioridad, estado, fechas, progreso, fases
  // con sus operarios y materiales asignados). ──────────────────────
  void _mostrarDetalleOrden(Orden o) {
    final materiales = _materialesPorOrden[o.idOrden] ?? o.materiales;
    final fases = _fasesPorOrden[o.idOrden] ?? const <OrdenOperario>[];
    final (prioBg, prioText) = _prioridadColors(o);
    final (estadoBg, estadoText) = _estadoColors(o);
    final progresoColor = _progresoColor(o);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
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
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.codigoOrden,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textFaint)),
                            const SizedBox(height: 2),
                            Text(o.producto,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: estadoBg,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(o.estadoLabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: estadoText)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: prioBg,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('Prioridad ${o.prioridadLabel}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: prioText)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _detalleSectionTitle('Progreso de fabricación'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${o.cantidadActual} de ${o.cantidadTotal} prendas',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                          Text('${o.progresoPorcentaje}%',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: progresoColor)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: o.progreso,
                          minHeight: 8,
                          backgroundColor: AppColors.cardBorder,
                          valueColor: AlwaysStoppedAnimation(progresoColor),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _detalleSectionTitle('Información general'),
                      const SizedBox(height: 8),
                      _detalleCard([
                        _detalleRow('Cliente', o.cliente),
                        _detalleRow('Material principal',
                            (o.nombreMaterial ?? '').trim().isEmpty
                                ? '—'
                                : o.nombreMaterial!),
                        _detalleRow('Dificultad', o.dificultad),
                        _detalleRow(
                            'Fecha de creación',
                            o.fechaCreacionCorta.isEmpty
                                ? '—'
                                : o.fechaCreacionCorta),
                        _detalleRow(
                            'Fecha límite',
                            o.fechaCorta.isEmpty
                                ? 'Sin fecha'
                                : o.fechaCorta),
                      ]),
                      if ((o.descripcion ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _detalleSectionTitle('Descripción'),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.searchBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(o.descripcion!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _detalleSectionTitle('Fases y operarios'),
                      const SizedBox(height: 8),
                      if (fases.isEmpty)
                        const Text('Sin fases asignadas',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textFaint))
                      else
                        ...fases.map((f) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.searchBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.statusInProgressBg,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text('Fase ${f.numeroFase}',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors
                                                    .statusInProgressText)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                            f.nombreOperario ?? 'Operario',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary)),
                                      ),
                                      Text(f.estadoFaseLabel,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textMuted)),
                                    ],
                                  ),
                                  if (f.descripcionFase.trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(f.descripcionFase,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                      'Cantidad realizada: ${f.cantidadRealizada}',
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textFaint)),
                                ],
                              ),
                            )),
                      const SizedBox(height: 22),
                      _detalleSectionTitle('Materiales'),
                      const SizedBox(height: 8),
                      if (materiales.isEmpty)
                        const Text('Sin materiales asignados',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textFaint))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: materiales
                              .map((m) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.searchBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border:
                                          Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Text(m,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detalleSectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: AppColors.textPrimary));
  }

  Widget _detalleCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _detalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 32, color: AppColors.textFaint),
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
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
              child: const Text('Reintentar',
                  style: TextStyle(color: Colors.white)),
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
  final _FiltroEstadoOrden filtro;
  _StatItem(this.label, this.value, this.icon, this.color, this.filtro);
}