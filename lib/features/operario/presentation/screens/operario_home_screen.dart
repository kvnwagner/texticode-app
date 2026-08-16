import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/data/models/orden_model.dart';
import '../../../admin/data/repositories/orden_repository.dart';
import 'perfil_screen.dart';
import 'tareas_asignadas_view.dart';
import 'reportar_avances_view.dart';

class OperarioHomeScreen extends StatefulWidget {
  const OperarioHomeScreen({super.key});

  @override
  State<OperarioHomeScreen> createState() => _OperarioHomeScreenState();
}

class _OperarioHomeScreenState extends State<OperarioHomeScreen> {
  final _repo = OrdenRepository();
  int _bottomIndex = 1;
  List<Orden> _ordenes = [];
  bool _loading = true;
  String? _error;

  static const _bottomIcons = [
    Icons.assignment_outlined,
    Icons.trending_up_rounded,
    Icons.person_outline_rounded,
  ];

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

  Future<void> _reportarAvance(Orden orden) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportProgressSheet(
        orden: orden,
        onSubmit: (cantidad) => _repo.reportarAvance(
          orden: orden,
          cantidadActual: cantidad,
        ),
      ),
    );
    if (updated == true) _cargar();
  }

  Future<void> _pausar(Orden orden) async {
    try {
      await _repo.actualizarEstado(orden.idOrden, 'Pendiente');
      await _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orden pausada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        bottom: false,
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildDock(),
    );
  }

  Widget _buildBody() {
    switch (_bottomIndex) {
      case 0:
        return TareasAsignadasView(
          ordenes: _ordenes,
          loading: _loading,
          error: _error,
          onRefresh: _cargar,
        );
      case 2:
        return const PerfilScreen();
      case 1:
      default:
        return ReportarAvancesView(
          ordenes: _ordenes,
          loading: _loading,
          error: _error,
          onRefresh: _cargar,
          onReport: _reportarAvance,
          onPause: _pausar,
        );
    }
  }

  Widget _buildDock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_bottomIcons.length, (i) {
            final selected = i == _bottomIndex;
            return GestureDetector(
              onTap: () => setState(() => _bottomIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _bottomIcons[i],
                  size: 20,
                  color: selected ? Colors.white : AppColors.textFaint,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}