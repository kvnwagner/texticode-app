import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_dock.dart';
import '../../../admin/data/models/orden_model.dart';
import '../../../admin/data/repositories/orden_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import 'cliente_dashboard_screen.dart';
import 'cliente_pedidos_screen.dart';
import 'cliente_soporte_screen.dart';
import 'cliente_perfil_screen.dart';

class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  final _authRepo = AuthRepository();
  final _ordenRepo = OrdenRepository();

  int _tab = 0;
  List<Orden> _ordenes = [];
  bool _loading = true;
  String? _error;

  static const _icons = [
    Icons.home_outlined,
    Icons.shopping_bag_outlined,
    Icons.support_agent_outlined,
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
      if (authUser == null) {
        if (mounted) context.go(AppRoutes.login);
        return;
      }
      final todas = await _ordenRepo.getOrdenes();
      final propias = todas.where((o) => o.idCliente == authUser.idUsuario).toList();
      if (!mounted) return;
      setState(() => _ordenes = propias);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _logout() {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ClienteDashboardScreen(
        ordenes: _ordenes,
        loading: _loading,
        error: _error,
        onRefresh: _cargar,
        onGoOrders: () => setState(() => _tab = 1),
      ),
      ClientePedidosScreen(
        ordenes: _ordenes,
        loading: _loading,
        error: _error,
        onRefresh: _cargar,
      ),
      const ClienteSoporteScreen(),
      ClientePerfilScreen(onLogout: _logout),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: AppDock(
        icons: _icons,
        selectedIndex: _tab,
        onSelected: (i) => setState(() => _tab = i),
      ),
    );
  }
}