import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/cliente_orders_data.dart';
import '../widgets/cliente_shared_widgets.dart';

class ClientePedidosScreen extends StatefulWidget {
  const ClientePedidosScreen({super.key});

  @override
  State<ClientePedidosScreen> createState() => _ClientePedidosScreenState();
}

class _ClientePedidosScreenState extends State<ClientePedidosScreen> {
  String _query = '';
  String _filter = 'Todos';

  static const filters = ['Todos', 'En progreso', 'Completado', 'Pausado'];

  Color _filterColor(String f) {
    if (f == 'Todos') return AppColors.navy;
    final (_, text) = clienteStatusColors(f);
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ClienteOrdersData.orders.where((o) {
      final matchQ = o.name.toLowerCase().contains(_query.toLowerCase()) ||
          o.id.toLowerCase().contains(_query.toLowerCase());
      final matchF = _filter == 'Todos' || o.status == _filter;
      return matchQ && matchF;
    }).toList();

    return Column(
      children: [
        const ClienteLogoHeader(
          title: 'Mis Pedidos',
          subtitle: 'Seguimiento y estado',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.searchBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.textFaint),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre o número...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: filters.map((f) {
              final active = _filter == f;
              final col = _filterColor(f);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? col : col.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: active ? col : col.withValues(alpha: 0.25)),
                    ),
                    alignment: Alignment.center,
                    child: Text(f,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : col)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 32, color: AppColors.textFaint),
                      SizedBox(height: 8),
                      Text('No se encontraron pedidos',
                          style: TextStyle(fontSize: 13, color: AppColors.textFaint)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => ClienteOrderCard(order: filtered[i]),
                ),
        ),
      ],
    );
  }
}