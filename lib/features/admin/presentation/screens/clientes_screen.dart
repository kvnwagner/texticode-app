import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/impresion_overlay.dart';

import '../../data/models/comprobante_model.dart';
import '../../data/models/orden_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/comprobante_repository.dart';
import '../../data/repositories/orden_repository.dart';
import '../../data/repositories/usuario_repository.dart';
import '../../data/services/pdf_descarga.dart';
import '../../data/services/comprobante_pdf_service.dart';
import '../widgets/comprobante_preview_sheet.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _usuarioRepo = UsuarioRepository();
  final _comprobanteRepo = ComprobanteRepository();
  final _ordenRepo = OrdenRepository();

  List<Usuario> _clientes = [];
  List<Comprobante> _comprobantes = [];
  Map<int, Orden> _ordenesPorId = {};

  bool _loading = true;
  String? _error;
  String _query = '';

  // ID del comprobante que se está generando.
  String? _descargando;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final resultados = await Future.wait([
        _usuarioRepo.getUsuarios(),
        _comprobanteRepo.getComprobantes(),
        _ordenRepo.getOrdenes(),
      ]);

      if (!mounted) return;

      setState(() {
        _clientes =
            (resultados[0] as List<Usuario>).where((u) => u.isCliente).toList();

        final comprobantes = resultados[1] as List<Comprobante>;
        final ordenes = resultados[2] as List<Orden>;
        final idsConComprobante = comprobantes.map((c) => c.idOrden).toSet();
        _ordenesPorId = {for (final orden in ordenes) orden.idOrden: orden};
        _comprobantes = [
          ...comprobantes,
          for (final orden in ordenes)
            if (orden.isCompletada &&
                !idsConComprobante.contains(orden.idOrden))
              Comprobante.deOrden(orden),
        ];
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<Usuario> get _clientesFiltrados {
    if (_query.trim().isEmpty) {
      return _clientes;
    }

    final q = _query.trim().toLowerCase();

    return _clientes.where((cliente) {
      final nombre = cliente.nombreCompleto.toLowerCase();
      final correo = (cliente.correo ?? '').toLowerCase();

      return nombre.contains(q) || correo.contains(q);
    }).toList();
  }

  Usuario? _clienteDe(Comprobante comprobante) {
    for (final cliente in _clientes) {
      if (cliente.idUsuario == comprobante.idCliente) {
        return cliente;
      }
    }

    return null;
  }

  List<Comprobante> _comprobantesDeCliente(Usuario cliente) {
    return _comprobantes
        .where((comprobante) => comprobante.idCliente == cliente.idUsuario)
        .toList();
  }

  Future<void> _descargarComprobante(Comprobante comprobante) async {
    if (_descargando != null) return;

    setState(() {
      _descargando = comprobante.numero;
    });

    try {
      final numero = comprobante.numero;
      // Animación de impresora, igual que en Gestión de Clientes de la web.
      await ImpresionOverlay.ejecutar<Uint8List>(
        context: context,
        tipo: TipoImpresion.comprobante,
        numero: numero,
        detalle: comprobante.cliente,
        generar: () => ComprobantePdfService.generar(
          comprobante: comprobante,
          cliente: _clienteDe(comprobante),
          orden: _ordenesPorId[comprobante.idOrden],
        ),
        entregar: (bytes) async {
          await PdfDescarga.guardar(bytes, 'comprobante-$numero.pdf');
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el PDF.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _descargando = null;
        });
      }
    }
  }

  void _verComprobante(Comprobante comprobante) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComprobantePreviewSheet(
        comprobante: comprobante,
        cliente: _clienteDe(comprobante),
        orden: _ordenesPorId[comprobante.idOrden],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.navy,
              ),
            )
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.navy,
                  onRefresh: _cargar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _buildSearch(),
                      _buildSectionHeader(
                        'Lista de Clientes',
                        _clientesFiltrados.length,
                      ),
                      if (_clientesFiltrados.isEmpty) _buildEmptyClientes(),

                      ..._clientesFiltrados.map(_buildClienteTile),

                      const SizedBox(height: 130),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.searchBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 18,
              color: AppColors.textFaint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Buscar clientes...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.inputText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta desplegable del cliente ───────────────────────────────────

  Widget _buildClienteTile(Usuario cliente) {
    final comprobantesCliente = _comprobantesDeCliente(cliente);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.cardBorder,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            iconColor: AppColors.brandIcon,
            collapsedIconColor: AppColors.textMuted,
            title: Row(
              children: [
                AvatarWidget(
                  initials: cliente.initials,
                  size: 38,
                  bg: AppColors
                      .avatarPalette[cliente.idUsuario %
                          AppColors.avatarPalette.length]['bg']!,
                  text: AppColors
                      .avatarPalette[cliente.idUsuario %
                          AppColors.avatarPalette.length]['text']!,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombreCompleto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cliente.correo ?? 'Sin correo registrado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cliente.telefono ?? 'Sin teléfono registrado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandTint.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 13,
                        color: AppColors.brandIcon,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comprobantesCliente.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              if (comprobantesCliente.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.searchBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 20,
                        color: AppColors.textFaint,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Este cliente no tiene comprobantes registrados.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...comprobantesCliente.map(
                  (comprobante) => _buildComprobanteTile(
                    comprobante,
                    insideCliente: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Comprobantes de entrega ───────────────────────────────────────────

  Widget _buildComprobanteTile(
    Comprobante comprobante, {
    bool insideCliente = false,
  }) {
    final descargando = _descargando == comprobante.numero;

    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: insideCliente ? 0 : 16,
        right: insideCliente ? 0 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.brandTint.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 19,
                color: AppColors.brandIcon,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comprobante #${comprobante.numero}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _textoFechaComprobante(comprobante),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _buildEstadoComprobante(comprobante),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // ── Botón VER ──────────────────────────────────────────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _verComprobante(comprobante),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // ── Botón DESCARGAR ────────────────────────────────────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: descargando
                    ? null
                    : () => _descargarComprobante(
                          comprobante,
                        ),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: descargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.download_outlined,
                          size: 19,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoComprobante(
    Comprobante comprobante,
  ) {
    final entregado = comprobante.isCompletado ||
        (_ordenesPorId[comprobante.idOrden]?.isCompletada ?? false);
    final color = entregado ? AppColors.iconActive : AppColors.badgeClientText;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            entregado ? Icons.check_circle_outline : Icons.schedule,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            _ordenesPorId[comprobante.idOrden]?.estado ??
                comprobante.estadoPedido,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _textoFechaComprobante(
    Comprobante comprobante,
  ) {
    return 'Fecha: ${comprobante.fechaCorta}';
  }

  // ── Estados vacíos ────────────────────────────────────────────────────

  Widget _buildEmptyClientes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        20,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 28,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.cardBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.brandTint.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 26,
                color: AppColors.brandIcon,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay clientes encontrados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'No existen clientes que coincidan con la búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.iconClient.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 30,
                color: AppColors.iconClient,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No se pudieron cargar los clientes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? 'Ocurrió un error inesperado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
