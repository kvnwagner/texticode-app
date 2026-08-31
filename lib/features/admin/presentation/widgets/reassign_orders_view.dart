import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/orden_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/orden_repository.dart';

/// Vista completa de "Reasignación de Órdenes" (reemplaza al antiguo
/// ReassignOrdersSheet). Ya no es un modal emergente: vive dentro del
/// mismo body de OperariosScreen, con botón de volver.
///
/// Flujo:
///  1. Arriba se listan los operarios sobrecargados; se selecciona uno
///     (tap sobre la tarjeta, comportamiento tipo radio).
///  2. Debajo se listan las órdenes activas de ese operario.
///  3. Cada orden trae sus "sugerencias disponibles" (los operarios con
///     capacidad libre) con un botón "Reasignar" directo por sugerencia.
///
/// Reutiliza OrdenRepository.actualizarOrden — mismo patrón que
/// EditUserSheet / NewOrderSheet: cambia solo Id_Operario y conserva el
/// resto de la orden.
class ReassignOrdersView extends StatefulWidget {
  final List<Usuario> sobrecargados;
  final List<Usuario> disponibles;
  final List<Orden> ordenes;
  final VoidCallback onChanged;
  final VoidCallback onBack;

  const ReassignOrdersView({
    super.key,
    required this.sobrecargados,
    required this.disponibles,
    required this.ordenes,
    required this.onChanged,
    required this.onBack,
  });

  @override
  State<ReassignOrdersView> createState() => _ReassignOrdersViewState();
}

class _ReassignOrdersViewState extends State<ReassignOrdersView> {
  final _repo = OrdenRepository();
  Usuario? _seleccionado;
  int? _reasignando; // idOrden en curso
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.sobrecargados.isNotEmpty) _seleccionado = widget.sobrecargados.first;
  }

  @override
  void didUpdateWidget(covariant ReassignOrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el operario seleccionado ya no está sobrecargado (p. ej. se
    // reasignaron todas sus órdenes), cae al siguiente disponible.
    final sigueSobrecargado = _seleccionado != null &&
        widget.sobrecargados.any((u) => u.idUsuario == _seleccionado!.idUsuario);
    if (!sigueSobrecargado) {
      _seleccionado = widget.sobrecargados.isNotEmpty ? widget.sobrecargados.first : null;
    }
  }

  int _activasDe(Usuario u) =>
      widget.ordenes.where((o) => o.idOperario == u.idUsuario && !o.isCompletada).length;

  List<Orden> _ordenesDe(Usuario u) =>
      widget.ordenes.where((o) => o.idOperario == u.idUsuario && !o.isCompletada).toList();

  Future<void> _reasignar(Orden o, int nuevoOperario) async {
    setState(() {
      _reasignando = o.idOrden;
      _error = null;
    });
    try {
      await _repo.reasignarOperario(orden: o, nuevoIdOperario: nuevoOperario);
      widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Orden reasignada correctamente.')));
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _reasignando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seleccionado = _seleccionado;
    final ordenesSeleccionado = seleccionado == null ? <Orden>[] : _ordenesDe(seleccionado);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildHeader(),
        if (_error != null) _buildErrorBanner(),
        const Text(
          'OPERARIO SOBRECARGADO',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textFaint, letterSpacing: 0.4),
        ),
        const SizedBox(height: 10),
        if (widget.sobrecargados.isEmpty) _buildSinSobrecargados(),
        ...widget.sobrecargados.map(
          (u) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildOperarioCard(u, seleccionado: seleccionado?.idUsuario == u.idUsuario),
          ),
        ),
        if (seleccionado != null) ...[
          const SizedBox(height: 10),
          _buildSectionHeader(
              'Órdenes de ${seleccionado.nombreCompleto.split(' ').first}', ordenesSeleccionado.length),
          const SizedBox(height: 10),
          if (ordenesSeleccionado.isEmpty) _buildSinOrdenes(),
          ...ordenesSeleccionado.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildOrdenCard(o),
            ),
          ),
        ],
      ],
    );
  }

  // ── HEADER ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.searchBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 15, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Reasignación de Órdenes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.cardBorder),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Text(_error!, style: const TextStyle(color: AppColors.errorText, fontSize: 12)),
    );
  }

  // ── OPERARIOS SOBRECARGADOS ──

  Widget _buildOperarioCard(Usuario u, {required bool seleccionado}) {
    final av = AppColors.avatarPalette[u.idUsuario % AppColors.avatarPalette.length];
    return GestureDetector(
      onTap: () => setState(() => _seleccionado = u),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.errorBg : AppColors.pageBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? AppColors.errorBorder : AppColors.cardBorder,
            width: seleccionado ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            AvatarWidget(initials: u.initials, size: 38, bg: av['bg']!, text: av['text']!),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.nombreCompleto,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('${_activasDe(u)} órdenes activas',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (seleccionado) const Icon(Icons.check_circle, size: 22, color: AppColors.errorText),
          ],
        ),
      ),
    );
  }

  Widget _buildSinSobrecargados() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded, size: 30, color: AppColors.textFaint),
          SizedBox(height: 8),
          Text('No hay operarios sobrecargados en este momento.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
        ],
      ),
    );
  }

  // ── ÓRDENES DEL OPERARIO SELECCIONADO ──

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
          child: Text('$count',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildSinOrdenes() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Text('Este operario no tiene órdenes activas.',
          style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
    );
  }

  Widget _buildOrdenCard(Orden o) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(o.producto,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration:
                    BoxDecoration(color: AppColors.badgeOpBlueBg, borderRadius: BorderRadius.circular(20)),
                child: Text(o.codigoOrden,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.badgeOpBlueText)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Vence: ${o.fechaCorta} · ${o.progresoPorcentaje}% completado',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: o.progreso,
              minHeight: 6,
              backgroundColor: AppColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.navy),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'SUGERENCIAS DISPONIBLES',
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textFaint, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          if (widget.disponibles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('No hay operarios con capacidad disponible.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textFaint)),
            )
          else
            ...widget.disponibles.map(
              (u) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSugerenciaRow(o, u),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSugerenciaRow(Orden o, Usuario u) {
    final av = AppColors.avatarPalette[u.idUsuario % AppColors.avatarPalette.length];
    final loading = _reasignando == o.idOrden;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AvatarWidget(initials: u.initials, size: 30, bg: av['bg']!, text: av['text']!),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.nombreCompleto,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('${_activasDe(u)} órdenes',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textFaint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: loading ? null : () => _reasignar(o, u.idUsuario),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Reasignar',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}