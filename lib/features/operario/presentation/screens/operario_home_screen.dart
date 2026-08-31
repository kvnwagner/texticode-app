// lib/features/operario/presentation/screens/operario_home_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_dock.dart';
import '../../../admin/data/models/orden_model.dart';
import '../../../admin/data/repositories/orden_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
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
  final _authRepo = AuthRepository();
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
      final authUser = await _authRepo.getUsuarioGuardado();
      final data = await _repo.getOrdenes();
      if (!mounted) return;
      setState(() {
        // Solo las órdenes asignadas a este operario.
        _ordenes = authUser == null
            ? data
            : data.where((o) => o.idOperario == authUser.idUsuario).toList();
      });
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
        onSubmit: (unidadesSesion, nota) => _repo.reportarAvanceIncremental(
          orden: orden,
          unidadesSesion: unidadesSesion,
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
      body: SafeArea(bottom: false, child: _buildBody()),
      bottomNavigationBar: AppDock(
        icons: _bottomIcons,
        selectedIndex: _bottomIndex,
        onSelected: (i) => setState(() => _bottomIndex = i),
      ),
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
}