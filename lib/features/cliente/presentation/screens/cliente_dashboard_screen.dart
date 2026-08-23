import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/cliente_orders_data.dart';
import '../widgets/cliente_shared_widgets.dart';

class ClienteDashboardScreen extends StatelessWidget {
  final VoidCallback onGoOrders;

  const ClienteDashboardScreen({
    super.key,
    required this.onGoOrders,
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
        const ClienteLogoHeader(
          title: 'Comprobantes',
          subtitle: 'Resumen de tus pedidos',
        ),
        Expanded(
          child: ListView(
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
                      (Icons.shopping_bag_outlined, '$total', 'Total pedidos', AppColors.navy),
                      (Icons.local_shipping_outlined, '$inProg', 'En progreso', AppColors.purple),
                      (Icons.check_circle_outline, '$done', 'Completados', AppColors.iconActive),
                      (Icons.pause_circle_outline, '$paused', 'Pausados', AppColors.textFaint),
                    ];
                    final (icon, value, label, color) = items[i];
                    return ClienteStatCard(icon: icon, value: value, label: label, color: color);
                  },
                ),
              ),
              ClienteSectionHeader(title: 'Pedidos recientes', count: orders.length),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: orders.take(3).map((o) => ClienteOrderCard(order: o)).toList(),
                ),
              ),
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