import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/orden_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/orden_repository.dart';

/// Estilo de las etiquetas pequeñas en mayúsculas ("OPERARIO SOBRECARGADO",
/// "SUGERENCIAS DISPONIBLES") — mismo patrón usado en new_user_sheet.dart /
/// new_order_sheet.dart (_labelStyle).
const _labelStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.bold,
  letterSpacing: 0.8,
  color: AppColors.textMuted,
);

/// Bottom sheet "Reasignación de Órdenes" — se abre al presionar el botón
/// "Reasignar Órdenes" en [OperariosScreen] (pestaña "Carga Laboral").
///
/// Sigue el mismo diseño ya usado en la pantalla de reasignación:
///   1) "OPERARIO SOBRECARGADO": cards de los operarios sobrecargados que
///      recibió por parámetro. La card SELECCIONADA se resalta en rojo
///      con un check.
///   2) Al seleccionar uno: "Órdenes de {Nombre}" con sus órdenes activas
///      (código, fecha, % completado, barra de progreso) y, por cada
///      orden, "SUGERENCIAS DISPONIBLES" (operarios disponibles, de menor
///      a mayor carga) con botón "Reasignar".
///
/// Recibe los operarios ya clasificados (sobrecargados / disponibles) y
/// todas las órdenes desde [OperariosScreen], que es quien conoce la
/// capacidad configurada por operario.
class ReassignOrdersSheet extends StatefulWidget {
  final List<Usuario> sobrecargados;
  final List<Usuario> disponibles;
  final List<Orden> ordenes;
  final VoidCallback onChanged;

  const ReassignOrdersSheet({
    super.key,
    required this.sobrecargados,
    required this.disponibles,
    required this.ordenes,
    required this.onChanged,
  });

  @override
  State<ReassignOrdersSheet> createState() => _ReassignOrdersSheetState();
}

class _ReassignOrdersSheetState extends State<ReassignOrdersSheet> {
  final _ordenRepo = OrdenRepository();

  late List<Orden> _ordenes;
  int? _seleccionadoId;
  int? _procesandoOrdenId; // orden que se está reasignando (spinner del botón)
  bool _refrescando = false;

  @override
  void initState() {
    super.initState();
    _ordenes = List.of(widget.ordenes);
    // Si solo hay un operario sobrecargado, lo pre-seleccionamos para
    // ahorrarle un tap al usuario (mismo criterio que el diseño, donde
    // Felipe ya aparece seleccionado al abrir la pantalla).
    if (widget.sobrecargados.length == 1) {
      _seleccionadoId = widget.sobrecargados.first.idUsuario;
    }
  }

  /// Refresca la lista de órdenes desde el backend (tras una reasignación)
  /// para que los contadores y las sugerencias queden al día sin cerrar
  /// el sheet.
  Future<void> _refrescarOrdenes() async {
    setState(() => _refrescando = true);
    try {
      final data = await _ordenRepo.getOrdenes();
      if (!mounted) return;
      setState(() => _ordenes = data);
    } catch (_) {
      // Si falla el refresh silencioso, el usuario aún puede cerrar el
      // sheet y refrescar desde la pantalla principal (onChanged ya se
      // llama de todas formas tras cada reasignación exitosa).
    } finally {
      if (mounted) setState(() => _refrescando = false);
    }
  }

  List<Orden> _activasDe(int idOperario) {
    return _ordenes.where((o) => o.idOperario == idOperario && !o.isCompletada).toList();
  }

  Usuario? get _seleccionado {
    if (_seleccionadoId == null) return null;
    for (final u in widget.sobrecargados) {
      if (u.idUsuario == _seleccionadoId) return u;
    }
    return null;
  }

  /// Operarios disponibles para recibir órdenes, ordenados de menor a
  /// mayor carga actual.
  List<MapEntry<Usuario, int>> _sugerencias() {
    final lista = widget.disponibles
        .map((u) => MapEntry(u, _activasDe(u.idUsuario).length))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return lista.take(3).toList();
  }

