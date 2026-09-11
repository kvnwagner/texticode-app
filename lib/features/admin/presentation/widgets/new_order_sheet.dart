import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/orden_model.dart';
import '../../data/repositories/orden_repository.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/usuario_repository.dart';
import '../../data/models/material_model.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/repositories/orden_material_repository.dart';
import '../../data/repositories/orden_operario_repository.dart';

class NewOrderSheet extends StatefulWidget {
  final VoidCallback onCreated;
  final Orden? orden;
  const NewOrderSheet({super.key, required this.onCreated, this.orden});

  @override
  State<NewOrderSheet> createState() => _NewOrderSheetState();
}

/// Un material elegido en el formulario + la cantidad que se va a usar
/// de él. Solo vive en memoria mientras se arma la orden; al enviar,
/// cada uno se registra vía OrdenMaterialRepository.agregarMaterial y
/// se descuenta del inventario real (MaterialRepository.actualizarMaterial).
///
/// [cantidadCtrl] permite mostrar/corregir en pantalla el valor cuando
/// el usuario intenta escribir más unidades de las que hay en stock.
class _MaterialSeleccionado {
  final MaterialItem material;
  int cantidad = 1;
  final TextEditingController cantidadCtrl;

  _MaterialSeleccionado({required this.material})
      : cantidadCtrl = TextEditingController(text: '1');
}

class _OperarioFaseSeleccionado {
  final int? idOrdenOperario;
  Usuario operario;
  int numeroFase;
  final TextEditingController numeroCtrl;
  final TextEditingController descripcionCtrl;

  _OperarioFaseSeleccionado({
    this.idOrdenOperario,
    required this.operario,
    required this.numeroFase,
    String descripcion = '',
  })  : numeroCtrl = TextEditingController(text: '$numeroFase'),
        descripcionCtrl = TextEditingController(text: descripcion);
}

