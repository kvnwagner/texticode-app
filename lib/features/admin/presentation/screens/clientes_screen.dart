import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';

import '../../data/models/comprobante_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/comprobante_repository.dart';
import '../../data/repositories/usuario_repository.dart';
import '../../data/services/comprobante_pdf_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _usuarioRepo = UsuarioRepository();
  final _comprobanteRepo = ComprobanteRepository();

  List<Usuario> _clientes = [];
  List<Comprobante> _comprobantes = [];

  bool _loading = true;
  String? _error;
  String _query = '';

  // ID del comprobante que se está generando.
  int? _descargando;

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
      ]);

      if (!mounted) return;

      setState(() {
        _clientes = (resultados[0] as List<Usuario>)
            .where((u) => u.isCliente)
            .toList();

        _comprobantes = resultados[1] as List<Comprobante>;
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

  // Solo se cuentan/muestran los comprobantes cuya orden esté "Completada".
  List<Comprobante> _comprobantesCompletados(Usuario cliente) {
    return _comprobantes.where((comprobante) {
      if (comprobante.idCliente != cliente.idUsuario) return false;

      final estado = _obtenerEstadoComprobante(comprobante).toLowerCase();
      return estado == 'completada' || estado == 'completado';
    }).toList();
  }

  // Genera el PDF real y abre la vista previa nativa.
  Future<void> _descargarComprobante(Comprobante comprobante) async {
    if (_descargando != null) return;

    setState(() {
      _descargando = comprobante.idComprobante;
    });

    try {
      final Uint8List bytes = await ComprobantePdfService.generar(
        comprobante: comprobante,
        cliente: _clienteDe(comprobante),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name:
            'comprobante-${comprobante.idComprobante.toString().padLeft(4, '0')}.pdf',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar el PDF.'),
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
      builder: (_) => _ComprobantePreviewSheet(
        comprobante: comprobante,
        cliente: _clienteDe(comprobante),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: _loading
          ? const Center(
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
            const Icon(
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
                style: const TextStyle(
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
            style: const TextStyle(
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
    final comprobantesCliente = _comprobantesCompletados(cliente);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pageBg,
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
            iconColor: AppColors.navy,
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
                        style: const TextStyle(
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cliente.telefono ?? 'Sin teléfono registrado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
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
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 13,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comprobantesCliente.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
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
                  child: const Row(
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
    final descargando = _descargando == comprobante.idComprobante;

    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: insideCliente ? 0 : 16,
        right: insideCliente ? 0 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
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
                color: AppColors.navy.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 19,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comprobante #${comprobante.idComprobante.toString().padLeft(4, '0')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
                    style: const TextStyle(
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
    // Estos tiles solo se renderizan para comprobantes cuya orden ya está
    // completada (ver _comprobantesCompletados), así que el badge siempre
    // refleja ese estado sin depender de qué campo trajo el backend.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.iconActive.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 12,
            color: AppColors.iconActive,
          ),
          SizedBox(width: 4),
          Text(
            'Completada',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.iconActive,
            ),
          ),
        ],
      ),
    );
  }

  String _obtenerEstadoComprobante(Comprobante comprobante) {
    final ordenEstado = comprobante.ordenEstado;
    if (ordenEstado != null && ordenEstado.trim().isNotEmpty) {
      return ordenEstado;
    }
    return comprobante.estado;
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
          color: AppColors.pageBg,
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
                color: AppColors.navy.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 26,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay clientes encontrados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
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
              child: const Icon(
                Icons.error_outline,
                size: 30,
                color: AppColors.iconClient,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
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
              style: const TextStyle(
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

// ── Vista previa del comprobante (bottom sheet con el PDF) ───────────────

class _ComprobantePreviewSheet extends StatelessWidget {
  final Comprobante comprobante;
  final Usuario? cliente;

  const _ComprobantePreviewSheet({
    required this.comprobante,
    required this.cliente,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comprobante #${comprobante.idComprobante.toString().padLeft(4, '0')}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<Uint8List>(
                  future: ComprobantePdfService.generar(
                    comprobante: comprobante,
                    cliente: cliente,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.navy,
                        ),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Text(
                          'No se pudo generar la vista previa.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    }

                    return PdfPreview(
                      build: (format) async => snapshot.data!,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      allowSharing: true,
                      allowPrinting: true,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}