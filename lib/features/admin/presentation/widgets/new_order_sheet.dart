import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/orden_repository.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/usuario_repository.dart';

/// Lista de materiales demo — reemplázala por tu propio endpoint/tabla
/// `material` cuando lo tengas en el backend, mismo patrón que
/// usuario_repository.dart.
const List<String> _materialesDemo = [
  'Algodón',
  'Poliéster',
  'Lino',
  'Denim',
  'Lycra',
  'Elastano',
];

class NewOrderSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const NewOrderSheet({super.key, required this.onCreated});

  @override
  State<NewOrderSheet> createState() => _NewOrderSheetState();
}

class _NewOrderSheetState extends State<NewOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repo = OrdenRepository();
  final _usuarioRepo = UsuarioRepository();

  final _productoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  List<Usuario> _clientes = [];
  List<Usuario> _operarios = [];
  bool _loadingUsuarios = true;

  Usuario? _clienteSeleccionado;
  Usuario? _operarioSeleccionado;
  final Set<String> _materialesSeleccionados = {};
  String _prioridad = 'Media';
  DateTime? _fechaLimite;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    try {
      final todos = await _usuarioRepo.getUsuarios();
      if (!mounted) return;
      setState(() {
        _clientes = todos.where((u) => u.isCliente).toList();
        _operarios = todos.where((u) => u.isOperario).toList();
        _loadingUsuarios = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingUsuarios = false);
    }
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

  Future<void> _pickMateriales() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _MaterialesPicker(initial: _materialesSeleccionados),
    );
    if (result != null) {
      setState(() {
        _materialesSeleccionados
          ..clear()
          ..addAll(result);
      });
    }
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
    if (_fechaLimite == null) {
      setState(() => _error = 'Selecciona la fecha límite');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.crearOrden(
        idCliente: _clienteSeleccionado!.idUsuario,
        producto: _productoCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        materiales: _materialesSeleccionados.toList(),
        cantidadTotal: int.tryParse(_cantidadCtrl.text.trim()) ?? 0,
        idOperario: _operarioSeleccionado!.idUsuario,
        prioridad: _prioridad,
        fechaLimite:
        '${_fechaLimite!.year.toString().padLeft(4, '0')}-${_fechaLimite!.month.toString().padLeft(2, '0')}-${_fechaLimite!.day.toString().padLeft(2, '0')}',
      );
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
                          Text('Crear Nueva Orden',
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
                    decoration: _dec(_loadingUsuarios ? 'Cargando...' : 'Selecciona un cliente'),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textFaint),
                    style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                    items: _clientes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.nombreCompleto)))
                        .toList(),
                    onChanged: (v) => setState(() => _clienteSeleccionado = v),
                  ),
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

                  _fieldLabel('Materiales'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickMateriales,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Text(
                        _materialesSeleccionados.isEmpty
                            ? 'Selecciona materiales'
                            : _materialesSeleccionados.join(', '),
                        style: TextStyle(
                          fontSize: 13,
                          color: _materialesSeleccionados.isEmpty
                              ? AppColors.inputPlaceholder
                              : AppColors.inputText,
                        ),
                      ),
                    ),
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
                    decoration: _dec(_loadingUsuarios ? 'Cargando...' : 'Seleccionar operador'),
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
                            _fieldLabel('Fecha Límite'),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _pickFecha,
                              child: Container(
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
                          ],
                        ),
                      ),
                    ],
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
                              shape:
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              shape:
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
}

/// Bottom sheet simple de selección múltiple de materiales.
class _MaterialesPicker extends StatefulWidget {
  final Set<String> initial;
  const _MaterialesPicker({required this.initial});

  @override
  State<_MaterialesPicker> createState() => _MaterialesPickerState();
}

class _MaterialesPickerState extends State<_MaterialesPicker> {
  late final Set<String> _seleccionados = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            const Text('Materiales',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ..._materialesDemo.map((m) => CheckboxListTile(
              value: _seleccionados.contains(m),
              title: Text(m, style: const TextStyle(fontSize: 13)),
              activeColor: AppColors.navy,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _seleccionados.add(m);
                } else {
                  _seleccionados.remove(m);
                }
              }),
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _seleccionados),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Listo',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}