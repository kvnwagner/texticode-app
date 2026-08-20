import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/material_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/repositories/usuario_repository.dart';

const _categorias = ['Accesorios', 'Telas', 'Hilos', 'Herramientas'];
const _unidades = ['Unidades', 'Metros', 'Carretes', 'Gramos', 'Kilogramos'];

/// Bottom sheet para crear (o editar, si se pasa [material]) un
/// material de inventario. Sigue el mismo patrón visual y de
/// validación que new_order_sheet.dart / new_user_sheet.dart.
class NewMaterialSheet extends StatefulWidget {
  final VoidCallback onCreated;
  final MaterialItem? material;

  const NewMaterialSheet({super.key, required this.onCreated, this.material});

  @override
  State<NewMaterialSheet> createState() => _NewMaterialSheetState();
}

class _NewMaterialSheetState extends State<NewMaterialSheet> {
  final _repo = MaterialRepository();
  final _usuarioRepo = UsuarioRepository();

  final _nombreCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  String? _categoria;
  String? _unidad;
  int? _idCliente;

  List<Usuario> _clientes = [];
  bool _loadingClientes = true;
  bool _saving = false;
  final Map<String, String> _errors = {};

  bool get _isEdit => widget.material != null;

  @override
  void initState() {
    super.initState();
    final m = widget.material;
    if (m != null) {
      _nombreCtrl.text = m.nombre;
      _stockCtrl.text = '${m.stockActual}';
      _minCtrl.text = '${m.stockMinimo}';
      _maxCtrl.text = '${m.stockMaximo}';
      _categoria = m.categoria;
      _unidad = m.unidad;
      _idCliente = m.idCliente;
    }
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    try {
      final data = await _usuarioRepo.getUsuarios();
      if (!mounted) return;
      setState(() {
        _clientes = data.where((u) => u.isCliente).toList();
        _loadingClientes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingClientes = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _stockCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  bool _validar() {
    _errors.clear();
    if (_nombreCtrl.text.trim().isEmpty) {
      _errors['nombre'] = 'El nombre es requerido';
    }
    if (_categoria == null) _errors['categoria'] = 'Selecciona una categoría';
    if (_unidad == null) _errors['unidad'] = 'Selecciona una unidad';
    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _guardar() async {
    if (!_validar()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await _repo.actualizarMaterial(
          id: widget.material!.idMaterial,
          nombre: _nombreCtrl.text.trim(),
          categoria: _categoria!,
          stockActual: int.tryParse(_stockCtrl.text) ?? 0,
          unidad: _unidad!,
          stockMinimo: int.tryParse(_minCtrl.text) ?? 0,
          stockMaximo: int.tryParse(_maxCtrl.text) ?? 0,
          idCliente: _idCliente,
        );
      } else {
        await _repo.crearMaterial(
          nombre: _nombreCtrl.text.trim(),
          categoria: _categoria!,
          stockActual: int.tryParse(_stockCtrl.text) ?? 0,
          unidad: _unidad!,
          stockMinimo: int.tryParse(_minCtrl.text) ?? 0,
          stockMaximo: int.tryParse(_maxCtrl.text) ?? 0,
          idCliente: _idCliente,
        );
      }
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec({String? hint, String? error}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: error != null ? AppColors.errorText : AppColors.inputBorder,
              width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: error != null ? AppColors.errorText : AppColors.inputBorder,
              width: 1.5),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.labelColor)),
      );

  Widget _errorText(String? key) {
    if (key == null || !_errors.containsKey(key)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(_errors[key]!,
          style: const TextStyle(fontSize: 10, color: AppColors.errorText)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder, borderRadius: BorderRadius.circular(20)),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? 'Editar MaterialItem' : 'Agregar Nuevo MaterialItem',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.searchBg,
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.close, size: 15, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nombre del MaterialItem'),
                    TextField(
                      controller: _nombreCtrl,
                      decoration: _dec(hint: 'Ej: Tela de Algodón', error: _errors['nombre']),
                      style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                    ),
                    _errorText('nombre'),
                    const SizedBox(height: 16),
                    _label('Categoría'),
                    DropdownButtonFormField<String>(
                      initialValue: _categoria,
                      decoration: _dec(hint: 'Selecciona categoría', error: _errors['categoria']),
                      hint: const Text('Selecciona categoría',
                          style: TextStyle(fontSize: 13, color: AppColors.iconDefault)),
                      style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                      items: _categorias
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _categoria = v),
                    ),
                    _errorText('categoria'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Stock Actual'),
                              TextField(
                                controller: _stockCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _dec(hint: '0'),
                                style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Unidad'),
                              DropdownButtonFormField<String>(
                                initialValue: _unidad,
                                decoration: _dec(hint: 'Unidad', error: _errors['unidad']),
                                hint: const Text('Unidad',
                                    style: TextStyle(fontSize: 13, color: AppColors.iconDefault)),
                                style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                                items: _unidades
                                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                    .toList(),
                                onChanged: (v) => setState(() => _unidad = v),
                              ),
                              _errorText('unidad'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Stock Mínimo'),
                              TextField(
                                controller: _minCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _dec(hint: '0'),
                                style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Stock Máximo'),
                              TextField(
                                controller: _maxCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _dec(hint: '0'),
                                style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label('Cliente'),
                    _loadingClientes
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : DropdownButtonFormField<int?>(
                            initialValue: _idCliente,
                            decoration: _dec(hint: '— Sin cliente asignado —'),
                            style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                            items: [
                              const DropdownMenuItem<int?>(
                                  value: null, child: Text('— Sin cliente asignado —')),
                              ..._clientes.map((c) => DropdownMenuItem<int?>(
                                  value: c.idUsuario, child: Text(c.nombreCompleto))),
                            ],
                            onChanged: (v) => setState(() => _idCliente = v),
                          ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_isEdit ? 'Guardar Cambios' : 'Agregar MaterialItem',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}