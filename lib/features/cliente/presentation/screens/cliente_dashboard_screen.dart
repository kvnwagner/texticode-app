import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/cliente_orders_data.dart';
import '../widgets/cliente_shared_widgets.dart';

class ClienteDashboardScreen extends StatelessWidget {
  final VoidCallback onGoOrders;
  final VoidCallback onLogout;

  const ClienteDashboardScreen({
    super.key,
    required this.onGoOrders,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final orders = ClienteOrdersData.orders;
    final total = orders.length;
    final inProg = orders.where((o) => o.status == 'En progreso').length;
    final done = orders.where((o) => o.status == 'Completado').length;
    final paused = orders.where((o) => o.status == 'Pausado').length;

    return Column(
      children: [
        ClienteLogoHeader(
          title: 'Comprobantes',
          subtitle: 'Resumen de tus pedidos',
          onLogout: onLogout,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumen de pedidos',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.1,
                      children: [
                        ClienteStatCard(
                          icon: Icons.shopping_bag_outlined,
                          value: '$total',
                          label: 'Total pedidos',
                          color: AppColors.navy,
                        ),
                        ClienteStatCard(
                          icon: Icons.local_shipping_outlined,
                          value: '$inProg',
                          label: 'En progreso',
                          color: AppColors.iconOp,
                        ),
                        ClienteStatCard(
                          icon: Icons.check_circle_outline,
                          value: '$done',
                          label: 'Completados',
                          color: AppColors.iconActive,
                        ),
                        ClienteStatCard(
                          icon: Icons.pause_circle_outline,
                          value: '$paused',
                          label: 'Pausados',
                          color: AppColors.iconClient,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ClienteSectionHeader(title: 'Pedidos recientes', count: orders.length),
              ...orders.take(3).map((o) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.pageBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.iconOp.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.shopping_bag_outlined,
                            size: 16, color: AppColors.iconOp),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Text('${o.id} · ${o.delivery}',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.textFaint)),
                          ],
                        ),
                      ),
                      ClienteStatusBadge(status: o.status),
                    ],
                  ),
                ),
              )),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Ver todos los pedidos →',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}