import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_dock.dart';
import '../../../admin/data/models/comprobante_model.dart';
import '../../../admin/data/models/orden_model.dart';
import '../../../admin/data/models/usuario_model.dart';
import '../../../admin/data/repositories/comprobante_repository.dart';
import '../../../admin/data/repositories/orden_repository.dart';
import '../../../admin/data/repositories/usuario_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import 'cliente_pedidos_screen.dart';
import 'cliente_soporte_screen.dart';
import 'cliente_perfil_screen.dart';
import 'cliente_alertas_screen.dart';

class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  final _authRepo = AuthRepository();
  final _ordenRepo = OrdenRepository();
  final _comprobanteRepo = ComprobanteRepository();
  final _usuarioRepo = UsuarioRepository();

  // ⬅️ Ya no hay pestaña "Comprobantes" (dashboard). La app de cliente
  // ahora abre directo en "Mis Pedidos", que además ya incluye las
  // stat cards que antes vivían solo en el dashboard.
  int _tab = 0;
  List<Orden> _ordenes = [];
  Map<int, List<Comprobante>> _comprobantesPorOrden = {};
  Usuario? _cliente;
  bool _loading = true;
  String? _error;

  static const _icons = [
    Icons.shopping_bag_outlined,
    Icons.warning_amber_rounded, // ⬅️ debe estar aquí
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
      final resultados = await Future.wait([
        _ordenRepo.getOrdenesDeCliente(authUser.idUsuario),
        _comprobanteRepo.getComprobantesPorCliente(authUser.idUsuario),
        _usuarioRepo.getUsuario(authUser.idUsuario).onError(
              (_, __) => Usuario(
                idUsuario: authUser.idUsuario,
                nombreCompleto: authUser.nombreCompleto,
                nombreUsuario: authUser.nombreUsuario,
                correo: authUser.correo,
                estado: authUser.estado,
                rol: authUser.rol,
                idRol: authUser.idRol,
              ),
            ),
      ]);
      if (!mounted) return;

      final porOrden = <int, List<Comprobante>>{};
      for (final comprobante in resultados[1] as List<Comprobante>) {
        (porOrden[comprobante.idOrden] ??= []).add(comprobante);
      }
      setState(() {
        _ordenes = resultados[0] as List<Orden>;
        _comprobantesPorOrden = porOrden;
        _cliente = resultados[2] as Usuario;
      });
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
      ClientePedidosScreen(
        ordenes: _ordenes,
        comprobantesPorOrden: _comprobantesPorOrden,
        cliente: _cliente,
        loading: _loading,
        error: _error,
        onRefresh: _cargar,
      ),
      const ClienteAlertasScreen(), // ⬅️ FALTABA ESTO
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