  Future<void> _reasignar(Orden orden, Usuario nuevoOperario) async {
    setState(() => _procesandoOrdenId = orden.idOrden);
    try {
      await _ordenRepo.actualizarOrden(
        id: orden.idOrden,
        idCliente: orden.idCliente,
        producto: orden.producto,
        descripcion: orden.descripcion,
        materiales: orden.materiales,
        cantidadTotal: orden.cantidadTotal,
        cantidadActual: orden.cantidadActual,
        idOperario: nuevoOperario.idUsuario,
        prioridad: orden.prioridad,
        estado: orden.estado,
        fechaLimite: orden.fechaLimite ?? '',
      );
      widget.onChanged(); // refresca la pantalla de fondo (Carga Laboral)
      await _refrescarOrdenes(); // refresca el propio sheet
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${orden.codigoOrden} reasignada a ${nuevoOperario.nombreCompleto}.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _procesandoOrdenId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
              _buildHandleAndHeader(),
              const Divider(height: 1, color: AppColors.cardBorder),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _buildSobrecargados(),
                    const SizedBox(height: 20),
                    _buildOrdenesSeleccionado(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandleAndHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reasignación de Órdenes',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    SizedBox(height: 2),
                    Text('Selecciona un operario sobrecargado',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (_refrescando)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                  ),
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
        ],
      ),
    );
  }

  Widget _buildSobrecargados() {
    if (widget.sobrecargados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No hay operarios sobrecargados en este momento.',
          style: TextStyle(fontSize: 12, color: AppColors.textFaint),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OPERARIO SOBRECARGADO', style: _labelStyle),
        const SizedBox(height: 10),
        ...widget.sobrecargados.map((u) {
          final activas = _activasDe(u.idUsuario);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OperarioOverloadCard(
              usuario: u,
              cantidadActivas: activas.length,
              selected: u.idUsuario == _seleccionadoId,
              onTap: () => setState(() => _seleccionadoId = u.idUsuario),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOrdenesSeleccionado() {
    final seleccionado = _seleccionado;
    if (seleccionado == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Selecciona un operario para ver sus órdenes.',
          style: TextStyle(fontSize: 12, color: AppColors.textFaint),
        ),
      );
    }
    final ordenes = _activasDe(seleccionado.idUsuario);
    final sugerencias = _sugerencias();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Órdenes de ${seleccionado.nombreCompleto.split(' ').first}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
              child: Text(
                '${ordenes.length}',
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (ordenes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Este operario no tiene órdenes activas.',
                style: TextStyle(fontSize: 12, color: AppColors.textFaint)),
          )
        else
          ...ordenes.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrdenReasignacionCard(
                  orden: o,
                  sugerencias: sugerencias,
                  procesando: _procesandoOrdenId == o.idOrden,
                  onReasignar: (nuevoOperario) => _reasignar(o, nuevoOperario),
                ),
              )),
      ],
    );
  }
}

/// Card de "operario sobrecargado" — se resalta en rojo con un check
/// cuando está seleccionada (misma paleta errorBg/errorBorder/errorText
/// que ya usa el resto de la app).
class _OperarioOverloadCard extends StatelessWidget {
  final Usuario usuario;
  final int cantidadActivas;
  final bool selected;
  final VoidCallback onTap;

  const _OperarioOverloadCard({
    required this.usuario,
    required this.cantidadActivas,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final av = AppColors.avatarPalette[usuario.idUsuario % AppColors.avatarPalette.length];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.errorBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.errorBorder : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AvatarWidget(initials: usuario.initials, size: 40, bg: av['bg']!, text: av['text']!),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nombreCompleto,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$cantidadActivas órdenes activas',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: const Icon(Icons.check, size: 14, color: AppColors.errorText),
              ),
          ],
        ),
      ),
    );
  }
}

/// Card de una orden activa del operario seleccionado, con su barra de
/// progreso y la lista de sugerencias de reasignación debajo.
class _OrdenReasignacionCard extends StatelessWidget {
  final Orden orden;
  final List<MapEntry<Usuario, int>> sugerencias;
  final bool procesando;
  final ValueChanged<Usuario> onReasignar;

  const _OrdenReasignacionCard({
    required this.orden,
    required this.sugerencias,
    required this.procesando,
    required this.onReasignar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  orden.producto,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.badgeOpBlueBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  orden.codigoOrden,
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.badgeOpBlueText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Vence: ${orden.fechaCorta.isEmpty ? 'Sin fecha' : orden.fechaCorta} · '
            '${orden.progresoPorcentaje}% completado',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: orden.progreso,
              minHeight: 6,
              backgroundColor: AppColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.purple),
            ),
          ),
          const SizedBox(height: 14),
          const Text('SUGERENCIAS DISPONIBLES', style: _labelStyle),
          const SizedBox(height: 10),
          if (sugerencias.isEmpty)
            const Text(
              'No hay operarios disponibles para reasignar.',
              style: TextStyle(fontSize: 11, color: AppColors.textFaint),
            )
          else
            ...sugerencias.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SugerenciaRow(
                    usuario: s.key,
                    cantidadActivas: s.value,
                    disabled: procesando,
                    onReasignar: () => onReasignar(s.key),
                  ),
                )),
        ],
      ),
    );
  }
}

/// Fila de operario sugerido + botón "Reasignar" (mismo patrón de avatar
/// circular con iniciales que usa el resto de la app).
class _SugerenciaRow extends StatelessWidget {
  final Usuario usuario;
  final int cantidadActivas;
  final bool disabled;
  final VoidCallback onReasignar;

  const _SugerenciaRow({
    required this.usuario,
    required this.cantidadActivas,
    required this.disabled,
    required this.onReasignar,
  });

  @override
  Widget build(BuildContext context) {
    final av = AppColors.avatarPalette[usuario.idUsuario % AppColors.avatarPalette.length];

    return Row(
      children: [
        AvatarWidget(initials: usuario.initials, size: 32, bg: av['bg']!, text: av['text']!),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario.nombreCompleto,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              Text(
                '$cantidadActivas órdenes',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 30,
          child: ElevatedButton(
            onPressed: disabled ? null : onReasignar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: disabled
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Reasignar',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}