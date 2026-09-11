// lib/features/operario/presentation/screens/operario_home_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_dock.dart';
import '../../../admin/data/models/orden_operario_model.dart';
import '../../../admin/data/repositories/orden_operario_repository.dart';
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
  final _repo = OrdenOperarioRepository();
  final _authRepo = AuthRepository();
  int _bottomIndex = 1;
  List<OrdenOperario> _fases = [];
  bool _loading = true;
  String? _error;
  final Map<int, List<AvanceReporte>> _reportes = {};

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
      final data = authUser == null
          ? <OrdenOperario>[]
          : await _repo.getFasesDeOperario(authUser.idUsuario);
      if (!mounted) return;
      setState(() => _fases = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reportarAvance(OrdenOperario fase) async {
    int? unidadesReportadas;
    String? notaReportada;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportProgressSheet(
        fase: fase,
        onSubmit: (unidadesSesion, nota) async {
          unidadesReportadas = unidadesSesion;
          notaReportada = nota;
          await _repo.reportarAvanceIncremental(
            idOrdenOperario: fase.idOrdenOperario,
            unidadesSesion: unidadesSesion,
          );
        },
      ),
    );
    if (updated == true) {
      final unidades = unidadesReportadas;
      if (unidades != null) {
        _reportes.putIfAbsent(fase.idOrdenOperario, () => []).add(
              AvanceReporte(
                fecha: DateTime.now(),
                unidades: unidades,
                acumulado: fase.cantidadRealizada + unidades,
                nota: notaReportada,
              ),
            );
      }
      await _cargar();
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
          fases: _fases,
          loading: _loading,
          error: _error,
          onRefresh: _cargar,
        );
      case 2:
        return const PerfilScreen();
      case 1:
      default:
        return ReportarAvancesView(
          fases: _fases,
          loading: _loading,
          error: _error,
          onRefresh: _cargar,
          onReport: _reportarAvance,
          reportes: _reportes,
        );
    }
  }
}