class _NewOrderSheetState extends State<NewOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repo = OrdenRepository();
  final _usuarioRepo = UsuarioRepository();
  final _materialRepo = MaterialRepository();
  final _ordenMaterialRepo = OrdenMaterialRepository();
  final _ordenOperarioRepo = OrdenOperarioRepository();

  final _productoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  List<Usuario> _clientes = [];
  List<Usuario> _operarios = [];
  bool _loadingDatos = true;

  Usuario? _clienteSeleccionado;
  Usuario? _operarioFaseParaAgregar;
  final _numeroFaseCtrl = TextEditingController(text: '1');
  final _descripcionFaseCtrl = TextEditingController();
  String _prioridad = 'Media';
  String _dificultad = 'Media';
  DateTime? _fechaLimite;

  // ── Materiales del cliente seleccionado (se recargan cada vez que
  // cambia el cliente) + los que el usuario ya agregó a la orden. ──
  List<MaterialItem> _materialesCliente = [];
  bool _loadingMateriales = false;
  MaterialItem? _materialParaAgregar;
  final List<_MaterialSeleccionado> _materialesSeleccionados = [];
  final List<_OperarioFaseSeleccionado> _fasesSeleccionadas = [];
  final List<int> _fasesEliminadas = [];

  bool _loading = false;
  String? _error;
  bool get _isEdit => widget.orden != null;

  @override
  void initState() {
    super.initState();
    _precargarOrden();
    _cargarDatos();
  }

  void _precargarOrden() {
    final orden = widget.orden;
    if (orden == null) return;
    _productoCtrl.text = orden.producto;
    _descripcionCtrl.text = orden.descripcion ?? '';
    _cantidadCtrl.text = '${orden.cantidadTotal}';
    _prioridad = orden.prioridadLabel;
    _dificultad = orden.dificultad;
    _fechaLimite = orden.fechaLimite == null
        ? null
        : DateTime.tryParse(orden.fechaLimite!);
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
        final orden = widget.orden;
        if (orden != null) {
          _clienteSeleccionado = _clientes
              .where((u) => u.idUsuario == orden.idCliente)
              .cast<Usuario?>()
              .firstOrNull;
        }
        _loadingDatos = false;
      });
      final orden = widget.orden;
      if (orden != null) {
        final cliente = _clienteSeleccionado;
        if (cliente != null) await _cargarMaterialesParaCliente(cliente);
        await _cargarFasesExistentes(orden.idOrden);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDatos = false);
    }
  }

  Future<void> _cargarMaterialesParaCliente(Usuario cliente) async {
    setState(() => _loadingMateriales = true);
    try {
      final materiales =
          await _materialRepo.getMaterialesPorCliente(cliente.idUsuario);
      if (!mounted) return;
      setState(() => _materialesCliente = materiales);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingMateriales = false);
    }
  }

  Future<void> _cargarFasesExistentes(int idOrden) async {
    try {
      final fases = await _ordenOperarioRepo.getFasesDeOrden(idOrden);
      if (!mounted) return;
      setState(() {
        for (final fase in fases) {
          final operario = _operarios
              .where((u) => u.idUsuario == fase.idOperario)
              .cast<Usuario?>()
              .firstOrNull;
          if (operario == null) continue;
          _fasesSeleccionadas.add(_OperarioFaseSeleccionado(
            idOrdenOperario: fase.idOrdenOperario,
            operario: operario,
            numeroFase: fase.numeroFase,
            descripcion: fase.descripcionFase,
          ));
        }
      });
    } catch (_) {
      // Si la orden vieja no tiene fases todavia, el formulario queda listo para agregarlas.
    }
  }

  /// Al elegir/cambiar el cliente: limpia los materiales ya agregados
  /// (pertenecían al cliente anterior) y trae SOLO los materiales de
  /// este cliente (GET /api/practica/clientes/:id/materiales).
  Future<void> _onClienteChanged(Usuario? cliente) async {
    for (final s in _materialesSeleccionados) {
      s.cantidadCtrl.dispose();
    }
    setState(() {
      _clienteSeleccionado = cliente;
      _materialParaAgregar = null;
      _materialesSeleccionados.clear();
      _materialesCliente = [];
      _error = null;
    });
    if (cliente == null) return;

    await _cargarMaterialesParaCliente(cliente);
  }

  /// Materiales del cliente que aún no están en la lista de agregados.
  /// Se excluyen además los que ya no tienen stock disponible, para no
  /// ofrecer algo que no se puede usar.
  List<MaterialItem> get _materialesDisponiblesParaAgregar => _materialesCliente
      .where((m) =>
          m.stockActual > 0 &&
          !_materialesSeleccionados
              .any((s) => s.material.idMaterial == m.idMaterial))
      .toList();

  void _agregarMaterial() {
    if (_materialParaAgregar == null) return;
    setState(() {
      _materialesSeleccionados
          .add(_MaterialSeleccionado(material: _materialParaAgregar!));
      _materialParaAgregar = null;
    });
  }

  void _quitarMaterial(int idMaterial) {
    final idx = _materialesSeleccionados
        .indexWhere((s) => s.material.idMaterial == idMaterial);
    if (idx == -1) return;
    _materialesSeleccionados[idx].cantidadCtrl.dispose();
    setState(() => _materialesSeleccionados.removeAt(idx));
  }

  void _agregarFase() {
    if (_operarioFaseParaAgregar == null) return;
    final numero = int.tryParse(_numeroFaseCtrl.text.trim());
    if (numero == null || numero <= 0) {
      setState(() => _error = 'El número de fase debe ser mayor que cero');
      return;
    }
    if (_fasesSeleccionadas.any((f) => f.numeroFase == numero)) {
      setState(() => _error = 'Ya agregaste una fase con ese número');
      return;
    }
    setState(() {
      _fasesSeleccionadas.add(_OperarioFaseSeleccionado(
        operario: _operarioFaseParaAgregar!,
        numeroFase: numero,
        descripcion: _descripcionFaseCtrl.text.trim(),
      ));
      _fasesSeleccionadas.sort((a, b) => a.numeroFase.compareTo(b.numeroFase));
      _operarioFaseParaAgregar = null;
      _numeroFaseCtrl.text = '${_siguienteNumeroFase()}';
      _descripcionFaseCtrl.clear();
      _error = null;
    });
  }

  int _siguienteNumeroFase() {
    if (_fasesSeleccionadas.isEmpty) return 1;
    return _fasesSeleccionadas
            .map((f) => f.numeroFase)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  void _quitarFase(_OperarioFaseSeleccionado fase) {
    if (fase.idOrdenOperario != null) {
      _fasesEliminadas.add(fase.idOrdenOperario!);
    }
    fase.numeroCtrl.dispose();
    fase.descripcionCtrl.dispose();
    setState(() => _fasesSeleccionadas.remove(fase));
  }

  void _moverFase(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _fasesSeleccionadas.length) return;
    setState(() {
      final item = _fasesSeleccionadas.removeAt(index);
      _fasesSeleccionadas.insert(target, item);
      for (var i = 0; i < _fasesSeleccionadas.length; i++) {
        _fasesSeleccionadas[i].numeroFase = i + 1;
        _fasesSeleccionadas[i].numeroCtrl.text = '${i + 1}';
      }
      _numeroFaseCtrl.text = '${_siguienteNumeroFase()}';
    });
  }

  @override
  void dispose() {
    for (final s in _materialesSeleccionados) {
      s.cantidadCtrl.dispose();
    }
    for (final f in _fasesSeleccionadas) {
      f.numeroCtrl.dispose();
      f.descripcionCtrl.dispose();
    }
    _productoCtrl.dispose();
    _descripcionCtrl.dispose();
    _cantidadCtrl.dispose();
    _numeroFaseCtrl.dispose();
    _descripcionFaseCtrl.dispose();
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
    if (_fasesSeleccionadas.isEmpty) {
      setState(() => _error = 'Agrega al menos un operario/fase');
      return;
    }
    if (!_isEdit && _materialesSeleccionados.isEmpty) {
      setState(() => _error = 'Agrega al menos un material');
      return;
    }
    if (_fechaLimite == null) {
      setState(() => _error = 'Selecciona la fecha límite');
      return;
    }

    final numerosFase = <int>{};
    for (final fase in _fasesSeleccionadas) {
      final numero = int.tryParse(fase.numeroCtrl.text.trim());
      if (numero == null || numero <= 0) {
        setState(() => _error = 'Todas las fases deben tener un número válido');
        return;
      }
      if (!numerosFase.add(numero)) {
        setState(() => _error = 'No puede haber dos fases con el mismo número');
        return;
      }
    }

    // ── Validación final de stock: por si el stock cambió entre que se
    // cargó la lista y el momento de enviar, no se permite pasar del
    // stock actual de ningún material seleccionado. ──
    for (final s in _materialesSeleccionados) {
      if (s.cantidad > s.material.stockActual) {
        setState(() => _error =
            'No hay suficiente stock de "${s.material.nombre}" (disponible: ${s.material.stockActual} ${s.material.unidad}).');
        return;
      }
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
      final fecha =
          '${_fechaLimite!.year.toString().padLeft(4, '0')}-${_fechaLimite!.month.toString().padLeft(2, '0')}-${_fechaLimite!.day.toString().padLeft(2, '0')}';
      final cantidadTotal = int.tryParse(_cantidadCtrl.text.trim()) ?? 0;
      final ordenEdit = widget.orden;
      final int idOrden;

      if (ordenEdit == null) {
        final principal = _materialesSeleccionados.first;
        idOrden = await _repo.crearOrden(
          idCliente: _clienteSeleccionado!.idUsuario,
          idMaterial: principal.material.idMaterial,
          producto: _productoCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          cantidadTotal: cantidadTotal,
          idOperario: _fasesSeleccionadas.first.operario.idUsuario,
          prioridad: _prioridad,
          dificultad: _dificultad,
          fechaLimite: fecha,
        );
      } else {
        idOrden = ordenEdit.idOrden;
        await _repo.actualizarOrden(
          id: ordenEdit.idOrden,
          idCliente: _clienteSeleccionado!.idUsuario,
          idMaterial: ordenEdit.idMaterial,
          producto: _productoCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          cantidadTotal: cantidadTotal,
          idOperario: _fasesSeleccionadas.first.operario.idUsuario,
          prioridad: _prioridad,
          estado: ordenEdit.estado,
          fechaLimite: fecha,
          unidades: ordenEdit.unidades,
          unidadesRealizadas: ordenEdit.cantidadActual,
          dificultad: _dificultad,
        );
      }

      for (final fase in _fasesSeleccionadas) {
        final numeroFase =
            int.tryParse(fase.numeroCtrl.text.trim()) ?? fase.numeroFase;
        final descripcion = fase.descripcionCtrl.text.trim();
        if (fase.idOrdenOperario == null) {
          await _ordenOperarioRepo.agregarFase(
            idOrden: idOrden,
            idOperario: fase.operario.idUsuario,
            numeroFase: numeroFase,
            descripcionFase: descripcion,
          );
        } else {
          await _ordenOperarioRepo.actualizarFase(
            idOrdenOperario: fase.idOrdenOperario!,
            numeroFase: numeroFase,
            descripcionFase: descripcion,
          );
        }
      }

      for (final idFase in _fasesEliminadas) {
        await _ordenOperarioRepo.eliminarFase(idFase);
      }

      if (ordenEdit != null) {
        if (!mounted) return;
        widget.onCreated();
        Navigator.pop(context);
        return;
      }

      for (final s in _materialesSeleccionados) {
        await _ordenMaterialRepo.agregarMaterial(
          idOrden: idOrden,
          idProducto: s.material.idMaterial,
          cantidadUsada: s.cantidad,
        );

        // Descuenta del inventario real lo que se usó en esta orden,
        // tanto en la app como en Supabase (PUT /api/materiales/:id).
        final nuevoStock = (s.material.stockActual - s.cantidad)
            .clamp(0, s.material.stockMaximo);
        await _materialRepo.actualizarMaterial(
          id: s.material.idMaterial,
          nombre: s.material.nombre,
          categoria: s.material.categoria,
          stockActual: nuevoStock,
          unidad: s.material.unidad,
          stockMinimo: s.material.stockMinimo,
          stockMaximo: s.material.stockMaximo,
          idCliente: s.material.idCliente,
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
        hintStyle:
            const TextStyle(color: AppColors.inputPlaceholder, fontSize: 13),
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _fieldLabel(String text) =>
      Text(text.toUpperCase(), style: _labelStyle);

  Widget _fieldLabelWithHint(String text, String hint) => RichText(
        text: TextSpan(
          children: [
            TextSpan(text: text.toUpperCase(), style: _labelStyle),
            TextSpan(
              text: '  $hint',
              style: _labelStyle.copyWith(
                  fontWeight: FontWeight.w500, letterSpacing: 0.2),
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
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              _isEdit
                                  ? 'Editar Orden de Producción'
                                  : 'Nueva Orden de Producción',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(
                              _isEdit
                                  ? 'Actualiza los campos de la orden'
                                  : 'Completa los campos para registrar la orden',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
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
                          child: const Icon(Icons.close,
                              size: 15, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _fieldLabel('Cliente'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Usuario>(
                    initialValue: _clienteSeleccionado,
                    decoration: _dec(_loadingDatos
                        ? 'Cargando...'
                        : 'Selecciona un cliente'),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textFaint),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inputText),
                    items: _clientes
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.nombreCompleto)))
                        .toList(),
                    onChanged: _onClienteChanged,
                  ),
                  const SizedBox(height: 14),

                  // ── MATERIALES: filtrados por el cliente elegido + varios
                  // materiales por orden (dropdown "+ Agregar material..."
                  // más botón "Agregar", como en la referencia). Solo se
                  // ofrecen materiales con stock disponible. ──
                  _fieldLabelWithHint(
                    'Materiales',
                    _isEdit
                        ? '— no se modifican desde edición'
                        : '— selecciona uno o más',
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<MaterialItem>(
                          key: ValueKey(_clienteSeleccionado?.idUsuario),
                          initialValue: _materialParaAgregar,
                          decoration: _dec(
                            _isEdit
                                ? 'Material principal: ${widget.orden?.nombreMaterial ?? 'sin nombre'}'
                                : _clienteSeleccionado == null
                                    ? 'Selecciona un cliente primero'
                                    : (_loadingMateriales
                                        ? 'Cargando...'
                                        : (_materialesDisponiblesParaAgregar
                                                .isEmpty
                                            ? (_materialesCliente.isEmpty
                                                ? 'Este cliente no tiene materiales'
                                                : 'Ya agregaste todos los materiales con stock')
                                            : '+ Agregar material...')),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.textFaint),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.inputText),
                          items: _materialesDisponiblesParaAgregar
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      '${m.nombre} · Stock: ${m.stockActual} ${m.unidad}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (_isEdit ||
                                  _clienteSeleccionado == null ||
                                  _loadingMateriales)
                              ? null
                              : (v) => setState(() => _materialParaAgregar = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _materialParaAgregar == null
                              ? null
                              : _agregarMaterial,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            disabledBackgroundColor:
                                AppColors.navy.withValues(alpha: 0.35),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add,
                              size: 16, color: Colors.white),
                          label: const Text('Agregar',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  if (_materialesSeleccionados.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ..._materialesSeleccionados
                        .map(_buildMaterialSeleccionadoRow),
                  ],
                  const SizedBox(height: 14),

                  _fieldLabel('Producto'),
                  const SizedBox(height: 6),
                  _textField(
                    controller: _productoCtrl,
                    hint: 'Nombre del producto',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El producto es requerido'
                        : null,
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

                  _fieldLabelWithHint(
                      'Operarios y fases', '— una fase por paso de producción'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Usuario>(
                    initialValue: _operarioFaseParaAgregar,
                    decoration: _dec(
                        _loadingDatos ? 'Cargando...' : 'Seleccionar operario'),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textFaint),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inputText),
                    items: _operarios
                        .map((o) => DropdownMenuItem(
                            value: o, child: Text(o.nombreCompleto)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _operarioFaseParaAgregar = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 78,
                        child: TextFormField(
                          controller: _numeroFaseCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: _dec('Fase'),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.inputText),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _descripcionFaseCtrl,
                          decoration: _dec('Descripción de la fase'),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.inputText),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _operarioFaseParaAgregar == null
                              ? null
                              : _agregarFase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            disabledBackgroundColor:
                                AppColors.navy.withValues(alpha: 0.35),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add,
                              size: 16, color: Colors.white),
                          label: const Text('Agregar',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  if (_fasesSeleccionadas.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ..._fasesSeleccionadas.asMap().entries.map((entry) =>
                        _buildFaseSeleccionadaRow(entry.key, entry.value)),
                  ],
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
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: AppColors.textFaint),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.inputText),
                              items: const ['Baja', 'Media', 'Alta']
                                  .map((p) => DropdownMenuItem(
                                      value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _prioridad = v ?? 'Media'),
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
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: AppColors.textFaint),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.inputText),
                              items: const ['Baja', 'Media', 'Alta']
                                  .map((p) => DropdownMenuItem(
                                      value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _dificultad = v ?? 'Media'),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.errorBorder),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppColors.errorText, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed:
                                _loading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side:
                                  const BorderSide(color: AppColors.cardBorder),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(
                                    _isEdit ? 'Guardar Cambios' : 'Crear Orden',
                                    style: const TextStyle(
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

  /// Fila de un material ya agregado a la orden. El campo de cantidad
  /// nunca deja escribir/guardar más unidades que el stock disponible
  /// (s.material.stockActual): si el usuario escribe un número mayor,
  /// se corrige automáticamente al máximo permitido.
  Widget _buildFaseSeleccionadaRow(int index, _OperarioFaseSeleccionado fase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fase.operario.nombreCompleto,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: index == 0 ? null : () => _moverFase(index, -1),
                icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                color: AppColors.textMuted,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: index == _fasesSeleccionadas.length - 1
                    ? null
                    : () => _moverFase(index, 1),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                color: AppColors.textMuted,
              ),
              GestureDetector(
                onTap: () => _quitarFase(fase),
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.errorBg, shape: BoxShape.circle),
                  child: const Icon(Icons.close,
                      size: 14, color: AppColors.errorText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 64,
                child: TextFormField(
                  controller: fase.numeroCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: _dec('Fase'),
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.inputText),
                  onChanged: (v) =>
                      fase.numeroFase = int.tryParse(v) ?? fase.numeroFase,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: fase.descripcionCtrl,
                  decoration: _dec('Descripción'),
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.inputText),
                ),
              ),
            ],
          ),
        ],
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(
                    'Disponible: ${s.material.stockActual} ${s.material.unidad}',
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textFaint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: TextFormField(
              controller: s.cantidadCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.inputText),
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
              onChanged: (v) {
                final maxDisponible = s.material.stockActual;
                var parsed = int.tryParse(v) ?? 1;
                if (parsed < 1) parsed = 1;
                if (parsed > maxDisponible) parsed = maxDisponible;
                s.cantidad = parsed;
                // Si el usuario escribió más de lo disponible, se
                // corrige el texto visible al tope permitido.
                if ('$parsed' != v) {
                  s.cantidadCtrl.value = TextEditingValue(
                    text: '$parsed',
                    selection:
                        TextSelection.collapsed(offset: '$parsed'.length),
                  );
                }
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _quitarMaterial(s.material.idMaterial),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppColors.errorBg, shape: BoxShape.circle),
              child:
                  const Icon(Icons.close, size: 14, color: AppColors.errorText),
            ),
          ),
        ],
      ),
    );
  }
}
