import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/data/models/material_model.dart';
import '../../../admin/data/repositories/material_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../operario/presentation/screens/operario_shared_widgets.dart'
    show ErrorState;
import '../widgets/cliente_shared_widgets.dart';

/// Pantalla "Alertas de Materiales" del rol Cliente.
///
/// Muestra un banner de alertas (agotados / stock bajo) SOLO cuando
/// existen — sin título/ícono de sección fijo — y debajo el detalle
/// completo de TODOS los materiales asignados al cliente autenticado
/// (Id_Cliente = authUser.idUsuario), vía
/// MaterialRepository.getMaterialesPorCliente.
class ClienteAlertasScreen extends StatefulWidget {
  const ClienteAlertasScreen({super.key});

  @override
  State<ClienteAlertasScreen> createState() => _ClienteAlertasScreenState();
}

class _ClienteAlertasScreenState extends State<ClienteAlertasScreen> {
  final _authRepo = AuthRepository();
  final _materialRepo = MaterialRepository();

  List<MaterialItem> _materiales = [];
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
      final authUser = await _authRepo.getUsuarioGuardado();
      if (authUser == null) {
        if (!mounted) return;
        setState(() {
          _materiales = [];
          _loading = false;
        });
        return;
      }
      final materiales =
          await _materialRepo.getMaterialesPorCliente(authUser.idUsuario);
      if (!mounted) return;
      setState(() => _materiales = materiales);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MaterialItem> get _agotados =>
      _materiales.where((m) => m.stockActual <= 0).toList();

  List<MaterialItem> get _stockBajo =>
      _materiales.where((m) => m.isLow && m.stockActual > 0).toList();

  List<MaterialItem> get _alertas => [..._agotados, ..._stockBajo];

  int get _totalAlertas => _alertas.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ClienteLogoHeader(
          title: 'Alertas de Materiales',
          subtitle: 'Estado de tus materiales',
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.navy))
              : _error != null
                  ? ErrorState(message: _error!, onRetry: _cargar)
                  : RefreshIndicator(
                      color: AppColors.navy,
                      onRefresh: _cargar,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          const SizedBox(height: 4),
                          _buildStats(),

                          // ---------- Banner de alertas: solo si hay ----------
                          if (_totalAlertas > 0) ...[
                            const SizedBox(height: 8),
                            _buildAlertBanner(),
                          ],

                          // ---------- Detalle completo de materiales ----------
                          const SizedBox(height: 16),
                          ClienteSectionHeader(
                            title: 'Todos tus materiales',
                            count: _materiales.length,
                          ),
                          if (_materiales.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No tienes materiales registrados',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.textMuted),
                                ),
                              ),
                            )
                          else
                            ..._materiales.map((m) => _buildMaterialCard(
                                  m,
                                  estado: m.stockActual <= 0
                                      ? _Estado.agotado
                                      : (m.isLow ? _Estado.bajo : _Estado.ok),
                                )),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: ClienteStatCard(
              icon: Icons.inventory_2_outlined,
              value: '${_materiales.length}',
              label: 'Total',
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClienteStatCard(
              icon: Icons.error_outline,
              value: '${_agotados.length}',
              label: 'Agotados',
              color: AppColors.errorText,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClienteStatCard(
              icon: Icons.trending_down_rounded,
              value: '${_stockBajo.length}',
              label: 'Stock bajo',
              color: AppColors.iconClient,
            ),
          ),
        ],
      ),
    );
  }

  /// Banner estilo "Alertas de Inventario" (mismo lenguaje visual que
  /// el de admin en inventario_screen.dart), pero SOLO se llama a este
  /// método cuando _totalAlertas > 0 — si el cliente no tiene ninguna
  /// alerta, esta sección entera desaparece (sin título ni ícono suelto).
  Widget _buildAlertBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: AppColors.errorText.withValues(alpha: 0.35), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: AppColors.errorBg,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: AppColors.errorText),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Alertas de Inventario',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.errorText)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.errorText,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('$_totalAlertas',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
              ..._alertas.map((m) {
                final agotado = m.stockActual <= 0;
                final color =
                    agotado ? AppColors.errorText : AppColors.priorityMediumText;
                final badgeBg = agotado ? AppColors.errorBg : AppColors.priorityMediumBg;
                final label = agotado ? 'Agotado' : 'Stock Bajo';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    border: Border(
                        top: BorderSide(
                            color: AppColors.errorText.withValues(alpha: 0.18))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(m.nombre,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(m.categoria,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Text('${m.stockActual} ${m.unidad}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withValues(alpha: 0.25))),
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialCard(MaterialItem m, {required _Estado estado}) {
    final color = switch (estado) {
      _Estado.agotado => AppColors.errorText,
      _Estado.bajo => AppColors.iconClient,
      _Estado.ok => AppColors.iconActive,
    };
    final bg = switch (estado) {
      _Estado.agotado => AppColors.errorBg,
      _Estado.bajo => AppColors.priorityMediumBg,
      _Estado.ok => AppColors.iconActive.withValues(alpha: 0.12),
    };
    final label = switch (estado) {
      _Estado.agotado => 'Agotado',
      _Estado.bajo => 'Stock bajo',
      _Estado.ok => 'Disponible',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.4),
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_outlined, size: 17, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.nombre,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(m.categoria,
                          style: const TextStyle(
                              fontSize: 10.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration:
                      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.bold, color: color)),
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
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${m.stockActual} ${m.unidad} disponibles',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text('Mín ${m.stockMinimo} / Máx ${m.stockMaximo}',
                    style:
                        const TextStyle(fontSize: 10, color: AppColors.textFaint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _Estado { agotado, bajo, ok }