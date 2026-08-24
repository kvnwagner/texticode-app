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
import '../widgets/user_action_sheet.dart';

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
  int? _descargando; // id del comprobante que se está generando, para spinner

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
      final resultados = await Future.wait([
        _usuarioRepo.getUsuarios(),
        _comprobanteRepo.getComprobantes(),
      ]);
      if (!mounted) return;
      setState(() {
        _clientes = (resultados[0] as List<Usuario>).where((u) => u.isCliente).toList();
        _comprobantes = resultados[1] as List<Comprobante>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Usuario> get _clientesFiltrados {
    if (_query.trim().isEmpty) return _clientes;
    final q = _query.toLowerCase();
    return _clientes
        .where((c) =>
    c.nombreCompleto.toLowerCase().contains(q) ||
        (c.correo ?? '').toLowerCase().contains(q))
        .toList();
  }

  Usuario? _clienteDe(Comprobante c) {
    for (final cl in _clientes) {
      if (cl.idUsuario == c.idCliente) return cl;
    }
    return null;
  }

  // ⬅️ genera el PDF real (mismo diseño que la versión web) y abre
  // la vista previa nativa, desde donde el usuario puede guardar/compartir.
  Future<void> _descargarComprobante(Comprobante c) async {
    setState(() => _descargando = c.idComprobante);
    try {
      final Uint8List bytes = await ComprobantePdfService.generar(
        comprobante: c,
        cliente: _clienteDe(c),
      );
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'comprobante-${c.idComprobante.toString().padLeft(4, '0')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No se pudo generar el PDF.')));
      }
    } finally {
      if (mounted) setState(() => _descargando = null);
    }
  }

  void _verComprobante(Comprobante c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComprobantePreviewSheet(
        comprobante: c,
        cliente: _clienteDe(c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _clientes.length;
    final activos = _clientes.where((c) => c.isActivo).length;
    final inactivos = total - activos;

    return Container(
      color: AppColors.pageBg,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
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
            _buildMetrics(total, activos, inactivos),
            _buildSectionHeader('Lista de Clientes', _clientesFiltrados.length),
            if (_clientesFiltrados.isEmpty) _buildEmptyClientes(),
            ..._clientesFiltrados.map(_buildClienteTile),
            const SizedBox(height: 8),
            _buildSectionHeader('Comprobantes de Entrega', _comprobantes.length),
            if (_comprobantes.isEmpty) _buildEmptyComprobantes(),
            ..._comprobantes.map(_buildComprobanteTile),
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
                  hintText: 'Buscar clientes...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.inputText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetrics(int total, int activos, int inactivos) {
    final items = <_MetricItem>[
      _MetricItem('Total Clientes', total, Icons.people_outline, AppColors.iconOp),
      _MetricItem('Activos', activos, Icons.verified_user_outlined, AppColors.iconActive),
      _MetricItem('Inactivos', inactivos, Icons.person_off_outlined, AppColors.iconClient),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 78, // misma altura fija que Gestión de Usuarios
        ),
        itemBuilder: (context, index) => _buildMetricCard(items[index]),
      ),
    );
  }

  Widget _buildMetricCard(_MetricItem m) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(width: 3.5, color: m.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${m.value}',
                              style: TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.bold, color: m.color)),
                          const SizedBox(height: 3),
                          Text(m.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: m.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(m.icon, size: 16, color: m.color),
                    ),
                  ],
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
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)),
            child: Text('$count',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteTile(Usuario c) {
    final av = AppColors.avatarPalette[c.idUsuario % AppColors.avatarPalette.length];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(initials: c.initials, size: 38, bg: av['bg']!, text: av['text']!),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.nombreCompleto,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.isActivo ? AppColors.badgeOpGreenBg : AppColors.searchBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(c.isActivo ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: c.isActivo ? AppColors.badgeOpGreenText : AppColors.textFaint)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(c.correo ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.call_outlined, size: 10, color: AppColors.textFaint),
                      const SizedBox(width: 4),
                      Text(c.telefono ?? '',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComprobanteTile(Comprobante c) {
    final entregado = c.estado.toLowerCase().contains('entregado') ||
        c.estado.toLowerCase().contains('completado');
    final st = entregado
        ? (bg: AppColors.badgeOpGreenBg, text: AppColors.badgeOpGreenText)
        : (bg: AppColors.badgeClientBg, text: AppColors.badgeClientText);
    final descargando = _descargando == c.idComprobante;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('#${c.idComprobante.toString().padLeft(4, '0')}',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.navy)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(20)),
                  child: Text(c.estado,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: st.text)),
                ),
                const Spacer(),
                // ── Botón ojito (ver comprobante) ──
                GestureDetector(
                  onTap: () => _verComprobante(c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.visibility_outlined, size: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                // ── Botón descargar PDF ──
                GestureDetector(
                  onTap: descargando ? null : () => _descargarComprobante(c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: descargando
                        ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.download_outlined, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(c.usuario,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Vence: ${c.fechaCorta}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textFaint)),
                if (c.ordenDescripcion != null) ...[
                  const SizedBox(width: 6),
                  const Text('·', style: TextStyle(color: AppColors.cardBorder)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(c.ordenDescripcion!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.textFaint)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyClientes() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text('No se encontraron clientes',
            style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
      ),
    );
  }

  Widget _buildEmptyComprobantes() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text('No hay comprobantes registrados',
            style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _MetricItem(this.label, this.value, this.icon, this.color);
}

/// Vista previa del comprobante dentro de la app (botón de ojito).
/// Replica el mismo diseño usado en el PDF (ComprobantePdfService):
/// cabecera azul con logo, bloque cliente/fechas/estado, tabla de
/// producto/orden, observaciones y firmas — usando la paleta AppColors
/// de la app para mantener consistencia visual con el resto de pantallas.
class _ComprobantePreviewSheet extends StatelessWidget {
  final Comprobante comprobante;
  final Usuario? cliente;

  const _ComprobantePreviewSheet({required this.comprobante, this.cliente});

  bool get _entregado =>
      comprobante.estado.toLowerCase().contains('entregado') ||
          comprobante.estado.toLowerCase().contains('completado');

  String _fechaHoy() {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final d = DateTime.now();
    return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoBg = _entregado ? AppColors.badgeOpGreenBg : AppColors.badgeClientBg;
    final estadoTexto = _entregado ? AppColors.badgeOpGreenText : AppColors.badgeClientText;
    final estadoLabel = comprobante.estado;
    final numero = comprobante.idComprobante.toString().padLeft(4, '0');
    final descripcion = comprobante.ordenDescripcion ?? '—';
    final clienteEmail = cliente?.correo ?? '';
    final clienteTel = cliente?.telefono ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Cabecera azul ──
                        Container(
                          color: AppColors.navy,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: Image.asset(
                                          'assets/images/logo_texticode.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                              Icons.qr_code_2,
                                              color: AppColors.navy,
                                              size: 18),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'TEXTICODE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Bogotá, Colombia · texticode@correo.com\n+57 300 000 0000',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 9.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'COMPROBANTE DE ENTREGA',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 9.5,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'N.° $numero',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: estadoBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      estadoLabel,
                                      style: TextStyle(
                                          color: estadoTexto, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Cliente / fechas ──
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('CLIENTE'),
                              const SizedBox(height: 4),
                              Text(
                                comprobante.usuario,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (clienteEmail.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(clienteEmail,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                              if (clienteTel.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text('Tel: $clienteTel',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _label('FECHA DE EMISIÓN'),
                                        const SizedBox(height: 4),
                                        Text(_fechaHoy(),
                                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _label('FECHA DE ENTREGA'),
                                        const SizedBox(height: 4),
                                        Text(comprobante.fechaCorta,
                                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Estado / referencia ──
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('ESTADO DEL PEDIDO'),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                          color: estadoBg, borderRadius: BorderRadius.circular(20)),
                                      child: Text(estadoLabel,
                                          style: TextStyle(
                                              color: estadoTexto, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('ORDEN DE REFERENCIA'),
                                    const SizedBox(height: 6),
                                    Text('#$numero',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Productos / servicios ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('PRODUCTOS / SERVICIOS'),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Column(
                                  children: [
                                    Container(
                                      color: AppColors.navy,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: const Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            child: Text('#',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text('DESCRIPCIÓN',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text('CANTIDAD',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text('ESTADO',
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      color: AppColors.pageBg,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            child: Text('01',
                                                style: TextStyle(fontSize: 12, color: AppColors.textFaint)),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              descripcion,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          const Expanded(
                                            flex: 2,
                                            child: Text('1',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Container(
                                                padding:
                                                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                    color: estadoBg, borderRadius: BorderRadius.circular(20)),
                                                child: Text(estadoLabel,
                                                    style: TextStyle(
                                                        color: estadoTexto,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Observaciones ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('OBSERVACIONES'),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.pageBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: const Text(
                                  'Ninguna observación registrada para este pedido.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Firmas ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  children: [
                                    Text('ENTREGADO POR',
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: AppColors.textMuted,
                                            letterSpacing: 0.5)),
                                    SizedBox(height: 4),
                                    Text('TEXTICODE S.A.S.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.navy)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('RECIBIDO POR',
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: AppColors.textMuted,
                                            letterSpacing: 0.5)),
                                    const SizedBox(height: 4),
                                    Text(comprobante.usuario,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.navy)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Pie de página ──
                        Container(
                          width: double.infinity,
                          color: AppColors.navy,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Text(
                            'Este documento es un comprobante oficial de entrega emitido por TEXTICODE. · Generado el ${_fechaHoy()}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}