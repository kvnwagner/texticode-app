import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/data/models/orden_model.dart';
import '../../../operario/presentation/screens/operario_shared_widgets.dart' show ErrorState;
import '../widgets/cliente_shared_widgets.dart';

class ClienteDashboardScreen extends StatelessWidget {
  final List<Orden> ordenes;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onGoOrders;

  const ClienteDashboardScreen({
    super.key,
    required this.ordenes,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onGoOrders,
  });

  @override
  Widget build(BuildContext context) {
    final total = ordenes.length;
    final enProceso = ordenes.where((o) => o.isEnProceso).length;
    final completadas = ordenes.where((o) => o.isCompletada).length;
    final pendientes = ordenes.where((o) => o.isPendiente).length;

    return Column(
      children: [
        const ClienteLogoHeader(
          title: 'Comprobantes',
          subtitle: 'Resumen de tus pedidos',
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
              : error != null
                  ? ErrorState(message: error!, onRetry: onRefresh)
                  : RefreshIndicator(
                      color: AppColors.navy,
                      onRefresh: onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 4,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 78,
                              ),
                              itemBuilder: (context, i) {
                                final items = [
                                  (Icons.shopping_bag_outlined, '$total', 'Total pedidos',
                                      AppColors.navy),
                                  (Icons.autorenew_rounded, '$enProceso', 'En proceso',
                                      AppColors.purple),
                                  (Icons.check_circle_outline, '$completadas', 'Completados',
                                      AppColors.iconActive),
                                  (Icons.hourglass_empty_rounded, '$pendientes', 'Pendientes',
                                      AppColors.textFaint),
                                ];
                                final (icon, value, label, color) = items[i];
                                return ClienteStatCard(
                                    icon: icon, value: value, label: label, color: color);
                              },
                            ),
                          ),
                          ClienteSectionHeader(title: 'Pedidos recientes', count: ordenes.length),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ordenes.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: Text('Aún no tienes pedidos registrados',
                                          style: TextStyle(
                                              color: AppColors.textFaint, fontSize: 13)),
                                    ),
                                  )
                                : Column(
                                    children: ordenes
                                        .take(3)
                                        .map((o) => ClienteOrderCard(orden: o))
                                        .toList(),
                                  ),
                          ),
                          if (ordenes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: onGoOrders,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.navy.withValues(alpha: 0.06),
                                    side: BorderSide(color: AppColors.navy.withValues(alpha: 0.2)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Ver todos los pedidos →',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navy)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}