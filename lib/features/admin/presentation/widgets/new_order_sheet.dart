import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/orden_repository.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/usuario_repository.dart';
import '../../data/models/material_model.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/repositories/orden_material_repository.dart';

class NewOrderSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const NewOrderSheet({super.key, required this.onCreated});

  @override
  State<NewOrderSheet> createState() => _NewOrderSheetState();
}

/// Un material elegido en el formulario + la cantidad que se va a usar
/// de él. Solo vive en memoria mientras se arma la orden; al enviar,
/// cada uno se registra vía OrdenMaterialRepository.agregarMaterial.
class _MaterialSeleccionado {
  final MaterialItem material;
  int cantidad;
  _MaterialSeleccionado({required this.material, this.cantidad = 1});
}

class _NewOrderSheetState extends State<NewOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repo = OrdenRepository();
  final _usuarioRepo = UsuarioRepository();
  final _materialRepo = MaterialRepository();
  final _ordenMaterialRepo = OrdenMaterialRepository();

  final _productoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  List<Usuario> _clientes = [];
  List<Usuario> _operarios = [];
  bool _loadingDatos = true;

  Usuario? _clienteSeleccionado;
  Usuario? _operarioSeleccionado;
  String _prioridad = 'Media';
  String _dificultad = 'Media';
  DateTime? _fechaLimite;

  // ── Materiales del cliente seleccionado (se recargan cada vez que
  // cambia el cliente) + los que el usuario ya agregó a la orden. ──
  List<MaterialItem> _materialesCliente = [];
  bool _loadingMateriales = false;
  MaterialItem? _materialParaAgregar;
  final List<_MaterialSeleccionado> _materialesSeleccionados = [];

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Solo clientes/operarios al abrir el formulario. Los materiales YA
  /// NO se cargan todos de una — dependen del cliente elegido.
  Future<void> _cargarDatos() async {
    try {
      final todos = await _usuarioRepo.getUsuarios();
      if (!mounted) return;
      setState(() {
        _clientes = todos.where((u) => u.isCliente).toList();
        _operarios = todos.where((u) => u.isOperario).toList();
        _loadingDatos = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDatos = false);
    }
  }

  /// Al elegir/cambiar el cliente: limpia los materiales ya agregados
  /// (pertenecían al cliente anterior) y trae SOLO los materiales de
  /// este cliente (GET /api/practica/clientes/:id/materiales).
  Future<void> _onClienteChanged(Usuario? cliente) async {
    setState(() {
      _clienteSeleccionado = cliente;
      _materialParaAgregar = null;
      _materialesSeleccionados.clear();
      _materialesCliente = [];
      _error = null;
    });
    if (cliente == null) return;

    setState(() => _loadingMateriales = true);
    try {
      final materiales = await _materialRepo.getMaterialesPorCliente(cliente.idUsuario);
      if (!mounted) return;
      setState(() => _materialesCliente = materiales);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingMateriales = false);
    }
  }

  /// Materiales del cliente que aún no están en la lista de agregados.
  List<MaterialItem> get _materialesDisponiblesParaAgregar => _materialesCliente
      .where((m) => !_materialesSeleccionados.any((s) => s.material.idMaterial == m.idMaterial))
      .toList();

  void _agregarMaterial() {
    if (_materialParaAgregar == null) return;
    setState(() {
      _materialesSeleccionados.add(_MaterialSeleccionado(material: _materialParaAgregar!));
      _materialParaAgregar = null;
    });
  }

  void _quitarMaterial(int idMaterial) {
    setState(() => _materialesSeleccionados.removeWhere((s) => s.material.idMaterial == idMaterial));
  }

  @override
  void dispose() {
    _productoCtrl.dispose();
    _descripcionCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaLimite ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _fechaLimite = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteSeleccionado == null) {
      setState(() => _error = 'Selecciona un cliente');
      return;
    }
    if (_operarioSeleccionado == null) {
      setState(() => _error = 'Selecciona un operador');
      return;
    }
    if (_materialesSeleccionados.isEmpty) {
      setState(() => _error = 'Agrega al menos un material');
      return;
    }
    if (_fechaLimite == null) {
      setState(() => _error = 'Selecciona la fecha límite');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // orden_produccion todavía exige un único Id_Material (FK NOT
      // NULL): se usa el primero de la lista como "principal". El
      // resto (y también ese principal) quedan además registrados en
      // orden_material, que sí soporta varios materiales por orden.
      final principal = _materialesSeleccionados.first;

      final idOrden = await _repo.crearOrden(
        idCliente: _clienteSeleccionado!.idUsuario,
        idMaterial: principal.material.idMaterial,
        producto: _productoCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        cantidadTotal: int.tryParse(_cantidadCtrl.text.trim()) ?? 0,
        idOperario: _operarioSeleccionado!.idUsuario,
        prioridad: _prioridad,
        dificultad: _dificultad,
        fechaLimite:
            '${_fechaLimite!.year.toString().padLeft(4, '0')}-${_fechaLimite!.month.toString().padLeft(2, '0')}-${_fechaLimite!.day.toString().padLeft(2, '0')}',
      );

      for (final s in _materialesSeleccionados) {
        await _ordenMaterialRepo.agregarMaterial(
          idOrden: idOrden,
          idProducto: s.material.idMaterial,
          cantidadUsada: s.cantidad,
        );
      }

      if (!mounted) return;
      widget.onCreated();
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _labelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.6,
    color: AppColors.textMuted,
  );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.inputPlaceholder, fontSize: 13),
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
        ),
      );

  Widget _fieldLabel(String text) => Text(text.toUpperCase(), style: _labelStyle);

  Widget _fieldLabelWithHint(String text, String hint) => RichText(
        text: TextSpan(
          children: [
            TextSpan(text: text.toUpperCase(), style: _labelStyle),
            TextSpan(
              text: '  $hint',
              style: _labelStyle.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.2),
            ),
          ],
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _dec(hint),
      style: const TextStyle(fontSize: 13, color: AppColors.inputText),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nueva Orden de Producción',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          SizedBox(height: 2),
                          Text('Completa los campos para registrar la orden',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.searchBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Icon(Icons.close, size: 15, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _fieldLabel('Cliente'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Usuario>(
                    initialValue: _clienteSeleccionado,
                    decoration: _dec(_loadingDatos ? 'Cargando...' : 'Selecciona un cliente'),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textFaint),
                    style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                    items: _clientes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.nombreCompleto)))
                        .toList(),
                    onChanged: _onClienteChanged,
                  ),
                  const SizedBox(height: 14),

                  // ── MATERIALES: filtrados por el cliente elegido + varios
                  // materiales por orden (dropdown "+ Agregar material..."
                  // más botón "Agregar", como en la referencia). ──
                  _fieldLabelWithHint('Materiales', '— selecciona uno o más'),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<MaterialItem>(
                          key: ValueKey(_clienteSeleccionado?.idUsuario),
                          initialValue: _materialParaAgregar,
                          decoration: _dec(
                            _clienteSeleccionado == null
                                ? 'Selecciona un cliente primero'
                                : (_loadingMateriales
                                    ? 'Cargando...'
                                    : (_materialesDisponiblesParaAgregar.isEmpty
                                        ? (_materialesCliente.isEmpty
                                            ? 'Este cliente no tiene materiales'
                                            : 'Ya agregaste todos los materiales')
                                        : '+ Agregar material...')),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textFaint),
                          style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                          items: _materialesDisponiblesParaAgregar
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      '${m.nombre} · Stock: ${m.stockActual} ${m.unidad}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (_clienteSeleccionado == null || _loadingMateriales)
                              ? null
                              : (v) => setState(() => _materialParaAgregar = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _materialParaAgregar == null ? null : _agregarMaterial,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.35),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add, size: 16, color: Colors.white),
                          label: const Text('Agregar',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  if (_materialesSeleccionados.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ..._materialesSeleccionados.map(_buildMaterialSeleccionadoRow),
                  ],
                  const SizedBox(height: 14),

                  _fieldLabel('Producto'),
                  const SizedBox(height: 6),
                  _textField(
                    controller: _productoCtrl,
                    hint: 'Nombre del producto',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'El producto es requerido' : null,
                  ),
                  const SizedBox(height: 14),

                  _fieldLabel('Descripción'),
                  const SizedBox(height: 6),
                  _textField(
                    controller: _descripcionCtrl,
                    hint: 'Descripción detallada',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),

                  _fieldLabel('Cantidad'),
                  const SizedBox(height: 6),
                  _textField(
                    controller: _cantidadCtrl,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Cantidad inválida';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _fieldLabel('Operador Asignado'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Usuario>(
                    initialValue: _operarioSeleccionado,
                    decoration: _dec(_loadingDatos ? 'Cargando...' : 'Seleccionar operador'),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textFaint),
                    style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                    items: _operarios
                        .map((o) => DropdownMenuItem(value: o, child: Text(o.nombreCompleto)))
                        .toList(),
                    onChanged: (v) => setState(() => _operarioSeleccionado = v),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Prioridad'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _prioridad,
                              decoration: _dec('Media'),
                              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textFaint),
                              style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                              items: const ['Baja', 'Media', 'Alta']
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) => setState(() => _prioridad = v ?? 'Media'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Dificultad'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _dificultad,
                              decoration: _dec('Media'),
                              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textFaint),
                              style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                              items: const ['Baja', 'Media', 'Alta']
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) => setState(() => _dificultad = v ?? 'Media'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _fieldLabel('Fecha Límite'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickFecha,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Text(
                        _fechaLimite == null
                            ? 'dd/mm/aaaa'
                            : '${_fechaLimite!.day.toString().padLeft(2, '0')}/${_fechaLimite!.month.toString().padLeft(2, '0')}/${_fechaLimite!.year}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _fechaLimite == null
                              ? AppColors.inputPlaceholder
                              : AppColors.inputText,
                        ),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.errorBorder),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.errorText, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: _loading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.cardBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Cancelar',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Crear Orden',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialSeleccionadoRow(_MaterialSeleccionado s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.material.nombre,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('Stock: ${s.material.stockActual} ${s.material.unidad}',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textFaint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: TextFormField(
              initialValue: '${s.cantidad}',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inputText),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
              ),
              onChanged: (v) => s.cantidad = int.tryParse(v) ?? s.cantidad,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _quitarMaterial(s.material.idMaterial),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.errorBg, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: AppColors.errorText),
            ),
          ),
        ],
      ),
    );
  }
}